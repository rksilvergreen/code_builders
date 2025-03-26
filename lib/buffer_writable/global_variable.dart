part of dart_source_builder;

class GlobalVariable extends PublicBufferWritable {
  final bool Const;
  final bool Final;
  final bool late;
  final String? type;
  final String name;
  final String? defaultValue;

  GlobalVariable({
    this.Const = false,
    this.Final = false,
    this.late = false,
    this.type,
    required this.name,
    this.defaultValue,
  });

  static Future<GlobalVariable> from(
    TopLevelVariableElement topLevelVariableElement,
    BuildStep buildStep, {
    bool? static,
    bool? Const,
    bool? Final,
    bool? covariant,
    String? type,
    String? name,
    String? defaultValue,
  }) async =>
      await GlobalVariable(
        Const: Const ?? topLevelVariableElement.isConst,
        Final: static ?? topLevelVariableElement.isFinal,
        type: type ?? '${topLevelVariableElement.type}',
        name: name ?? topLevelVariableElement.name,
        defaultValue: defaultValue
        // ?? '${topLevelVariableElement.initializer}'
        ,
      );

  void _writeToBuffer(StringBuffer b) {
    if (Const) b.write('const ');
    if (Final) b.write('final ');
    if (late) b.write('late ');
    b.write('${type ?? 'dynamic'} ');
    b.write(name);
    if (defaultValue != null) b.write(' = $defaultValue');
    b.write(';');
  }
}
