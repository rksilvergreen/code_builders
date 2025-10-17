part of dart_source_builder;

extension DartObjectExtension on DartObject {
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

  if (value == null) {
    DartType type = dartObject.type!;
    try {
      DartObjectConverter dartObjectConverter = DartObjectExtension._dartObjectConverters.entries.firstWhere((entry) {
        // print('entry.key.toString(): ${entry.key.toString()} (${entry.key.toString().length})');
        // print('type.element!.name: ${type.element!.name} (${type.element!.name!.length})');
        // print('entry.key.toString() == type.element!.name: ${entry.key.toString() == type.element!.name}');
        return entry.key.toString() == type.element!.name;
      }).value;
      // print(1);
      value = dartObjectConverter.convert(dartObject);
      // print(2);
    } catch (e) {
      // print('e!!!!!!!!!!!: $e');
      if (e is StateError) {
        throw 'DartObjectConverter not found for type ${type.element!.name}';
      } else
        throw e;
    }
  }
  return value;
}
