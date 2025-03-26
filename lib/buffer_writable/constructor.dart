part of dart_source_builder;

class Constructor implements BufferWritable {
  final bool Const;
  final bool factory;
  final String className;
  final String? constructorName;
  late List<ConstructorParameter> unnamedParameters;
  late List<ConstructorParameter> optionalParameters;
  late List<ConstructorParameter> namedParameters;
  final bool multiLineParameters;
  List<AssertionInitializer> assertionInitializers;
  List<PropertyInitializer> propertyInitializers;
  SuperInitializer? superInitializer;
  final void Function(StringBuffer)? body;

  Constructor({
    this.Const = false,
    this.factory = false,
    required this.className,
    this.constructorName,
    List<ConstructorParameter>? parameters,
    this.multiLineParameters = true,
    List<AssertionInitializer>? assertionInitializers,
    List<PropertyInitializer>? propertyInitializers,
    this.superInitializer,
    this.body,
  })  : assertionInitializers = assertionInitializers ?? [],
        propertyInitializers = propertyInitializers ?? [] {
    if (parameters != null) {
      this.unnamedParameters = parameters.where((p) => !p.named).toList();
      this.optionalParameters = parameters.where((p) => p.optional).toList();
      this.namedParameters = parameters.where((p) => p.named).toList();
    } else {
      this.unnamedParameters = [];
      this.optionalParameters = [];
      this.namedParameters = [];
    }
    assert(
      !(optionalParameters.isNotEmpty && namedParameters.isNotEmpty),
      'The constructor [${className}.$constructorName] can have optional parameters or named parameters but not both',
    );
  }

  static Future<Constructor> from(
    ConstructorElement constructorElement,
    BuildStep buildStep, {
    bool? factory,
    String? className,
    String? constructorName,
    List<ConstructorParameter>? parameters,
    bool? multiLineParameters,
    List<AssertionInitializer>? assertionInitializers,
    List<PropertyInitializer>? propertyInitializers,
    SuperInitializer? superInitializer,
    // void Function(StringBuffer)? body,
  }) async {
    ConstructorDeclaration astNode = await buildStep.resolver.astNodeFor(constructorElement) as ConstructorDeclaration;
    return Constructor(
        factory: factory ?? constructorElement.isFactory,
        className: className ?? constructorElement.enclosingElement.name,
        constructorName: constructorName ?? constructorElement.name,
        parameters:
            parameters ?? await constructorElement.parameters.mapAsync((e) => ConstructorParameter.from(e, buildStep)),
        multiLineParameters: multiLineParameters ?? true,
        assertionInitializers: assertionInitializers ??
            await astNode.initializers
                .whereType<AssertInitializer>()
                .toList()
                .mapAsync((e) => AssertionInitializer.from(e, buildStep)),
        propertyInitializers: propertyInitializers ??
            await astNode.initializers
                .whereType<ConstructorFieldInitializer>()
                .toList()
                .mapAsync((e) => PropertyInitializer.from(e, buildStep)),
        superInitializer: superInitializer ??
            await SuperInitializer.from(
                astNode.initializers.firstWhereType<SuperConstructorInvocation>() as SuperConstructorInvocation,
                buildStep),
        body: (astNode.body is EmptyFunctionBody)
            ? null
            : (StringBuffer b) {
                BlockFunctionBody body = astNode.body as BlockFunctionBody;
                b.write(body.block.statements.toCleanString());
              });
  }

  void _writeToBuffer(StringBuffer b) {
    if (Const) b.write('const ');
    if (factory) b.write('factory ');
    b.write(className);
    if (constructorName != null) b.write('.${constructorName}');
    b.write('(');

    if (unnamedParameters.isNotEmpty) {
      unnamedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < unnamedParameters.length - 1)
          b.write(', ');
        else {
          if (namedParameters.isNotEmpty || optionalParameters.isNotEmpty)
            b.write(', ');
          else {
            if (multiLineParameters) b.write(', ');
          }
        }
      });
    }

    if (namedParameters.isNotEmpty) {
      b.write('{');
      namedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < namedParameters.length - 1)
          b.write(', ');
        else {
          if (multiLineParameters) b.write(',');
          b.write('}');
        }
      });
    }

    if (optionalParameters.isNotEmpty) {
      b.write('[');
      optionalParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < optionalParameters.length - 1)
          b.write(', ');
        else {
          if (multiLineParameters) b.write(',');
          b.write(']');
        }
      });
    }

    b.write(')');

    if (assertionInitializers.isNotEmpty || propertyInitializers.isNotEmpty || superInitializer != null) {
      b.write(' : ');
      assertionInitializers.asMap().forEach((i, initializer) {
        initializer._writeToBuffer(b);
        if (i < assertionInitializers.length - 1)
          b.write(', ');
        else {
          if (propertyInitializers.isNotEmpty || superInitializer != null) b.write(',');
        }
      });

      propertyInitializers.asMap().forEach((i, initializer) {
        initializer._writeToBuffer(b);
        if (i < propertyInitializers.length - 1)
          b.write(', ');
        else {
          if (superInitializer != null) b.write(',');
        }
      });

      superInitializer?._writeToBuffer(b);
    }

    if (body != null) {
      b.write(' { ');
      StringBuffer buffer = StringBuffer();
      body!(buffer);
      b.write(buffer.toString());
      b.write('}');
    } else
      b.write(';');
  }
}

class ConstructorParameter implements BufferWritable {
  final bool named;
  final bool Required;
  final bool optional;
  final bool assigned;
  final String? type;
  final String name;
  final String? defaultValue;

  ConstructorParameter({
    required this.name,
    this.named = false,
    this.Required = false,
    this.optional = false,
    this.assigned = false,
    this.type,
    this.defaultValue,
  })  : assert(!(named && optional), 'The constructor parameter [$name] can be either named or optional, but not both'),
        assert(!Required || (Required && named),
            'If the constructor parameter [$name] is required, then it must be named'),
        assert(!(assigned && type != null),
            'If the constructor parameter [$name] is assigned, then there is no point in setting its type'),
        assert(defaultValue == null || ((named && !Required) || optional),
            'the constructor parameter [$name] is not optional, yet it has a default value');

  static Future<ConstructorParameter> from(
    ParameterElement parameterElement,
    BuildStep buildStep, {
    bool? named,
    bool? Required,
    bool? optional,
    bool? assigned,
    String? type,
    String? name,
    String? defaultValue,
  }) async =>
      await ConstructorParameter(
        name: name ?? parameterElement.name,
        named: named ?? parameterElement.isNamed,
        Required: Required ?? parameterElement.isRequiredNamed,
        optional: optional ?? parameterElement.isOptionalPositional,
        assigned: assigned ?? parameterElement.isInitializingFormal,
        type: type ?? parameterElement.type.toString(),
        defaultValue: defaultValue ?? parameterElement.defaultValueCode,
      );

  void _writeToBuffer(StringBuffer b) {
    if (!named && !optional) {
      if (type != null)
        b.write('${type} ');
      else if (assigned) b.write('this.');
      b.write(name);
    } else {
      if (named) {
        if (Required) b.write('required ');
      }
      if (type != null)
        b.write('${type} ');
      else if (assigned) b.write('this.');
      b.write('$name');
      if (defaultValue != null) b.write(' = $defaultValue');
    }
  }
}

abstract class ConstructorInitializer implements BufferWritable {}

class AssertionInitializer extends ConstructorInitializer {
  final String expression;
  final String message;

  AssertionInitializer({
    required this.expression,
    required this.message,
  });

  static Future<AssertionInitializer> from(
    AssertInitializer assertInitializer,
    BuildStep buildStep, {
    String? expression,
    String? message,
  }) async =>
      await AssertionInitializer(
        expression: expression ?? '${assertInitializer.condition}',
        message: message ?? '${assertInitializer.message}',
      );

  void _writeToBuffer(StringBuffer b) {
    b.write('assert($expression, \'$message\')');
  }
}

class PropertyInitializer extends ConstructorInitializer {
  final String name;
  final String value;

  PropertyInitializer({
    required this.name,
    required this.value,
  });

  static Future<PropertyInitializer> from(
    ConstructorFieldInitializer constructorFieldInitializer,
    BuildStep buildStep, {
    String? name,
    String? value,
  }) async =>
      await PropertyInitializer(
        name: name ?? '${constructorFieldInitializer.fieldName}',
        value: value ?? '${constructorFieldInitializer.expression}',
      );

  void _writeToBuffer(StringBuffer b) {
    b.write('$name = $value');
  }
}

class SuperInitializer extends ConstructorInitializer {
  final String? name;
  final List<SuperInitializerArgument> arguments;
  final bool multiLineArguments;

  SuperInitializer({
    this.name,
    List<SuperInitializerArgument>? arguments,
    this.multiLineArguments = true,
  }) : arguments = arguments ?? [];

  static Future<SuperInitializer> from(
    SuperConstructorInvocation superConstructorInvocation,
    BuildStep buildStep, {
    String? name,
    List<SuperInitializerArgument>? arguments,
    bool? multiLineArguments,
  }) async =>
      await SuperInitializer(
        name: name ?? '${superConstructorInvocation.constructorName}',
        arguments: arguments ??
            await superConstructorInvocation.argumentList.arguments
                .mapAsync((e) => SuperInitializerArgument.from(e, buildStep)),
        multiLineArguments: multiLineArguments ?? true,
      );

  void _writeToBuffer(StringBuffer b) {
    b.write('super');
    if (name != null) b.write('.${name}');
    b.write('(');
    if (arguments.isNotEmpty) {
      arguments.asMap().forEach((i, argument) {
        argument._writeToBuffer(b);
        if (i < arguments.length - 1)
          b.write(',');
        else {
          if (multiLineArguments) b.write(',');
        }
      });
    }
    b.write(')');
  }
}

class SuperInitializerArgument implements BufferWritable {
  final String? name;
  final String value;

  SuperInitializerArgument({
    this.name,
    required this.value,
  });

  static Future<SuperInitializerArgument> from(
    Expression argumentExpression,
    BuildStep buildStep, {
    String? name,
    String? value,
  }) async =>
      await SuperInitializerArgument(
        name: name ?? ((argumentExpression is NamedExpression) ? '${argumentExpression.name}' : null),
        value: value ??
            ((argumentExpression is NamedExpression) ? '${argumentExpression.expression}' : '$argumentExpression'),
      );

  void _writeToBuffer(StringBuffer b) {
    b.write((name == null) ? '' : '$name: ');
    b.write(value);
  }
}
