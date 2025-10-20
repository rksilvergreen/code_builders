part of code_builders;

/// Extension on [LibraryElement] providing element collection and filtering methods.
///
/// This extension adds methods to collect and filter various types of elements
/// from a library. It provides convenient ways to find classes, mixins, extensions,
/// enums, functions, and variables that have specific annotations.
///
/// ## Features
///
/// - Collect all elements of specific types (classes, mixins, extensions, enums, functions, variables)
/// - Filter elements by annotation type
/// - Cross-unit element collection (handles multiple compilation units)
/// - Type-safe filtering with generics
/// - Support for annotation-based filtering
///
/// ## Usage
///
/// ```dart
/// // Get all classes in library
/// final allClasses = library.classes;
///
/// // Get classes with specific annotation
/// final annotatedClasses = library.getAllClassesAnnotatedWith<MyAnnotation>();
///
/// // Get all functions
/// final allFunctions = library.functions;
///
/// // Get functions with specific annotation
/// final annotatedFunctions = library.getAllFunctionsAnnotatedWith<MyFunctionAnnotation>();
///
/// // Process annotated elements
/// for (final classElement in annotatedClasses) {
///   // Process class with MyAnnotation
/// }
/// ```
extension LibraryElementExtension on LibraryElement {
  /// Gets all classes in this library across all compilation units.
  ///
  /// This method collects all [ClassElement] instances from all compilation
  /// units in this library.
  ///
  /// ## Returns
  ///
  /// A list of [ClassElement] instances representing all classes in the library.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allClasses = library.classes;
  /// for (final classElement in allClasses) {
  ///   print('Class: ${classElement.name}');
  /// }
  /// ```
  List<ClassElement> get classes => fragments.expand((f) => f.classes).map((c) => c.element).toList();

  /// Gets all classes that have an annotation of type [T].
  ///
  /// This method filters the library's classes to only return those
  /// that have an annotation matching the specified type [T].
  ///
  /// ## Returns
  ///
  /// A list of [ClassElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get classes with MyAnnotation
  /// final annotatedClasses = library.getAllClassesAnnotatedWith<MyAnnotation>();
  ///
  /// for (final classElement in annotatedClasses) {
  ///   final annotation = classElement.getAnnotationOf<MyAnnotation>();
  ///   if (annotation != null) {
  ///     // Process class with annotation
  ///     print('Class ${classElement.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<ClassElement> getAllClassesAnnotatedWith<T>() => fragments
      .expand((f) => f.classes)
      .map((c) => c.element)
      .where((classElement) => classElement.isAnnotated<T>())
      .toList();

  /// Gets all mixins in this library across all compilation units.
  ///
  /// This method collects all [MixinElement] instances from all compilation
  /// units in this library.
  ///
  /// ## Returns
  ///
  /// A list of [MixinElement] instances representing all mixins in the library.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allMixins = library.mixins;
  /// for (final mixinElement in allMixins) {
  ///   print('Mixin: ${mixinElement.name}');
  /// }
  /// ```
  List<MixinElement> get mixins => fragments.expand((f) => f.mixins).map((m) => m.element).toList();

  /// Gets all mixins that have an annotation of type [T].
  ///
  /// This method filters the library's mixins to only return those
  /// that have an annotation matching the specified type [T].
  ///
  /// ## Returns
  ///
  /// A list of [MixinElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get mixins with MyAnnotation
  /// final annotatedMixins = library.getAllMixinsAnnotatedWith<MyAnnotation>();
  ///
  /// for (final mixinElement in annotatedMixins) {
  ///   final annotation = mixinElement.getAnnotationOf<MyAnnotation>();
  ///   if (annotation != null) {
  ///     // Process mixin with annotation
  ///     print('Mixin ${mixinElement.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<MixinElement> getAllMixinsAnnotatedWith<T>() => fragments
      .expand((f) => f.mixins)
      .map((m) => m.element)
      .where((mixinElement) => mixinElement.isAnnotated<T>())
      .toList();

  /// Gets all extensions in this library across all compilation units.
  ///
  /// This method collects all [ExtensionElement] instances from all compilation
  /// units in this library.
  ///
  /// ## Returns
  ///
  /// A list of [ExtensionElement] instances representing all extensions in the library.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allExtensions = library.extensions;
  /// for (final extensionElement in allExtensions) {
  ///   print('Extension: ${extensionElement.name}');
  /// }
  /// ```
  List<ExtensionElement> get extensions => fragments.expand((f) => f.extensions).map((e) => e.element).toList();

  /// Gets all extensions that have an annotation of type [T].
  ///
  /// This method filters the library's extensions to only return those
  /// that have an annotation matching the specified type [T].
  ///
  /// ## Returns
  ///
  /// A list of [ExtensionElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get extensions with MyAnnotation
  /// final annotatedExtensions = library.getAllExtensionsAnnotatedWith<MyAnnotation>();
  ///
  /// for (final extensionElement in annotatedExtensions) {
  ///   final annotation = extensionElement.getAnnotationOf<MyAnnotation>();
  ///   if (annotation != null) {
  ///     // Process extension with annotation
  ///     print('Extension ${extensionElement.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<ExtensionElement> getAllExtensionsAnnotatedWith<T>() => fragments
      .expand((f) => f.extensions)
      .map((e) => e.element)
      .where((extensionElement) => extensionElement.isAnnotated<T>())
      .toList();

  /// Gets all enums in this library across all compilation units.
  ///
  /// This method collects all [EnumElement] instances from all compilation
  /// units in this library.
  ///
  /// ## Returns
  ///
  /// A list of [EnumElement] instances representing all enums in the library.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allEnums = library.enums;
  /// for (final enumElement in allEnums) {
  ///   print('Enum: ${enumElement.name}');
  /// }
  /// ```
  List<EnumElement> get enums => fragments.expand((f) => f.enums).map((e) => e.element).toList();

  /// Gets all enums that have an annotation of type [T].
  ///
  /// This method filters the library's enums to only return those
  /// that have an annotation matching the specified type [T].
  ///
  /// ## Returns
  ///
  /// A list of [EnumElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get enums with MyAnnotation
  /// final annotatedEnums = library.getAllEnumsAnnotatedWith<MyAnnotation>();
  ///
  /// for (final enumElement in annotatedEnums) {
  ///   final annotation = enumElement.getAnnotationOf<MyAnnotation>();
  ///   if (annotation != null) {
  ///     // Process enum with annotation
  ///     print('Enum ${enumElement.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<EnumElement> getAllEnumsAnnotatedWith<T>() => fragments
      .expand((f) => f.enums)
      .map((e) => e.element)
      .where((enumElement) => enumElement.isAnnotated<T>())
      .toList();

  /// Gets all top-level functions in this library across all compilation units.
  ///
  /// This method collects all [FunctionElement] instances from all compilation
  /// units in this library.
  ///
  /// ## Returns
  ///
  /// A list of [FunctionElement] instances representing all top-level functions in the library.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allFunctions = library.functions;
  /// for (final functionElement in allFunctions) {
  ///   print('Function: ${functionElement.name}');
  /// }
  /// ```
  List<TopLevelFunctionElement> get functions => fragments.expand((f) => f.functions).map((fn) => fn.element).toList();

  /// Gets all top-level functions that have an annotation of type [T].
  ///
  /// This method filters the library's functions to only return those
  /// that have an annotation matching the specified type [T].
  ///
  /// ## Returns
  ///
  /// A list of [FunctionElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get functions with MyAnnotation
  /// final annotatedFunctions = library.getAllFunctionsAnnotatedWith<MyAnnotation>();
  ///
  /// for (final functionElement in annotatedFunctions) {
  ///   final annotation = functionElement.getAnnotationOf<MyAnnotation>();
  ///   if (annotation != null) {
  ///     // Process function with annotation
  ///     print('Function ${functionElement.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<TopLevelFunctionElement> getAllFunctionsAnnotatedWith<T>() => fragments
      .expand((f) => f.functions)
      .map((fn) => fn.element)
      .where((functionElement) => functionElement.isAnnotated<T>())
      .toList();

  /// Gets all top-level variables in this library across all compilation units.
  ///
  /// This method collects all [TopLevelVariableElement] instances from all compilation
  /// units in this library.
  ///
  /// ## Returns
  ///
  /// A list of [TopLevelVariableElement] instances representing all top-level variables in the library.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allVariables = library.topLevelVariables;
  /// for (final variableElement in allVariables) {
  ///   print('Variable: ${variableElement.name}');
  /// }
  /// ```
  List<TopLevelVariableElement> get topLevelVariables =>
      fragments.expand((f) => f.topLevelVariables).map((v) => v.element).toList();

  /// Gets all top-level variables that have an annotation of type [T].
  ///
  /// This method filters the library's variables to only return those
  /// that have an annotation matching the specified type [T].
  ///
  /// ## Returns
  ///
  /// A list of [TopLevelVariableElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get variables with MyAnnotation
  /// final annotatedVariables = library.getAllTopLevelVariablesAnnotatedWith<MyAnnotation>();
  ///
  /// for (final variableElement in annotatedVariables) {
  ///   final annotation = variableElement.getAnnotationOf<MyAnnotation>();
  ///   if (annotation != null) {
  ///     // Process variable with annotation
  ///     print('Variable ${variableElement.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<TopLevelVariableElement> getAllTopLevelVariablesAnnotatedWith<T>() => fragments
      .expand((f) => f.topLevelVariables)
      .map((v) => v.element)
      .where((variableElement) => variableElement.isAnnotated<T>())
      .toList();
}
