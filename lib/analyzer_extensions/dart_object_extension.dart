part of code_builders;

extension DartObjectExtension on DartObject {
  bool hasField(String field) => getField(field) != null;

  dynamic getFieldValue(String fieldName, [List<DartObjectConverter> DartObjectConverters = const []]) {
    DartObject? fieldObject = getField(fieldName);
    if (fieldObject == null) {
      throw StateError('Field $fieldName not found');
    }
    return fieldObject.getValue();
  }

  /// Can't be an extended method because toListValue() returns List<DartObjectImpl>
  /// which is not and CANNOT be extended
  dynamic getValue() {
    if (isNull) return null;

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

    if (value is List) {
      value = value.map((i) => (i as DartObject).getValue()).toList();
    }

    if (value is Set) {
      value = value.map((i) => (i as DartObject).getValue()).toSet();
    }

    if (value is Map) {
      value = value.map((k, v) => MapEntry((k as DartObject).getValue(), (v as DartObject).getValue()));
    }

    if (value == null) {
      // DartType type = dartObject.type!;
      try {
        DartObjectConverter dartObjectConverter = DartObjectExtension._dartObjectConverters.entries.firstWhere((entry) {
          // print('entry.key.toString(): ${entry.key.toString()} (${entry.key.toString().length})');
          // print('type.element!.name: ${type.element!.name} (${type.element!.name!.length})');
          // print('entry.key.toString() == type.element!.name: ${entry.key.toString() == type.element!.name}');
          return entry.key.toString() == type!.element!.name;
        }).value;
        // print(1);
        value = dartObjectConverter.convert(this);
        // print(2);
      } catch (e) {
        // print('e!!!!!!!!!!!: $e');
        if (e is StateError) {
          throw 'DartObjectConverter not found for type ${type!.element!.name}';
        } else
          throw e;
      }
    }
    return value;
  }

  static Map<Type, DartObjectConverter> _dartObjectConverters = {
    Duration: durationDartObjectConverter,
  };
}
