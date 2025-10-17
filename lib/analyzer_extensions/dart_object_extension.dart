
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'dart_object_converter.dart';

extension DartObjectExtension on DartObject {
  // bool isType<T>({bool withTypeParams = false}) => type!.isType<T>(withTypeParams: withTypeParams);

  bool hasField(String field) => getField(field) != null;

  dynamic getFieldValue(String fieldName, [List<DartObjectConverter> DartObjectConverters = const []]) {
    DartObject? fieldObject = getField(fieldName);
    if (fieldObject == null) {
      throw StateError('Field $fieldName not found');
    }
    return getValue(fieldObject);
  }

  static Map<Type, DartObjectConverter> _dartObjectConverters = {
    Duration: durationDartObjectConverter,
  };
}

/// Can't be an extended method because toListValue() returns List<DartObjectImpl>
/// which is not and CANNOT be extended
dynamic getValue(DartObject dartObject) {
  if (dartObject.isNull) return null;

  var value = dartObject.toBoolValue() ??
      dartObject.toStringValue() ??
      dartObject.toIntValue() ??
      dartObject.toDoubleValue() ??
      dartObject.toListValue() ??
      dartObject.toSetValue() ??
      dartObject.toMapValue() ??
      dartObject.toFunctionValue() ??
      dartObject.toTypeValue() ??
      dartObject.toSymbolValue();

  if (value is List) {
    value = value.map((i) => getValue(i)).toList();
  }

  if (value is Set) {
    value = value.map((i) => getValue(i)).toSet();
  }

  if (value is Map) {
    value = value.map((k, v) => MapEntry(getValue(k), getValue(v)));
  }

  if (dartObject.type!.element is EnumElement) {
    throw StateError('DartObject is not an enum');
  }

  if (value == null) {
    DartType type = dartObject.type!;
    try {
      DartObjectConverter dartObjectConverter = DartObjectExtension._dartObjectConverters.entries
          .firstWhere((entry) => entry.key.toString() == type.element!.name)
          .value;
      value = dartObjectConverter.convert(dartObject);
    } on StateError {
      throw StateError('DartObjectConverter not found for type ${type.element!.name}');
    }
  }
  return value;
}
