part of code_builder;

/// Represents a single enum constant declaration.
///
/// Enum constants can be simple (just a name) or enhanced (with constructor arguments).
///
/// **Examples:**
///
/// Simple constant:
/// ```dart
/// EnumConstant(name: 'red')
/// // Generates: red
/// ```
///
/// Constant with constructor arguments:
/// ```dart
/// EnumConstant(name: 'red', arguments: ['255', '0', '0'])
/// // Generates: red(255, 0, 0)
/// ```
class EnumConstant implements BufferWritable {
  /// The name of this enum constant.
  ///
  /// This is the identifier used to access this constant value.
  final String name;

  /// The constructor arguments for this constant, if any.
  ///
  /// When null or empty, this is a simple constant without arguments.
  /// When provided, the constant calls the enum constructor with these arguments.
  ///
  /// **Example:**
  /// ```dart
  /// EnumConstant(name: 'car', arguments: ['2', '4'])
  /// // Generates: car(2, 4)
  /// ```
  final List<String>? arguments;

  /// Creates an enum constant with the given [name] and optional [arguments].
  ///
  /// **Examples:**
  /// ```dart
  /// EnumConstant(name: 'red')
  /// // Simple constant: red
  ///
  /// EnumConstant(name: 'red', arguments: ['255', '0', '0'])
  /// // Enhanced constant: red(255, 0, 0)
  /// ```
  const EnumConstant({
    required this.name,
    this.arguments,
  });

  /// Creates a copy of this enum constant with the specified properties replaced.
  EnumConstant copyWith({
    String? name,
    List<String>? arguments,
  }) =>
      EnumConstant(
        name: name ?? this.name,
        arguments: arguments ?? this.arguments,
      );

  @override
  void _writeToBuffer(StringBuffer b) {
    b.write(name);
    if (arguments != null && arguments!.isNotEmpty) {
      b.write('(');
      b.write(arguments!.join(', '));
      b.write(')');
    }
  }
}

/// Represents a Dart enum declaration with full support for all Dart enum features.
///
/// This class provides a complete representation of Dart enums, supporting:
/// - Simple enums (just constant values)
/// - Enhanced enums with fields, constructors, methods, getters, and setters
/// - Mixins (`with` clause)
/// - Interfaces (`implements` clause)
///
/// **Examples:**
///
/// Simple enum:
/// ```dart
/// Enum(
///   name: 'Color',
///   constants: [
///     EnumConstant(name: 'red'),
///     EnumConstant(name: 'green'),
///     EnumConstant(name: 'blue'),
///   ],
/// )
/// // Generates: enum Color { red, green, blue }
/// ```
///
/// Enhanced enum with constructor and fields:
/// ```dart
/// Enum(
///   name: 'Color',
///   constants: [
///     EnumConstant(name: 'red', arguments: ['255', '0', '0']),
///     EnumConstant(name: 'green', arguments: ['0', '255', '0']),
///     EnumConstant(name: 'blue', arguments: ['0', '0', '255']),
///   ],
///   properties: [
///     Property(Final: true, type: 'int', name: 'r'),
///     Property(Final: true, type: 'int', name: 'g'),
///     Property(Final: true, type: 'int', name: 'b'),
///   ],
///   constructors: [
///     Constructor(
///       Const: true,
///       className: 'Color',
///       parameters: [
///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'r'),
///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'g'),
///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'b'),
///       ],
///     ),
///   ],
/// )
/// // Generates:
/// // enum Color {
/// //   red(255, 0, 0),
/// //   green(0, 255, 0),
/// //   blue(0, 0, 255);
/// //
/// //   const Color(this.r, this.g, this.b);
/// //   final int r;
/// //   final int g;
/// //   final int b;
/// // }
/// ```
///
/// Enum with interfaces and methods:
/// ```dart
/// Enum(
///   name: 'Vehicle',
///   implementations: ['Comparable<Vehicle>'],
///   constants: [
///     EnumConstant(name: 'car', arguments: ['2', '4']),
///     EnumConstant(name: 'bicycle', arguments: ['0', '2']),
///   ],
///   properties: [
///     Property(Final: true, type: 'int', name: 'engines'),
///     Property(Final: true, type: 'int', name: 'wheels'),
///   ],
///   constructors: [
///     Constructor(
///       Const: true,
///       className: 'Vehicle',
///       parameters: [
///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'engines'),
///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'wheels'),
///       ],
///     ),
///   ],
///   methods: [
///     Method(
///       override: true,
///       returnType: 'int',
///       name: 'compareTo',
///       parameters: [MethodParameter(type: 'Vehicle', name: 'other')],
///       body: (b) => b.write('return wheels.compareTo(other.wheels);'),
///     ),
///   ],
/// )
/// ```
class Enum extends PublicBufferWritable {
  // ============================================================================
  // METADATA
  // ============================================================================

  /// The documentation comment for this enum.
  ///
  /// Should be a multi-line string with `///` prefix for each line, following
  /// Dart documentation conventions. This appears directly above the enum
  /// declaration and is used to generate API documentation.
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   docComment: '''
  /// /// Represents the status of an operation.
  /// ///
  /// /// This enum contains all possible status values.
  /// ''',
  ///   name: 'Status',
  ///   constants: [EnumConstant(name: 'pending')],
  /// )
  /// ```
  final String? docComment;

  /// A list of metadata annotations to be applied to this enum.
  ///
  /// Annotations are prefixed with `@` and appear before the enum declaration.
  /// Common examples include:
  /// - `@deprecated` - marks this enum as deprecated
  /// - `@immutable` - indicates this enum is immutable (enums are implicitly immutable)
  /// - Custom annotations from your codebase
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   annotations: ['@deprecated'],
  ///   name: 'OldStatus',
  ///   constants: [EnumConstant(name: 'active')],
  /// )
  /// // Generates:
  /// // @deprecated
  /// // enum OldStatus { active }
  /// ```
  final List<String> annotations;

  // ============================================================================
  // DECLARATION
  // ============================================================================

  /// The name of the enum.
  ///
  /// This is the identifier used to reference the enum throughout the code.
  final String name;

  /// The list of enum constant declarations.
  ///
  /// Every enum must have at least one constant. Constants can be simple
  /// (just a name) or enhanced (with constructor arguments).
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   name: 'Status',
  ///   constants: [
  ///     EnumConstant(name: 'pending'),
  ///     EnumConstant(name: 'active'),
  ///     EnumConstant(name: 'completed'),
  ///   ],
  /// )
  /// // Generates: enum Status { pending, active, completed }
  /// ```
  final List<EnumConstant> constants;

  // ============================================================================
  // INHERITANCE
  // ============================================================================

  /// The list of mixins applied to this enum using the `with` clause.
  ///
  /// Mixins add functionality to this enum without using inheritance.
  /// They are applied in order from left to right.
  ///
  /// **Note:** Enums cannot extend other classes (they implicitly extend `Enum`).
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   name: 'Status',
  ///   mixins: ['JsonSerializable'],
  ///   constants: [EnumConstant(name: 'pending')],
  /// )
  /// // Generates: enum Status with JsonSerializable { pending }
  /// ```
  final List<String> mixins;

  /// The list of interfaces this enum implements using the `implements` clause.
  ///
  /// Implementing an interface creates a contract that this enum must fulfill
  /// by providing implementations for all interface members.
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   name: 'Priority',
  ///   implementations: ['Comparable<Priority>'],
  ///   constants: [EnumConstant(name: 'low'), EnumConstant(name: 'high')],
  ///   methods: [
  ///     Method(
  ///       override: true,
  ///       returnType: 'int',
  ///       name: 'compareTo',
  ///       parameters: [MethodParameter(type: 'Priority', name: 'other')],
  ///       body: (b) => b.write('return index.compareTo(other.index);'),
  ///     ),
  ///   ],
  /// )
  /// // Generates: enum Priority implements Comparable<Priority> { low, high; ... }
  /// ```
  final List<String> implementations;

  // ============================================================================
  // MEMBERS
  // ============================================================================

  /// The list of field/property declarations in this enum.
  ///
  /// Enum properties are typically final and initialized through the constructor.
  /// Static properties are also supported.
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   name: 'Planet',
  ///   constants: [
  ///     EnumConstant(name: 'earth', arguments: ['5.97e24', '6371']),
  ///   ],
  ///   properties: [
  ///     Property(Final: true, type: 'double', name: 'mass'),
  ///     Property(Final: true, type: 'double', name: 'radius'),
  ///   ],
  ///   constructors: [
  ///     Constructor(
  ///       Const: true,
  ///       className: 'Planet',
  ///       parameters: [
  ///         ConstructorParameter(fieldFormal: true, type: 'double', name: 'mass'),
  ///         ConstructorParameter(fieldFormal: true, type: 'double', name: 'radius'),
  ///       ],
  ///     ),
  ///   ],
  /// )
  /// ```
  final List<Property> properties;

  /// The list of getter methods in this enum.
  ///
  /// Getters provide computed properties or controlled access to internal state.
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   name: 'Size',
  ///   constants: [
  ///     EnumConstant(name: 'small', arguments: ['1']),
  ///     EnumConstant(name: 'large', arguments: ['10']),
  ///   ],
  ///   properties: [Property(Final: true, type: 'int', name: 'value')],
  ///   constructors: [
  ///     Constructor(
  ///       Const: true,
  ///       className: 'Size',
  ///       parameters: [ConstructorParameter(fieldFormal: true, type: 'int', name: 'value')],
  ///     ),
  ///   ],
  ///   getters: [
  ///     Getter(
  ///       returnType: 'bool',
  ///       name: 'isSmall',
  ///       body: (b) => b.write('value < 5'),
  ///     ),
  ///   ],
  /// )
  /// ```
  final List<Getter> getters;

  /// The list of setter methods in this enum.
  ///
  /// Setters provide controlled modification of mutable state.
  /// Note that enum instance fields are typically final.
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   name: 'Config',
  ///   constants: [EnumConstant(name: 'debug'), EnumConstant(name: 'release')],
  ///   properties: [Property(static: true, type: 'bool', name: '_verbose')],
  ///   setters: [
  ///     Setter(
  ///       static: true,
  ///       name: 'verbose',
  ///       parameterType: 'bool',
  ///       body: (b) => b.write('_verbose = verbose;'),
  ///     ),
  ///   ],
  /// )
  /// ```
  final List<Setter> setters;

  /// The list of constructors in this enum.
  ///
  /// **Important constraints for enum constructors:**
  /// - All enum constructors MUST be `const`
  /// - Enum constructors cannot be `factory` constructors
  /// - If any constant has arguments, a matching constructor must be defined
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   name: 'Color',
  ///   constants: [
  ///     EnumConstant(name: 'red', arguments: ['255', '0', '0']),
  ///   ],
  ///   properties: [
  ///     Property(Final: true, type: 'int', name: 'r'),
  ///     Property(Final: true, type: 'int', name: 'g'),
  ///     Property(Final: true, type: 'int', name: 'b'),
  ///   ],
  ///   constructors: [
  ///     Constructor(
  ///       Const: true,
  ///       className: 'Color',
  ///       parameters: [
  ///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'r'),
  ///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'g'),
  ///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'b'),
  ///       ],
  ///     ),
  ///   ],
  /// )
  /// ```
  final List<Constructor> constructors;

  /// The list of methods in this enum.
  ///
  /// Methods can be instance or static, synchronous or asynchronous, and may be generators.
  ///
  /// **Example:**
  /// ```dart
  /// Enum(
  ///   name: 'Operation',
  ///   constants: [
  ///     EnumConstant(name: 'add'),
  ///     EnumConstant(name: 'subtract'),
  ///   ],
  ///   methods: [
  ///     Method(
  ///       returnType: 'int',
  ///       name: 'apply',
  ///       parameters: [
  ///         MethodParameter(type: 'int', name: 'a'),
  ///         MethodParameter(type: 'int', name: 'b'),
  ///       ],
  ///       body: (b) => b.write('''
  ///         switch (this) {
  ///           case Operation.add: return a + b;
  ///           case Operation.subtract: return a - b;
  ///         }
  ///       '''),
  ///     ),
  ///   ],
  /// )
  /// ```
  final List<Method> methods;

  /// Creates a new enum declaration.
  ///
  /// All list parameters default to empty lists if not provided, except [constants]
  /// which is required and must have at least one element.
  ///
  /// **Validation Rules:**
  ///
  /// The constructor enforces several validation rules via assertions:
  ///
  /// 1. **Constants Validation:**
  ///    - Must have at least one constant
  ///
  /// 2. **Constructor Validation:**
  ///    - All constructors must be `const` (enum constructors cannot be non-const)
  ///    - Enum constructors cannot be factory constructors
  ///    - If any constant has arguments, at least one constructor must be defined
  ///
  /// 3. **Inheritance Validation:**
  ///    - Enums cannot extend other classes (they implicitly extend `Enum`)
  ///    - Cannot mix in the same interface being implemented
  ///
  /// 4. **Mixin Validation:**
  ///    - Cannot implement the same class that's being mixed in
  ///
  /// **Examples:**
  ///
  /// ```dart
  /// // Simple enum
  /// Enum(
  ///   name: 'Status',
  ///   constants: [
  ///     EnumConstant(name: 'pending'),
  ///     EnumConstant(name: 'active'),
  ///   ],
  /// )
  ///
  /// // Enhanced enum with constructor
  /// Enum(
  ///   name: 'Color',
  ///   constants: [
  ///     EnumConstant(name: 'red', arguments: ['255', '0', '0']),
  ///   ],
  ///   properties: [
  ///     Property(Final: true, type: 'int', name: 'r'),
  ///     Property(Final: true, type: 'int', name: 'g'),
  ///     Property(Final: true, type: 'int', name: 'b'),
  ///   ],
  ///   constructors: [
  ///     Constructor(
  ///       Const: true,
  ///       className: 'Color',
  ///       parameters: [
  ///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'r'),
  ///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'g'),
  ///         ConstructorParameter(fieldFormal: true, type: 'int', name: 'b'),
  ///       ],
  ///     ),
  ///   ],
  /// )
  /// ```
  ///
  /// **Parameters:**
  ///
  /// - [docComment]: Documentation comment for the enum
  /// - [annotations]: Metadata annotations
  /// - [name]: The enum name (required)
  /// - [constants]: Enum constant declarations (required, must have at least one)
  /// - [mixins]: Mixins to apply
  /// - [implementations]: Interfaces to implement
  /// - [properties]: Field declarations
  /// - [getters]: Getter methods
  /// - [setters]: Setter methods
  /// - [constructors]: Constructor declarations (must be const)
  /// - [methods]: Method declarations
  Enum({
    this.docComment,
    List<String>? annotations,
    required this.name,
    required this.constants,
    List<String>? mixins,
    List<String>? implementations,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Constructor>? constructors,
    List<Method>? methods,
  })  : annotations = annotations ?? [],
        mixins = mixins ?? [],
        implementations = implementations ?? [],
        properties = properties ?? [],
        getters = getters ?? [],
        setters = setters ?? [],
        constructors = constructors ?? [],
        methods = methods ?? [] {
    // Validate constants
    assert(constants.isNotEmpty, 'Enum "$name": must declare at least one constant');

    // Validate constructors
    assert(
      this.constructors.every((c) => c.Const),
      'Enum "$name": all constructors must be const',
    );
    assert(
      this.constructors.every((c) => !c.factory),
      'Enum "$name": enum constructors cannot be factory constructors',
    );

    // If any constant has arguments, we need at least one constructor
    final hasConstantsWithArgs = constants.any((c) => c.arguments != null && c.arguments!.isNotEmpty);
    assert(
      !hasConstantsWithArgs || this.constructors.isNotEmpty,
      'Enum "$name": has constants with arguments but no constructor defined',
    );

    // Validate mixin/implementation relationships
    assert(
      this.mixins.every((mixin) => !this.implementations.contains(mixin)),
      'Enum "$name": cannot implement the same class it mixes in',
    );
    assert(
      this.implementations.every((impl) => !this.mixins.contains(impl)),
      'Enum "$name": cannot mix in the same class it implements',
    );
  }

  /// Creates an [Enum] instance from an analyzer [EnumElement].
  ///
  /// This static factory method extracts all enum information from the analyzer's
  /// representation of a Dart enum, including constants, mixins, interfaces, and all members.
  ///
  /// **Extraction Logic:**
  ///
  /// - **Constants:** Extracts constant names and constructor arguments (if any)
  /// - **Mixins:** Extracts all applied mixins
  /// - **Interfaces:** Extracts all implemented interfaces
  /// - **Members:** Asynchronously converts all fields, accessors, constructors, and methods
  ///
  /// **Parameters:**
  ///
  /// - [enumElement]: The analyzer's representation of the enum
  /// - [buildStep]: The build step providing access to resolution and AST nodes
  ///
  /// **Returns:**
  ///
  /// An [Enum] instance representing the complete enum declaration.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// // In a Builder
  /// final libraryElement = await buildStep.inputLibrary;
  /// for (final element in libraryElement.topLevelElements) {
  ///   if (element is EnumElement) {
  ///     final enumDeclaration = await Enum.from(element, buildStep);
  ///     // Use enumDeclaration...
  ///   }
  /// }
  /// ```
  static Future<Enum> from(
    EnumElement enumElement,
    BuildStep buildStep,
  ) async {
    EnumDeclaration astNode = await buildStep.resolver.astNodeFor(enumElement) as EnumDeclaration;

    // Extract constants with their arguments
    List<EnumConstant> constants = astNode.constants.map((constantDecl) {
      String constantName = constantDecl.name.lexeme;
      List<String>? arguments;

      // Check if the constant has constructor arguments
      if (constantDecl.arguments != null) {
        arguments = constantDecl.arguments!.argumentList.arguments.map((arg) => arg.toString()).toList();
      }

      return EnumConstant(
        name: constantName,
        arguments: arguments,
      );
    }).toList();

    return Enum(
      docComment: enumElement.documentationComment,
      annotations: enumElement.metadata.map((e) => e.toSource()).toList(),
      name: enumElement.name,
      constants: constants,
      mixins: enumElement.mixins.map((e) => e.element.name).toList(),
      implementations: enumElement.interfaces.map((e) => e.element.name).toList(),
      properties: await enumElement.fields
          .where((f) => !f.isEnumConstant) // Exclude the enum constants themselves
          .toList()
          .mapAsync((e) => Property.from(e, buildStep)),
      getters: await enumElement.accessors.where((e) => e.isGetter).toList().mapAsync((e) => Getter.from(e, buildStep)),
      setters: await enumElement.accessors.where((e) => e.isSetter).toList().mapAsync((e) => Setter.from(e, buildStep)),
      constructors:
          await enumElement.constructors.mapAsync<Constructor>((e) async => await Constructor.from(e, buildStep)),
      methods: await enumElement.methods.mapAsync((e) => Method.from(e, buildStep)),
    );
  }

  /// Creates a copy of this enum with the specified properties replaced.
  ///
  /// This method creates a new [Enum] instance with the same values as the current
  /// instance, except for the properties explicitly provided as parameters.
  /// Properties not provided will retain their current values.
  ///
  /// **Usage:**
  ///
  /// This is useful when you need to create a variation of an existing enum
  /// or when building enums incrementally.
  ///
  /// **Parameters:**
  ///
  /// All parameters are optional. When a parameter is provided (non-null), it replaces
  /// the corresponding property in the new instance. When null, the original value is preserved.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final basicEnum = Enum(
  ///   name: 'Status',
  ///   constants: [EnumConstant(name: 'active')],
  /// );
  ///
  /// // Add implementations
  /// final comparableEnum = basicEnum.copyWith(
  ///   implementations: ['Comparable<Status>'],
  ///   methods: [
  ///     Method(
  ///       override: true,
  ///       returnType: 'int',
  ///       name: 'compareTo',
  ///       parameters: [MethodParameter(type: 'Status', name: 'other')],
  ///       body: (b) => b.write('return index.compareTo(other.index);'),
  ///     ),
  ///   ],
  /// );
  /// ```
  ///
  /// **Returns:**
  ///
  /// A new [Enum] instance with the specified properties replaced.
  Enum copyWith({
    String? docComment,
    List<String>? annotations,
    String? name,
    List<EnumConstant>? constants,
    List<String>? mixins,
    List<String>? implementations,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Constructor>? constructors,
    List<Method>? methods,
  }) =>
      Enum(
        docComment: docComment ?? this.docComment,
        annotations: annotations ?? this.annotations,
        name: name ?? this.name,
        constants: constants ?? this.constants,
        mixins: mixins ?? this.mixins,
        implementations: implementations ?? this.implementations,
        properties: properties ?? this.properties,
        getters: getters ?? this.getters,
        setters: setters ?? this.setters,
        constructors: constructors ?? this.constructors,
        methods: methods ?? this.methods,
      );

  /// Writes the Dart source code representation of this enum to the provided [StringBuffer].
  ///
  /// This is an internal method used by the [PublicBufferWritable] interface to generate
  /// the actual Dart code. It writes the complete enum declaration including all constants,
  /// mixins, interfaces, and members.
  ///
  /// **Output Format:**
  ///
  /// The method follows the standard Dart enum declaration syntax:
  /// ```
  /// enum Name [with Mixins] [implements Interfaces] {
  ///   constant1[(args)],
  ///   constant2[(args)][;]
  ///   [members]
  /// }
  /// ```
  ///
  /// **Writing Order:**
  ///
  /// 1. **Enum keyword and name**: `enum Name`
  ///
  /// 2. **Inheritance clauses** (in order):
  ///    - `with Mixin1, Mixin2` (if mixins list is not empty)
  ///    - `implements Interface1, Interface2` (if implementations list is not empty)
  ///
  /// 3. **Constants**: Comma-separated list of enum constants
  ///    - Constants with arguments: `constantName(arg1, arg2)`
  ///    - Simple constants: `constantName`
  ///    - Followed by semicolon (`;`) if enum has members
  ///
  /// 4. **Body** (members in order, only if present):
  ///    - Properties
  ///    - Getters
  ///    - Setters
  ///    - Constructors
  ///    - Methods
  ///
  /// **Example Outputs:**
  ///
  /// ```dart
  /// // Simple enum
  /// enum Color { red, green, blue }
  ///
  /// // Enhanced enum with constructor
  /// enum Color {
  ///   red(255, 0, 0),
  ///   green(0, 255, 0),
  ///   blue(0, 0, 255);
  ///
  ///   const Color(this.r, this.g, this.b);
  ///   final int r;
  ///   final int g;
  ///   final int b;
  /// }
  ///
  /// // Enum with interfaces
  /// enum Priority implements Comparable<Priority> {
  ///   low,
  ///   high;
  ///
  ///   int compareTo(Priority other) { return index.compareTo(other.index); }
  /// }
  ///
  /// // Enum with mixins
  /// enum Status with JsonSerializable { pending, active }
  /// ```
  ///
  /// **Parameters:**
  ///
  /// - [b]: The StringBuffer to write the enum declaration into
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment
    if (docComment != null && docComment!.isNotEmpty) {
      b.write('$docComment\n');
    }

    // Write annotations
    for (final annotation in annotations) {
      b.write('$annotation ');
    }

    b.write('enum $name');

    // Write inheritance clauses
    if (mixins.isNotEmpty) b.write(' with ${mixins.join(', ')}');
    if (implementations.isNotEmpty) b.write(' implements ${implementations.join(', ')}');

    b.write(' {');

    // Write enum constants
    for (int i = 0; i < constants.length; i++) {
      constants[i]._writeToBuffer(b);
      if (i < constants.length - 1) {
        b.write(', ');
      }
    }

    // Determine if we have any members
    final hasMembers = properties.isNotEmpty ||
        getters.isNotEmpty ||
        setters.isNotEmpty ||
        constructors.isNotEmpty ||
        methods.isNotEmpty;

    // Add semicolon after constants if there are members
    if (hasMembers) {
      b.write(';');

      // Write members
      [
        ...properties,
        ...getters,
        ...setters,
        ...constructors,
        ...methods,
      ]._writeToBuffer(b);
    }

    b.write('}');
  }
}
