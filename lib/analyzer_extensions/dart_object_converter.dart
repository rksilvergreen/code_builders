part of code_builders;

/// A generic converter for transforming [DartObject] instances into specific Dart types.
///
/// This class provides a way to convert analyzer [DartObject] instances into
/// actual Dart values of a specific type. It's particularly useful for handling
/// complex types that can't be automatically converted by the analyzer.
///
/// ## Usage
///
/// ```dart
/// // Create a converter for a custom type
/// final converter = DartObjectConverter<MyType>((dartObject) =>
///   MyType(
///     value: dartObject.getFieldValue('value'),
///     name: dartObject.getFieldValue('name'),
///   )
/// );
///
/// // Register with CodeBuilder
/// final builder = CodeBuilder(
///   name: 'my_builder',
///   buildExtensions: {'lib/*.dart': ['lib/gen/*.g.dart']},
///   dartObjectConverters: {MyType: converter},
///   build: (buildStep) async => StringBuffer(),
/// );
/// ```
///
/// ## Type Safety
///
/// The converter is generic and provides compile-time type safety. The [convert]
/// function must return a value of type [T].
///
/// ## Error Handling
///
/// The converter function should handle potential errors when accessing fields
/// or converting values. Use [DartObject.getFieldValue] for safe field access.
class DartObjectConverter<T> {
  /// The type this converter handles.
  final Type type = T;

  /// The conversion function that transforms a [DartObject] into type [T].
  ///
  /// This function receives a [DartObject] and must return a value of type [T].
  /// It should handle field access and type conversion appropriately.
  final T Function(DartObject) convert;

  /// Creates a new [DartObjectConverter] with the specified conversion function.
  ///
  /// [convert]: The function that converts [DartObject] to type [T].
  DartObjectConverter(this.convert);
}

/// Pre-configured converter for [Duration] objects.
///
/// This converter handles the conversion of [DartObject] instances representing
/// [Duration] values. It accesses the internal `_duration` field and creates
/// a new [Duration] instance with the microsecond value.
///
/// ## Usage
///
/// This converter is automatically registered when using [CodeBuilder] with
/// default [dartObjectConverters]. It can also be used manually:
///
/// ```dart
/// final dartObject = element.computeConstantValue();
/// if (dartObject != null) {
///   final duration = durationDartObjectConverter.convert(dartObject);
/// }
/// ```
DartObjectConverter<Duration> durationDartObjectConverter = DartObjectConverter<Duration>((dartObject) => Duration(
      microseconds: dartObject.getFieldValue('_duration') as int,
    ));
