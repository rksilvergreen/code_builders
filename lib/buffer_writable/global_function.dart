part of dart_source_builder;

class GlobalFunction extends PublicBufferWritable {
  final String? returnType;
  final String name;
  late List<FunctionParameter> unnamedParameters;
  late List<FunctionParameter> optionalParameters;
  late List<FunctionParameter> namedParameters;
  final List<String>? genericTypes;
  final bool multiLineParameters;
  final bool async;
  final bool generator;
  final bool arrowFunction;
  void Function(StringBuffer) body;

  GlobalFunction({
    this.returnType,
    required this.name,
    List<FunctionParameter>? parameters,
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

  static Future<GlobalFunction> from(
    FunctionElement functionElement,
    BuildStep buildStep, {
    bool? override,
    bool? static,
    String? returnType,
    String? name,
    List<FunctionParameter>? parameters,
    List<String>? genericTypes,
    bool? multiLineParameters,
    bool? async,
    bool? generator,
    bool? arrowFunction,
    Function(StringBuffer)? body,
  }) async {
    FunctionDeclaration astNode = await buildStep.resolver.astNodeFor(functionElement) as FunctionDeclaration;
    return GlobalFunction(
        returnType: returnType ?? '${functionElement.returnType}',
        name: name ?? functionElement.name,
        parameters:
            parameters ?? await functionElement.parameters.mapAsync((p) => FunctionParameter.from(p, buildStep)),
        genericTypes: genericTypes ?? functionElement.typeParameters.map((p) => '$p').toList(),
        multiLineParameters: multiLineParameters ?? true,
        async: async ?? functionElement.isAsynchronous,
        generator: generator ?? functionElement.isGenerator,
        arrowFunction: astNode.functionExpression.body is ExpressionFunctionBody,
        body: (astNode.functionExpression.body is EmptyFunctionBody)
            ? (StringBuffer b) => ''
            : (StringBuffer b) {
                FunctionBody body = astNode.functionExpression.body;
                if (body is BlockFunctionBody)
                  b.write(body.block.statements.toCleanString());
                else if (body is ExpressionFunctionBody) b.write('${body.expression}');
              });
  }

  void _writeToBuffer(StringBuffer b) {
    if (returnType != null) b.write('${returnType} ');
    b.write('${name}');
    if (genericTypes != null) b.write('<${genericTypes!.toCleanString(',')}>');

    b.write('(');

    if (namedParameters.isNotEmpty && unnamedParameters.isEmpty) b.write('{');
    if (optionalParameters.isNotEmpty && unnamedParameters.isEmpty) b.write('[');

    if (unnamedParameters.isNotEmpty) {
      unnamedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < unnamedParameters.length - 1)
          b.write(',');
        else {
          if (namedParameters.isNotEmpty)
            b.write(', {');
          else if (optionalParameters.isNotEmpty)
            b.write(', [');
          else {
            if (multiLineParameters) b.write(', ');
          }
        }
      });
    }

    if (namedParameters.isNotEmpty) {
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

    if (optionalParameters.isNotEmpty) {
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

class FunctionParameter implements BufferWritable {
  final String name;
  final bool named;
  final bool Required;
  final bool optional;
  final String type;
  final String? defaultValue;

  FunctionParameter({
    required this.name,
    this.named = false,
    this.Required = false,
    this.optional = false,
    required this.type,
    this.defaultValue,
  })  : assert(!(named && optional), 'The function parameter [$name] can be either named or optional, but not both'),
        assert(
            !Required || (Required && named), 'If the function parameter [$name] is required, then it must be named'),
        assert(defaultValue == null || ((named && !Required) || optional),
            'the function parameter [$name] is not optional, yet it has a default value');

  static Future<FunctionParameter> from(
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
    return FunctionParameter(
      name: name ?? parameterElement.name,
      named: named ?? parameterElement.isNamed,
      Required: Required ?? parameterElement.isRequiredNamed,
      optional: optional ?? parameterElement.isOptionalPositional,
      type: type ?? '${parameterElement.type}',
      defaultValue: defaultValue ?? ((astNode is DefaultFormalParameter) ? '${astNode.defaultValue}' : null),
    );
  }

  void _writeToBuffer(StringBuffer b) {
    if (!named && !optional) {
      b.write('$type ');
      b.write('$name');
    } else {
      if (named) {
        if (Required) b.write('required ');
      }
      b.write('$type ');
      b.write('$name');
      if (defaultValue != null) b.write(' = $defaultValue');
    }
  }
}
