part of dart_source_builder;

/// Represents a Dart mixin declaration with full support for all mixin features.
///
/// This class provides a complete representation of Dart mixins, supporting:
/// - Simple mixins and enhanced mixins with members
/// - Base modifier (`base mixin`)
/// - Generic type parameters with bounds
/// - Superclass constraints (`on` clause)
/// - Interface implementations (`implements` clause)
/// - All member types (properties, getters, setters, methods)
/// - Documentation comments and annotations
///
/// **Examples:**
///
/// Simple mixin:
/// ```dart
/// Mixin(
///   name: 'Flyable',
///   methods: [
///     Method(name: 'fly', body: (b) => b.write('print("Flying!");')),
///   ],
/// )
/// // Generates: mixin Flyable { void fly() { print("Flying!"); } }
/// ```
///
/// Mixin with constraints:
/// ```dart
/// Mixin(
///   name: 'Swimmer',
///   on: ['Animal'],
///   methods: [
///     Method(name: 'swim', body: (b) => b.write('print("Swimming!");')),
///   ],
/// )
/// // Generates: mixin Swimmer on Animal { void swim() { print("Swimming!"); } }
/// ```
///
/// Generic mixin:
/// ```dart
/// Mixin(
///   name: 'Comparable',
///   typeParameters: [TypeParameter('T')],
///   methods: [
///     Method(
///       returnType: 'bool',
///       name: 'isGreaterThan',
///       parameters: [MethodParameter(type: 'T', name: 'other')],
///       body: (b) => b.write('// implementation'),
///     ),
///   ],
/// )
/// // Generates: mixin Comparable<T> { bool isGreaterThan(T other) { // implementation } }
/// ```
///
/// Base mixin with interfaces:
/// ```dart
/// Mixin(
///   base: true,
///   name: 'JsonSerializable',
///   implementations: ['Serializable'],
///   methods: [
///     Method(
///       override: true,
///       returnType: 'String',
///       name: 'toJson',
///       body: (b) => b.write('return "{}";'),
///     ),
///   ],
/// )
/// // Generates: base mixin JsonSerializable implements Serializable { @override String toJson() { return "{}"; } }
/// ```
class Mixin extends PublicBufferWritable {
  // ============================================================================
  // METADATA
  // ============================================================================

  /// The documentation comment for this mixin.
  ///
  /// Should be a multi-line string with `///` prefix for each line, following
  /// Dart documentation conventions. This appears directly above the mixin
  /// declaration and is used to generate API documentation.
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(
  ///   docComment: '''
  /// /// A mixin that provides flying capabilities.
  /// ///
  /// /// Classes using this mixin can fly.
  /// ''',
  ///   name: 'Flyable',
  /// )
  /// ```
  final String? docComment;

  /// A list of metadata annotations to be applied to this mixin.
  ///
  /// Annotations are prefixed with `@` and appear before the mixin declaration.
  /// Common examples include:
  /// - `@deprecated` - marks this mixin as deprecated
  /// - `@experimental` - marks this mixin as experimental
  /// - Custom annotations from your codebase
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(
  ///   annotations: ['@deprecated', '@experimental'],
  ///   name: 'OldMixin',
  /// )
  /// // Generates:
  /// // @deprecated
  /// // @experimental
  /// // mixin OldMixin { }
  /// ```
  final List<String> annotations;

  // ============================================================================
  // MODIFIERS
  // ============================================================================

  /// Whether this is a base mixin.
  ///
  /// Base mixins (introduced in Dart 3.0) can only be mixed in within the same
  /// library, preventing external code from mixing it in.
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(base: true, name: 'InternalMixin')
  /// // Generates: base mixin InternalMixin { }
  /// ```
  final bool base;

  // ============================================================================
  // DECLARATION
  // ============================================================================

  /// The name of the mixin.
  ///
  /// This is the identifier used to reference the mixin throughout the code.
  final String name;

  /// The generic type parameters for this mixin, if any.
  ///
  /// When null or empty, the mixin is not generic. When provided, each
  /// [TypeParameter] represents a type variable with an optional upper bound.
  ///
  /// **Examples:**
  /// ```dart
  /// // Generic mixin with one parameter
  /// Mixin(
  ///   name: 'Container',
  ///   typeParameters: [TypeParameter('T')],
  /// )
  /// // Generates: mixin Container<T> { }
  ///
  /// // Generic mixin with bounded parameter
  /// Mixin(
  ///   name: 'NumericMixin',
  ///   typeParameters: [TypeParameter('T', 'num')],
  /// )
  /// // Generates: mixin NumericMixin<T extends num> { }
  /// ```
  final List<TypeParameter>? typeParameters;

  // ============================================================================
  // INHERITANCE
  // ============================================================================

  /// The list of superclass constraints for this mixin using the `on` clause.
  ///
  /// The `on` clause specifies which types this mixin can be applied to.
  /// A class must extend or implement all types in the `on` clause to use this mixin.
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(
  ///   name: 'Swimmer',
  ///   on: ['Animal', 'LivingThing'],
  ///   methods: [Method(name: 'swim', body: (b) => b.write('...'))],
  /// )
  /// // Generates: mixin Swimmer on Animal, LivingThing { void swim() { ... } }
  /// ```
  final List<String> on;

  /// The list of interfaces this mixin implements using the `implements` clause.
  ///
  /// Implementing an interface creates a contract that this mixin must fulfill
  /// by providing implementations for all interface members.
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(
  ///   name: 'JsonMixin',
  ///   implementations: ['Serializable'],
  ///   methods: [
  ///     Method(
  ///       override: true,
  ///       returnType: 'String',
  ///       name: 'toJson',
  ///       body: (b) => b.write('return "{}";'),
  ///     ),
  ///   ],
  /// )
  /// // Generates: mixin JsonMixin implements Serializable { @override String toJson() { return "{}"; } }
  /// ```
  final List<String> implementations;

  // ============================================================================
  // MEMBERS
  // ============================================================================

  /// The list of field/property declarations in this mixin.
  ///
  /// Properties can be instance or static, final or const, and may have default values.
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(
  ///   name: 'Timestamped',
  ///   properties: [
  ///     Property(type: 'DateTime', name: 'timestamp'),
  ///   ],
  /// )
  /// // Generates: mixin Timestamped { DateTime timestamp; }
  /// ```
  final List<Property> properties;

  /// The list of getter methods in this mixin.
  ///
  /// Getters provide computed properties or controlled access to internal state.
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(
  ///   name: 'Describable',
  ///   getters: [
  ///     Getter(
  ///       returnType: 'String',
  ///       name: 'description',
  ///       body: (b) => b.write('"A describable object"'),
  ///     ),
  ///   ],
  /// )
  /// // Generates: mixin Describable { String get description => "A describable object"; }
  /// ```
  final List<Getter> getters;

  /// The list of setter methods in this mixin.
  ///
  /// Setters provide controlled modification of internal state.
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(
  ///   name: 'Updatable',
  ///   setters: [
  ///     Setter(
  ///       name: 'value',
  ///       parameterType: 'String',
  ///       body: (b) => b.write('_value = value;'),
  ///     ),
  ///   ],
  /// )
  /// // Generates: mixin Updatable { set value(String value) { _value = value; } }
  /// ```
  final List<Setter> setters;

  /// The list of methods in this mixin.
  ///
  /// Methods can be instance or static, synchronous or asynchronous, and may be generators.
  ///
  /// **Example:**
  /// ```dart
  /// Mixin(
  ///   name: 'Logger',
  ///   methods: [
  ///     Method(
  ///       returnType: 'void',
  ///       name: 'log',
  ///       parameters: [MethodParameter(type: 'String', name: 'message')],
  ///       body: (b) => b.write('print(message);'),
  ///     ),
  ///   ],
  /// )
  /// // Generates: mixin Logger { void log(String message) { print(message); } }
  /// ```
  final List<Method> methods;

  /// Creates a new mixin declaration.
  ///
  /// All list parameters default to empty lists if not provided.
  ///
  /// **Validation Rules:**
  ///
  /// The constructor enforces several validation rules via assertions:
  ///
  /// 1. **Constraint/Implementation Validation:**
  ///    - Cannot have the same type in both `on` and `implementations`
  ///    - A type can only appear once in `on`
  ///    - A type can only appear once in `implementations`
  ///
  /// **Examples:**
  ///
  /// ```dart
  /// // Simple mixin
  /// Mixin(name: 'Flyable')
  ///
  /// // Mixin with constraints
  /// Mixin(
  ///   name: 'Swimmer',
  ///   on: ['Animal'],
  ///   methods: [Method(name: 'swim', body: (b) => b.write('...'))],
  /// )
  ///
  /// // Base mixin with generics
  /// Mixin(
  ///   base: true,
  ///   name: 'Comparable',
  ///   typeParameters: [TypeParameter('T')],
  ///   implementations: ['Comparison<T>'],
  /// )
  /// ```
  ///
  /// **Parameters:**
  ///
  /// - [docComment]: Documentation comment for the mixin
  /// - [annotations]: Metadata annotations
  /// - [base]: Whether this is a base mixin (default: false)
  /// - [name]: The mixin name (required)
  /// - [typeParameters]: Generic type parameters
  /// - [on]: Superclass constraints
  /// - [implementations]: Interfaces to implement
  /// - [properties]: Field declarations
  /// - [getters]: Getter methods
  /// - [setters]: Setter methods
  /// - [methods]: Method declarations
  Mixin({
    this.docComment,
    List<String>? annotations,
    this.base = false,
    required this.name,
    this.typeParameters,
    List<String>? on,
    List<String>? implementations,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Method>? methods,
  })  : annotations = annotations ?? [],
        on = on ?? [],
        implementations = implementations ?? [],
        properties = properties ?? [],
        getters = getters ?? [],
        setters = setters ?? [],
        methods = methods ?? [] {
    // Validate on/implementation relationships
    assert(
      this.on.every((constraint) => !this.implementations.contains(constraint)),
      'Mixin "$name": cannot have the same type in both "on" and "implements" clauses',
    );
    assert(
      this.implementations.every((impl) => !this.on.contains(impl)),
      'Mixin "$name": cannot have the same type in both "implements" and "on" clauses',
    );

    // Validate no duplicates in constraints
    assert(
      this.on.length == this.on.toSet().length,
      'Mixin "$name": duplicate types in "on" clause',
    );

    // Validate no duplicates in implementations
    assert(
      this.implementations.length == this.implementations.toSet().length,
      'Mixin "$name": duplicate types in "implements" clause',
    );
  }

  /// Creates a [Mixin] instance from an analyzer [MixinElement].
  ///
  /// This static factory method extracts all mixin information from the analyzer's
  /// representation of a Dart mixin, including modifiers, type parameters,
  /// constraints, implementations, and all members.
  ///
  /// **Extraction Logic:**
  ///
  /// - **Modifiers:** Detects `base` modifier
  /// - **Type Parameters:** Extracts generic type parameters with their bounds
  /// - **Constraints:** Extracts superclass constraints from the `on` clause
  /// - **Implementations:** Extracts interface implementations
  /// - **Members:** Asynchronously converts all fields, accessors, and methods
  ///
  /// **Parameters:**
  ///
  /// - [mixinElement]: The analyzer's representation of the mixin
  /// - [buildStep]: The build step providing access to resolution and AST nodes
  ///
  /// **Returns:**
  ///
  /// A [Mixin] instance representing the complete mixin declaration.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// // In a Builder
  /// final libraryElement = await buildStep.inputLibrary;
  /// for (final element in libraryElement.topLevelElements) {
  ///   if (element is MixinElement) {
  ///     final mixinDeclaration = await Mixin.from(element, buildStep);
  ///     // Use mixinDeclaration...
  ///   }
  /// }
  /// ```
  static Future<Mixin> from(
    MixinElement mixinElement,
    BuildStep buildStep,
  ) async {
    return Mixin(
      docComment: mixinElement.documentationComment,
      annotations: mixinElement.metadata.map((e) => e.toSource()).toList(),
      base: mixinElement.isBase,
      name: mixinElement.name,
      typeParameters: mixinElement.typeParameters.isEmpty
          ? null
          : mixinElement.typeParameters.map((tp) {
              String? bound = tp.bound != null ? tp.bound.toString() : null;
              return TypeParameter(tp.name, bound);
            }).toList(),
      on: mixinElement.superclassConstraints.map((e) => e.element.name).toList(),
      implementations: mixinElement.interfaces.map((e) => e.element.name).toList(),
      properties: await mixinElement.fields.mapAsync((e) => Property.from(e, buildStep)),
      getters:
          await mixinElement.accessors.where((e) => e.isGetter).toList().mapAsync((e) => Getter.from(e, buildStep)),
      setters:
          await mixinElement.accessors.where((e) => e.isSetter).toList().mapAsync((e) => Setter.from(e, buildStep)),
      methods: await mixinElement.methods.mapAsync((e) => Method.from(e, buildStep)),
    );
  }

  /// Creates a copy of this mixin with the specified properties replaced.
  ///
  /// This method creates a new [Mixin] instance with the same values as the current
  /// instance, except for the properties explicitly provided as parameters.
  /// Properties not provided will retain their current values.
  ///
  /// **Usage:**
  ///
  /// This is useful when you need to create a variation of an existing mixin
  /// or when building mixins incrementally.
  ///
  /// **Parameters:**
  ///
  /// All parameters are optional. When a parameter is provided (non-null), it replaces
  /// the corresponding property in the new instance. When null, the original value is preserved.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final baseMixin = Mixin(
  ///   name: 'Loggable',
  ///   methods: [Method(name: 'log', body: (b) => b.write('...'))],
  /// );
  ///
  /// // Make it a base mixin
  /// final restrictedMixin = baseMixin.copyWith(base: true);
  /// // Result: base mixin Loggable { ... }
  ///
  /// // Add constraints
  /// final constrainedMixin = baseMixin.copyWith(on: ['Object']);
  /// // Result: mixin Loggable on Object { ... }
  /// ```
  ///
  /// **Returns:**
  ///
  /// A new [Mixin] instance with the specified properties replaced.
  Mixin copyWith({
    String? docComment,
    List<String>? annotations,
    bool? base,
    String? name,
    List<TypeParameter>? typeParameters,
    List<String>? on,
    List<String>? implementations,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Method>? methods,
  }) =>
      Mixin(
        docComment: docComment ?? this.docComment,
        annotations: annotations ?? this.annotations,
        base: base ?? this.base,
        name: name ?? this.name,
        typeParameters: typeParameters ?? this.typeParameters,
        on: on ?? this.on,
        implementations: implementations ?? this.implementations,
        properties: properties ?? this.properties,
        getters: getters ?? this.getters,
        setters: setters ?? this.setters,
        methods: methods ?? this.methods,
      );

  /// Writes the Dart source code representation of this mixin to the provided [StringBuffer].
  ///
  /// This is an internal method used by the [PublicBufferWritable] interface to generate
  /// the actual Dart code. It writes the complete mixin declaration including all modifiers,
  /// type parameters, constraints, implementations, and members.
  ///
  /// **Output Format:**
  ///
  /// The method follows the standard Dart mixin declaration syntax:
  /// ```
  /// [docComment]
  /// [annotations]
  /// [base] mixin Name[<TypeParams>] [on Constraints] [implements Interfaces] {
  ///   [members]
  /// }
  /// ```
  ///
  /// **Writing Order:**
  ///
  /// 1. **Documentation Comment** (if present)
  ///
  /// 2. **Annotations** (if any): Each on its own line
  ///
  /// 3. **Modifiers**:
  ///    - `base` (if true)
  ///
  /// 4. **Mixin keyword and name**: `mixin Name`
  ///
  /// 5. **Type parameters**: `<T, E extends List>` (if any)
  ///
  /// 6. **Inheritance clauses** (in order):
  ///    - `on Constraint1, Constraint2` (if on list is not empty)
  ///    - `implements Interface1, Interface2` (if implementations list is not empty)
  ///
  /// 7. **Body** (members in order):
  ///    - Properties
  ///    - Getters
  ///    - Setters
  ///    - Methods
  ///
  /// **Example Outputs:**
  ///
  /// ```dart
  /// // Simple mixin
  /// mixin Flyable { }
  ///
  /// // Mixin with constraints
  /// mixin Swimmer on Animal { }
  ///
  /// // Base mixin with generics
  /// base mixin Comparable<T> { }
  ///
  /// // Mixin with full features
  /// /// A mixin for serialization.
  /// @experimental
  /// mixin JsonSerializable implements Serializable {
  ///   String toJson() { return "{}"; }
  /// }
  ///
  /// // Generic mixin with constraints and interfaces
  /// mixin Comparable<T extends num> on Object implements Comparison<T> { }
  /// ```
  ///
  /// **Parameters:**
  ///
  /// - [b]: The StringBuffer to write the mixin declaration into
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment
    if (docComment != null && docComment!.isNotEmpty) {
      b.write(docComment);
    }

    // Write annotations
    for (final annotation in annotations) {
      b.write('$annotation ');
    }

    // Write modifiers
    if (base) b.write('base ');

    b.write('mixin $name');

    // Write type parameters
    if (typeParameters != null && typeParameters!.isNotEmpty) {
      b.write('<');
      b.write(typeParameters!.map((tp) => tp.toString()).join(', '));
      b.write('>');
    }

    b.write(' ');

    // Write inheritance clauses
    if (on.isNotEmpty) b.write('on ${on.join(', ')} ');
    if (implementations.isNotEmpty) b.write('implements ${implementations.join(', ')} ');

    b.write('{');
    [
      ...properties,
      ...getters,
      ...setters,
      ...methods,
    ]._writeToBuffer(b);
    b.write('}');
  }
}
