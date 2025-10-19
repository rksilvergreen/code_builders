part of code_builders;

extension InterfaceTypeExtensions on InterfaceType {
  List<InterfaceType> get extendedInterfaces {
    List<InterfaceType> allInterfaces = [];
    allInterfaces.addAll(interfaces);
    if (superclass != null) {
      allInterfaces.addAll(superclass!.extendedInterfaces);
    }
    return allInterfaces;
  }

  List<InterfaceType> get extendedMixins {
    List<InterfaceType> allMixins = [];
    allMixins.addAll(mixins);
    if (superclass != null) {
      allMixins.addAll(superclass!.extendedMixins);
    }
    return allMixins;
  }

  bool doesImplementType<T>({bool withTypeParams = false, bool extended = true}) =>
      (extended ? extendedInterfaces : interfaces)
          .any((interfaceType) => interfaceType.isType<T>(withTypeParams: withTypeParams));

  bool doesExtendType<T>({bool withTypeParams = false, bool extended = true}) {
    if (isType<T>(withTypeParams: withTypeParams)) return true;
    if (superclass == null) return false;
    if (superclass!.isType<T>(withTypeParams: withTypeParams)) return true;
    return extended ? superclass!.doesExtendType<T>(withTypeParams: withTypeParams, extended: extended) : false;
  }

  bool doesMixinType<T>({bool withTypeParams = false, bool extended = true}) => (extended ? extendedMixins : mixins)
      .any((interfaceType) => interfaceType.isType<T>(withTypeParams: withTypeParams));

  bool doesImplementDartType(DartType dartType, {bool withTypeParams = false, bool extended = true}) =>
      (extended ? extendedInterfaces : interfaces)
          .any((interfaceType) => interfaceType.isDartType(dartType, withTypeParams: withTypeParams));

  bool doesExtendDartType(DartType dartType, {bool withTypeParams = false, bool extended = true}) {
    if (isDartType(dartType, withTypeParams: withTypeParams)) return true;
    if (superclass == null) return false;
    if (superclass!.isDartType(dartType, withTypeParams: withTypeParams)) return true;
    return extended
        ? superclass!.doesExtendDartType(dartType, withTypeParams: withTypeParams, extended: extended)
        : false;
  }

  bool doesMixinDartType(DartType dartType, {bool withTypeParams = false, bool extended = true}) =>
      (extended ? extendedMixins : mixins)
          .any((interfaceType) => interfaceType.isDartType(dartType, withTypeParams: withTypeParams));

  bool hasGetter(String name) =>
      (element as ClassElement).accessors.any((accessor) => accessor.isGetter ? accessor.name == name : false);

  bool hasSetter(String name) =>
      (element as ClassElement).accessors.any((accessor) => accessor.isSetter ? accessor.name == name : false);

  bool hasMethod(String name) => (element as ClassElement).methods.any((method) => method.name == name);

  bool hasField(String name) => (element as ClassElement).fields.any((field) => field.name == name);

  bool hasNamedConstructor(String name) =>
      (element as ClassElement).constructors.any((constructor) => constructor.name == name);
}
