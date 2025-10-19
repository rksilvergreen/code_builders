part of code_builders;

/// Represents a global (top-level) variable declaration in Dart.
///
/// This class allows you to programmatically create top-level variable declarations
/// with all possible Dart configurations including const, final, late, external modifiers,
/// documentation comments, and annotations.
///
/// Global variables in Dart are variables declared at the top level of a Dart file,
/// outside of any class, function, or other structure.
///
/// ## Valid Modifier Combinations:
///
/// The following modifiers can be combined:
/// - `external` + `const`
/// - `external` + `final`
/// - `external` + `late`
/// - `late` + `final`
///
/// The following combinations are **invalid** and will throw an assertion error:
/// - `const` + `final` (const implies final)
/// - `const` + `late` (const values are compile-time constants)
/// - `external` + initializer (`defaultValue`)
/// - `const` without initializer (unless `external`)
///
/// ## Syntax Order:
///
/// The generated Dart code follows this order:
/// 1. Documentation comment (`docComment`)
/// 2. Annotations (`@annotation`)
/// 3. `external` keyword
/// 4. `late` keyword
/// 5. `const` or `final` keyword
/// 6. Type or `var` keyword
/// 7. Variable name
/// 8. Initializer (if any)
/// 9. Semicolon
///
/// ## Examples:
///
/// ```dart
/// // Simple variable with type inference
/// GlobalVariable(
///   name: 'counter',
///   defaultValue: '0',
/// )
/// // Generates: var counter = 0;
///
/// // Const variable with documentation
/// GlobalVariable(
///   docComment: '/// The maximum number of retries.',
///   Const: true,
///   type: 'int',
///   name: 'maxRetries',
///   defaultValue: '3',
/// )
/// // Generates:
/// // /// The maximum number of retries.
/// // const int maxRetries = 3;
///
/// // Late final variable with annotation
/// GlobalVariable(
///   annotations: ['deprecated'],
///   late: true,
///   Final: true,
///   type: 'String',
///   name: 'apiKey',
/// )
/// // Generates:
/// // @deprecated
/// // late final String apiKey;
///
/// // External constant
/// GlobalVariable(
///   external: true,
///   Const: true,
///   type: 'int',
///   name: 'nativeValue',
/// )
/// // Generates: external const int nativeValue;
/// ```
class GlobalVariable extends PublicBufferWritable {
  /// Optional documentation comment for this global variable.
  ///
  /// Should include the `///` or `/**` comment markers if desired.
  /// This will be written directly before any annotations and the variable declaration.
  ///
  /// Example: `'/// The default timeout in milliseconds.'`
  final String? docComment;

  /// Optional list of annotations to apply to this global variable.
  ///
  /// Each string should be the annotation name without the '@' symbol.
  /// For example: `['deprecated', 'override', 'pragma("vm:entry-point")']`
  ///
  /// These will be written as `@annotation` on separate lines before the variable.
  final List<String>? annotations;

  /// Whether this variable is declared with the `const` modifier.
  ///
  /// A const variable is a compile-time constant. Its value must be a constant expression
  /// that can be fully evaluated at compile time.
  ///
  /// **Rules:**
  /// - Cannot be combined with `final` (const implies final)
  /// - Cannot be combined with `late` (const values are compile-time constants)
  /// - Must have an initializer (`defaultValue`) unless also `external`
  /// - The value cannot be changed after initialization
  ///
  /// Example: `const int maxValue = 100;`
  final bool Const;

  /// Whether this variable is declared with the `final` modifier.
  ///
  /// A final variable can only be set once. Unlike const, final variables can be
  /// initialized at runtime.
  ///
  /// **Rules:**
  /// - Cannot be combined with `const` (const implies final)
  /// - Can be combined with `late` for late initialization
  /// - The value cannot be changed after initialization
  ///
  /// Example: `final String appName = 'MyApp';`
  final bool Final;

  /// Whether this variable is declared with the `late` modifier.
  ///
  /// The late modifier indicates that the variable will be initialized after its
  /// declaration but before it's first used. This defers initialization and allows
  /// non-nullable variables to be declared without an immediate initializer.
  ///
  /// **Rules:**
  /// - Cannot be combined with `const`
  /// - Can be combined with `final` for late final variables
  /// - The variable must be initialized before its first use
  ///
  /// Example: `late String configPath;`
  final bool late;

  /// Whether this variable is declared with the `external` modifier.
  ///
  /// An external variable is declared but defined elsewhere (typically in native code
  /// or through FFI). External variables don't have an initializer in the Dart code.
  ///
  /// **Rules:**
  /// - Cannot have an initializer (`defaultValue` must be null)
  /// - Can be combined with `const`, `final`, or `late`
  /// - The actual implementation is provided externally
  ///
  /// Example: `external int platformVersion;`
  final bool external;

  /// The type annotation for this variable.
  ///
  /// If `null`:
  /// - For `const`, `final`, or `late` variables: type will be inferred from the initializer
  /// - For regular variables: the `var` keyword will be used
  ///
  /// If specified, should be a valid Dart type (e.g., 'int', 'String', 'List<dynamic>').
  ///
  /// Examples:
  /// - `'int'` → `int myVar = 0;`
  /// - `'List<String>'` → `List<String> items = [];`
  /// - `null` with const → `const value = 42;` (type inferred)
  /// - `null` without modifiers → `var value = 42;`
  final String? type;

  /// The name of the variable.
  ///
  /// This is required and should follow Dart naming conventions:
  /// - Use lowerCamelCase for variable names
  /// - Use SCREAMING_CAPS for compile-time constants (const variables)
  /// - Should be a valid Dart identifier
  ///
  /// Examples: `'counter'`, `'apiEndpoint'`, `'MAX_RETRY_COUNT'`
  final String name;

  /// The initializer expression for this variable.
  ///
  /// This is the value assigned to the variable when it's declared.
  /// Should be a valid Dart expression as a string.
  ///
  /// **Rules:**
  /// - Cannot be set if `external` is true
  /// - Must be set if `Const` is true (unless `external` is also true)
  /// - For const variables, must be a constant expression
  ///
  /// Examples:
  /// - `'0'` → `= 0`
  /// - `"'default'"` → `= 'default'`
  /// - `'DateTime.now()'` → `= DateTime.now()`
  /// - `'[1, 2, 3]'` → `= [1, 2, 3]`
  final String? defaultValue;

  /// Creates a new [GlobalVariable] instance.
  ///
  /// All parameters except [name] are optional. The constructor includes assertions
  /// to ensure that invalid modifier combinations are caught at runtime.
  ///
  /// ## Parameters:
  ///
  /// - [docComment]: Optional documentation comment
  /// - [annotations]: Optional list of annotations (without '@' symbol)
  /// - [Const]: Whether this is a const variable (default: false)
  /// - [Final]: Whether this is a final variable (default: false)
  /// - [late]: Whether this is a late variable (default: false)
  /// - [external]: Whether this is an external variable (default: false)
  /// - [type]: Optional type annotation (null uses inference or 'var')
  /// - [name]: The variable name (required)
  /// - [defaultValue]: Optional initializer expression
  ///
  /// ## Throws:
  ///
  /// Throws an [AssertionError] if:
  /// - Both [Const] and [Final] are true
  /// - Both [Const] and [late] are true
  /// - [external] is true and [defaultValue] is not null
  /// - [Const] is true, [external] is false, and [defaultValue] is null
  GlobalVariable({
    this.docComment,
    this.annotations,
    this.Const = false,
    this.Final = false,
    this.late = false,
    this.external = false,
    this.type,
    required this.name,
    this.defaultValue,
  })  : assert(
          !Const || !Final,
          'A variable cannot be both const and final (const implies final)',
        ),
        assert(
          !Const || !late,
          'A variable cannot be both const and late',
        ),
        assert(
          !external || defaultValue == null,
          'An external variable cannot have an initializer',
        ),
        assert(
          !Const || external || defaultValue != null,
          'A const variable must have an initializer (unless external)',
        );

  /// Creates a [GlobalVariable] instance from an analyzer [TopLevelVariableElement].
  ///
  /// This factory method is useful when working with Dart's analyzer API or build_runner
  /// to extract variable information from existing Dart code.
  ///
  /// **Note:** The [defaultValue] is intentionally set to `null` because extracting
  /// the actual initializer expression from the AST would require additional AST
  /// traversal. If you need the default value, you should extract it separately
  /// and use [copyWith] to add it.
  ///
  /// ## Parameters:
  ///
  /// - [topLevelVariableElement]: The analyzer element representing a top-level variable
  /// - [buildStep]: The build step (currently unused but kept for API consistency)
  ///
  /// ## Returns:
  ///
  /// A [Future] that completes with a [GlobalVariable] instance populated with
  /// the variable's modifiers, type, and name from the element.
  ///
  /// ## Example:
  ///
  /// ```dart
  /// final variable = await GlobalVariable.from(element, buildStep);
  /// // Add the default value separately if needed
  /// final withValue = variable.copyWith(defaultValue: '42');
  /// ```
  static Future<GlobalVariable> from(
    TopLevelVariableElement topLevelVariableElement,
    BuildStep buildStep,
  ) async =>
      GlobalVariable(
        Const: topLevelVariableElement.isConst,
        Final: topLevelVariableElement.isFinal,
        late: topLevelVariableElement.isLate,
        external: topLevelVariableElement.isExternal,
        type: '${topLevelVariableElement.type}',
        name: topLevelVariableElement.name,
        defaultValue: null,
      );

  /// Creates a copy of this [GlobalVariable] with the specified properties replaced.
  ///
  /// This method allows you to create a modified version of an existing variable
  /// without mutating the original. Any parameter not provided will default to
  /// the current instance's value.
  ///
  /// ## Parameters:
  ///
  /// All parameters are optional. If a parameter is `null`, the current value is used.
  ///
  /// - [docComment]: New documentation comment
  /// - [annotations]: New list of annotations
  /// - [Const]: New const modifier value
  /// - [Final]: New final modifier value
  /// - [late]: New late modifier value
  /// - [external]: New external modifier value
  /// - [type]: New type annotation
  /// - [name]: New variable name
  /// - [defaultValue]: New initializer expression
  ///
  /// ## Returns:
  ///
  /// A new [GlobalVariable] instance with the specified properties changed.
  ///
  /// ## Example:
  ///
  /// ```dart
  /// final original = GlobalVariable(
  ///   name: 'counter',
  ///   type: 'int',
  ///   defaultValue: '0',
  /// );
  ///
  /// final modified = original.copyWith(
  ///   Const: true,
  ///   name: 'MAX_COUNT',
  ///   defaultValue: '100',
  /// );
  /// // modified is now: const int MAX_COUNT = 100;
  /// ```
  GlobalVariable copyWith({
    String? docComment,
    List<String>? annotations,
    bool? Const,
    bool? Final,
    bool? late,
    bool? external,
    String? type,
    String? name,
    String? defaultValue,
  }) =>
      GlobalVariable(
        docComment: docComment ?? this.docComment,
        annotations: annotations ?? this.annotations,
        Const: Const ?? this.Const,
        Final: Final ?? this.Final,
        late: late ?? this.late,
        external: external ?? this.external,
        type: type ?? this.type,
        name: name ?? this.name,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  /// Writes the variable declaration to the provided [StringBuffer].
  ///
  /// This method generates the complete Dart source code for the variable declaration,
  /// including documentation, annotations, modifiers, type, name, and initializer.
  ///
  /// ## Output Format:
  ///
  /// The method writes components in this order:
  ///
  /// 1. **Documentation comment** (if present): Written with newline
  /// 2. **Annotations** (if any): Each on its own line with '@' prefix
  /// 3. **Modifiers** (in order):
  ///    - `external` (if true)
  ///    - `late` (if true)
  ///    - `const` (if true)
  ///    - `final` (if true)
  /// 4. **Type or var keyword**:
  ///    - If `const`, `final`, or `late`: type is optional (uses inference if null)
  ///    - Otherwise: uses specified type or `var` if type is null
  /// 5. **Variable name**
  /// 6. **Initializer** (if [defaultValue] is not null): ` = <defaultValue>`
  /// 7. **Semicolon**
  ///
  /// ## Type Handling:
  ///
  /// - For `const`/`final`/`late` variables: If [type] is null, no type keyword is written
  ///   (Dart will infer the type from the initializer)
  /// - For regular variables: If [type] is null, writes `var` keyword instead
  ///
  /// ## Parameters:
  ///
  /// - [b]: The [StringBuffer] to write the variable declaration to
  ///
  /// ## Example Output:
  ///
  /// ```dart
  /// // With all features:
  /// /// A constant value.
  /// @deprecated
  /// const int maxValue = 100;
  ///
  /// // Type inference:
  /// final value = 42;
  ///
  /// // With var:
  /// var counter = 0;
  ///
  /// // External:
  /// external late String apiKey;
  /// ```
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment first
    if (docComment != null) {
      b.write('$docComment\n');
    }

    // Write annotations
    if (annotations != null && annotations!.isNotEmpty) {
      for (var annotation in annotations!) {
        b.write('@$annotation\n');
      }
    }

    // Write variable modifiers
    if (external) b.write('external ');
    if (late) b.write('late ');
    if (Const) b.write('const ');
    if (Final) b.write('final ');

    // Handle type/var keyword
    if (Const || Final || late) {
      // const/final/late can omit type for inference, or specify a type
      if (type != null) b.write('$type ');
    } else {
      // Regular variable needs either a type or 'var'
      b.write('${type ?? 'var'} ');
    }

    b.write(name);
    if (defaultValue != null) b.write(' = $defaultValue');
    b.write(';');
  }
}
