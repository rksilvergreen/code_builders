part of code_builders;

/// Represents a Dart constructor declaration with all its possible configurations.
///
/// This class models any valid Dart constructor including:
/// - Generative constructors (default constructors)
/// - Named constructors
/// - Const constructors
/// - Factory constructors
/// - External constructors
/// - Redirecting constructors
/// - Constructors with initializer lists
///
/// Example usage:
/// ```dart
/// // Create a simple constructor: MyClass(String name)
/// final constructor = Constructor(
///   className: 'MyClass',
///   parameters: [
///     ConstructorParameter(name: 'name', type: 'String'),
///   ],
/// );
///
/// // Create a const named constructor with initializers
/// final namedConstructor = Constructor(
///   Const: true,
///   className: 'Point',
///   constructorName: 'origin',
///   propertyInitializers: [
///     PropertyInitializer(name: 'x', value: '0'),
///     PropertyInitializer(name: 'y', value: '0'),
///   ],
/// );
/// ```
class Constructor implements BufferWritable {
  /// Whether this is a const constructor.
  ///
  /// When true, generates `const ClassName(...)` syntax.
  /// Cannot be combined with [factory] or [external].
  final bool Const;

  /// Whether this is a factory constructor.
  ///
  /// When true, generates `factory ClassName(...)` syntax.
  /// Factory constructors cannot have initializing formals (this.x parameters).
  /// Cannot be combined with [Const].
  final bool factory;

  /// Whether this is an external constructor.
  ///
  /// When true, generates `external ClassName(...)` syntax.
  /// External constructors must not have a [body].
  /// Cannot be combined with [Const].
  final bool external;

  /// The name of the class this constructor belongs to.
  ///
  /// This is required and will be the prefix of the constructor declaration.
  /// For example, if className is 'MyClass', the output starts with 'MyClass'.
  final String className;

  /// The optional name of this constructor for named constructors.
  ///
  /// When null, this is the default (unnamed) constructor.
  /// When provided, generates `ClassName.constructorName(...)` syntax.
  ///
  /// Examples:
  /// - null → `MyClass(...)`
  /// - 'fromJson' → `MyClass.fromJson(...)`
  final String? constructorName;

  /// The list of required positional parameters.
  ///
  /// These are parameters that are not optional and not named.
  /// They appear first in the parameter list.
  /// Automatically populated from the [parameters] list in the constructor.
  late List<ConstructorParameter> unnamedParameters;

  /// The list of optional positional parameters.
  ///
  /// These parameters are wrapped in square brackets [].
  /// Automatically populated from the [parameters] list in the constructor.
  /// Cannot be used together with [namedParameters].
  late List<ConstructorParameter> optionalParameters;

  /// The list of named parameters.
  ///
  /// These parameters are wrapped in curly braces {}.
  /// Automatically populated from the [parameters] list in the constructor.
  /// Cannot be used together with [optionalParameters].
  late List<ConstructorParameter> namedParameters;

  /// Whether to format parameters with a trailing comma for multi-line style.
  ///
  /// When true, adds a trailing comma after the last parameter,
  /// which encourages dart formatter to place parameters on separate lines.
  final bool multiLineParameters;

  /// The list of assertion initializers in the initializer list.
  ///
  /// These appear in the initializer list as `assert(condition, message)`.
  /// Example: `MyClass(int x) : assert(x > 0, 'x must be positive');`
  final List<AssertionInitializer> assertionInitializers;

  /// The list of property/field initializers in the initializer list.
  ///
  /// These appear in the initializer list as `property = value`.
  /// Example: `MyClass(int x) : _x = x * 2;`
  final List<PropertyInitializer> propertyInitializers;

  /// Optional super constructor initializer.
  ///
  /// Calls a superclass constructor in the initializer list.
  /// Example: `ChildClass() : super.named(arg1, arg2);`
  final SuperInitializer? superInitializer;

  /// Optional redirect initializer for redirecting constructors.
  ///
  /// When present, this constructor redirects to another constructor of the same class.
  /// Redirecting constructors cannot have a [body] or any other initializers.
  /// Example: `MyClass.redirect() : this.main();`
  final RedirectInitializer? redirectInitializer;

  /// Optional constructor body.
  ///
  /// A function that writes the constructor body statements to a StringBuffer.
  /// If null, generates an empty body (semicolon-terminated constructor).
  /// Cannot be present if [redirectInitializer] is set or if [external] is true.
  final void Function(StringBuffer)? body;

  /// Optional documentation comment for this constructor.
  ///
  /// This is the doc comment that appears above the constructor declaration.
  /// Should include the `///` prefix for each line.
  ///
  /// Example:
  /// ```dart
  /// Constructor(
  ///   className: 'User',
  ///   docComment: '/// Creates a new [User] instance.\n///\n/// The [name] parameter is required.',
  /// )
  /// ```
  ///
  /// Generates:
  /// ```dart
  /// /// Creates a new [User] instance.
  /// ///
  /// /// The [name] parameter is required.
  /// User(...);
  /// ```
  final String? docComment;

  /// Optional list of annotations for this constructor.
  ///
  /// Annotations are metadata that appear before the constructor declaration.
  /// Each string should be the annotation without the '@' symbol.
  ///
  /// Common annotations:
  /// - `'deprecated'` - Marks the constructor as deprecated
  /// - `'override'` - Not typically used for constructors
  /// - Custom annotations like `'JsonConstructor()'`
  ///
  /// Example:
  /// ```dart
  /// Constructor(
  ///   className: 'User',
  ///   annotations: ['deprecated', 'JsonConstructor()'],
  /// )
  /// ```
  ///
  /// Generates:
  /// ```dart
  /// @deprecated
  /// @JsonConstructor()
  /// User(...);
  /// ```
  final List<String> annotations;

  /// Creates a new [Constructor] with the specified properties.
  ///
  /// The constructor automatically categorizes the provided [parameters] into
  /// [unnamedParameters], [optionalParameters], and [namedParameters] based on
  /// their properties.
  ///
  /// Validation rules enforced by assertions:
  /// - Cannot mix optional positional and named parameters
  /// - Cannot be both const and factory
  /// - Cannot be both const and external
  /// - External constructors cannot have a body
  /// - Factory constructors cannot have initializing formals (this.x)
  /// - Redirecting constructors cannot have a body or other initializers
  ///
  /// Parameters:
  /// - [Const]: Makes this a const constructor
  /// - [factory]: Makes this a factory constructor
  /// - [external]: Makes this an external constructor
  /// - [className]: Required class name
  /// - [constructorName]: Optional name for named constructors
  /// - [parameters]: List of all parameters (will be auto-categorized)
  /// - [multiLineParameters]: Whether to use trailing commas for formatting
  /// - [assertionInitializers]: Assertion statements in initializer list
  /// - [propertyInitializers]: Property assignments in initializer list
  /// - [superInitializer]: Super constructor call in initializer list
  /// - [redirectInitializer]: Redirect to another constructor
  /// - [body]: Constructor body implementation
  Constructor({
    this.Const = false,
    this.factory = false,
    this.external = false,
    required this.className,
    this.constructorName,
    List<ConstructorParameter>? parameters,
    this.multiLineParameters = true,
    List<AssertionInitializer>? assertionInitializers,
    List<PropertyInitializer>? propertyInitializers,
    this.superInitializer,
    this.redirectInitializer,
    this.body,
    this.docComment,
    List<String>? annotations,
  })  : assertionInitializers = assertionInitializers ?? [],
        propertyInitializers = propertyInitializers ?? [],
        annotations = annotations ?? [] {
    if (parameters != null) {
      this.unnamedParameters = parameters.where((p) => !p.named && !p.optional).toList();
      this.optionalParameters = parameters.where((p) => p.optional).toList();
      this.namedParameters = parameters.where((p) => p.named).toList();
    } else {
      this.unnamedParameters = [];
      this.optionalParameters = [];
      this.namedParameters = [];
    }
    assert(
      !(optionalParameters.isNotEmpty && namedParameters.isNotEmpty),
      'The constructor [$className.$constructorName] can have optional parameters or named parameters but not both',
    );
    assert(!(Const && factory), 'Constructor [$className.$constructorName]: cannot be both const and factory.');
    assert(!(Const && external), 'Constructor [$className.$constructorName]: cannot be both const and external.');
    assert(
      !external || body == null,
      'Constructor [$className.$constructorName]: external constructor cannot have a body.',
    );
    assert(
      !factory || !parameters!.any((p) => p.assigned && !p.isSuper),
      'Constructor [$className.$constructorName]: factory constructor cannot have initializing formals (this.x).',
    );
    assert(
        redirectInitializer == null ||
            (body == null &&
                this.assertionInitializers.isEmpty &&
                this.propertyInitializers.isEmpty &&
                superInitializer == null),
        'Constructor [$className.$constructorName]: redirecting constructor cannot have a body or any initializers.');
  }

  /// Creates a [Constructor] from an analyzer [ConstructorElement].
  ///
  /// This factory method extracts all constructor information from the analyzer's
  /// representation of a constructor, including its AST node, and builds a
  /// corresponding [Constructor] instance.
  ///
  /// Used primarily in code generation contexts where you need to recreate
  /// a constructor's structure from existing code.
  ///
  /// Parameters:
  /// - [constructorElement]: The analyzer's representation of the constructor
  /// - [buildStep]: The build context providing resolver access
  ///
  /// Returns a fully populated [Constructor] instance matching the source constructor.
  static Future<Constructor> from(
    ConstructorElement constructorElement,
    BuildStep buildStep,
  ) async {
    ConstructorDeclaration astNode = await buildStep.resolver.astNodeFor(constructorElement) as ConstructorDeclaration;

    // Extract documentation comment
    String? docComment;
    if (astNode.documentationComment != null) {
      docComment = astNode.documentationComment!.tokens.map((token) => token.toString()).join('\n');
    }

    // Extract annotations
    List<String> annotations = astNode.metadata.map((annotation) => annotation.toSource().substring(1)).toList();

    return Constructor(
        Const: constructorElement.isConst,
        factory: constructorElement.isFactory,
        external: constructorElement.isExternal,
        className: constructorElement.enclosingElement.name,
        constructorName: constructorElement.name,
        parameters: await constructorElement.parameters.mapAsync((e) => ConstructorParameter.from(e, buildStep)),
        multiLineParameters: true,
        assertionInitializers: await astNode.initializers
            .whereType<AssertInitializer>()
            .toList()
            .mapAsync((e) => AssertionInitializer.from(e, buildStep)),
        propertyInitializers: await astNode.initializers
            .whereType<ConstructorFieldInitializer>()
            .toList()
            .mapAsync((e) => PropertyInitializer.from(e, buildStep)),
        superInitializer: astNode.initializers.whereType<SuperConstructorInvocation>().isNotEmpty
            ? await SuperInitializer.from(astNode.initializers.whereType<SuperConstructorInvocation>().first, buildStep)
            : null,
        redirectInitializer: astNode.initializers.whereType<RedirectingConstructorInvocation>().isNotEmpty
            ? await RedirectInitializer.from(
                astNode.initializers.whereType<RedirectingConstructorInvocation>().first, buildStep)
            : null,
        body: (astNode.body is EmptyFunctionBody)
            ? null
            : (StringBuffer b) {
                BlockFunctionBody body = astNode.body as BlockFunctionBody;
                b.write(body.block.statements.toCleanString());
              },
        docComment: docComment,
        annotations: annotations);
  }

  /// Creates a copy of this [Constructor] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter not provided will retain its
  /// current value from this instance.
  ///
  /// Note: When providing [parameters], they will be re-categorized into
  /// unnamed, optional, and named parameter lists. If you don't provide
  /// [parameters], the current categorization is merged back together.
  ///
  /// Example:
  /// ```dart
  /// final original = Constructor(className: 'MyClass');
  /// final modified = original.copyWith(
  ///   Const: true,
  ///   constructorName: 'create',
  /// );
  /// // modified is now a const named constructor
  /// ```
  Constructor copyWith({
    bool? Const,
    bool? factory,
    bool? external,
    String? className,
    String? constructorName,
    List<ConstructorParameter>? parameters,
    bool? multiLineParameters,
    List<AssertionInitializer>? assertionInitializers,
    List<PropertyInitializer>? propertyInitializers,
    SuperInitializer? superInitializer,
    RedirectInitializer? redirectInitializer,
    void Function(StringBuffer)? body,
    String? docComment,
    List<String>? annotations,
  }) =>
      Constructor(
        Const: Const ?? this.Const,
        factory: factory ?? this.factory,
        external: external ?? this.external,
        className: className ?? this.className,
        constructorName: constructorName ?? this.constructorName,
        parameters: parameters ?? [...unnamedParameters, ...optionalParameters, ...namedParameters],
        multiLineParameters: multiLineParameters ?? this.multiLineParameters,
        assertionInitializers: assertionInitializers ?? this.assertionInitializers,
        propertyInitializers: propertyInitializers ?? this.propertyInitializers,
        superInitializer: superInitializer ?? this.superInitializer,
        redirectInitializer: redirectInitializer ?? this.redirectInitializer,
        body: body ?? this.body,
        docComment: docComment ?? this.docComment,
        annotations: annotations ?? this.annotations,
      );

  /// Writes the complete constructor declaration to the provided [StringBuffer].
  ///
  /// Generates valid Dart syntax for the constructor including:
  /// 1. Documentation comment (if present)
  /// 2. Annotations (if present)
  /// 3. Keywords (external, const, factory) in proper order
  /// 4. Class name and optional constructor name
  /// 5. Parameter list with proper grouping (positional, optional, named)
  /// 6. Initializer list (assertions, property assignments, super call)
  /// 7. Redirecting constructor syntax (if applicable)
  /// 8. Constructor body or semicolon terminator
  ///
  /// The output format follows Dart's constructor syntax rules:
  /// - Documentation comments appear first
  /// - Annotations appear after doc comments, before keywords
  /// - Keywords appear before the class name
  /// - Redirecting constructors end after the redirect and cannot have other initializers
  /// - Regular constructors can have initializer lists before the body
  /// - Empty constructors are terminated with a semicolon
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment
    if (docComment != null && docComment!.isNotEmpty) {
      b.writeln(docComment);
    }

    // Write annotations
    if (annotations.isNotEmpty) {
      for (var annotation in annotations) {
        b.writeln('@$annotation');
      }
    }

    if (external) b.write('external ');
    if (Const) b.write('const ');
    if (factory) b.write('factory ');
    b.write(className);
    if (constructorName != null) b.write('.${constructorName}');
    b.write('(');

    if (unnamedParameters.isNotEmpty) {
      unnamedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < unnamedParameters.length - 1)
          b.write(', ');
        else {
          if (namedParameters.isNotEmpty || optionalParameters.isNotEmpty)
            b.write(', ');
          else {
            if (multiLineParameters) b.write(', ');
          }
        }
      });
    }

    if (namedParameters.isNotEmpty) {
      b.write('{');
      namedParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < namedParameters.length - 1)
          b.write(', ');
        else {
          if (multiLineParameters) b.write(',');
          b.write('}');
        }
      });
    }

    if (optionalParameters.isNotEmpty) {
      b.write('[');
      optionalParameters.asMap().forEach((i, parameter) {
        parameter._writeToBuffer(b);
        if (i < optionalParameters.length - 1)
          b.write(', ');
        else {
          if (multiLineParameters) b.write(',');
          b.write(']');
        }
      });
    }

    b.write(')');

    // Redirect initializer (if present, must be the only initializer)
    if (redirectInitializer != null) {
      b.write(' : ');
      redirectInitializer!._writeToBuffer(b);
      b.write(';');
      return;
    }

    final ai = assertionInitializers;
    final pi = propertyInitializers;
    if (ai.isNotEmpty || pi.isNotEmpty || superInitializer != null) {
      b.write(' : ');
      if (ai.isNotEmpty) {
        ai.asMap().forEach((i, initializer) {
          initializer._writeToBuffer(b);
          if (i < ai.length - 1)
            b.write(', ');
          else {
            if (pi.isNotEmpty || superInitializer != null) b.write(', ');
          }
        });
      }

      if (pi.isNotEmpty) {
        pi.asMap().forEach((i, initializer) {
          initializer._writeToBuffer(b);
          if (i < pi.length - 1)
            b.write(', ');
          else {
            if (superInitializer != null) b.write(', ');
          }
        });
      }

      superInitializer?._writeToBuffer(b);
    }

    if (body != null) {
      b.write(' { ');
      StringBuffer buffer = StringBuffer();
      body!(buffer);
      b.write(buffer.toString());
      b.write('}');
    } else
      b.write(';');
  }
}

/// Represents a single parameter in a constructor's parameter list.
///
/// This class models all forms of constructor parameters in Dart:
/// - Required positional parameters: `MyClass(int x)`
/// - Optional positional parameters: `MyClass([int x = 0])`
/// - Named parameters: `MyClass({int x = 0})`
/// - Required named parameters: `MyClass({required int x})`
/// - Field formal parameters: `MyClass(this.x)`
/// - Super parameters (Dart 2.17+): `MyClass(super.x)`
/// - Typed and untyped parameters
///
/// Example usage:
/// ```dart
/// // Required positional: int x
/// ConstructorParameter(name: 'x', type: 'int')
///
/// // Field formal: this.name
/// ConstructorParameter(name: 'name', assigned: true, type: 'String')
///
/// // Required named: {required String id}
/// ConstructorParameter(name: 'id', named: true, Required: true, type: 'String')
///
/// // Super parameter: super.value
/// ConstructorParameter(name: 'value', isSuper: true, type: 'int')
/// ```
class ConstructorParameter implements BufferWritable {
  /// Whether this is a named parameter (appears in curly braces).
  ///
  /// Named parameters are surrounded by `{}` in the parameter list.
  /// Cannot be true if [optional] is true.
  final bool named;

  /// Whether this named parameter is required.
  ///
  /// When true, generates the `required` keyword.
  /// Can only be true if [named] is also true.
  /// Example: `{required String name}`
  final bool Required;

  /// Whether this is an optional positional parameter (appears in square brackets).
  ///
  /// Optional positional parameters are surrounded by `[]` in the parameter list.
  /// Cannot be true if [named] is true.
  /// Example: `MyClass(int x, [int y])`
  final bool optional;

  /// Whether this is a field formal parameter (initializing formal).
  ///
  /// When true, generates `this.parameterName` syntax.
  /// Field formal parameters automatically assign to instance fields.
  /// Cannot be true if [isSuper] is true.
  /// Example: `MyClass(this.name, this.age)`
  final bool assigned;

  /// Whether this is a super parameter (Dart 2.17+).
  ///
  /// When true, generates `super.parameterName` syntax.
  /// Super parameters forward arguments to superclass constructors.
  /// Cannot be true if [assigned] is true.
  /// Example: `ChildClass(super.name, super.age)`
  final bool isSuper;

  /// The optional type annotation for this parameter.
  ///
  /// When null, the parameter has no explicit type (inferred or dynamic).
  /// For field formals and super parameters, the type appears before `this.` or `super.`.
  /// Examples:
  /// - `String name` → type = 'String'
  /// - `this.value` → type = null (inferred from field)
  /// - `int super.x` → type = 'int'
  final String? type;

  /// The name of the parameter.
  ///
  /// This is the identifier used in the parameter list and potentially in the constructor body.
  /// Required for all parameters.
  final String name;

  /// The optional default value expression for this parameter.
  ///
  /// Only valid for optional positional or non-required named parameters.
  /// The value should be a valid Dart expression as a string.
  /// Examples:
  /// - `0` for numeric defaults
  /// - `'default'` for string defaults (include quotes)
  /// - `const []` for const collection defaults
  final String? defaultValue;

  /// Creates a new [ConstructorParameter] with the specified properties.
  ///
  /// Validation rules enforced by assertions:
  /// - Cannot be both [named] and [optional] (mutually exclusive)
  /// - [Required] can only be true if [named] is also true
  /// - [defaultValue] can only be provided for optional or non-required named parameters
  /// - Cannot be both [assigned] (this.x) and [isSuper] (super.x)
  ///
  /// The [name] parameter is required. All other parameters have sensible defaults.
  ConstructorParameter({
    required this.name,
    this.named = false,
    this.Required = false,
    this.optional = false,
    this.assigned = false,
    this.isSuper = false,
    this.type,
    this.defaultValue,
  })  : assert(!(named && optional), 'The constructor parameter [$name] can be either named or optional, but not both'),
        assert(!Required || (Required && named),
            'If the constructor parameter [$name] is required, then it must be named'),
        assert(defaultValue == null || ((named && !Required) || optional),
            'the constructor parameter [$name] is not optional, yet it has a default value'),
        assert(!(assigned && isSuper),
            'The constructor parameter [$name] cannot be both this.x (assigned) and super.x (isSuper)');

  /// Creates a [ConstructorParameter] from an analyzer [ParameterElement].
  ///
  /// Extracts all parameter information from the analyzer's representation
  /// and creates a corresponding [ConstructorParameter] instance.
  ///
  /// Used in code generation to recreate parameter definitions from existing code.
  ///
  /// Parameters:
  /// - [parameterElement]: The analyzer's representation of the parameter
  /// - [buildStep]: The build context (currently unused but kept for API consistency)
  ///
  /// Returns a fully populated [ConstructorParameter] matching the source parameter.
  static Future<ConstructorParameter> from(
    ParameterElement parameterElement,
    BuildStep buildStep,
  ) async =>
      ConstructorParameter(
        name: parameterElement.name,
        named: parameterElement.isNamed,
        Required: parameterElement.isRequiredNamed,
        optional: parameterElement.isOptionalPositional,
        assigned: parameterElement.isInitializingFormal,
        isSuper: parameterElement.isSuperFormal,
        type: parameterElement.type.toString(),
        defaultValue: parameterElement.defaultValueCode,
      );

  /// Creates a copy of this [ConstructorParameter] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter not provided will retain its
  /// current value from this instance.
  ///
  /// Example:
  /// ```dart
  /// final original = ConstructorParameter(name: 'x', type: 'int');
  /// final modified = original.copyWith(
  ///   named: true,
  ///   Required: true,
  /// );
  /// // modified is now {required int x}
  /// ```
  ConstructorParameter copyWith({
    bool? named,
    bool? Required,
    bool? optional,
    bool? assigned,
    bool? isSuper,
    String? type,
    String? name,
    String? defaultValue,
  }) =>
      ConstructorParameter(
        name: name ?? this.name,
        named: named ?? this.named,
        Required: Required ?? this.Required,
        optional: optional ?? this.optional,
        assigned: assigned ?? this.assigned,
        isSuper: isSuper ?? this.isSuper,
        type: type ?? this.type,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  /// Writes the parameter declaration to the provided [StringBuffer].
  ///
  /// Generates valid Dart syntax for this parameter including:
  /// - The `required` keyword for required named parameters
  /// - Type annotations (placed correctly before this./super. for field/super formals)
  /// - The `this.` prefix for field formal parameters
  /// - The `super.` prefix for super parameters
  /// - The parameter name
  /// - Default value assignment if present
  ///
  /// Examples of generated syntax:
  /// - `int x` (typed positional)
  /// - `this.name` (field formal)
  /// - `super.value` (super parameter)
  /// - `required String id` (required named)
  /// - `int y = 0` (with default value)
  void _writeToBuffer(StringBuffer b) {
    // Write 'required' keyword for named parameters
    if (named && Required) {
      b.write('required ');
    }

    // Write type if present (but not for field formals or super formals without explicit type)
    if (type != null && !assigned && !isSuper) {
      b.write('$type ');
    } else if (type != null && (assigned || isSuper)) {
      // For field formals and super formals, type comes before this./super.
      b.write('$type ');
    }

    // Write this. or super. for field formals and super formals
    if (assigned) {
      b.write('this.');
    } else if (isSuper) {
      b.write('super.');
    }

    // Write parameter name
    b.write(name);

    // Write default value if present
    if (defaultValue != null) {
      b.write(' = $defaultValue');
    }
  }
}

/// Abstract base class for all constructor initializer types.
///
/// Constructor initializers appear in the initializer list between the parameter
/// list and the constructor body, separated by a colon.
///
/// Dart supports several types of initializers:
/// - [AssertionInitializer]: Assert statements
/// - [PropertyInitializer]: Field assignments
/// - [SuperInitializer]: Superclass constructor calls
/// - [RedirectInitializer]: Redirecting to another constructor
///
/// All initializers implement [BufferWritable] to generate their syntax.
abstract class ConstructorInitializer implements BufferWritable {}

/// Represents an assertion initializer in a constructor's initializer list.
///
/// Assertions in initializers validate constructor arguments at construction time.
/// They appear as `assert(condition)` or `assert(condition, message)` in the
/// initializer list.
///
/// Example usage:
/// ```dart
/// // assert(x > 0)
/// AssertionInitializer(expression: 'x > 0')
///
/// // assert(name.isNotEmpty, 'Name cannot be empty')
/// AssertionInitializer(
///   expression: 'name.isNotEmpty',
///   message: "'Name cannot be empty'",
/// )
/// ```
///
/// Note: The [message] is optional in Dart, so it's nullable here.
class AssertionInitializer extends ConstructorInitializer {
  /// The boolean condition expression to assert.
  ///
  /// This should be a valid Dart boolean expression as a string.
  /// Example: `x > 0`, `name.isNotEmpty`, `value != null`
  final String expression;

  /// The optional message to display if the assertion fails.
  ///
  /// When provided, this should be a complete expression (usually a string literal).
  /// Include quotes if it's a string: `"'Error message'"` or `'"Error message"'`.
  ///
  /// When null or empty, the assertion is generated without a message.
  final String? message;

  /// Creates a new [AssertionInitializer].
  ///
  /// The [expression] is required and should be a boolean expression.
  /// The [message] is optional.
  AssertionInitializer({
    required this.expression,
    this.message,
  });

  /// Creates an [AssertionInitializer] from an analyzer [AssertInitializer] AST node.
  ///
  /// Extracts the condition and optional message from the analyzer's
  /// representation of an assert statement in a constructor initializer.
  ///
  /// Parameters:
  /// - [assertInitializer]: The AST node representing the assert statement
  /// - [buildStep]: The build context (currently unused but kept for API consistency)
  static Future<AssertionInitializer> from(
    AssertInitializer assertInitializer,
    BuildStep buildStep,
  ) async =>
      AssertionInitializer(
        expression: '${assertInitializer.condition}',
        message: assertInitializer.message != null ? '${assertInitializer.message}' : null,
      );

  /// Creates a copy of this [AssertionInitializer] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter not provided will retain its
  /// current value from this instance.
  AssertionInitializer copyWith({
    String? expression,
    String? message,
  }) =>
      AssertionInitializer(
        expression: expression ?? this.expression,
        message: message ?? this.message,
      );

  /// Writes the assertion initializer to the provided [StringBuffer].
  ///
  /// Generates `assert(expression)` or `assert(expression, message)` syntax.
  /// The message is only included if it's not null and not empty.
  @override
  void _writeToBuffer(StringBuffer b) {
    b.write('assert($expression');
    if (message != null && message!.isNotEmpty) {
      b.write(', $message');
    }
    b.write(')');
  }
}

/// Represents a property/field initializer in a constructor's initializer list.
///
/// Property initializers assign values to instance fields in the initializer list.
/// They appear as `fieldName = expression` before the constructor body.
///
/// Example usage:
/// ```dart
/// // _value = value * 2
/// PropertyInitializer(name: '_value', value: 'value * 2')
///
/// // items = const []
/// PropertyInitializer(name: 'items', value: 'const []')
/// ```
///
/// Common use cases:
/// - Initializing private fields with computed values
/// - Setting fields to const values
/// - Converting constructor parameters before assignment
class PropertyInitializer extends ConstructorInitializer {
  /// The name of the field/property being initialized.
  ///
  /// This should be a valid field name that exists in the class.
  /// Can include privacy prefix: `_value`, `_name`, etc.
  final String name;

  /// The expression that produces the value to assign to the field.
  ///
  /// This should be a valid Dart expression as a string.
  /// Examples: `value * 2`, `name.trim()`, `const []`, `0`
  final String value;

  /// Creates a new [PropertyInitializer].
  ///
  /// Both [name] and [value] are required.
  PropertyInitializer({
    required this.name,
    required this.value,
  });

  /// Creates a [PropertyInitializer] from an analyzer [ConstructorFieldInitializer] AST node.
  ///
  /// Extracts the field name and initialization expression from the analyzer's
  /// representation of a field initializer.
  ///
  /// Parameters:
  /// - [constructorFieldInitializer]: The AST node representing the field initializer
  /// - [buildStep]: The build context (currently unused but kept for API consistency)
  static Future<PropertyInitializer> from(
    ConstructorFieldInitializer constructorFieldInitializer,
    BuildStep buildStep,
  ) async =>
      PropertyInitializer(
        name: '${constructorFieldInitializer.fieldName}',
        value: '${constructorFieldInitializer.expression}',
      );

  /// Creates a copy of this [PropertyInitializer] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter not provided will retain its
  /// current value from this instance.
  PropertyInitializer copyWith({
    String? name,
    String? value,
  }) =>
      PropertyInitializer(
        name: name ?? this.name,
        value: value ?? this.value,
      );

  /// Writes the property initializer to the provided [StringBuffer].
  ///
  /// Generates `name = value` syntax for the initializer list.
  @override
  void _writeToBuffer(StringBuffer b) {
    b.write('$name = $value');
  }
}

/// Represents a super constructor invocation in a constructor's initializer list.
///
/// Super initializers call a superclass constructor, passing along arguments.
/// They appear as `super()` or `super.named(args)` in the initializer list.
///
/// Example usage:
/// ```dart
/// // super()
/// SuperInitializer()
///
/// // super.named(arg1, arg2)
/// SuperInitializer(
///   name: 'named',
///   arguments: [
///     SuperInitializerArgument(value: 'arg1'),
///     SuperInitializerArgument(value: 'arg2'),
///   ],
/// )
///
/// // super(x, y: namedArg)
/// SuperInitializer(
///   arguments: [
///     SuperInitializerArgument(value: 'x'),
///     SuperInitializerArgument(name: 'y', value: 'namedArg'),
///   ],
/// )
/// ```
class SuperInitializer extends ConstructorInitializer {
  /// The optional name of the superclass constructor to call.
  ///
  /// When null or empty, calls the default superclass constructor: `super()`
  /// When provided, calls a named superclass constructor: `super.name()`
  final String? name;

  /// The list of arguments to pass to the superclass constructor.
  ///
  /// Can include both positional and named arguments via [SuperInitializerArgument].
  /// Empty list means no arguments: `super()` or `super.named()`
  final List<SuperInitializerArgument> arguments;

  /// Whether to format arguments with a trailing comma for multi-line style.
  ///
  /// When true, adds a trailing comma after the last argument.
  final bool multiLineArguments;

  /// Creates a new [SuperInitializer].
  ///
  /// All parameters are optional with sensible defaults.
  SuperInitializer({
    this.name,
    List<SuperInitializerArgument>? arguments,
    this.multiLineArguments = true,
  }) : arguments = arguments ?? [];

  /// Creates a [SuperInitializer] from an analyzer [SuperConstructorInvocation] AST node.
  ///
  /// Extracts the constructor name and all arguments from the analyzer's
  /// representation of a super constructor call.
  ///
  /// Parameters:
  /// - [superConstructorInvocation]: The AST node representing the super call
  /// - [buildStep]: The build context providing resolver access
  static Future<SuperInitializer> from(
    SuperConstructorInvocation superConstructorInvocation,
    BuildStep buildStep,
  ) async =>
      SuperInitializer(
        name: '${superConstructorInvocation.constructorName}',
        arguments: await superConstructorInvocation.argumentList.arguments
            .mapAsync((e) => SuperInitializerArgument.from(e, buildStep)),
        multiLineArguments: true,
      );

  /// Creates a copy of this [SuperInitializer] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter not provided will retain its
  /// current value from this instance.
  SuperInitializer copyWith({
    String? name,
    List<SuperInitializerArgument>? arguments,
    bool? multiLineArguments,
  }) =>
      SuperInitializer(
        name: name ?? this.name,
        arguments: arguments ?? this.arguments,
        multiLineArguments: multiLineArguments ?? this.multiLineArguments,
      );

  /// Writes the super initializer to the provided [StringBuffer].
  ///
  /// Generates `super()`, `super.name()`, or `super.name(args)` syntax.
  /// Handles both positional and named arguments.
  /// Adds trailing comma if [multiLineArguments] is true and there are arguments.
  @override
  void _writeToBuffer(StringBuffer b) {
    b.write('super');
    if (name != null && name!.isNotEmpty) b.write('.$name');
    b.write('(');
    if (arguments.isNotEmpty) {
      arguments.asMap().forEach((i, argument) {
        argument._writeToBuffer(b);
        if (i < arguments.length - 1)
          b.write(', ');
        else {
          if (multiLineArguments) b.write(',');
        }
      });
    }
    b.write(')');
  }
}

/// Represents a single argument in a [SuperInitializer] invocation.
///
/// Arguments can be either positional or named:
/// - Positional: `SuperInitializerArgument(value: 'expression')`
/// - Named: `SuperInitializerArgument(name: 'argName', value: 'expression')`
///
/// Example usage:
/// ```dart
/// // Positional argument: x
/// SuperInitializerArgument(value: 'x')
///
/// // Named argument: name: userName
/// SuperInitializerArgument(name: 'name', value: 'userName')
/// ```
class SuperInitializerArgument implements BufferWritable {
  /// The optional name for a named argument.
  ///
  /// When null, this is a positional argument.
  /// When provided, generates `name: value` syntax.
  final String? name;

  /// The expression value of this argument.
  ///
  /// This should be a valid Dart expression as a string.
  /// Examples: `x`, `value * 2`, `'constant'`, `obj.property`
  final String value;

  /// Creates a new [SuperInitializerArgument].
  ///
  /// The [value] is required. The [name] is optional (null for positional arguments).
  SuperInitializerArgument({
    this.name,
    required this.value,
  });

  /// Creates a [SuperInitializerArgument] from an analyzer [Expression] AST node.
  ///
  /// Determines if the expression is a named or positional argument and
  /// extracts the appropriate values.
  ///
  /// Parameters:
  /// - [argumentExpression]: The AST node representing the argument expression
  /// - [buildStep]: The build context (currently unused but kept for API consistency)
  static Future<SuperInitializerArgument> from(
    Expression argumentExpression,
    BuildStep buildStep,
  ) async =>
      SuperInitializerArgument(
        name: (argumentExpression is NamedExpression) ? '${argumentExpression.name}' : null,
        value: (argumentExpression is NamedExpression) ? '${argumentExpression.expression}' : '$argumentExpression',
      );

  /// Creates a copy of this [SuperInitializerArgument] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter not provided will retain its
  /// current value from this instance.
  SuperInitializerArgument copyWith({
    String? name,
    String? value,
  }) =>
      SuperInitializerArgument(
        name: name ?? this.name,
        value: value ?? this.value,
      );

  /// Writes the argument to the provided [StringBuffer].
  ///
  /// Generates either `value` for positional arguments or `name: value` for named arguments.
  @override
  void _writeToBuffer(StringBuffer b) {
    b.write((name == null) ? '' : '$name: ');
    b.write(value);
  }
}

/// Represents a redirecting constructor initializer.
///
/// Redirecting constructors delegate to another constructor of the same class.
/// They appear as `this()` or `this.named(args)` in the initializer list.
///
/// Important: Redirecting constructors cannot have:
/// - A constructor body
/// - Any other initializers (assertions, property initializers, super calls)
///
/// Example usage:
/// ```dart
/// // this()
/// RedirectInitializer(targetConstructor: '')
///
/// // this.named()
/// RedirectInitializer(targetConstructor: 'named')
///
/// // this.create(arg1, arg2)
/// RedirectInitializer(
///   targetConstructor: 'create',
///   arguments: ['arg1', 'arg2'],
/// )
/// ```
class RedirectInitializer extends ConstructorInitializer {
  /// The name of the target constructor to redirect to.
  ///
  /// When empty string, redirects to the default constructor: `this()`
  /// When provided, redirects to a named constructor: `this.targetConstructor()`
  final String targetConstructor;

  /// The list of argument expressions to pass to the target constructor.
  ///
  /// Each string should be a complete argument expression (including names for named arguments).
  /// Examples: `'x'`, `'value * 2'`, `'name: userName'`
  final List<String> arguments;

  /// Creates a new [RedirectInitializer].
  ///
  /// The [targetConstructor] is required (use empty string for default constructor).
  /// The [arguments] list is optional and defaults to empty.
  RedirectInitializer({
    required this.targetConstructor,
    List<String>? arguments,
  }) : arguments = arguments ?? [];

  /// Creates a [RedirectInitializer] from an analyzer [RedirectingConstructorInvocation] AST node.
  ///
  /// Extracts the target constructor name and all argument expressions from
  /// the analyzer's representation of a redirecting constructor.
  ///
  /// Parameters:
  /// - [redirectNode]: The AST node representing the redirecting constructor invocation
  /// - [buildStep]: The build context (currently unused but kept for API consistency)
  ///
  /// Returns a [RedirectInitializer] with the target constructor name and arguments.
  static Future<RedirectInitializer> from(
    RedirectingConstructorInvocation redirectNode,
    BuildStep buildStep,
  ) async {
    return RedirectInitializer(
      targetConstructor: redirectNode.constructorName?.name ?? '',
      arguments: redirectNode.argumentList.arguments.map((e) => e.toSource()).toList(),
    );
  }

  /// Creates a copy of this [RedirectInitializer] with the specified properties replaced.
  ///
  /// All parameters are optional. Any parameter not provided will retain its
  /// current value from this instance.
  RedirectInitializer copyWith({
    String? targetConstructor,
    List<String>? arguments,
  }) =>
      RedirectInitializer(
        targetConstructor: targetConstructor ?? this.targetConstructor,
        arguments: arguments ?? this.arguments,
      );

  /// Writes the redirect initializer to the provided [StringBuffer].
  ///
  /// Generates `this()`, `this.name()`, or `this.name(args)` syntax.
  /// Properly handles redirects to both the default constructor (empty [targetConstructor])
  /// and named constructors.
  @override
  void _writeToBuffer(StringBuffer b) {
    b.write('this');
    if (targetConstructor.isNotEmpty) {
      b.write('.$targetConstructor');
    }
    b.write('(');
    for (int i = 0; i < arguments.length; i++) {
      b.write(arguments[i]);
      if (i < arguments.length - 1) b.write(', ');
    }
    b.write(')');
  }
}
