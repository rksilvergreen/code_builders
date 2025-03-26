part of dart_source_builder;

class Enum extends PublicBufferWritable {
  final String name;
  final List<String> constants;

  Enum({
    required this.name,
    required this.constants,
  }) : assert(constants.isNotEmpty, 'The enum [$name] must declare at least one constant');

  static Future<Enum> from(
    EnumElement enumElement,
    BuildStep buildStep, {
    String? name,
    List<String>? constants,
  }) async {
    EnumDeclaration astNode = await buildStep.resolver.astNodeFor(enumElement) as EnumDeclaration;
    return Enum(
      name: name ?? enumElement.name,
      constants: constants ?? astNode.constants.map((e) => '${e.name}').toList(),
    );
  }

  void _writeToBuffer(StringBuffer b) {
    b.write('enum $name ');
    b.write('{');
    b.write(constants.toCleanString(','));
    b.write('}');
  }
}
