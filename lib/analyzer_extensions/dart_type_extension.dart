part of code_builders;

/// Extension on [DartType] providing type comparison and checking methods.
///
/// This extension adds convenient methods for comparing [DartType] instances
/// with generic types and other [DartType] instances. It supports both
/// exact matching and matching without type parameters.
///
/// ## Features
///
/// - Generic type checking with `isType<T>()`
/// - Direct [DartType] comparison with `isDartType()`
/// - Type parameter handling (with/without generic parameters)
/// - String-based comparison for reliability
///
/// ## Usage
///
/// ```dart
/// // Check if type matches a generic type
/// if (dartType.isType<String>()) {
///   // Handle String type
/// }
///
/// if (dartType.isType<List<int>>(withTypeParams: true)) {
///   // Handle List<int> with type parameters
/// }
///
/// // Compare with another DartType
/// if (dartType.isDartType(otherType)) {
///   // Types match
/// }
/// ```
extension DartTypeExtension on DartType {
  /// Checks if this [DartType] matches the specified generic type [T].
  ///
  /// This method compares the string representation of this type with the
  /// string representation of type [T]. It can optionally include or exclude
  /// type parameters in the comparison.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in comparison.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// `true` if the types match, `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Check for String type
  /// if (dartType.isType<String>()) {
  ///   // This is a String type
  /// }
  ///
  /// // Check for List type (ignoring type parameters)
  /// if (dartType.isType<List>()) {
  ///   // This is a List type (could be List<String>, List<int>, etc.)
  /// }
  ///
  /// // Check for specific List type with type parameters
  /// if (dartType.isType<List<String>>(withTypeParams: true)) {
  ///   // This is specifically a List<String>
  /// }
  /// ```
  bool isType<T>({bool withTypeParams = false}) {
    String firstType = getDisplayString();
    String secondType = '$T';
    return _isSameType(firstType, secondType, withTypeParams);
  }

  /// Checks if this [DartType] matches the specified [dartType].
  ///
  /// This method compares the string representation of this type with the
  /// string representation of the provided [dartType]. It can optionally
  /// include or exclude type parameters in the comparison.
  ///
  /// [dartType]: The [DartType] to compare against.
  /// [withTypeParams]: If `true`, includes type parameters in comparison.
  ///                  If `false`, ignores type parameters (default).
  ///
  /// ## Returns
  ///
  /// `true` if the types match, `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final otherType = element.thisType;
  /// if (dartType.isDartType(otherType)) {
  ///   // Types match
  /// }
  ///
  /// // Compare with type parameters
  /// if (dartType.isDartType(otherType, withTypeParams: true)) {
  ///   // Types match including type parameters
  /// }
  /// ```
  bool isDartType(DartType dartType, {bool withTypeParams = false}) {
    String firstType = '$this';
    String secondType = '$dartType';
    return _isSameType(firstType, secondType, withTypeParams);
  }
}

/// Helper function to compare two type strings.
///
/// This function performs string-based type comparison, optionally handling
/// type parameters. It strips type parameters from the type strings when
/// [withTypeParams] is `false`.
///
/// [firstType]: The first type string to compare.
/// [secondType]: The second type string to compare.
/// [withTypeParams]: If `true`, includes type parameters in comparison.
///                  If `false`, strips type parameters before comparison.
///
/// ## Returns
///
/// `true` if the types match, `false` otherwise.
///
/// ## Example
///
/// ```dart
/// // Compare with type parameters
/// _isSameType('List<String>', 'List<String>', true); // true
///
/// // Compare without type parameters
/// _isSameType('List<String>', 'List<int>', false); // true
/// _isSameType('List<String>', 'List<String>', false); // true
/// ```
bool _isSameType(String firstType, String secondType, bool withTypeParams) {
  if (withTypeParams) {
    return firstType == secondType;
  } else {
    // Strip type parameters for comparison
    int firstIndex = firstType.indexOf('<');
    int secondIndex = secondType.indexOf('<');

    if (firstIndex != -1) firstType = firstType.substring(0, firstIndex);
    if (secondIndex != -1) secondType = secondType.substring(0, secondIndex);
    return firstType == secondType;
  }
}
