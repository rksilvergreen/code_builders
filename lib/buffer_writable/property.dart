part of dart_source_builder;

class Property implements BufferWritable {
  final bool static;
  final bool Const;
  final bool Final;
  final bool late;
  final bool covariant;
  final String? type;
  final String name;
  final String? defaultValue;

  Property({
    this.static = false,
    this.Const = false,
    this.Final = false,
    this.late = false,
    this.covariant = false,
    this.type,
    required this.name,
    this.defaultValue,
  });

  static Future<Property> from(
    FieldElement fieldElement,
    BuildStep buildStep, {
    bool? static,
    bool? Const,
    bool? Final,
    bool? covariant,
    String? type,
    String? name,
    String? defaultValue,
  }) async {
    VariableDeclaration astNode = (await buildStep.resolver.astNodeFor(fieldElement) as FieldDeclaration)
        .fields
        .variables
        .firstWhere((declaration) => declaration.name.stringValue == name);

    return Property(
      static: static ?? fieldElement.isStatic,
      Const: Const ?? fieldElement.isConst,
      Final: static ?? fieldElement.isFinal,
      covariant: static ?? fieldElement.isCovariant,
      type: type ?? '${fieldElement.type}',
      name: name ?? fieldElement.name,
      defaultValue: defaultValue ?? '${astNode.initializer}',
    );
  }

  void _writeToBuffer(StringBuffer b) {
    if (static) b.write('static ');
    if (Const) b.write('const ');
    if (Final) b.write('final ');
    if (late) b.write('late ');
    if (covariant) b.write('covariant ');
    b.write('${type ?? 'dynamic'} ');
    b.write(name);
    if (defaultValue != null) b.write(' = $defaultValue');
    b.write(';');
  }
}