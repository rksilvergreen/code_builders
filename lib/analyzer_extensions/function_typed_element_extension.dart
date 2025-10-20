part of code_builders;

/// Extension on [FunctionTypedElement] providing parameter filtering methods.
///
/// This extension adds methods to filter parameters and type parameters
/// of function elements based on their annotations. It's particularly
/// useful for code generation scenarios where you need to process
/// specific parameters that have certain annotations.
///
/// ## Features
///
/// - Filter parameters by annotation type
/// - Filter type parameters by annotation type
/// - Support for type parameters in annotation matching
/// - Type-safe filtering with generics
///
/// ## Usage
///
/// ```dart
/// // Get parameters with specific annotation
/// final annotatedParams = functionElement.getParametersAnnotatedWith<MyParamAnnotation>();
///
/// // Get type parameters with specific annotation
/// final annotatedTypeParams = functionElement.getTypeParametersAnnotatedWith<MyTypeAnnotation>();
///
/// // Process annotated parameters
/// for (final param in annotatedParams) {
///   // Process parameter with MyParamAnnotation
/// }
/// ```
extension FunctionTypedElementExtension on FunctionTypedElement {
  /// Gets all parameters that have an annotation of type [T].
  ///
  /// This method filters the function's parameters to only return those
  /// that have an annotation matching the specified type [T]. It can
  /// optionally include or exclude type parameters in the annotation matching.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in annotation matching.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of [ParameterElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get parameters with MyParamAnnotation
  /// final annotatedParams = functionElement.getParametersAnnotatedWith<MyParamAnnotation>();
  ///
  /// for (final param in annotatedParams) {
  ///   final annotation = param.getAnnotationOf<MyParamAnnotation>();
  ///   if (annotation != null) {
  ///     // Process parameter with annotation
  ///     print('Parameter ${param.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<FormalParameterElement> getParametersAnnotatedWith<T>({bool withTypeParams = false}) =>
      formalParameters.where((parameter) => parameter.isAnnotated<T>(withTypeParams: withTypeParams)).toList();

  /// Gets all type parameters that have an annotation of type [T].
  ///
  /// This method filters the function's type parameters to only return those
  /// that have an annotation matching the specified type [T]. It can
  /// optionally include or exclude type parameters in the annotation matching.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in annotation matching.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// A list of [TypeParameterElement] instances that have annotations of type [T].
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Get type parameters with MyTypeAnnotation
  /// final annotatedTypeParams = functionElement.getTypeParametersAnnotatedWith<MyTypeAnnotation>();
  ///
  /// for (final typeParam in annotatedTypeParams) {
  ///   final annotation = typeParam.getAnnotationOf<MyTypeAnnotation>();
  ///   if (annotation != null) {
  ///     // Process type parameter with annotation
  ///     print('Type parameter ${typeParam.name} has annotation: ${annotation.value}');
  ///   }
  /// }
  /// ```
  List<TypeParameterElement> getTypeParametersAnnotatedWith<T>({bool withTypeParams = false}) =>
      typeParameters.where((typeParameter) => typeParameter.isAnnotated<T>(withTypeParams: withTypeParams)).toList();
}
