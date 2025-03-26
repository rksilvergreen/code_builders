part of dart_source_builder;

class Mixin extends PublicBufferWritable {
  final String name;
  final List<String> on;
  final List<Property> properties;
  final List<Getter> getters;
  final List<Setter> setters;
  final List<Method> methods;

  Mixin({
    required this.name,
    List<String>? on,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Method>? methods,
  })  : on = on ?? [],
        properties = properties ?? [],
        getters = getters ?? [],
        setters = setters ?? [],
        methods = methods ?? [];

  static Future<Mixin> from(
    MixinElement mixinElement,
    BuildStep buildStep, {
    String? name,
    List<String>? on,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Method>? methods,
  }) async {
    return Mixin(
      name: name ?? mixinElement.name,
      on: on ?? mixinElement.superclassConstraints.map((e) => e.element.name).toList(),
      properties: properties ?? await mixinElement.fields.mapAsync((e) => Property.from(e, buildStep)),
      getters: getters ??
          await mixinElement.accessors.where((e) => e.isGetter).toList().mapAsync((e) => Getter.from(e, buildStep)),
      setters: setters ??
          await mixinElement.accessors.where((e) => e.isSetter).toList().mapAsync((e) => Setter.from(e, buildStep)),
      methods: methods ?? await mixinElement.methods.toList().mapAsync((e) => Method.from(e, buildStep)),
    );
  }

  void _writeToBuffer(StringBuffer b) {
    b.write('mixin ${name} ');
    if (on.isNotEmpty) b.write('on ${on.toCleanString()} ');
    b.write('{');
    [
      ...properties,
      ...getters,
      ...setters,
      ...methods,
    ]._writeToBuffer(b);
    b.write('}');
  }
}
