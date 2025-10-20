part of code_builders;

/// Represents a Dart getter method declaration.
///
/// A getter is a special method that provides read-only access to a property.
/// It uses the `get` keyword and cannot accept parameters. This class models
/// all possible configurations of a getter in Dart, including:
/// - External getters (declared but implemented elsewhere)
/// - Static getters (class-level, not instance-level)
/// - Async getters (returning Future or Stream)
/// - Generator getters (using sync* or async*)
/// - Arrow function syntax (=>) or block body syntax
/// - Type annotations (explicit return types)
/// - Metadata annotations (@override, @deprecated, custom annotations)
/// - Documentation comments
///
/// Example usage:
/// ```dart
/// // Simple getter with arrow function
/// final getter = Getter(
///   type: 'String',
///   name: 'fullName',
///   arrowFunction: true,
///   body: (b) => b.write('"\$firstName \$lastName"'),
/// );
///
/// // Async getter returning a Future
/// final asyncGetter = Getter(
///   type: 'Future<User>',
///   name: 'currentUser',
///   async: true,
///   body: (b) => b.write('return await _userRepository.getCurrentUser();'),
/// );
///
/// // External getter (no implementation)
/// final externalGetter = Getter(
///   external: true,
///   type: 'int',
///   name: 'platformVersion',
/// );
/// ```
class Getter implements BufferWritable {
  /// A list of metadata annotations to be applied to this getter.
  ///
  /// Annotations are prefixed with `@` and appear before the getter declaration.
  /// Common examples include:
  /// - `@override` - indicates this getter overrides a superclass/interface getter
  /// - `@deprecated` - marks this getter as deprecated
  /// - `@pragma('vm:entry-point')` - compiler directives
  /// - Custom annotations from your codebase
  ///
  /// Example: `['@override', '@deprecated']`
  final List<String> annotations;

  /// The documentation comment for this getter.
  ///
  /// Should be a multi-line string with `///` prefix for each line, following
  /// Dart documentation conventions. This appears directly above the getter
  /// declaration and is used to generate API documentation.
  ///
  /// Example:
  /// ```dart
  /// '''
  /// /// Returns the full name of the user.
  /// ///
  /// /// Combines [firstName] and [lastName] with a space.
  /// '''
  /// ```
  final String docComment;

  /// Whether this getter is declared as external.
  ///
  /// External getters have no implementation in Dart code - they are implemented
  /// in native code (C++, JavaScript, etc.) or provided by another mechanism.
  /// External getters:
  /// - Cannot have a body
  /// - Cannot be async or generators
  /// - End with a semicolon instead of a body
  ///
  /// Example: `external String get platformName;`
  final bool external;

  /// Whether this getter is static (class-level rather than instance-level).
  ///
  /// Static getters belong to the class itself, not to instances of the class.
  /// They can be called without creating an instance:
  /// - `MyClass.staticGetter` instead of `instance.getter`
  /// - Cannot access instance members (this)
  /// - Useful for factory-like patterns or class-level configuration
  final bool static;

  /// The return type of this getter.
  ///
  /// Can be any valid Dart type including:
  /// - Primitive types: `int`, `String`, `bool`, etc.
  /// - Generic types: `List<String>`, `Map<int, User>`, etc.
  /// - Future/Stream: `Future<int>`, `Stream<String>`, etc.
  /// - Custom types: `User`, `MyCustomClass`, etc.
  /// - Empty string (`''`) for type inference (Dart will infer the type)
  ///
  /// If empty, the type annotation is omitted from the generated code.
  final String type;

  /// The name of this getter.
  ///
  /// Must be a valid Dart identifier following these rules:
  /// - Cannot be empty
  /// - Must start with a letter or underscore
  /// - Can contain letters, digits, and underscores
  /// - Should follow Dart naming conventions (lowerCamelCase)
  /// - Private getters start with underscore (e.g., `_privateGetter`)
  final String name;

  /// Whether this getter is asynchronous (returns a Future).
  ///
  /// Async getters are marked with the `async` keyword and must return a Future.
  /// They allow using `await` within the getter body.
  ///
  /// Example: `Future<String> get data async { return await fetchData(); }`
  ///
  /// Cannot be used with [external] getters.
  final bool async;

  /// Whether this getter is a generator (uses sync* or async*).
  ///
  /// Generator getters produce a sequence of values:
  /// - `sync*` with [async]=false: Returns an Iterable, uses `yield`
  /// - `async*` with [async]=true: Returns a Stream, uses `yield`
  ///
  /// Example: `Stream<int> get numbers async* { yield 1; yield 2; }`
  ///
  /// Cannot be used with [external] getters.
  final bool generator;

  /// Whether this getter uses arrow function syntax (=>) instead of a block body.
  ///
  /// Arrow syntax is concise single-expression syntax:
  /// - `get name => expression;` instead of `get name { return expression; }`
  /// - Automatically returns the expression result
  /// - Cannot contain multiple statements
  /// - Commonly used for simple getters
  ///
  /// Example: `String get fullName => '$firstName $lastName';`
  final bool arrowFunction;

  /// The implementation body of this getter.
  ///
  /// A function that writes the getter's implementation to a StringBuffer.
  /// The function receives a StringBuffer parameter and should write the
  /// getter's logic to it.
  ///
  /// For [arrowFunction]=true: Write the single expression (no return keyword)
  /// For [arrowFunction]=false: Write the statements for the block body
  ///
  /// This is `null` for [external] getters (which have no body).
  ///
  /// Example:
  /// ```dart
  /// // Arrow function body
  /// body: (b) => b.write('"$firstName $lastName"')
  ///
  /// // Block body
  /// body: (b) => b.write('return _firstName + " " + _lastName;')
  /// ```
  final void Function(StringBuffer)? body;

  /// Creates a new [Getter] instance.
  ///
  /// All parameters are optional except [name] and [body] (unless [external] is true).
  ///
  /// Validation rules enforced by assertions:
  /// - [name] cannot be empty
  /// - [external] getters cannot have a [body]
  /// - If [body] is null, then [async], [generator], and [arrowFunction] must all be false
  /// - Non-[external] getters must have a [body]
  ///
  /// Example:
  /// ```dart
  /// // Standard getter with type and arrow function
  /// final getter = Getter(
  ///   type: 'String',
  ///   name: 'greeting',
  ///   arrowFunction: true,
  ///   body: (b) => b.write('"Hello, World!"'),
  /// );
  ///
  /// // Overriding getter
  /// final overrideGetter = Getter(
  ///   annotations: ['@override'],
  ///   type: 'int',
  ///   name: 'hashCode',
  ///   arrowFunction: true,
  ///   body: (b) => b.write('name.hashCode ^ age.hashCode'),
  /// );
  ///
  /// // External getter
  /// final externalGetter = Getter(
  ///   external: true,
  ///   type: 'String',
  ///   name: 'platformVersion',
  /// );
  /// ```
  Getter({
    this.annotations = const [],
    this.docComment = '',
    this.external = false,
    this.static = false,
    this.type = '',
    required this.name,
    this.async = false,
    this.generator = false,
    this.arrowFunction = false,
    this.body,
  })  : assert(name.isNotEmpty, 'Getter name cannot be empty'),
        assert(!external || body == null, 'External getters cannot have a body'),
        assert(body != null || !async, 'Cannot be async without a body'),
        assert(body != null || !generator, 'Cannot be a generator without a body'),
        assert(body != null || !arrowFunction, 'Cannot use arrow function syntax without a body'),
        assert(external || body != null, 'Non-external getters must have a body');

  /// Creates a [Getter] instance from analyzer's [PropertyAccessorElement].
  ///
  /// This factory method is used during code generation to extract getter
  /// information from existing Dart source code using the analyzer package.
  /// It reconstructs a [Getter] object from the AST (Abstract Syntax Tree).
  ///
  /// Parameters:
  /// - [getterElement]: The analyzer element representing the getter.
  ///   Must be a getter (not a setter), validated by assertion.
  /// - [buildStep]: The build step from the build package, used to resolve
  ///   AST nodes from elements.
  ///
  /// The method extracts:
  /// - All metadata annotations (including @override and custom annotations)
  /// - Documentation comments from the AST node
  /// - Whether the getter is external
  /// - Whether the getter is static
  /// - The return type as a string
  /// - The getter name
  /// - Whether it's async or a generator
  /// - Whether it uses arrow syntax or block syntax
  /// - The body implementation (or null for external/empty bodies)
  ///
  /// Returns a [Future<Getter>] that completes with the reconstructed getter.
  ///
  /// Throws an [AssertionError] if [getterElement] is not actually a getter.
  ///
  /// Example usage in a code generator:
  /// ```dart
  /// final element = libraryReader.classes
  ///     .first
  ///     .accessors
  ///     .firstWhere((a) => a.isGetter);
  /// final getter = await Getter.from(element, buildStep);
  /// ```
  static Future<Getter> from(
    GetterElement getterElement,
    BuildStep buildStep,
  ) async {
    MethodDeclaration astNode = await buildStep.resolver.astNodeFor(getterElement.firstFragment) as MethodDeclaration;

    // Collect all annotations
    List<String> annotations = [];
    for (var annotation in getterElement.metadata.annotations) {
      if (annotation.isOverride) {
        annotations.add('@override');
      } else {
        annotations.add(annotation.toSource());
      }
    }

    // Extract doc comment if present
    String docComment = '';
    if (astNode.documentationComment != null) {
      docComment = astNode.documentationComment!.tokens.map((token) => token.toString()).join('\n');
    }

    return Getter(
        annotations: annotations,
        docComment: docComment,
        external: getterElement.isExternal,
        static: getterElement.isStatic,
        type: '${getterElement.returnType}',
        name: getterElement.name!,
        async: getterElement.firstFragment.isAsynchronous,
        generator: getterElement.firstFragment.isGenerator,
        arrowFunction: astNode.body is ExpressionFunctionBody,
        body: (astNode.body is EmptyFunctionBody)
            ? null
            : (StringBuffer b) {
                FunctionBody body = astNode.body;
                if (body is BlockFunctionBody)
                  b.write(body.block.statements.join(' '));
                else if (body is ExpressionFunctionBody) b.write('${body.expression}');
              });
  }

  /// Creates a copy of this [Getter] with the specified properties replaced.
  ///
  /// This method allows you to create a modified version of an existing getter
  /// without mutating the original instance. Any parameter that is not provided
  /// (or is null) will use the value from the current instance.
  ///
  /// This is useful for:
  /// - Making slight variations of a getter
  /// - Programmatically modifying getters during code generation
  /// - Creating getter templates that can be customized
  ///
  /// All validation rules from the constructor still apply to the copied instance.
  ///
  /// Example:
  /// ```dart
  /// final original = Getter(
  ///   type: 'String',
  ///   name: 'firstName',
  ///   body: (b) => b.write('_firstName'),
  /// );
  ///
  /// // Create a static version of the same getter
  /// final staticVersion = original.copyWith(static: true);
  ///
  /// // Add an @override annotation
  /// final overridden = original.copyWith(
  ///   annotations: ['@override'],
  /// );
  ///
  /// // Change to arrow function syntax
  /// final arrow = original.copyWith(arrowFunction: true);
  /// ```
  Getter copyWith({
    List<String>? annotations,
    String? docComment,
    bool? external,
    bool? static,
    String? type,
    String? name,
    bool? async,
    bool? generator,
    bool? arrowFunction,
    void Function(StringBuffer)? body,
  }) =>
      Getter(
        annotations: annotations ?? this.annotations,
        docComment: docComment ?? this.docComment,
        external: external ?? this.external,
        static: static ?? this.static,
        type: type ?? this.type,
        name: name ?? this.name,
        async: async ?? this.async,
        generator: generator ?? this.generator,
        arrowFunction: arrowFunction ?? this.arrowFunction,
        body: body ?? this.body,
      );

  /// Writes the complete Dart getter declaration to a [StringBuffer].
  ///
  /// This method generates valid Dart source code for the getter by writing
  /// all components in the correct syntactic order according to Dart language
  /// specifications.
  ///
  /// The output follows this structure:
  /// ```
  /// [docComment]
  /// [annotations]
  /// [external] [static] [type] get [name] [async-modifier] [body]
  /// ```
  ///
  /// Specific behaviors:
  /// - **Documentation comment**: Written first if present, followed by newline
  /// - **Annotations**: Each annotation followed by a space (e.g., `@override `)
  /// - **Modifiers**: Written in order: `external`, then `static`
  /// - **Type**: Only written if non-empty, followed by space
  /// - **Getter keyword and name**: Always `get name`
  /// - **External getters**: End with semicolon, no body or async modifiers
  /// - **Async modifiers**: Space before modifier (`async`, `async*`, or `sync*`)
  /// - **Arrow function body**: ` => expression;`
  /// - **Block body**: ` { statements }`
  ///
  /// Example outputs:
  /// ```dart
  /// // Simple getter
  /// String get name => _name;
  ///
  /// // With annotations and documentation
  /// /// Returns the user's full name.
  /// @override
  /// String get fullName { return '$firstName $lastName'; }
  ///
  /// // Static external getter
  /// external static int get platformVersion;
  ///
  /// // Async generator
  /// Stream<int> get numbers async* { yield 1; yield 2; }
  /// ```
  ///
  /// Parameters:
  /// - [b]: The StringBuffer to write the getter declaration to
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment
    if (docComment.isNotEmpty) {
      b.writeln(docComment);
    }

    // Write annotations
    for (var annotation in annotations) {
      b.write('$annotation ');
    }

    // Write modifiers in correct order: external, static
    if (external) b.write('external ');
    if (static) b.write('static ');

    // Write return type (if provided)
    if (type.isNotEmpty) {
      b.write('$type ');
    }

    // Write getter keyword and name
    b.write('get $name');

    // For external getters, just end with semicolon
    if (external) {
      b.write(';');
      return;
    }

    // Write async modifiers
    if (async) {
      if (generator)
        b.write(' async*');
      else
        b.write(' async');
    } else if (generator) {
      b.write(' sync*');
    }

    // Write body
    if (arrowFunction) {
      b.write(' => ');
      StringBuffer buffer = StringBuffer();
      body!(buffer);
      b.write(buffer.toString());
      b.write(';');
    } else {
      b.write(' { ');
      StringBuffer buffer = StringBuffer();
      body!(buffer);
      b.write(buffer.toString());
      b.write(' }');
    }
  }
}
