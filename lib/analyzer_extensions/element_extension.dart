part of code_builders;

/// Extension on [Element] providing annotation-related functionality.
///
/// This extension adds methods to work with annotations on Dart elements.
/// It provides convenient ways to check for specific annotations, extract
/// annotation values, and work with annotation metadata.
///
/// ## Features
///
/// - Check if element has specific annotations
/// - Extract all annotations or annotations of specific types
/// - Get annotation values as Dart objects
/// - Type-safe annotation access with generics
/// - Support for type parameters in annotation matching
///
/// ## Usage
///
/// ```dart
/// // Check if element has specific annotation
/// if (element.isAnnotated<MyAnnotation>()) {
///   // Element has MyAnnotation
/// }
///
/// // Get all annotations of specific type
/// final annotations = element.getAllAnnotationsOf<MyAnnotation>();
///
/// // Get first annotation of specific type
/// final annotation = element.getAnnotationOf<MyAnnotation>();
///
/// // Get all annotation values
/// final allValues = element.getAllAnnotations();
/// ```
extension ElementExtension on Element {
  /// Checks if this element has an annotation of type [T].
  ///
  /// This method searches through the element's metadata to find annotations
  /// that match the specified type [T]. It can optionally include or exclude
  /// type parameters in the matching.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in annotation matching.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// `true` if the element has an annotation of type [T], `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Check for any annotation of type MyAnnotation
  /// if (element.isAnnotated<MyAnnotation>()) {
  ///   // Element has MyAnnotation
  /// }
  ///
  /// // Check for specific annotation with type parameters
  /// if (element.isAnnotated<MyAnnotation<String>>(withTypeParams: true)) {
  ///   // Element has MyAnnotation<String>
  /// }
  /// ```
  bool isAnnotated<T>({bool withTypeParams = false}) => metadata.annotations.any((elementAnnotation) {
        DartType? annotationType = elementAnnotation.computeConstantValue()?.type;
        if (annotationType == null) return false;
        return annotationType.isType<T>(withTypeParams: withTypeParams);
      });

  /// Gets all annotation [DartObject] instances from this element.
  ///
  /// This method extracts all [DartObject] instances from the element's
  /// metadata, filtering out any null values.
  ///
  /// ## Returns
  ///
  /// A list of [DartObject] instances representing all annotations.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final annotationObjects = element.getAllAnnotationDartObjects();
  /// for (final obj in annotationObjects) {
  ///   final value = obj.getValue();
  ///   // Process annotation value
  /// }
  /// ```
  List<DartObject> getAllAnnotationDartObjects() => metadata.annotations
      .map((elementAnnotation) => elementAnnotation.computeConstantValue())
      .where((dartObject) => dartObject != null)
      .cast<DartObject>()
      .toList();

  /// Gets all annotation [DartObject] instances of type [T].
  ///
  /// This method filters the element's annotations to only return those
  /// that match the specified type [T]. It can optionally include or exclude
  /// type parameters in the matching.
  ///
  /// [withTypeParameters]: If `true`, includes type parameters in annotation matching.
  ///                      If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of [DartObject] instances representing annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// final myAnnotations = element.getAllAnnotationDartObjectsOf<MyAnnotation>();
  /// for (final obj in myAnnotations) {
  ///   final value = obj.getValue();
  ///   // Process MyAnnotation values
  /// }
  /// ```
  List<DartObject> getAllAnnotationDartObjectsOf<T>({bool withTypeParameters = false}) => getAllAnnotationDartObjects()
      .where((dartObject) => dartObject.type!.isType<T>(withTypeParams: withTypeParameters))
      .cast<DartObject>()
      .toList();

  /// Gets all annotation values as Dart objects.
  ///
  /// This method extracts all annotation values from the element's metadata
  /// and converts them to their actual Dart values using [DartObject.getValue].
  ///
  /// ## Returns
  ///
  /// A list of Dart values representing all annotations.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allValues = element.getAllAnnotations();
  /// for (final value in allValues) {
  ///   // Process annotation value
  /// }
  /// ```
  List<dynamic> getAllAnnotations() =>
      getAllAnnotationDartObjects().map((dartObject) => dartObject.getValue()).toList();

  /// Gets all annotation values of type [T].
  ///
  /// This method filters the element's annotations to only return those
  /// that match the specified type [T], then converts them to their actual
  /// Dart values. It can optionally include or exclude type parameters
  /// in the matching.
  ///
  /// [withTypeParameters]: If `true`, includes type parameters in annotation matching.
  ///                      If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of values of type [T] representing annotations of that type.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final myAnnotations = element.getAllAnnotationsOf<MyAnnotation>();
  /// for (final annotation in myAnnotations) {
  ///   // annotation is of type MyAnnotation
  ///   print(annotation.value);
  /// }
  /// ```
  List<T> getAllAnnotationsOf<T>({bool withTypeParameters = false}) =>
      getAllAnnotationDartObjectsOf<T>(withTypeParameters: withTypeParameters)
          .map((dartObject) => dartObject.getValue())
          .cast<T>()
          .toList();

  /// Gets the first annotation of type [T].
  ///
  /// This method finds the first annotation that matches the specified type [T]
  /// and returns its value. It can optionally include or exclude type parameters
  /// in the matching.
  ///
  /// [withTypeParameters]: If `true`, includes type parameters in annotation matching.
  ///                      If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// The first annotation value of type [T], or `null` if no such annotation exists.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final annotation = element.getAnnotationOf<MyAnnotation>();
  /// if (annotation != null) {
  ///   // Use the annotation
  ///   print(annotation.value);
  /// }
  /// ```
  T? getAnnotationOf<T>({bool withTypeParameters = false}) =>
      getAllAnnotationsOf<T>(withTypeParameters: withTypeParameters).firstOrNull;
}
