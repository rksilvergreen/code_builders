part of code_builders;

/// Extension on [InterfaceElement] providing member filtering methods.
///
/// This extension adds methods to filter members of interface elements
/// (classes, mixins) based on their annotations. It provides convenient
/// ways to find constructors, methods, fields, getters, and setters
/// that have specific annotations.
///
/// ## Features
///
/// - Filter constructors by annotation type
/// - Filter methods by annotation type
/// - Filter fields by annotation type
/// - Filter getters by annotation type
/// - Filter setters by annotation type
/// - Support for type parameters in annotation matching
/// - Type-safe filtering with generics
///
/// ## Usage
///
/// ```dart
/// // Get methods with specific annotation
/// final annotatedMethods = classElement.getMethodsAnnotatedWith<MyMethodAnnotation>();
///
/// // Get fields with specific annotation
/// final annotatedFields = classElement.getFieldsAnnotatedWith<MyFieldAnnotation>();
///
/// // Get constructors with specific annotation
/// final annotatedConstructors = classElement.getConstructorsAnnotatedWith<MyConstructorAnnotation>();
///
/// // Process annotated members
/// for (final method in annotatedMethods) {
///   // Process method with MyMethodAnnotation
/// }
/// ```
extension InterfaceElementExtension on InterfaceElement {
  /// Gets all constructors that have an annotation of type [T].
  ///
  /// This method filters the interface's constructors to only return those
  /// that have an annotation matching the specified type [T]. It can
  /// optionally include or exclude type parameters in the annotation matching.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in annotation matching.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of [ConstructorElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get constructors with MyConstructorAnnotation
  /// final annotatedConstructors = classElement.getConstructorsAnnotatedWith<MyConstructorAnnotation>();
  ///
  /// for (final constructor in annotatedConstructors) {
  ///   final annotation = constructor.getAnnotationOf<MyConstructorAnnotation>();
  ///   if (annotation != null) {
  ///     // Process constructor with annotation
  ///     print('Constructor ${constructor.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<ConstructorElement> getConstructorsAnnotatedWith<T>({bool withTypeParams = false}) =>
      constructors.where((constructor) => constructor.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  /// Gets all methods that have an annotation of type [T].
  ///
  /// This method filters the interface's methods to only return those
  /// that have an annotation matching the specified type [T]. It can
  /// optionally include or exclude type parameters in the annotation matching.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in annotation matching.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of [MethodElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get methods with MyMethodAnnotation
  /// final annotatedMethods = classElement.getMethodsAnnotatedWith<MyMethodAnnotation>();
  ///
  /// for (final method in annotatedMethods) {
  ///   final annotation = method.getAnnotationOf<MyMethodAnnotation>();
  ///   if (annotation != null) {
  ///     // Process method with annotation
  ///     print('Method ${method.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<MethodElement> getMethodsAnnotatedWith<T>({bool withTypeParams = false}) =>
      methods.where((method) => method.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  /// Gets all fields that have an annotation of type [T].
  ///
  /// This method filters the interface's fields to only return those
  /// that have an annotation matching the specified type [T]. It can
  /// optionally include or exclude type parameters in the annotation matching.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in annotation matching.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of [FieldElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get fields with MyFieldAnnotation
  /// final annotatedFields = classElement.getFieldsAnnotatedWith<MyFieldAnnotation>();
  ///
  /// for (final field in annotatedFields) {
  ///   final annotation = field.getAnnotationOf<MyFieldAnnotation>();
  ///   if (annotation != null) {
  ///     // Process field with annotation
  ///     print('Field ${field.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<FieldElement> getFieldsAnnotatedWith<T>({bool withTypeParams = false}) =>
      fields.where((field) => field.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  /// Gets all getters that have an annotation of type [T].
  ///
  /// This method filters the interface's accessors to only return those
  /// that are getters and have an annotation matching the specified type [T].
  /// It can optionally include or exclude type parameters in the annotation matching.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in annotation matching.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of [PropertyAccessorElement] instances that are getters and have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get getters with MyGetterAnnotation
  /// final annotatedGetters = classElement.getGettersAnnotatedWith<MyGetterAnnotation>();
  ///
  /// for (final getter in annotatedGetters) {
  ///   final annotation = getter.getAnnotationOf<MyGetterAnnotation>();
  ///   if (annotation != null) {
  ///     // Process getter with annotation
  ///     print('Getter ${getter.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<GetterElement> getGettersAnnotatedWith<T>({bool withTypeParams = false}) =>
      getters.where((getter) => getter.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  /// Gets all setters that have an annotation of type [T].
  ///
  /// This method filters the interface's accessors to only return those
  /// that are setters and have an annotation matching the specified type [T].
  /// It can optionally include or exclude type parameters in the annotation matching.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in annotation matching.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of [PropertyAccessorElement] instances that are setters and have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get setters with MySetterAnnotation
  /// final annotatedSetters = classElement.getSettersAnnotatedWith<MySetterAnnotation>();
  ///
  /// for (final setter in annotatedSetters) {
  ///   final annotation = setter.getAnnotationOf<MySetterAnnotation>();
  ///   if (annotation != null) {
  ///     // Process setter with annotation
  ///     print('Setter ${setter.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<SetterElement> getSettersAnnotatedWith<T>({bool withTypeParams = false}) =>
      setters.where((setter) => setter.isAnnotated<T>(withTypeParams: withTypeParams)).toList();
}
