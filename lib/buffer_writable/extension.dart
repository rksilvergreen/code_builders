part of dart_source_builder;

class Extension extends PublicBufferWritable {
  final String? extensionName;
  final String className;
  final List<Getter> getters;
  final List<Setter> setters;
  final List<Method> methods;

  Extension({
    this.extensionName,
    required this.className,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Method>? methods,
  })  : getters = getters ?? [],
        setters = setters ?? [],
        methods = methods ?? [];

  static Future<Extension> from(
    ExtensionElement extensionElement,
    BuildStep buildStep, {
    String? extensionName,
    String? className,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Method>? methods,
  }) async =>
      Extension(
        extensionName: extensionName ?? extensionElement.name,
        className: className ?? '${extensionElement.extendedType}',
        getters: getters ??
            await extensionElement.accessors
                .where((e) => e.isGetter)
                .toList()
                .mapAsync((e) => Getter.from(e, buildStep)),
        setters: setters ??
            await extensionElement.accessors
                .where((e) => e.isSetter)
                .toList()
                .mapAsync((e) => Setter.from(e, buildStep)),
        methods: methods ?? await extensionElement.methods.toList().mapAsync((e) => Method.from(e, buildStep)),
      );

  void _writeToBuffer(StringBuffer b) {
    b.write('extension ${extensionName ?? ''} ');
    b.write('on $className');
    b.write('{');
    [
      ...getters,
      ...setters,
      ...methods,
    ]._writeToBuffer(b);
    b.write('}');
  }
}
