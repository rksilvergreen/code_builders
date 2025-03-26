part of dart_source_builder;

class Method implements BufferWritable {
  final bool override;
  final bool static;
  final String? returnType;
  final String name;
  final List<MethodParameter> unnamedParameters;
  final List<MethodParameter> optionalParameters;
  final List<MethodParameter> namedParameters;
  final List<String>? genericTypes;
  final bool multiLineParameters;
  final bool async;
  final bool generator;
  final bool arrowFunction;
  void Function(StringBuffer) body;

  Method({
    this.override = false,
    this.static = false,
    this.returnType,
    required this.name,
    List<MethodParameter>? parameters,
    this.genericTypes,
    this.multiLineParameters = true,
    this.async = false,
    this.generator = false,
    this.arrowFunction = false,
    required this.body,
  })  : unnamedParameters = (parameters != null) ? parameters.where((p) => !p.named).toList() : [],
        optionalParameters = (parameters != null) ? parameters.where((p) => p.optional).toList() : [],
        namedParameters = (parameters != null) ? parameters.where((p) => p.named).toList() : [] {
    assert(
      !(optionalParameters.isNotEmpty && namedParameters.isNotEmpty),
      'The method [$name] can have optional parameters or named parameters but not both',
    );
    assert(
        body != null || (body == null && arrowFunction), 'The method [$name] can\'t be an arrow function with no body');
  }

  static Future<Method> from(
    MethodElement methodElement,
    BuildStep buildStep, {
    bool? override,
    bool? static,
    String? returnType,
    String? name,
    List<MethodParameter>? parameters,
    List<String>? genericTypes,
    bool? multiLineParameters,
    bool? async,
    bool? generator,
    bool? arrowFunction,
    Function(StringBuffer)? body,
  }) async {
    MethodDeclaration astNode = await buildStep.resolver.astNodeFor(methodElement) as MethodDeclaration;
    return Method(
        override: override ?? methodElement.metadata.any((elementAnnotation) => elementAnnotation.isOverride),
        static: static ?? methodElement.isStatic,
        returnType: returnType ?? '${methodElement.returnType}',
        name: name ?? methodElement.name,
        parameters: parameters ?? await methodElement.parameters.mapAsync((p) => MethodParameter.from(p, buildStep)),
        genericTypes: genericTypes ?? methodElement.typeParameters.map((p) => '$p').toList(),
        multiLineParameters: multiLineParameters ?? true,
        async: async ?? methodElement.isAsynchronous,
        generator: generator ?? methodElement.isGenerator,
        arrowFunction: astNode.body is ExpressionFunctionBody,
        body: (astNode.body is EmptyFunctionBody)
            ? (StringBuffer b) => ''
            : (StringBuffer b) {
                FunctionBody body = astNode.body;
                if (body is BlockFunctionBody)
                  b.write(body.block.statements.toCleanString());
                else if (body is ExpressionFunctionBody) b.write('${body.expression}');
              });
  }

  void _writeToBuffer(StringBuffer b) {
    if (override) b.write('@override ');
    if (static) b.write('static ');
    if (returnType != null) b.write('${returnType} ');
    b.write('${name}');
    if (genericTypes != null) b.write('<${genericTypes!.toCleanString(',')}>');

    b.write('(');

    if (namedParameters.length > 0 && unnamedParameters.length == 0) b.write('{');
    if (optionalParameters.length > 0 && unnamedParameters.length == 0) b.write('[');

    if (unnamedParameters.length > 0) {
      unnamedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < unnamedParameters.length - 1)
          b.write(',');
        else {
          if (namedParameters.length > 0)
            b.write(', {');
          else if (optionalParameters.length > 0)
            b.write(', [');
          else {
            if (multiLineParameters) b.write(', ');
          }
        }
      });
    }

    if (namedParameters.length > 0) {
      namedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < namedParameters.length - 1)
          b.write(',');
        else {
          if (multiLineParameters) b.write(',');
          b.write('}');
        }
      });
    }

    if (optionalParameters.length > 0) {
      optionalParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < optionalParameters.length - 1)
          b.write(',');
        else {
          if (multiLineParameters) b.write(',');
          b.write(']');
        }
      });
    }
    b.write(') ');

    if (body == null) {
      b.write(';');
      return;
    }

    if (async) {
      if (generator)
        b.write('async* ');
      else
        b.write('async ');
    } else if (generator) b.write('sync* ');

    if (arrowFunction)
      b.write('=>');
    else
      b.write('{');

    StringBuffer buffer = StringBuffer();
    body(buffer);
    b.write(buffer.toString());

    if (arrowFunction)
      b.write(';');
    else {
      b.write('}');
    }
  }
}

class MethodParameter implements BufferWritable {
  final bool covariant;
  final String name;
  final bool named;
  final bool Required;
  final bool optional;
  final String type;
  final String? defaultValue;

  MethodParameter({
    this.covariant = false,
    required this.name,
    this.named = false,
    this.Required = false,
    this.optional = false,
    this.type = '',
    this.defaultValue,
  })  : assert(!(named && optional), 'The method parameter [$name] can be either named or optional, but not both'),
        assert(!Required || (Required && named), 'If the method parameter [$name] is required, then it must be named'),
        assert(defaultValue == null || ((defaultValue != null) && ((named && !Required) || optional)),
            'the method parameter [$name] is not optional, yet it has a default value');

  static Future<MethodParameter> from(
    ParameterElement parameterElement,
    BuildStep buildStep, {
    bool? covariant,
    String? name,
    bool? named,
    bool? Required,
    bool? optional,
    String? type,
    String? defaultValue,
  }) async {
    FormalParameter astNode = await buildStep.resolver.astNodeFor(parameterElement) as FormalParameter;
    return MethodParameter(
      covariant: covariant ?? parameterElement.isCovariant,
      name: name ?? parameterElement.name,
      named: named ?? parameterElement.isNamed,
      Required: Required ?? parameterElement.isRequiredNamed,
      optional: optional ?? parameterElement.isOptionalPositional,
      type: type ?? '${parameterElement.type}',
      defaultValue: defaultValue ?? ((astNode is DefaultFormalParameter) ? '$astNode.defaultValue}' : null),
    );
  }

  void _writeToBuffer(StringBuffer b) {
    if (!named && !optional) {
      if (covariant) b.write('covariant ');
      b.write('$type ');
      b.write('$name');
    } else {
      if (named) {
        if (Required) b.write('required ');
      }
      if (covariant) b.write('covariant ');
      b.write('$type ');
      b.write('$name');
      if (defaultValue != null) b.write(' = $defaultValue');
    }
  }
}
