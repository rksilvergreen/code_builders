part of dart_source_builder;

class Class extends PublicBufferWritable {
  final bool abstract;
  final String name;
  final String? extension;
  final List<String> mixins;
  final List<String> implementations;
  final List<Property> properties;
  final List<Getter> getters;
  final List<Setter> setters;
  final List<Constructor> constructors;
  final List<Method> methods;

  Class({
    this.abstract = false,
    required this.name,
    this.extension,
    List<String>? mixins,
    List<String>? implementations,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Constructor>? constructors,
    List<Method>? methods,
  })  : mixins = mixins ?? [],
        implementations = implementations ?? [],
        properties = properties ?? [],
        getters = getters ?? [],
        setters = setters ?? [],
        constructors = constructors ?? [],
        methods = methods ?? [];

  static Future<Class> from(
    ClassElement classElement,
    BuildStep buildStep, {
    bool? abstract,
    String? name,
    String? extension,
    List<String>? mixins,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Constructor>? constructors,
    List<Method>? methods,
  }) async =>
      Class(
        abstract: abstract ?? classElement.isAbstract,
        name: name ?? classElement.name,
        extension: extension ?? classElement.supertype?.element.name,
        mixins: mixins ?? classElement.mixins.map((e) => e.element.name).toList(),
        properties: properties ?? await classElement.fields.mapAsync((e) => Property.from(e, buildStep)),
        getters: getters ??
            await classElement.accessors.where((e) => e.isGetter).toList().mapAsync((e) => Getter.from(e, buildStep)),
        setters: setters ??
            await classElement.accessors.where((e) => e.isSetter).toList().mapAsync((e) => Setter.from(e, buildStep)),
        constructors: constructors ??
            await classElement.constructors.mapAsync<Constructor>((e) async => await Constructor.from(e, buildStep)),
        methods: methods ?? await classElement.methods.mapAsync((e) => Method.from(e, buildStep)),
      );

  void _writeToBuffer(StringBuffer b) {
    if (abstract) b.write('abstract ');
    b.write('class ${name} ');
    if (extension != null) b.write('extends ${extension} ');
    if (mixins.isNotEmpty) b.write('with ${mixins.toCleanString(',')} ');
    b.write('{');
    [
      ...properties,
      ...getters,
      ...setters,
      ...constructors,
      ...methods,
    ]._writeToBuffer(b);
    b.write('}');
  }
}
