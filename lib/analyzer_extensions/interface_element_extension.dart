part of dart_source_builder;

extension InterfaceElementExtension on InterfaceElement {
  List<ConstructorElement> getConstructorsAnnotatedWith<T>({bool withTypeParams = false}) =>
      constructors.where((constructor) => constructor.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  List<MethodElement> getMethodsAnnotatedWith<T>({bool withTypeParams = false}) =>
      methods.where((method) => method.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  List<FieldElement> getFieldsAnnotatedWith<T>({bool withTypeParams = false}) =>
      fields.where((field) => field.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  List<PropertyAccessorElement> getGettersAnnotatedWith<T>({bool withTypeParams = false}) => accessors
      .where((accessor) => accessor.isGetter && accessor.isAnnotated<T>(withTypeParams: withTypeParams))
      .toList();

  List<PropertyAccessorElement> getSettersAnnotatedWith<T>({bool withTypeParams = false}) => accessors
      .where((accessor) => accessor.isSetter && accessor.isAnnotated<T>(withTypeParams: withTypeParams))
      .toList();
}