part of 'builder.dart';

final _dartObjectConverters = {
  NullableStrategy: _nullableStrategyConverter,
  GenerationStyle: _generationStyleConverter,
  NestedCopyStrategy: _nestedCopyStrategyConverter,
  CopyableField: _copyableFieldConverter,
  Copyable: _copyableConverter,
};

DartObjectConverter<NullableStrategy> _nullableStrategyConverter = DartObjectConverter<NullableStrategy>(
  (dartObject) => NullableStrategy.values.firstWhere((e) => e.name == dartObject.variable!.name),
);

DartObjectConverter<GenerationStyle> _generationStyleConverter = DartObjectConverter<GenerationStyle>(
  (dartObject) => GenerationStyle.values.firstWhere((e) => e.name == dartObject.variable!.name),
);

DartObjectConverter<NestedCopyStrategy> _nestedCopyStrategyConverter = DartObjectConverter<NestedCopyStrategy>(
  (dartObject) => NestedCopyStrategy.values.firstWhere((e) => e.name == dartObject.variable!.name),
);

DartObjectConverter<CopyableField> _copyableFieldConverter = DartObjectConverter<CopyableField>(
  (dartObject) => CopyableField(
    exclude: dartObject.getFieldValue('exclude') as bool,
    parameterName: dartObject.getFieldValue('parameterName') as String?,
    deepCopy: dartObject.getFieldValue('deepCopy') as bool,
    customCopyExpression: dartObject.getFieldValue('customCopyExpression') as String?,
    immutable: dartObject.getFieldValue('immutable') as bool,
  ),
);

DartObjectConverter<Copyable> _copyableConverter = DartObjectConverter<Copyable>(
  (dartObject) => Copyable(
    nullableStrategy: dartObject.getFieldValue('nullableStrategy', [_nullableStrategyConverter]) as NullableStrategy,
    style: dartObject.getFieldValue('style', [_generationStyleConverter]) as GenerationStyle,
    nestedCopyStrategy:
        dartObject.getFieldValue('nestedCopyStrategy', [_nestedCopyStrategyConverter]) as NestedCopyStrategy,
    nameSuffix: dartObject.getFieldValue('nameSuffix') as String?,
    generateDocs: dartObject.getFieldValue('generateDocs') as bool,
    includePrivateFields: dartObject.getFieldValue('includePrivateFields') as bool,
    imports: dartObject.getFieldValue('imports').cast<String>(),
  ),
);
