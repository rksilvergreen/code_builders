part of dart_source_builder;

extension LibraryElementExtension on LibraryElement {
  List<ClassElement> get classes => units.expand((u) => u.classes).toList();

  List<ClassElement> getAllClassesAnnotatedWith<T>() =>
      units.expand((u) => u.classes.where((classElement) => classElement.isAnnotated<T>())).toList();

  List<MixinElement> get mixins => units.expand((u) => u.mixins).toList();

  List<MixinElement> getAllMixinsAnnotatedWith<T>() =>
      units.expand((u) => u.mixins.where((mixinElement) => mixinElement.isAnnotated<T>())).toList();

  List<ExtensionElement> get extensions => units.expand((u) => u.extensions).toList();

  List<ExtensionElement> getAllExtensionsAnnotatedWith<T>() =>
      units.expand((u) => u.extensions.where((extensionElement) => extensionElement.isAnnotated<T>())).toList();

  List<EnumElement> get enums => units.expand((u) => u.enums).toList();

  List<EnumElement> getAllEnumsAnnotatedWith<T>() =>
      units.expand((u) => u.enums.where((enumElement) => enumElement.isAnnotated<T>())).toList();

  List<FunctionElement> get functions => units.expand((u) => u.functions).toList();

  List<FunctionElement> getAllFunctionsAnnotatedWith<T>() =>
      units.expand((u) => u.functions.where((functionElement) => functionElement.isAnnotated<T>())).toList();

  List<TopLevelVariableElement> get topLevelVariables => units.expand((u) => u.topLevelVariables).toList();

  List<TopLevelVariableElement> getAllTopLevelVariablesAnnotatedWith<T>() =>
      units.expand((u) => u.topLevelVariables.where((variableElement) => variableElement.isAnnotated<T>())).toList();
}