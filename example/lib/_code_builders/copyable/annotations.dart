/// Strategy for handling null values in copyWith
enum NullableStrategy {
  /// Use standard nullable parameters (can't distinguish between "don't change" and "set to null")
  standard,

  /// Generate a separate copyWithNull(['field1', 'field2']) method to explicitly set fields to null
  separateMethod,
}

/// How to generate the copyWith method
enum GenerationStyle {
  /// Generate as an extension method (default)
  extension,

  /// Generate as a mixin to be applied to the class
  mixin,
}

/// Strategy for copying nested objects
enum NestedCopyStrategy {
  /// Don't generate copyWith for nested objects (shallow copy)
  shallow,

  /// If nested object has copyWith, use it; otherwise shallow copy
  deepIfAvailable,

  /// Always try to deep copy nested objects
  deepCopy,
}

/// Field-level annotation to control how a specific field is copied
class CopyableField {
  /// Whether to exclude this field from copyWith parameters
  final bool exclude;

  /// Custom parameter name (if different from field name)
  final String? parameterName;

  /// Whether this field should always be deep copied
  final bool deepCopy;

  /// Custom copy expression to use instead of default behavior
  /// Example: 'tags?.map((e) => e).toList()' for lists
  /// Example: 'metadata != null ? Map.from(metadata!) : null' for maps
  final String? customCopyExpression;

  /// Whether this field is immutable (ID fields, timestamps, etc.)
  /// Alias for exclude=true, but more semantic
  final bool immutable;

  const CopyableField({
    this.exclude = false,
    this.parameterName,
    this.deepCopy = false,
    this.customCopyExpression,
    this.immutable = false,
  });

  @override
  String toString() {
    return 'CopyableField(exclude: $exclude, parameterName: $parameterName, deepCopy: $deepCopy, customCopyExpression: $customCopyExpression, immutable: $immutable)';
  }
}

/// Main annotation for generating copyWith functionality
class Copyable {
  /// Strategy for handling nullable fields
  final NullableStrategy nullableStrategy;

  /// How to generate the copyWith method
  final GenerationStyle style;

  /// Strategy for copying nested objects (default behavior when @CopyableField not specified)
  final NestedCopyStrategy nestedCopyStrategy;

  /// Name suffix for the generated extension/mixin (e.g., 'User' -> 'UserCopyable')
  /// If null, defaults to 'Copyable' for extensions or 'CopyableMixin' for mixins
  final String? nameSuffix;

  /// Whether to generate documentation comments for generated methods
  final bool generateDocs;

  /// Whether to include private fields (starting with _) in copyWith
  final bool includePrivateFields;

  /// Custom imports to add to generated file (e.g., for custom types)
  final List<String> imports;

  const Copyable({
    this.nullableStrategy = NullableStrategy.standard,
    this.style = GenerationStyle.extension,
    this.nestedCopyStrategy = NestedCopyStrategy.shallow,
    this.nameSuffix,
    this.generateDocs = true,
    this.includePrivateFields = false,
    this.imports = const [],
  });

  @override
  String toString() {
    return 'Copyable(nullableStrategy: $nullableStrategy, style: $style, nestedCopyStrategy: $nestedCopyStrategy, nameSuffix: $nameSuffix, generateDocs: $generateDocs, includePrivateFields: $includePrivateFields, imports: $imports)';
  }
}
