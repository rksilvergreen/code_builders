part of code_builders;

/// Extension on [DartObject] providing enhanced functionality for field access and value extraction.
///
/// This extension adds methods to work with [DartObject] instances more conveniently,
/// including field checking, value extraction, and automatic type conversion.
/// It supports both primitive types and complex types through custom converters.
///
/// ## Features
///
/// - Field existence checking
/// - Safe field value extraction with error handling
/// - Automatic conversion of primitive types (bool, String, int, double)
/// - Collection handling (List, Set, Map) with recursive value extraction
/// - Custom converter support for complex types
/// - Null safety with proper null handling
///
/// ## Usage
///
/// ```dart
/// final dartObject = element.computeConstantValue();
/// if (dartObject != null) {
///   // Check if field exists
///   if (dartObject.hasField('myField')) {
///     // Get field value (throws if field doesn't exist)
///     final fieldValue = dartObject.getFieldValue('myField');
///   }
///
///   // Get the actual Dart value
///   final value = dartObject.getValue();
/// }
/// ```
extension DartObjectExtension on DartObject {
  /// Checks if this [DartObject] has a field with the specified name.
  ///
  /// Returns `true` if the field exists, `false` otherwise.
  ///
  /// [field]: The name of the field to check for.
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (dartObject.hasField('name')) {
  ///   // Field exists, safe to access
  /// }
  /// ```
  bool hasField(String field) => getField(field) != null;

  /// Gets the value of a field by name.
  ///
  /// This method provides safe field access with proper error handling.
  /// If the field doesn't exist, a [StateError] is thrown.
  ///
  /// [fieldName]: The name of the field to access.
  /// [DartObjectConverters]: Optional list of custom converters (currently unused).
  ///
  /// ## Returns
  ///
  /// The value of the field, automatically converted to the appropriate Dart type.
  ///
  /// ## Throws
  ///
  /// [StateError] if the field doesn't exist.
  ///
  /// ## Example
  ///
  /// ```dart
  /// try {
  ///   final value = dartObject.getFieldValue('name');
  ///   // Use the value
  /// } catch (e) {
  ///   // Handle missing field
  /// }
  /// ```
  dynamic getFieldValue(String fieldName, [List<DartObjectConverter> DartObjectConverters = const []]) {
    DartObject? fieldObject = getField(fieldName);
    if (fieldObject == null) {
      throw StateError('Field $fieldName not found');
    }
    return fieldObject.getValue();
  }

  /// Extracts the actual Dart value from this [DartObject].
  ///
  /// This method automatically converts the [DartObject] to the appropriate
  /// Dart type. It handles:
  ///
  /// - Primitive types: bool, String, int, double
  /// - Collections: List, Set, Map (with recursive conversion)
  /// - Functions, Types, and Symbols
  /// - Custom types through registered converters
  /// - Null values
  ///
  /// ## Returns
  ///
  /// The converted Dart value, or `null` if the object is null.
  ///
  /// ## Throws
  ///
  /// Throws an error if no converter is found for a custom type.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final dartObject = element.computeConstantValue();
  /// if (dartObject != null) {
  ///   final value = dartObject.getValue();
  ///   // value is now the actual Dart value (String, int, List, etc.)
  /// }
  /// ```
  dynamic getValue() {
    if (isNull) return null;

    // Try to convert to primitive types first
    var value = toBoolValue() ??
        toStringValue() ??
        toIntValue() ??
        toDoubleValue() ??
        toListValue() ??
        toSetValue() ??
        toMapValue() ??
        toFunctionValue() ??
        toTypeValue() ??
        toSymbolValue();

    // Handle collections with recursive conversion
    if (value is List) {
      value = value.map((i) => (i as DartObject).getValue()).toList();
    }

    if (value is Set) {
      value = value.map((i) => (i as DartObject).getValue()).toSet();
    }

    if (value is Map) {
      value = value.map((k, v) => MapEntry((k as DartObject).getValue(), (v as DartObject).getValue()));
    }

    // Try custom converters for complex types
    if (value == null) {
      try {
        DartObjectConverter dartObjectConverter = DartObjectExtension._dartObjectConverters.entries
            .firstWhere((entry) => entry.key.toString() == type!.element!.name)
            .value;
        value = dartObjectConverter.convert(this);
      } catch (e) {
        if (e is StateError) {
          throw 'DartObjectConverter not found for type ${type!.element!.name}';
        } else
          throw e;
      }
    }
    return value;
  }

  /// Registry of custom [DartObjectConverter] instances.
  ///
  /// This map contains converters for complex types that can't be automatically
  /// converted by the analyzer. Converters are registered by their type.
  ///
  /// ## Default Converters
  ///
  /// - [Duration]: Uses [durationDartObjectConverter]
  ///
  /// ## Adding Custom Converters
  ///
  /// Custom converters are typically added through the [CodeBuilder] constructor:
  ///
  /// ```dart
  /// final builder = CodeBuilder(
  ///   name: 'my_builder',
  ///   dartObjectConverters: {MyType: myConverter},
  ///   // ...
  /// );
  /// ```
  static Map<Type, DartObjectConverter> _dartObjectConverters = {
    Duration: durationDartObjectConverter,
  };
}
