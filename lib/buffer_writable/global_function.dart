part of dart_source_builder;

/// Represents a global (top-level) function declaration in Dart.
///
/// This class allows you to programmatically create function declarations with all
/// possible Dart configurations including generic types, various parameter types,
/// async/generator modifiers, arrow functions, and external declarations.
///
/// Example:
/// ```dart
/// GlobalFunction(
///   docComment: '/// Calculates the sum of two numbers.',
///   annotations: ['deprecated'],
///   returnType: 'int',
///   name: 'add',
///   parameters: [
///     FunctionParameter(name: 'a', type: 'int'),
///     FunctionParameter(name: 'b', type: 'int'),
///   ],
///   body: (b) => b.write('return a + b;'),
/// )
/// ```
///
/// This would generate:
/// ```dart
/// /// Calculates the sum of two numbers.
/// @deprecated
/// int add(int a, int b) { return a + b; }
/// ```
class GlobalFunction extends PublicBufferWritable {
  /// Optional list of annotations to apply to this function.
  ///
  /// Each string should be the annotation name without the '@' symbol.
  /// For example: `['deprecated', 'override', 'pragma("vm:entry-point")']`
  ///
  /// These will be written as `@annotation` on separate lines before the function.
  final List<String>? annotations;

  /// Optional documentation comment for this function.
  ///
  /// Should include the `///` or `/**` comment markers if desired.
  /// This will be written directly before any annotations and the function signature.
  ///
  /// Example: `'/// Adds two numbers together.'`
  final String? docComment;

  /// The return type of the function.
  ///
  /// If `null`, the function has no explicit return type (implicitly dynamic in Dart 2,
  /// or would need to be inferred in Dart 3 with strict type checking).
  ///
  /// Example: `'int'`, `'Future<String>'`, `'void'`
  final String? returnType;

  /// The name of the function.
  ///
  /// This is required and should follow Dart naming conventions (camelCase for functions).
  final String name;

  /// List of regular (required positional) parameters.
  ///
  /// These are automatically extracted from the `parameters` list passed to the constructor
  /// by filtering for parameters where `named == false` and `optional == false`.
  ///
  /// These parameters appear first in the function signature and must be provided in order.
  late List<FunctionParameter> unnamedParameters;

  /// List of optional positional parameters.
  ///
  /// These are automatically extracted from the `parameters` list by filtering for
  /// parameters where `optional == true`.
  ///
  /// In Dart syntax, these appear in square brackets: `void foo(int a, [int b, int c])`
  ///
  /// Note: A function cannot have both optional positional and named parameters.
  late List<FunctionParameter> optionalParameters;

  /// List of named parameters.
  ///
  /// These are automatically extracted from the `parameters` list by filtering for
  /// parameters where `named == true`.
  ///
  /// In Dart syntax, these appear in curly braces: `void foo(int a, {int b, required int c})`
  ///
  /// Note: A function cannot have both optional positional and named parameters.
  late List<FunctionParameter> namedParameters;

  /// Optional list of generic type parameters for this function.
  ///
  /// Each string should be a complete type parameter declaration.
  ///
  /// Example: `['T', 'E extends Exception']` would generate `<T, E extends Exception>`
  final List<String>? genericTypes;

  /// Whether to format parameters on multiple lines.
  ///
  /// When `true`, adds trailing commas after parameters (Dart formatter will then
  /// format them on multiple lines).
  ///
  /// When `false`, parameters will be on a single line.
  ///
  /// Defaults to `true`.
  final bool multiLineParameters;

  /// Whether this function is asynchronous.
  ///
  /// When `true`, adds the `async` modifier before the function body.
  /// Typically used with functions that return `Future` or `FutureOr`.
  ///
  /// Can be combined with `generator` to create `async*` functions.
  final bool async;

  /// Whether this function is a generator.
  ///
  /// When `true` with `async == true`: creates an `async*` generator (returns `Stream`).
  /// When `true` with `async == false`: creates a `sync*` generator (returns `Iterable`).
  ///
  /// Generator functions use `yield` or `yield*` to produce values.
  ///
  /// Note: Cannot be combined with `arrowFunction` (generators cannot use arrow syntax).
  final bool generator;

  /// Whether this function uses arrow syntax.
  ///
  /// When `true`, the function uses `=>` instead of `{ }` for the body.
  ///
  /// Example: `int add(int a, int b) => a + b;`
  ///
  /// Note: Cannot be combined with `generator` (arrow functions cannot be generators).
  final bool arrowFunction;

  /// Whether this is an external function declaration.
  ///
  /// When `true`, the function has no body (only a semicolon) and is declared with
  /// the `external` keyword. External functions are implemented outside of Dart,
  /// typically in native code or JavaScript.
  ///
  /// Example: `external void nativeFunction();`
  final bool external;

  /// A callback function that writes the function body to the provided [StringBuffer].
  ///
  /// This is required even for external functions (though it won't be called for external).
  ///
  /// The callback receives a [StringBuffer] and should write the function body content
  /// (without the surrounding braces or arrow, which are added automatically).
  ///
  /// Example:
  /// ```dart
  /// body: (b) {
  ///   b.write('var result = a + b;');
  ///   b.write('return result;');
  /// }
  /// ```
  final void Function(StringBuffer) body;

  /// Creates a new [GlobalFunction] with the specified properties.
  ///
  /// The [name] and [body] parameters are required. All other parameters are optional.
  ///
  /// The [parameters] list is automatically separated into [unnamedParameters],
  /// [optionalParameters], and [namedParameters] based on each parameter's properties.
  ///
  /// Throws an [AssertionError] if:
  /// - Both optional positional and named parameters are provided (Dart doesn't allow this)
  /// - Both [arrowFunction] and [generator] are true (generators cannot use arrow syntax)
  GlobalFunction({
    this.annotations,
    this.docComment,
    this.returnType,
    required this.name,
    List<FunctionParameter>? parameters,
    this.genericTypes,
    this.multiLineParameters = true,
    this.async = false,
    this.generator = false,
    this.arrowFunction = false,
    this.external = false,
    required this.body,
  })  : unnamedParameters = (parameters != null) ? parameters.where((p) => !p.named).toList() : [],
        optionalParameters = (parameters != null) ? parameters.where((p) => p.optional).toList() : [],
        namedParameters = (parameters != null) ? parameters.where((p) => p.named).toList() : [] {
    assert(
      !(optionalParameters.isNotEmpty && namedParameters.isNotEmpty),
      'The function [$name] can have optional parameters or named parameters but not both',
    );
    assert(
      !(arrowFunction && generator),
      'The function [$name] cannot be both an arrow function and a generator',
    );
  }

  /// Creates a [GlobalFunction] from an analyzer [FunctionElement].
  ///
  /// This factory method is used internally by code generation tools to extract
  /// function declarations from analyzed Dart code.
  ///
  /// The [functionElement] is the analyzer's representation of the function,
  /// and [buildStep] provides access to the AST and resolver for extracting
  /// detailed information like the function body.
  ///
  /// Returns a [Future] that completes with a new [GlobalFunction] instance
  /// that mirrors the analyzed function.
  static Future<GlobalFunction> from(
    FunctionElement functionElement,
    BuildStep buildStep,
  ) async {
    FunctionDeclaration astNode = await buildStep.resolver.astNodeFor(functionElement) as FunctionDeclaration;
    return GlobalFunction(
        external: functionElement.isExternal,
        returnType: '${functionElement.returnType}',
        name: functionElement.name,
        parameters: await functionElement.parameters.mapAsync((p) => FunctionParameter.from(p, buildStep)),
        genericTypes: functionElement.typeParameters.map((p) => '$p').toList(),
        multiLineParameters: true,
        async: functionElement.isAsynchronous,
        generator: functionElement.isGenerator,
        arrowFunction: astNode.functionExpression.body is ExpressionFunctionBody,
        body: (astNode.functionExpression.body is EmptyFunctionBody)
            ? (StringBuffer b) => ''
            : (StringBuffer b) {
                FunctionBody body = astNode.functionExpression.body;
                if (body is BlockFunctionBody)
                  b.write(body.block.statements.toCleanString());
                else if (body is ExpressionFunctionBody) b.write('${body.expression}');
              });
  }

  /// Creates a copy of this [GlobalFunction] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter that is not provided (or is `null`)
  /// will use the value from the current instance.
  ///
  /// Note: When copying [parameters], you must provide the complete list. The current
  /// parameters are reconstructed by combining [unnamedParameters], [optionalParameters],
  /// and [namedParameters] if no new parameters are provided.
  ///
  /// Example:
  /// ```dart
  /// var original = GlobalFunction(
  ///   name: 'foo',
  ///   returnType: 'void',
  ///   body: (b) => b.write('print("hi");'),
  /// );
  ///
  /// var modified = original.copyWith(
  ///   returnType: 'String',
  ///   async: true,
  /// );
  /// // Modified function has returnType: 'String' and async: true,
  /// // but keeps name: 'foo' and the same body
  /// ```
  GlobalFunction copyWith({
    List<String>? annotations,
    String? docComment,
    String? returnType,
    String? name,
    List<FunctionParameter>? parameters,
    List<String>? genericTypes,
    bool? multiLineParameters,
    bool? async,
    bool? generator,
    bool? arrowFunction,
    bool? external,
    void Function(StringBuffer)? body,
  }) =>
      GlobalFunction(
        annotations: annotations ?? this.annotations,
        docComment: docComment ?? this.docComment,
        external: external ?? this.external,
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

  /// Writes the complete function declaration to the provided [StringBuffer].
  ///
  /// This method generates the full Dart function syntax in the correct order:
  /// 1. Documentation comment (if present)
  /// 2. Annotations (if any)
  /// 3. `external` keyword (if applicable)
  /// 4. Return type (if specified)
  /// 5. Function name
  /// 6. Generic type parameters (if any)
  /// 7. Parameter list (with proper grouping for named/optional parameters)
  /// 8. Function modifiers (`async`, `async*`, or `sync*`)
  /// 9. Function body (arrow `=>` or block `{ }`)
  ///
  /// For external functions, only outputs a semicolon after the parameters and skips
  /// modifiers and body.
  ///
  /// This method is called automatically when the function is written to a source file.
  void _writeToBuffer(StringBuffer b) {
    if (docComment != null) {
      b.write('$docComment\n');
    }
    if (annotations != null && annotations!.isNotEmpty) {
      for (var annotation in annotations!) {
        b.write('@$annotation\n');
      }
    }
    if (external) b.write('external ');
    if (returnType != null) b.write('${returnType} ');
    b.write('${name}');
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
    b.write(') ');

    if (external) {
      b.write(';');
      return;
    }

    if (async) {
      if (generator)
        b.write('async* ');
      else
        b.write('async ');
    } else if (generator) b.write('sync* ');

    if (arrowFunction)
      b.write('=> ');
    else
      b.write('{ ');

    StringBuffer buffer = StringBuffer();
    body(buffer);
    b.write(buffer.toString());

    if (arrowFunction)
      b.write(';');
    else
      b.write(' }');
  }
}

/// Represents a parameter in a Dart function.
///
/// This class supports all parameter types in Dart:
/// - **Required positional**: `named: false, optional: false, required: false`
/// - **Optional positional**: `named: false, optional: true, required: false`
/// - **Named optional**: `named: true, optional: false, required: false`
/// - **Named required**: `named: true, optional: false, required: true`
///
/// Example:
/// ```dart
/// // Required positional parameter: int x
/// FunctionParameter(name: 'x', type: 'int')
///
/// // Optional positional parameter: [int y = 5]
/// FunctionParameter(name: 'y', type: 'int', optional: true, defaultValue: '5')
///
/// // Named optional parameter: {String? name}
/// FunctionParameter(name: 'name', type: 'String?', named: true)
///
/// // Named required parameter: {required bool flag}
/// FunctionParameter(name: 'flag', type: 'bool', named: true, required: true)
/// ```
class FunctionParameter implements BufferWritable {
  /// Optional list of annotations to apply to this parameter.
  ///
  /// Each string should be the annotation name without the '@' symbol.
  /// For example: `['deprecated', 'visibleForTesting']`
  ///
  /// These will be written as `@annotation ` before the parameter type.
  final List<String>? annotations;

  /// The name of the parameter.
  ///
  /// This is required and should follow Dart naming conventions (camelCase).
  final String name;

  /// Whether this is a named parameter.
  ///
  /// When `true`, the parameter appears in curly braces in the function signature
  /// and can be passed by name when calling the function.
  ///
  /// Example: `void foo({int x})` - `x` is a named parameter
  ///
  /// Note: Cannot be combined with [optional] (a parameter cannot be both
  /// named and positional optional).
  final bool named;

  /// Whether this named parameter is required.
  ///
  /// Only applies when [named] is `true`. When both [named] and [required] are `true`,
  /// the parameter is marked with the `required` keyword.
  ///
  /// Example: `void foo({required int x})` - `x` is a required named parameter
  ///
  /// Defaults to `false`.
  final bool required;

  /// Whether this is an optional positional parameter.
  ///
  /// When `true`, the parameter appears in square brackets in the function signature.
  ///
  /// Example: `void foo(int x, [int y])` - `y` is an optional positional parameter
  ///
  /// Note: Cannot be combined with [named] (a parameter cannot be both
  /// named and positional optional).
  ///
  /// Defaults to `false`.
  final bool optional;

  /// The type of the parameter.
  ///
  /// This is required and should be a valid Dart type expression.
  ///
  /// Examples: `'int'`, `'String?'`, `'List<int>'`, `'Future<void>'`
  final String type;

  /// The default value for this parameter.
  ///
  /// Only applies to optional positional parameters or named parameters that are
  /// not required. The value should be a valid Dart expression as a string.
  ///
  /// Examples: `'5'`, `'true'`, `'const []'`, `'null'`
  ///
  /// When provided, it's written as `= defaultValue` after the parameter name.
  final String? defaultValue;

  /// Creates a new [FunctionParameter] with the specified properties.
  ///
  /// The [name] and [type] parameters are required. All other parameters are optional.
  ///
  /// Throws an [AssertionError] if:
  /// - Both [named] and [optional] are true (a parameter cannot be both named and positional optional)
  /// - [required] is true but [named] is false (only named parameters can be required)
  /// - [defaultValue] is provided for a required positional parameter (only optional/named parameters can have defaults)
  ///
  /// Examples:
  /// ```dart
  /// // Required positional
  /// FunctionParameter(name: 'x', type: 'int')
  ///
  /// // Optional positional with default
  /// FunctionParameter(name: 'y', type: 'int', optional: true, defaultValue: '0')
  ///
  /// // Named optional with default
  /// FunctionParameter(name: 'flag', type: 'bool', named: true, defaultValue: 'false')
  ///
  /// // Named required
  /// FunctionParameter(name: 'id', type: 'String', named: true, required: true)
  /// ```
  FunctionParameter({
    this.annotations,
    required this.name,
    this.named = false,
    this.required = false,
    this.optional = false,
    required this.type,
    this.defaultValue,
  })  : assert(!(named && optional), 'The function parameter [$name] cannot be both named and positional optional'),
        assert(
            !required || (required && named), 'If the function parameter [$name] is required, then it must be named'),
        assert(defaultValue == null || ((named && !required) || optional),
            'the function parameter [$name] is not optional, yet it has a default value');

  /// Creates a [FunctionParameter] from an analyzer [ParameterElement].
  ///
  /// This factory method is used internally by code generation tools to extract
  /// parameter information from analyzed Dart code.
  ///
  /// The [parameterElement] is the analyzer's representation of the parameter,
  /// and [buildStep] provides access to the AST for extracting detailed information
  /// like default values.
  ///
  /// Returns a [Future] that completes with a new [FunctionParameter] instance
  /// that mirrors the analyzed parameter.
  static Future<FunctionParameter> from(
    ParameterElement parameterElement,
    BuildStep buildStep,
  ) async {
    FormalParameter astNode = await buildStep.resolver.astNodeFor(parameterElement) as FormalParameter;
    return FunctionParameter(
      name: parameterElement.name,
      named: parameterElement.isNamed,
      required: parameterElement.isRequiredNamed,
      optional: parameterElement.isOptionalPositional,
      type: '${parameterElement.type}',
      defaultValue: (astNode is DefaultFormalParameter) ? '${astNode.defaultValue}' : null,
    );
  }

  /// Creates a copy of this [FunctionParameter] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter that is not provided (or is `null`)
  /// will use the value from the current instance.
  ///
  /// Example:
  /// ```dart
  /// var original = FunctionParameter(name: 'x', type: 'int');
  ///
  /// var modified = original.copyWith(
  ///   type: 'String',
  ///   named: true,
  ///   defaultValue: '"hello"',
  /// );
  /// // Modified parameter has type: 'String', named: true, defaultValue: '"hello"'
  /// // but keeps name: 'x'
  /// ```
  FunctionParameter copyWith({
    List<String>? annotations,
    String? name,
    bool? named,
    bool? required,
    bool? optional,
    String? type,
    String? defaultValue,
  }) =>
      FunctionParameter(
        annotations: annotations ?? this.annotations,
        name: name ?? this.name,
        named: named ?? this.named,
        required: required ?? this.required,
        optional: optional ?? this.optional,
        type: type ?? this.type,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  /// Writes the parameter declaration to the provided [StringBuffer].
  ///
  /// This method generates the parameter syntax in the correct format based on
  /// the parameter type:
  ///
  /// - **Required positional**: `type name`
  /// - **Optional positional**: `type name` (with default value if provided)
  /// - **Named optional**: `type name` (with default value if provided)
  /// - **Named required**: `required type name`
  ///
  /// Annotations (if any) are written before the parameter type with `@` prefix.
  ///
  /// Examples of output:
  /// ```dart
  /// int x                    // Required positional
  /// int y = 5                // Optional positional with default
  /// String name              // Named optional
  /// String name = 'default'  // Named optional with default
  /// required bool flag       // Named required
  /// @deprecated int old      // With annotation
  /// ```
  ///
  /// Note: The grouping delimiters (`[`, `]`, `{`, `}`) are handled by the
  /// containing function, not by this method.
  void _writeToBuffer(StringBuffer b) {
    if (annotations != null && annotations!.isNotEmpty) {
      for (var annotation in annotations!) {
        b.write('@$annotation ');
      }
    }
    if (!named && !optional) {
      b.write('$type ');
      b.write('$name');
    } else {
      if (named) {
        if (required) b.write('required ');
      }
      b.write('$type ');
      b.write('$name');
      if (defaultValue != null) b.write(' = $defaultValue');
    }
  }
}
