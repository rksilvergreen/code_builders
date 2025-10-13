part of dart_source_builder;

/// Represents a Dart setter method declaration.
///
/// A setter is a special method that provides write-only access to a property.
/// It uses the `set` keyword and must accept exactly one parameter. This class
/// models all possible configurations of a setter in Dart, including:
/// - External setters (declared but implemented elsewhere)
/// - Static setters (class-level, not instance-level)
/// - Arrow function syntax (=>) or block body syntax
/// - Type annotations on parameters
/// - Metadata annotations (@override, @deprecated, custom annotations)
/// - Documentation comments
/// - Covariant parameters
///
/// Note: Unlike getters, setters CANNOT be async or generators.
///
/// Example usage:
/// ```dart
/// // Simple setter with arrow function
/// final setter = Setter(
///   name: 'age',
///   parameter: SetterParameter(type: 'int', name: 'value'),
///   arrowFunction: true,
///   body: (b) => b.write('_age = value'),
/// );
///
/// // Setter with validation in block body
/// final validatedSetter = Setter(
///   name: 'email',
///   parameter: SetterParameter(type: 'String', name: 'value'),
///   body: (b) => b.write('if (value.contains("@")) _email = value;'),
/// );
///
/// // External setter (no implementation)
/// final externalSetter = Setter(
///   external: true,
///   name: 'platformName',
///   parameter: SetterParameter(type: 'String', name: 'value'),
/// );
/// ```
class Setter implements BufferWritable {
  /// A list of metadata annotations to be applied to this setter.
  ///
  /// Annotations are prefixed with `@` and appear before the setter declaration.
  /// Common examples include:
  /// - `@override` - indicates this setter overrides a superclass/interface setter
  /// - `@deprecated` - marks this setter as deprecated
  /// - `@pragma('vm:entry-point')` - compiler directives
  /// - Custom annotations from your codebase
  ///
  /// Example: `['@override', '@deprecated']`
  final List<String> annotations;

  /// The documentation comment for this setter.
  ///
  /// Should be a multi-line string with `///` prefix for each line, following
  /// Dart documentation conventions. This appears directly above the setter
  /// declaration and is used to generate API documentation.
  ///
  /// Example:
  /// ```dart
  /// '''
  /// /// Sets the user's age.
  /// ///
  /// /// The value must be a positive integer.
  /// '''
  /// ```
  final String docComment;

  /// Whether this setter is declared as external.
  ///
  /// External setters have no implementation in Dart code - they are implemented
  /// in native code (C++, JavaScript, etc.) or provided by another mechanism.
  /// External setters:
  /// - Cannot have a body
  /// - End with a semicolon instead of a body
  ///
  /// Example: `external set platformName(String value);`
  final bool external;

  /// Whether this setter is static (class-level rather than instance-level).
  ///
  /// Static setters belong to the class itself, not to instances of the class.
  /// They can be called without creating an instance:
  /// - `MyClass.staticSetter = value` instead of `instance.setter = value`
  /// - Cannot access instance members (this)
  /// - Useful for class-level configuration
  /// - Cannot be combined with @override annotation (static methods don't override)
  final bool static;

  /// The name of this setter.
  ///
  /// Must be a valid Dart identifier following these rules:
  /// - Cannot be empty
  /// - Must start with a letter or underscore
  /// - Can contain letters, digits, and underscores
  /// - Should follow Dart naming conventions (lowerCamelCase)
  /// - Private setters start with underscore (e.g., `_privateSetter`)
  final String name;

  /// The parameter that this setter accepts.
  ///
  /// Setters must accept exactly one parameter. This parameter can be:
  /// - Typed or untyped
  /// - Marked as covariant
  /// - Named with any valid identifier
  final SetterParameter parameter;

  /// Whether this setter uses arrow function syntax (=>) instead of a block body.
  ///
  /// Arrow syntax is concise single-expression syntax:
  /// - `set name(type value) => expression;` instead of `set name(type value) { expression; }`
  /// - Commonly used for simple assignments
  ///
  /// Example: `set name(String value) => _name = value;`
  final bool arrowFunction;

  /// The implementation body of this setter.
  ///
  /// A function that writes the setter's implementation to a StringBuffer.
  /// The function receives a StringBuffer parameter and should write the
  /// setter's logic to it.
  ///
  /// For [arrowFunction]=true: Write the single expression (no semicolon)
  /// For [arrowFunction]=false: Write the statements for the block body
  ///
  /// This is `null` for [external] setters (which have no body).
  ///
  /// Example:
  /// ```dart
  /// // Arrow function body
  /// body: (b) => b.write('_name = value')
  ///
  /// // Block body
  /// body: (b) => b.write('_name = value.trim();')
  /// ```
  final void Function(StringBuffer)? body;

  /// Creates a new [Setter] instance.
  ///
  /// All parameters are optional except [name], [parameter], and [body] (unless [external] is true).
  ///
  /// Validation rules enforced by assertions:
  /// - [name] cannot be empty
  /// - [external] setters cannot have a [body]
  /// - Non-[external] setters must have a [body]
  /// - If [body] is null, then [arrowFunction] must be false
  /// - [static] setters cannot have @override in [annotations]
  ///
  /// Example:
  /// ```dart
  /// // Standard setter with arrow function
  /// final setter = Setter(
  ///   name: 'value',
  ///   parameter: SetterParameter(type: 'int', name: 'v'),
  ///   arrowFunction: true,
  ///   body: (b) => b.write('_value = v'),
  /// );
  ///
  /// // Overriding setter
  /// final overrideSetter = Setter(
  ///   annotations: ['@override'],
  ///   name: 'name',
  ///   parameter: SetterParameter(type: 'String', name: 'value'),
  ///   body: (b) => b.write('_name = value;'),
  /// );
  ///
  /// // External setter
  /// final externalSetter = Setter(
  ///   external: true,
  ///   name: 'platformValue',
  ///   parameter: SetterParameter(type: 'int', name: 'value'),
  /// );
  /// ```
  Setter({
    this.annotations = const [],
    this.docComment = '',
    this.external = false,
    this.static = false,
    required this.name,
    required this.parameter,
    this.arrowFunction = false,
    this.body,
  })  : assert(name.isNotEmpty, 'Setter name cannot be empty'),
        assert(!external || body == null, 'External setters cannot have a body'),
        assert(body != null || !arrowFunction, 'Cannot use arrow function syntax without a body'),
        assert(external || body != null, 'Non-external setters must have a body'),
        assert(!static || !annotations.contains('@override'), 'Static setters cannot have @override annotation');

  /// Creates a [Setter] instance from analyzer's [PropertyAccessorElement].
  ///
  /// This factory method is used during code generation to extract setter
  /// information from existing Dart source code using the analyzer package.
  /// It reconstructs a [Setter] object from the AST (Abstract Syntax Tree).
  ///
  /// Parameters:
  /// - [setterElement]: The analyzer element representing the setter.
  ///   Must be a setter (not a getter), validated by assertion.
  /// - [buildStep]: The build step from the build package, used to resolve
  ///   AST nodes from elements.
  ///
  /// The method extracts:
  /// - All metadata annotations (including @override and custom annotations)
  /// - Documentation comments from the AST node
  /// - Whether the setter is external
  /// - Whether the setter is static
  /// - The setter name
  /// - The parameter information
  /// - Whether it uses arrow syntax or block syntax
  /// - The body implementation (or null for external/empty bodies)
  ///
  /// Returns a [Future<Setter>] that completes with the reconstructed setter.
  ///
  /// Throws an [AssertionError] if [setterElement] is not actually a setter.
  ///
  /// Example usage in a code generator:
  /// ```dart
  /// final element = libraryReader.classes
  ///     .first
  ///     .accessors
  ///     .firstWhere((a) => a.isSetter);
  /// final setter = await Setter.from(element, buildStep);
  /// ```
  static Future<Setter> from(
    PropertyAccessorElement setterElement,
    BuildStep buildStep,
  ) async {
    assert(setterElement.isSetter, 'The PropertyAccessorElement [${setterElement.name}] is not a setter');
    MethodDeclaration astNode = await buildStep.resolver.astNodeFor(setterElement) as MethodDeclaration;

    // Collect all annotations
    List<String> annotations = [];
    for (var annotation in setterElement.metadata) {
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

    return Setter(
        annotations: annotations,
        docComment: docComment,
        external: setterElement.isExternal,
        static: setterElement.isStatic,
        name: setterElement.name,
        parameter: await SetterParameter.from(setterElement.parameters.first, buildStep),
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

  /// Creates a copy of this [Setter] with the specified properties replaced.
  ///
  /// This method allows you to create a modified version of an existing setter
  /// without mutating the original instance. Any parameter that is not provided
  /// (or is null) will use the value from the current instance.
  ///
  /// This is useful for:
  /// - Making slight variations of a setter
  /// - Programmatically modifying setters during code generation
  /// - Creating setter templates that can be customized
  ///
  /// All validation rules from the constructor still apply to the copied instance.
  ///
  /// Example:
  /// ```dart
  /// final original = Setter(
  ///   name: 'value',
  ///   parameter: SetterParameter(type: 'int', name: 'v'),
  ///   body: (b) => b.write('_value = v;'),
  /// );
  ///
  /// // Create a static version of the same setter
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
  Setter copyWith({
    List<String>? annotations,
    String? docComment,
    bool? external,
    bool? static,
    String? name,
    SetterParameter? parameter,
    bool? arrowFunction,
    void Function(StringBuffer)? body,
  }) =>
      Setter(
        annotations: annotations ?? this.annotations,
        docComment: docComment ?? this.docComment,
        external: external ?? this.external,
        static: static ?? this.static,
        name: name ?? this.name,
        parameter: parameter ?? this.parameter,
        arrowFunction: arrowFunction ?? this.arrowFunction,
        body: body ?? this.body,
      );

  /// Writes the complete Dart setter declaration to a [StringBuffer].
  ///
  /// This method generates valid Dart source code for the setter by writing
  /// all components in the correct syntactic order according to Dart language
  /// specifications.
  ///
  /// The output follows this structure:
  /// ```
  /// [docComment]
  /// [annotations]
  /// [external] [static] set [name]([parameter]) [body]
  /// ```
  ///
  /// Specific behaviors:
  /// - **Documentation comment**: Written first if present, followed by newline
  /// - **Annotations**: Each annotation followed by a space (e.g., `@override `)
  /// - **Modifiers**: Written in order: `external`, then `static`
  /// - **Setter keyword and name**: Always `set name`
  /// - **Parameter**: The setter parameter with type and name
  /// - **External setters**: End with semicolon, no body
  /// - **Arrow function body**: ` => expression;`
  /// - **Block body**: ` { statements }`
  ///
  /// Example outputs:
  /// ```dart
  /// // Simple setter
  /// set name(String value) => _name = value;
  ///
  /// // With annotations and documentation
  /// /// Sets the user's full name.
  /// @override
  /// set fullName(String value) { _firstName = value.split(' ').first; }
  ///
  /// // Static external setter
  /// external static set platformVersion(int value);
  /// ```
  ///
  /// Parameters:
  /// - [b]: The StringBuffer to write the setter declaration to
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

    // Write setter keyword and name
    b.write('set $name(');
    parameter._writeToBuffer(b);
    b.write(')');

    // For external setters, just end with semicolon
    if (external) {
      b.write(';');
      return;
    }

    // Write body
    b.write(' ');
    if (arrowFunction) {
      b.write('=> ');
      StringBuffer buffer = StringBuffer();
      body!(buffer);
      b.write(buffer.toString());
      b.write(';');
    } else {
      b.write('{ ');
      StringBuffer buffer = StringBuffer();
      body!(buffer);
      b.write(buffer.toString());
      b.write(' }');
    }
  }
}

/// Represents a parameter for a Dart setter.
///
/// Setters in Dart must have exactly one parameter. This class models all
/// possible configurations of that parameter, including:
/// - Type annotation (explicit or inferred)
/// - Parameter name
/// - Covariant modifier (for tightening types in subclasses)
///
/// Example usage:
/// ```dart
/// // Simple typed parameter
/// final param = SetterParameter(type: 'String', name: 'value');
///
/// // Covariant parameter (allows subclass to tighten the type)
/// final covariantParam = SetterParameter(
///   type: 'Animal',
///   name: 'pet',
///   covariant: true,
/// );
///
/// // Inferred type
/// final inferredParam = SetterParameter(type: '', name: 'value');
/// ```
class SetterParameter implements BufferWritable {
  /// The type of this parameter.
  ///
  /// Can be any valid Dart type including:
  /// - Primitive types: `int`, `String`, `bool`, etc.
  /// - Generic types: `List<String>`, `Map<int, User>`, etc.
  /// - Custom types: `User`, `MyCustomClass`, etc.
  /// - Empty string (`''`) for type inference
  ///
  /// If empty, the type annotation is omitted and Dart will infer the type.
  final String type;

  /// The name of this parameter.
  ///
  /// Must be a valid Dart identifier following these rules:
  /// - Cannot be empty
  /// - Must start with a letter or underscore
  /// - Can contain letters, digits, and underscores
  /// - Should follow Dart naming conventions (lowerCamelCase)
  final String name;

  /// Whether this parameter is marked as covariant.
  ///
  /// Covariant parameters allow a subclass to tighten the type of an
  /// inherited setter parameter. This is useful when overriding setters
  /// in a type-safe way.
  ///
  /// Example:
  /// ```dart
  /// class Animal {}
  /// class Dog extends Animal {}
  ///
  /// class AnimalHouse {
  ///   set pet(Animal value) { ... }
  /// }
  ///
  /// class DogHouse extends AnimalHouse {
  ///   // Covariant allows us to accept Dog instead of Animal
  ///   @override
  ///   set pet(covariant Dog value) { ... }
  /// }
  /// ```
  final bool covariant;

  /// Creates a new [SetterParameter] instance.
  ///
  /// All parameters are required except [covariant] which defaults to false.
  ///
  /// Validation rules:
  /// - [name] cannot be empty (enforced by assertion)
  ///
  /// Example:
  /// ```dart
  /// // Standard parameter
  /// final param = SetterParameter(type: 'int', name: 'age');
  ///
  /// // Covariant parameter
  /// final covariantParam = SetterParameter(
  ///   type: 'String',
  ///   name: 'value',
  ///   covariant: true,
  /// );
  /// ```
  SetterParameter({
    required this.type,
    required this.name,
    this.covariant = false,
  }) : assert(name.isNotEmpty, 'Parameter name cannot be empty');

  /// Creates a [SetterParameter] instance from analyzer's [ParameterElement].
  ///
  /// This factory method is used during code generation to extract parameter
  /// information from existing Dart source code using the analyzer package.
  ///
  /// The method extracts:
  /// - The parameter type as a string
  /// - The parameter name
  /// - Whether the parameter is marked as covariant
  ///
  /// Returns a [Future<SetterParameter>] that completes with the reconstructed parameter.
  ///
  /// Example usage in a code generator:
  /// ```dart
  /// final paramElement = setterElement.parameters.first;
  /// final param = await SetterParameter.from(paramElement, buildStep);
  /// ```
  static Future<SetterParameter> from(
    ParameterElement parameterElement,
    BuildStep buildStep,
  ) async =>
      SetterParameter(
        type: '${parameterElement.type}',
        name: parameterElement.name,
        covariant: parameterElement.isCovariant,
      );

  /// Creates a copy of this [SetterParameter] with the specified properties replaced.
  ///
  /// This method allows you to create a modified version of an existing parameter
  /// without mutating the original instance. Any parameter that is not provided
  /// (or is null) will use the value from the current instance.
  ///
  /// Example:
  /// ```dart
  /// final original = SetterParameter(type: 'int', name: 'value');
  ///
  /// // Change the type
  /// final withDifferentType = original.copyWith(type: 'String');
  ///
  /// // Make it covariant
  /// final covariantVersion = original.copyWith(covariant: true);
  /// ```
  SetterParameter copyWith({
    String? type,
    String? name,
    bool? covariant,
  }) =>
      SetterParameter(
        type: type ?? this.type,
        name: name ?? this.name,
        covariant: covariant ?? this.covariant,
      );

  /// Writes the parameter declaration to a [StringBuffer].
  ///
  /// This method generates valid Dart source code for the parameter by writing
  /// all components in the correct syntactic order.
  ///
  /// The output follows this structure:
  /// ```
  /// [covariant] [type] [name]
  /// ```
  ///
  /// Specific behaviors:
  /// - **Covariant**: Written first if true, followed by space
  /// - **Type**: Always written (or 'dynamic' if empty), followed by space
  /// - **Name**: The parameter name
  ///
  /// Example outputs:
  /// ```dart
  /// // Simple parameter
  /// String value
  ///
  /// // Covariant parameter
  /// covariant Animal pet
  ///
  /// // Inferred type parameter
  /// dynamic value
  /// ```
  ///
  /// Parameters:
  /// - [b]: The StringBuffer to write the parameter declaration to
  void _writeToBuffer(StringBuffer b) {
    if (covariant) b.write('covariant ');
    if (type.isNotEmpty) {
      b.write('$type ');
    }
    b.write(name);
  }
}
