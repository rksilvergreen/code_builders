part of dart_source_builder;

class Setter implements BufferWritable {
  final bool override;
  final bool static;
  final String name;
  final SetterParameter parameter;
  final bool arrowFunction;
  final void Function(StringBuffer) body;

  Setter({
    this.override = false,
    this.static = false,
    required this.name,
    required this.parameter,
    this.arrowFunction = false,
    required this.body,
  }) {
    assert(
        body != null || (body == null && arrowFunction), 'The setter [$name] can\'t be an arrow function with no body');
  }

  static Future<Setter> from(
    PropertyAccessorElement setterElement,
    BuildStep buildStep, {
    bool? override,
    bool? static,
    String? name,
    SetterParameter? parameter,
    bool? arrowFunction,
    Function(StringBuffer)? body,
  }) async {
    assert(setterElement.isSetter, 'The PropertyAccessorElement [${setterElement.name}] is not a setter');
    MethodDeclaration astNode = await buildStep.resolver.astNodeFor(setterElement) as MethodDeclaration;
    return Setter(
        override: override ?? setterElement.metadata.any((elementAnnotation) => elementAnnotation.isOverride),
        static: static ?? setterElement.isStatic,
        name: name ?? setterElement.name,
        parameter: parameter ?? await SetterParameter.from(setterElement.parameters.first, buildStep),
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
    b.write('set ');
    b.write('$name ');
    b.write('(');
    parameter._writeToBuffer(b);
    b.write(')');
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

class SetterParameter implements BufferWritable {
  final String type;
  final String name;

  SetterParameter({
    required this.type,
    required this.name,
  });

  static Future<SetterParameter> from(
    ParameterElement parameterElement,
    BuildStep buildStep, {
    String? type,
    String? name,
  }) async =>
      SetterParameter(
        type: type ?? '${parameterElement.type}',
        name: name ?? parameterElement.name,
      );

  void _writeToBuffer(StringBuffer b) {
    b.write('$type ');
    b.write('name');
  }
}
