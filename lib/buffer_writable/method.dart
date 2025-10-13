part of dart_source_builder;

/// Represents a Dart method declaration with full support for all method features.
///
/// This class models any valid Dart method including:
/// - Instance and static methods
/// - Methods with generic type parameters
/// - Async methods (async, async*, sync*)
/// - External methods (implemented outside Dart)
/// - Arrow function syntax vs block body syntax
/// - All parameter types (positional, optional, named, required named)
/// - Documentation comments and metadata annotations
///
/// **Examples:**
///
/// Simple method:
/// ```dart
/// Method(
///   name: 'greet',
///   returnType: 'String',
///   body: (b) => b.write('return "Hello";'),
/// )
/// // Generates: String greet() { return "Hello"; }
/// ```
///
/// Async method with parameters:
/// ```dart
/// Method(
///   returnType: 'Future<User>',
///   name: 'fetchUser',
///   async: true,
///   parameters: [
///     MethodParameter(type: 'String', name: 'id'),
///   ],
///   body: (b) => b.write('return await userRepo.getById(id);'),
/// )
/// // Generates: Future<User> fetchUser(String id) async { return await userRepo.getById(id); }
/// ```
///
/// Generic method with arrow syntax:
/// ```dart
/// Method(
///   returnType: 'T',
///   name: 'identity',
///   genericTypes: ['T'],
///   parameters: [MethodParameter(type: 'T', name: 'value')],
///   arrowFunction: true,
///   body: (b) => b.write('value'),
/// )
/// // Generates: T identity<T>(T value) => value;
/// ```
///
/// External method:
/// ```dart
/// Method(
///   external: true,
///   returnType: 'void',
///   name: 'nativeMethod',
/// )
/// // Generates: external void nativeMethod();
/// ```
class Method implements BufferWritable {
  /// A list of metadata annotations to be applied to this method.
  ///
  /// Annotations are prefixed with `@` and appear before the method declaration.
  /// Common examples include:
  /// - `@override` - indicates this method overrides a superclass/interface method
  /// - `@deprecated` - marks this method as deprecated
  /// - `@pragma('vm:entry-point')` - compiler directives
  /// - Custom annotations from your codebase
  ///
  /// Example: `['@override', '@deprecated']`
  final List<String> annotations;

  /// The documentation comment for this method.
  ///
  /// Should be a multi-line string with `///` prefix for each line, following
  /// Dart documentation conventions. This appears directly above the method
  /// declaration and is used to generate API documentation.
  ///
  /// Example:
  /// ```dart
  /// '''
  /// /// Calculates the sum of two numbers.
  /// ///
  /// /// Returns the result of adding [a] and [b].
  /// '''
  /// ```
  final String docComment;

  /// Whether this method is declared as external.
  ///
  /// External methods have no implementation in Dart code - they are implemented
  /// in native code (C++, JavaScript, etc.) or provided by another mechanism.
  /// External methods:
  /// - Cannot have a body
  /// - Cannot be async or generators
  /// - Cannot use arrow function syntax
  /// - End with a semicolon instead of a body
  ///
  /// Example: `external String platformMethod();`
  final bool external;

  /// Whether this method overrides a superclass or interface method.
  ///
  /// When true, generates the `@override` annotation. Note that this can also
  /// be set via the [annotations] list. This property exists for backward
  /// compatibility and convenience.
  ///
  /// Example: `@override void toString() { ... }`
  final bool override;

  /// Whether this method is static (class-level rather than instance-level).
  ///
  /// Static methods belong to the class itself, not to instances of the class.
  /// They can be called without creating an instance:
  /// - `MyClass.staticMethod()` instead of `instance.method()`
  /// - Cannot access instance members (this)
  /// - Useful for utility functions or factory-like patterns
  ///
  /// Example: `static int parse(String str) { ... }`
  final bool static;

  /// The return type of this method.
  ///
  /// Can be any valid Dart type including:
  /// - Primitive types: `int`, `String`, `bool`, etc.
  /// - Generic types: `List<String>`, `Map<int, User>`, etc.
  /// - Future/Stream: `Future<int>`, `Stream<String>`, etc.
  /// - Custom types: `User`, `MyCustomClass`, etc.
  /// - `void` for methods that don't return a value
  /// - `null` to omit the type annotation (Dart will infer or use dynamic)
  ///
  /// Example: `'Future<String>'` generates `Future<String> methodName() { ... }`
  final String? returnType;

  /// The name of this method.
  ///
  /// Must be a valid Dart identifier following these rules:
  /// - Cannot be empty
  /// - Must start with a letter or underscore
  /// - Can contain letters, digits, and underscores
  /// - Should follow Dart naming conventions (lowerCamelCase)
  /// - Private methods start with underscore (e.g., `_privateMethod`)
  ///
  /// This is required for all methods.
  final String name;

  /// The list of required positional parameters.
  ///
  /// These parameters appear first in the method signature and must be provided
  /// in order when calling the method. Automatically populated from the
  /// [parameters] list passed to the constructor by filtering for parameters
  /// where `named == false` and `optional == false`.
  ///
  /// Example: `void method(int x, String y)` - `x` and `y` are unnamed parameters
  final List<MethodParameter> unnamedParameters;

  /// The list of optional positional parameters.
  ///
  /// These parameters appear in square brackets `[]` and can be omitted when
  /// calling the method. Automatically populated from the [parameters] list
  /// by filtering for parameters where `optional == true`.
  ///
  /// Cannot be used together with [namedParameters].
  ///
  /// Example: `void method(int x, [int y, int z])` - `y` and `z` are optional
  final List<MethodParameter> optionalParameters;

  /// The list of named parameters.
  ///
  /// These parameters appear in curly braces `{}` and can be passed by name
  /// when calling the method. Automatically populated from the [parameters]
  /// list by filtering for parameters where `named == true`.
  ///
  /// Cannot be used together with [optionalParameters].
  ///
  /// Example: `void method(int x, {required int y, int? z})` - `y` and `z` are named
  final List<MethodParameter> namedParameters;

  /// The generic type parameters for this method, if any.
  ///
  /// Each string should be a complete type parameter declaration including
  /// any bounds. When null or empty, the method is not generic.
  ///
  /// Examples:
  /// - `['T']` generates `<T>`
  /// - `['T', 'E']` generates `<T, E>`
  /// - `['T extends num']` generates `<T extends num>`
  /// - `['K', 'V extends Comparable<V>']` generates `<K, V extends Comparable<V>>`
  final List<String>? genericTypes;

  /// Whether to format parameters with a trailing comma for multi-line style.
  ///
  /// When `true`, adds a trailing comma after the last parameter,
  /// which encourages the dart formatter to place parameters on separate lines.
  /// When `false`, parameters will typically be formatted on a single line.
  ///
  /// Defaults to `true`.
  final bool multiLineParameters;

  /// Whether this method is asynchronous (returns a Future).
  ///
  /// Async methods are marked with the `async` keyword and must return a Future
  /// or FutureOr type. They allow using `await` within the method body.
  ///
  /// Can be combined with [generator] to create async generators (async*).
  /// Cannot be used with [external] methods (they have no body to execute).
  ///
  /// Example: `Future<String> fetchData() async { return await http.get('...'); }`
  final bool async;

  /// Whether this method is a generator (uses sync* or async*).
  ///
  /// Generator methods produce a sequence of values:
  /// - `sync*` with [async]=false: Returns an Iterable, uses `yield`
  /// - `async*` with [async]=true: Returns a Stream, uses `yield`
  ///
  /// Generators cannot use arrow function syntax and require a block body.
  /// Cannot be used with [external] methods.
  ///
  /// Example: `Stream<int> numbers() async* { yield 1; yield 2; }`
  final bool generator;

  /// Whether this method uses arrow function syntax (=>) instead of a block body.
  ///
  /// Arrow syntax is concise single-expression syntax:
  /// - `methodName() => expression;` instead of `methodName() { return expression; }`
  /// - Automatically returns the expression result
  /// - Cannot contain multiple statements
  /// - Cannot be used with generators
  /// - Commonly used for simple one-liner methods
  ///
  /// Example: `String fullName() => '$firstName $lastName';`
  final bool arrowFunction;

  /// The implementation body of this method.
  ///
  /// A function that writes the method's implementation to a StringBuffer.
  /// The function receives a StringBuffer parameter and should write the
  /// method's logic to it.
  ///
  /// For [arrowFunction]=true: Write the single expression (no return keyword)
  /// For [arrowFunction]=false: Write the statements for the block body
  ///
  /// This is `null` for [external] methods (which have no body).
  ///
  /// Example:
  /// ```dart
  /// // Arrow function body
  /// body: (b) => b.write('"$firstName $lastName"')
  ///
  /// // Block body
  /// body: (b) => b.write('var sum = a + b; return sum;')
  /// ```
  final void Function(StringBuffer)? body;

  /// Creates a new [Method] with the specified properties.
  ///
  /// The [name] parameter is required. All other parameters are optional with
  /// sensible defaults.
  ///
  /// The [parameters] list is automatically categorized into [unnamedParameters],
  /// [optionalParameters], and [namedParameters] based on each parameter's
  /// [MethodParameter.named] and [MethodParameter.optional] properties.
  ///
  /// **Validation Rules:**
  ///
  /// The constructor enforces several validation rules via assertions:
  ///
  /// 1. **Parameter Validation:**
  ///    - Cannot have both optional positional and named parameters
  ///
  /// 2. **Arrow Function Validation:**
  ///    - Cannot be both arrow function and generator (generators need block bodies)
  ///
  /// 3. **External Method Validation:**
  ///    - External methods cannot have a body
  ///    - External methods cannot be async or generators
  ///    - External methods cannot use arrow function syntax
  ///
  /// 4. **Body Validation:**
  ///    - Non-external methods must have a body
  ///    - Async methods require a body
  ///    - Arrow functions require a body
  ///    - Generator functions require a body
  ///
  /// **Examples:**
  ///
  /// ```dart
  /// // Simple method
  /// Method(
  ///   name: 'greet',
  ///   returnType: 'String',
  ///   body: (b) => b.write('return "Hello";'),
  /// )
  ///
  /// // Method with documentation and annotations
  /// Method(
  ///   docComment: '/// Returns the user\'s full name.',
  ///   annotations: ['@override'],
  ///   returnType: 'String',
  ///   name: 'toString',
  ///   arrowFunction: true,
  ///   body: (b) => b.write('name'),
  /// )
  ///
  /// // Generic async method
  /// Method(
  ///   returnType: 'Future<T>',
  ///   name: 'fetch',
  ///   genericTypes: ['T'],
  ///   async: true,
  ///   parameters: [
  ///     MethodParameter(type: 'String', name: 'id'),
  ///   ],
  ///   body: (b) => b.write('return await repo.get(id);'),
  /// )
  ///
  /// // External method
  /// Method(
  ///   external: true,
  ///   returnType: 'void',
  ///   name: 'nativeCall',
  /// )
  /// ```
  Method({
    this.annotations = const [],
    this.docComment = '',
    this.external = false,
    this.override = false,
    this.static = false,
    this.returnType,
    required this.name,
    List<MethodParameter>? parameters,
    this.genericTypes,
    this.multiLineParameters = true,
    this.async = false,
    this.generator = false,
    this.arrowFunction = false,
    this.body,
  })  : unnamedParameters = (parameters != null) ? parameters.where((p) => !p.named).toList() : [],
        optionalParameters = (parameters != null) ? parameters.where((p) => p.optional).toList() : [],
        namedParameters = (parameters != null) ? parameters.where((p) => p.named).toList() : [] {
    assert(
      !(optionalParameters.isNotEmpty && namedParameters.isNotEmpty),
      'The method [$name] can have optional parameters or named parameters but not both',
    );
    assert(
      !(arrowFunction && generator),
      'The method [$name] cannot be both an arrow function and a generator',
    );
    assert(!external || body == null, 'External methods cannot have a body');
    assert(!external || (!async && !generator), 'External methods cannot be async or generator');
    assert(!external || !arrowFunction, 'External methods cannot use arrow function syntax');
    assert(external || body != null, 'Non-external methods must have a body');
    assert(body != null || !async, 'Async methods require a body');
    assert(body != null || !arrowFunction, 'Arrow functions require a body');
    assert(body != null || !generator, 'Generator functions require a body');
  }

  /// Creates a [Method] instance from an analyzer [MethodElement].
  ///
  /// This factory method extracts all method information from the analyzer's
  /// representation of a Dart method, including its AST node, and builds a
  /// corresponding [Method] instance.
  ///
  /// **Extraction Process:**
  ///
  /// - **Annotations:** Collects all metadata annotations, specially handling `@override`
  /// - **Documentation:** Extracts documentation comments from the AST node
  /// - **Modifiers:** Detects `external`, `static`, `async`, `generator`, and arrow syntax
  /// - **Parameters:** Asynchronously converts all parameters to [MethodParameter] instances
  /// - **Generic Types:** Extracts type parameters with their bounds
  /// - **Body:** Extracts the method body (or null for external/empty methods)
  ///
  /// **Note on @override:**
  ///
  /// The `@override` annotation is extracted into the [annotations] list, and the
  /// [override] property is set to `false` to avoid duplication in the output.
  ///
  /// **Parameters:**
  ///
  /// - [methodElement]: The analyzer's representation of the method
  /// - [buildStep]: The build step providing access to resolution and AST nodes
  ///
  /// **Returns:**
  ///
  /// A [Future] that completes with a [Method] instance representing the complete
  /// method declaration.
  ///
  /// **Example Usage:**
  ///
  /// ```dart
  /// // In a code generator
  /// final element = classElement.methods.first;
  /// final method = await Method.from(element, buildStep);
  /// // Use method to generate code...
  /// ```
  static Future<Method> from(
    MethodElement methodElement,
    BuildStep buildStep,
  ) async {
    MethodDeclaration astNode = await buildStep.resolver.astNodeFor(methodElement) as MethodDeclaration;

    // Collect all annotations
    List<String> annotations = [];
    for (var annotation in methodElement.metadata) {
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

    return Method(
        annotations: annotations,
        docComment: docComment,
        external: methodElement.isExternal,
        override: false, // Already captured in annotations
        static: methodElement.isStatic,
        returnType: '${methodElement.returnType}',
        name: methodElement.name,
        parameters: await methodElement.parameters.mapAsync((p) => MethodParameter.from(p, buildStep)),
        genericTypes: methodElement.typeParameters.map((p) => '$p').toList(),
        multiLineParameters: true,
        async: methodElement.isAsynchronous,
        generator: methodElement.isGenerator,
        arrowFunction: astNode.body is ExpressionFunctionBody,
        body: (astNode.body is EmptyFunctionBody)
            ? null
            : (StringBuffer b) {
                FunctionBody body = astNode.body;
                if (body is BlockFunctionBody)
                  b.write(body.block.statements.toCleanString());
                else if (body is ExpressionFunctionBody) b.write('${body.expression}');
              });
  }

  /// Creates a copy of this [Method] with the specified properties replaced.
  ///
  /// This method allows you to create a modified version of an existing method
  /// without mutating the original instance. Any parameter that is not provided
  /// (or is null) will use the value from the current instance.
  ///
  /// **Note on Parameters:**
  ///
  /// When providing a new [parameters] list, you must provide the complete list.
  /// If [parameters] is null, the current parameters are reconstructed by
  /// combining [unnamedParameters], [optionalParameters], and [namedParameters]
  /// from the current instance.
  ///
  /// All validation rules from the constructor still apply to the copied instance.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final original = Method(
  ///   name: 'calculate',
  ///   returnType: 'int',
  ///   body: (b) => b.write('return 42;'),
  /// );
  ///
  /// // Create an async version
  /// final asyncVersion = original.copyWith(
  ///   async: true,
  ///   returnType: 'Future<int>',
  /// );
  ///
  /// // Add documentation and annotations
  /// final documented = original.copyWith(
  ///   docComment: '/// Calculates a value.',
  ///   annotations: ['@deprecated'],
  /// );
  ///
  /// // Make it static
  /// final staticVersion = original.copyWith(static: true);
  /// ```
  Method copyWith({
    List<String>? annotations,
    String? docComment,
    bool? external,
    bool? override,
    bool? static,
    String? returnType,
    String? name,
    List<MethodParameter>? parameters,
    List<String>? genericTypes,
    bool? multiLineParameters,
    bool? async,
    bool? generator,
    bool? arrowFunction,
    void Function(StringBuffer)? body,
  }) =>
      Method(
        annotations: annotations ?? this.annotations,
        docComment: docComment ?? this.docComment,
        external: external ?? this.external,
        override: override ?? this.override,
        static: static ?? this.static,
        returnType: returnType ?? this.returnType,
        name: name ?? this.name,
        parameters: parameters ?? [...unnamedParameters, ...optionalParameters, ...namedParameters],
        genericTypes: genericTypes ?? this.genericTypes,
        multiLineParameters: multiLineParameters ?? this.multiLineParameters,
        async: async ?? this.async,
        generator: generator ?? this.generator,
        arrowFunction: arrowFunction ?? this.arrowFunction,
        body: body ?? this.body,
      );

  /// Writes the complete Dart method declaration to a [StringBuffer].
  ///
  /// This method generates valid Dart source code for the method by writing
  /// all components in the correct syntactic order according to Dart language
  /// specifications.
  ///
  /// **Output Structure:**
  ///
  /// ```
  /// [docComment]
  /// [annotations]
  /// [external] [@override] [static] [returnType] name[<genericTypes>](parameters) [async-modifier] body
  /// ```
  ///
  /// **Writing Order:**
  ///
  /// 1. **Documentation comment** (if present), followed by newline
  /// 2. **Annotations** (if any), each followed by a space
  /// 3. **Modifiers** in order: `external`, `@override`, `static`
  /// 4. **Return type** (if specified), followed by space
  /// 5. **Method name**
  /// 6. **Generic type parameters** (if any) in angle brackets
  /// 7. **Parameter list:**
  ///    - Required positional parameters first
  ///    - Then optional positional `[...]` or named `{...}` parameters
  ///    - Proper comma separation and trailing commas
  /// 8. **External methods:** End with semicolon and return
  /// 9. **Async modifiers:** `async`, `async*`, or `sync*` (if applicable)
  /// 10. **Body:**
  ///     - Arrow function: ` => expression;`
  ///     - Block body: ` { statements }`
  ///
  /// **Example Outputs:**
  ///
  /// ```dart
  /// // Simple method
  /// String greet() { return "Hello"; }
  ///
  /// // With documentation and annotations
  /// /// Returns the user's full name.
  /// @override
  /// String toString() => name;
  ///
  /// // Static external method
  /// external static int platformVersion();
  ///
  /// // Async generator
  /// Stream<int> numbers() async* { yield 1; yield 2; }
  ///
  /// // Generic method
  /// T identity<T>(T value) => value;
  /// ```
  ///
  /// **Parameters:**
  ///
  /// - [b]: The StringBuffer to write the method declaration to
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment
    if (docComment.isNotEmpty) {
      b.writeln(docComment);
    }

    // Write annotations
    for (var annotation in annotations) {
      b.write('$annotation ');
    }

    // Write modifiers in correct order: external, @override, static
    if (external) b.write('external ');
    if (override) b.write('@override ');
    if (static) b.write('static ');

    // Write return type
    if (returnType != null) b.write('${returnType} ');

    // Write method name
    b.write('${name}');

    // Write generic type parameters
    if (genericTypes != null) b.write('<${genericTypes!.toCleanString(',')}>');

    b.write('(');

    if (namedParameters.isNotEmpty && unnamedParameters.isEmpty) b.write('{');
    if (optionalParameters.isNotEmpty && unnamedParameters.isEmpty) b.write('[');

    if (unnamedParameters.isNotEmpty) {
      unnamedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < unnamedParameters.length - 1)
          b.write(',');
        else {
          if (namedParameters.isNotEmpty)
            b.write(', {');
          else if (optionalParameters.isNotEmpty)
            b.write(', [');
          else {
            if (multiLineParameters) b.write(', ');
          }
        }
      });
    }

    if (namedParameters.isNotEmpty) {
      namedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < namedParameters.length - 1)
          b.write(',');
        else {
          if (multiLineParameters) b.write(',');
          b.write('}');
        }
      });
    }

    if (optionalParameters.isNotEmpty) {
      optionalParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < optionalParameters.length - 1)
          b.write(',');
        else {
          if (multiLineParameters) b.write(',');
          b.write(']');
        }
      });
    }
    b.write(')');

    // For external methods, just end with semicolon
    if (external) {
      b.write(';');
      return;
    }

    b.write(' ');

    // Write async modifiers
    if (async) {
      if (generator)
        b.write('async* ');
      else
        b.write('async ');
    } else if (generator) b.write('sync* ');

    // Write body
    if (arrowFunction)
      b.write('=> ');
    else
      b.write('{ ');

    StringBuffer buffer = StringBuffer();
    body!(buffer);
    b.write(buffer.toString());

    if (arrowFunction)
      b.write(';');
    else
      b.write(' }');
  }
}

/// Represents a single parameter in a Dart method's parameter list.
///
/// This class supports all parameter types in Dart:
/// - **Required positional**: `named: false, optional: false`
/// - **Optional positional**: `named: false, optional: true`
/// - **Named optional**: `named: true, Required: false`
/// - **Named required**: `named: true, Required: true`
///
/// Parameters can have:
/// - Type annotations
/// - Default values (for optional/named non-required parameters)
/// - The `covariant` modifier
/// - Metadata annotations
///
/// **Examples:**
///
/// ```dart
/// // Required positional: int x
/// MethodParameter(type: 'int', name: 'x')
///
/// // Optional positional with default: [int y = 5]
/// MethodParameter(
///   type: 'int',
///   name: 'y',
///   optional: true,
///   defaultValue: '5',
/// )
///
/// // Named optional: {String? name}
/// MethodParameter(
///   type: 'String?',
///   name: 'name',
///   named: true,
/// )
///
/// // Named required: {required bool flag}
/// MethodParameter(
///   type: 'bool',
///   name: 'flag',
///   named: true,
///   Required: true,
/// )
///
/// // Covariant parameter: covariant Animal animal
/// MethodParameter(
///   type: 'Animal',
///   name: 'animal',
///   covariant: true,
/// )
///
/// // With annotation: @deprecated int old
/// MethodParameter(
///   annotations: ['@deprecated'],
///   type: 'int',
///   name: 'old',
/// )
/// ```
class MethodParameter implements BufferWritable {
  /// A list of metadata annotations to be applied to this parameter.
  ///
  /// Annotations are prefixed with `@` and appear before the parameter type.
  /// Common examples include `@deprecated`, `@visibleForTesting`, or custom
  /// annotations.
  ///
  /// Example: `['@deprecated']` generates `@deprecated int param`
  final List<String> annotations;

  /// Whether this parameter has the `covariant` modifier.
  ///
  /// The covariant keyword is used in overriding methods to indicate that
  /// a parameter type can be more specific than the parameter type in the
  /// superclass method.
  ///
  /// Example: `covariant Animal animal`
  ///
  /// This is typically used when:
  /// - Overriding a method from a superclass or interface
  /// - The parameter type is contravariant but you want to allow a subtype
  final bool covariant;

  /// The name of the parameter.
  ///
  /// This is required and should follow Dart naming conventions (lowerCamelCase).
  /// It's the identifier used to refer to the parameter within the method body.
  final String name;

  /// Whether this is a named parameter.
  ///
  /// When `true`, the parameter appears in curly braces `{}` in the method
  /// signature and can be passed by name when calling the method.
  ///
  /// Example: `void method({int x})` - `x` is a named parameter
  ///
  /// Cannot be `true` if [optional] is also `true` (a parameter cannot be
  /// both named and positional optional).
  final bool named;

  /// Whether this named parameter is required.
  ///
  /// Only valid when [named] is `true`. When both [named] and [Required] are
  /// `true`, the parameter is marked with the `required` keyword.
  ///
  /// Example: `void method({required int x})` - `x` is a required named parameter
  ///
  /// Defaults to `false`.
  final bool Required;

  /// Whether this is an optional positional parameter.
  ///
  /// When `true`, the parameter appears in square brackets `[]` in the method
  /// signature and can be omitted when calling the method.
  ///
  /// Example: `void method(int x, [int y])` - `y` is an optional positional parameter
  ///
  /// Cannot be `true` if [named] is also `true` (a parameter cannot be both
  /// named and positional optional).
  ///
  /// Defaults to `false`.
  final bool optional;

  /// The type annotation for this parameter.
  ///
  /// Should be a valid Dart type expression. Can be an empty string for
  /// type inference (though this is rare for parameters).
  ///
  /// Examples:
  /// - `'int'` - primitive type
  /// - `'String?'` - nullable type
  /// - `'List<int>'` - generic type
  /// - `'Future<void>'` - async type
  /// - `'void Function(int)'` - function type
  final String type;

  /// The default value for this parameter.
  ///
  /// Only valid for optional positional parameters or named parameters that
  /// are not required. The value should be a valid Dart expression as a string.
  ///
  /// Examples:
  /// - `'5'` - numeric literal
  /// - `'true'` - boolean literal
  /// - `'const []'` - const collection
  /// - `'null'` - null value
  ///
  /// When provided, it's written as `= defaultValue` after the parameter name.
  final String? defaultValue;

  /// Creates a new [MethodParameter] with the specified properties.
  ///
  /// The [name] and [type] parameters are required. All other parameters are
  /// optional with sensible defaults.
  ///
  /// **Validation Rules:**
  ///
  /// The constructor enforces several validation rules via assertions:
  ///
  /// 1. **Parameter Type Validation:**
  ///    - Cannot be both [named] and [optional] (mutually exclusive)
  ///
  /// 2. **Required Parameter Validation:**
  ///    - If [Required] is `true`, then [named] must also be `true`
  ///    - Only named parameters can be required
  ///
  /// 3. **Default Value Validation:**
  ///    - [defaultValue] can only be provided for:
  ///      - Optional positional parameters ([optional] = true)
  ///      - Named non-required parameters ([named] = true and [Required] = false)
  ///    - Required positional parameters cannot have default values
  ///
  /// **Examples:**
  ///
  /// ```dart
  /// // Required positional
  /// MethodParameter(type: 'int', name: 'x')
  ///
  /// // Optional positional with default
  /// MethodParameter(
  ///   type: 'int',
  ///   name: 'y',
  ///   optional: true,
  ///   defaultValue: '0',
  /// )
  ///
  /// // Named optional with default
  /// MethodParameter(
  ///   type: 'bool',
  ///   name: 'flag',
  ///   named: true,
  ///   defaultValue: 'false',
  /// )
  ///
  /// // Named required
  /// MethodParameter(
  ///   type: 'String',
  ///   name: 'id',
  ///   named: true,
  ///   Required: true,
  /// )
  ///
  /// // Covariant parameter
  /// MethodParameter(
  ///   type: 'Animal',
  ///   name: 'animal',
  ///   covariant: true,
  /// )
  /// ```
  MethodParameter({
    this.annotations = const [],
    this.covariant = false,
    required this.name,
    this.named = false,
    this.Required = false,
    this.optional = false,
    this.type = '',
    this.defaultValue,
  })  : assert(!(named && optional), 'The method parameter [$name] can be either named or optional, but not both'),
        assert(!Required || (Required && named), 'If the method parameter [$name] is required, then it must be named'),
        assert(defaultValue == null || ((named && !Required) || optional),
            'the method parameter [$name] is not optional, yet it has a default value');

  /// Creates a [MethodParameter] instance from an analyzer [ParameterElement].
  ///
  /// This factory method extracts all parameter information from the analyzer's
  /// representation of a Dart parameter, including its AST node, and builds a
  /// corresponding [MethodParameter] instance.
  ///
  /// **Extraction Process:**
  ///
  /// - **Annotations:** Collects all metadata annotations
  /// - **Modifiers:** Detects `covariant` modifier
  /// - **Parameter Type:** Determines if named, required, or optional
  /// - **Type:** Extracts the parameter type as a string
  /// - **Default Value:** Extracts default value from AST node if present
  ///
  /// **Parameters:**
  ///
  /// - [parameterElement]: The analyzer's representation of the parameter
  /// - [buildStep]: The build step providing access to resolution and AST nodes
  ///
  /// **Returns:**
  ///
  /// A [Future] that completes with a [MethodParameter] instance representing
  /// the parameter.
  ///
  /// **Example Usage:**
  ///
  /// ```dart
  /// // In a code generator
  /// final paramElement = methodElement.parameters.first;
  /// final param = await MethodParameter.from(paramElement, buildStep);
  /// ```
  static Future<MethodParameter> from(
    ParameterElement parameterElement,
    BuildStep buildStep,
  ) async {
    FormalParameter astNode = await buildStep.resolver.astNodeFor(parameterElement) as FormalParameter;

    // Collect all annotations
    List<String> annotations = [];
    for (var annotation in parameterElement.metadata) {
      annotations.add(annotation.toSource());
    }

    return MethodParameter(
      annotations: annotations,
      covariant: parameterElement.isCovariant,
      name: parameterElement.name,
      named: parameterElement.isNamed,
      Required: parameterElement.isRequiredNamed,
      optional: parameterElement.isOptionalPositional,
      type: '${parameterElement.type}',
      defaultValue: (astNode is DefaultFormalParameter) ? '${astNode.defaultValue}' : null,
    );
  }

  /// Creates a copy of this [MethodParameter] with the specified properties replaced.
  ///
  /// This method allows you to create a modified version of an existing parameter
  /// without mutating the original instance. Any parameter that is not provided
  /// (or is null) will use the value from the current instance.
  ///
  /// All validation rules from the constructor still apply to the copied instance.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final original = MethodParameter(type: 'int', name: 'x');
  ///
  /// // Make it named
  /// final namedVersion = original.copyWith(named: true);
  ///
  /// // Add a default value (must be optional or named non-required)
  /// final withDefault = original.copyWith(
  ///   optional: true,
  ///   defaultValue: '0',
  /// );
  ///
  /// // Make it required named
  /// final requiredNamed = original.copyWith(
  ///   named: true,
  ///   Required: true,
  /// );
  ///
  /// // Change type
  /// final stringVersion = original.copyWith(type: 'String');
  /// ```
  MethodParameter copyWith({
    List<String>? annotations,
    bool? covariant,
    String? name,
    bool? named,
    bool? Required,
    bool? optional,
    String? type,
    String? defaultValue,
  }) =>
      MethodParameter(
        annotations: annotations ?? this.annotations,
        covariant: covariant ?? this.covariant,
        name: name ?? this.name,
        named: named ?? this.named,
        Required: Required ?? this.Required,
        optional: optional ?? this.optional,
        type: type ?? this.type,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  /// Writes the parameter declaration to the provided [StringBuffer].
  ///
  /// This method generates valid Dart syntax for the parameter based on its
  /// type and modifiers.
  ///
  /// **Output Structure:**
  ///
  /// ```
  /// [@annotations] [required] [covariant] type name [= defaultValue]
  /// ```
  ///
  /// **Writing Order:**
  ///
  /// 1. **Annotations** (if any), each followed by a space
  /// 2. **Required keyword** (if [named] and [Required] are both true)
  /// 3. **Covariant modifier** (if [covariant] is true)
  /// 4. **Type annotation**
  /// 5. **Parameter name**
  /// 6. **Default value** (if provided): ` = defaultValue`
  ///
  /// **Note:** The grouping delimiters (`[`, `]`, `{`, `}`) for optional and
  /// named parameters are handled by the containing method, not by this method.
  ///
  /// **Example Outputs:**
  ///
  /// ```dart
  /// // Required positional
  /// int x
  ///
  /// // Optional positional with default
  /// int y = 5
  ///
  /// // Named optional
  /// String name
  ///
  /// // Named optional with default
  /// String name = 'default'
  ///
  /// // Named required
  /// required bool flag
  ///
  /// // Covariant parameter
  /// covariant Animal animal
  ///
  /// // With annotation
  /// @deprecated int old
  /// ```
  ///
  /// **Parameters:**
  ///
  /// - [b]: The StringBuffer to write the parameter declaration to
  void _writeToBuffer(StringBuffer b) {
    // Write annotations
    for (var annotation in annotations) {
      b.write('$annotation ');
    }

    if (!named && !optional) {
      // Required positional parameter
      if (covariant) b.write('covariant ');
      b.write('$type ');
      b.write('$name');
    } else {
      // Named or optional positional parameter
      if (named) {
        if (Required) b.write('required ');
      }
      if (covariant) b.write('covariant ');
      b.write('$type ');
      b.write('$name');
      if (defaultValue != null) b.write(' = $defaultValue');
    }
  }
}
