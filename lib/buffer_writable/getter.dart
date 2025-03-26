part of dart_source_builder;

class Getter implements BufferWritable {
  final bool override;
  final bool static;
  final String type;
  final String name;
  final bool async;
  final bool generator;
  final bool arrowFunction;
  void Function(StringBuffer) body;

  Getter({
    this.override = false,
    this.static = false,
    this.type = '',
    required this.name,
    this.async = false,
    this.generator = false,
    this.arrowFunction = false,
    required this.body,
  });

  static Future<Getter> from(
    PropertyAccessorElement getterElement,
    BuildStep buildStep, {
    bool? override,
    bool? static,
    String? type,
    String? name,
    bool? async,
    bool? generator,
    bool? arrowFunction,
    Function(StringBuffer)? body,
  }) async {
    assert(getterElement.isGetter, 'The PropertyAccessorElement [${getterElement.name}] is not a getter');
    MethodDeclaration astNode = await buildStep.resolver.astNodeFor(getterElement) as MethodDeclaration;
    return Getter(
        override: override ?? getterElement.metadata.any((elementAnnotation) => elementAnnotation.isOverride),
        static: static ?? getterElement.isStatic,
        type: type ?? '${getterElement.returnType}',
        name: name ?? getterElement.name,
        async: async ?? getterElement.isAsynchronous,
        generator: generator ?? getterElement.isGenerator,
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
    b.write('$type ');
    b.write('get ');
    b.write('${name}');

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
