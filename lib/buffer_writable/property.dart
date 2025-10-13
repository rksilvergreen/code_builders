part of dart_source_builder;

class Property implements BufferWritable {
  /// The documentation comment for this property.
  ///
  /// Should be a multi-line string with `///` prefix for each line, following
  /// Dart documentation conventions. This appears directly above the property
  /// declaration and is used to generate API documentation.
  ///
  /// Example:
  /// ```dart
  /// '''
  /// /// The user's email address.
  /// ///
  /// /// This field is required for account creation.
  /// '''
  /// ```
  final String? docComment;

  /// A list of metadata annotations to be applied to this property.
  ///
  /// Annotations are prefixed with `@` and appear before the property declaration.
  /// Common examples include:
  /// - `@override` - indicates this property overrides a superclass/interface property
  /// - `@deprecated` - marks this property as deprecated
  /// - Custom annotations from your codebase
  ///
  /// Example: `['@override', '@deprecated']`
  final List<String> annotations;

  /// Whether this property is static (class-level rather than instance-level).
  ///
  /// Static properties belong to the class itself, not to instances of the class.
  final bool static;

  /// Whether this property is a compile-time constant.
  ///
  /// Const properties:
  /// - Must be static (at class level)
  /// - Must have an initializer (defaultValue)
  /// - Cannot be late
  /// - Cannot be external
  /// - Their value is computed at compile time
  final bool Const;

  /// Whether this property is final (can only be set once).
  ///
  /// Final properties can be initialized either:
  /// - At declaration with a defaultValue
  /// - In a constructor initializer list
  /// - In the constructor body (for late final)
  final bool Final;

  /// Whether this property uses late initialization.
  ///
  /// Late properties:
  /// - Are initialized lazily when first accessed
  /// - Cannot be const
  /// - Cannot be external
  /// - Can be combined with final
  final bool late;

  /// Whether this property is covariant.
  ///
  /// Covariant properties:
  /// - Allow a subclass to tighten the type of an inherited field
  /// - Cannot be static (only applies to instance members)
  /// - Are instance-level only
  final bool covariant;

  /// Whether this property is external.
  ///
  /// External properties:
  /// - Have no implementation in Dart code
  /// - Are implemented in native code or provided by another mechanism
  /// - Cannot have an initializer (defaultValue)
  /// - Cannot be const
  /// - Cannot be late
  final bool external;

  /// The type of this property.
  ///
  /// If null, the type will be inferred or default to 'dynamic'.
  final String? type;

  /// The name of this property.
  final String name;

  /// The default value/initializer for this property.
  ///
  /// Constraints:
  /// - Required for const properties
  /// - Not allowed for external properties
  final String? defaultValue;

  Property({
    this.docComment,
    this.annotations = const [],
    this.static = false,
    this.Const = false,
    this.Final = false,
    this.late = false,
    this.covariant = false,
    this.external = false,
    this.type,
    required this.name,
    this.defaultValue,
  })  : assert(!Const || static, 'Const properties must be static.'),
        assert(!Const || !late, 'A const property cannot be late.'),
        assert(!Const || !external, 'A const property cannot be external.'),
        assert(!Const || defaultValue != null, 'A const property must have a defaultValue.'),
        assert(!external || defaultValue == null, 'An external property cannot have a defaultValue.'),
        assert(!late || !external, 'A property cannot be both late and external.'),
        assert(!static || !covariant, 'A property cannot be both static and covariant.');

  static Future<Property> from(
    FieldElement fieldElement,
    BuildStep buildStep,
  ) async {
    VariableDeclaration astNode = (await buildStep.resolver.astNodeFor(fieldElement) as FieldDeclaration)
        .fields
        .variables
        .firstWhere((declaration) => declaration.name.stringValue == fieldElement.name);

    return Property(
      docComment: fieldElement.documentationComment,
      annotations: fieldElement.metadata.map((e) => e.toSource()).toList(),
      static: fieldElement.isStatic,
      Const: fieldElement.isConst,
      Final: fieldElement.isFinal,
      late: fieldElement.isLate,
      covariant: fieldElement.isCovariant,
      external: fieldElement.isExternal,
      type: '${fieldElement.type}',
      name: fieldElement.name,
      defaultValue: '${astNode.initializer}',
    );
  }

  Property copyWith({
    String? docComment,
    List<String>? annotations,
    bool? static,
    bool? Const,
    bool? Final,
    bool? late,
    bool? covariant,
    bool? external,
    String? type,
    String? name,
    String? defaultValue,
  }) =>
      Property(
        docComment: docComment ?? this.docComment,
        annotations: annotations ?? this.annotations,
        static: static ?? this.static,
        Const: Const ?? this.Const,
        Final: Final ?? this.Final,
        late: late ?? this.late,
        covariant: covariant ?? this.covariant,
        external: external ?? this.external,
        type: type ?? this.type,
        name: name ?? this.name,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  /// Writes the property declaration to the provided StringBuffer.
  ///
  /// The output follows Dart's field declaration syntax in the correct order:
  ///
  /// 1. **Documentation comment** (if present)
  /// 2. **Annotations** (e.g., `@override`, `@deprecated`)
  /// 3. **External modifier** (if external)
  /// 4. **Static or covariant modifier** (mutually exclusive)
  /// 5. **Late, const, or final modifier**
  /// 6. **Type** (or 'dynamic' if not specified)
  /// 7. **Name**
  /// 8. **Initializer** (if present)
  /// 9. **Semicolon**
  ///
  /// **Example outputs:**
  ///
  /// ```dart
  /// // Simple property
  /// String name;
  ///
  /// // With documentation and annotations
  /// /// The user's email address.
  /// @override
  /// final String email = 'default@example.com';
  ///
  /// // Static const
  /// static const int maxCount = 100;
  ///
  /// // Late final
  /// late final String apiKey;
  ///
  /// // External
  /// external static String platformVersion;
  /// ```
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment first
    if (docComment != null && docComment!.isNotEmpty) {
      b.write('$docComment\n');
    }

    // Write annotations
    for (var annotation in annotations) {
      b.write('@$annotation\n');
    }

    // Write modifiers in correct order per Dart specification:
    // external -> (static | covariant) -> (late | const | final) -> type -> name

    // 1. External modifier
    if (external) b.write('external ');

    // 2. Static or covariant (mutually exclusive)
    if (static) b.write('static ');
    if (covariant) b.write('covariant ');

    // 3. Late, const, or final
    if (late) b.write('late ');
    if (Const) b.write('const ');
    if (Final) b.write('final ');

    // 4. Type
    b.write('${type ?? 'dynamic'} ');

    // 5. Name
    b.write(name);

    // 6. Initializer (if present)
    if (defaultValue != null) b.write(' = $defaultValue');

    // 7. Semicolon
    b.write(';');
  }
}
