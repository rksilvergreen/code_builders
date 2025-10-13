part of dart_source_builder;

/// Enum representing the primary class modifiers introduced in Dart 3.0.
///
/// These modifiers control how classes can be extended, implemented, and mixed in.
/// Only ONE of these modifiers can be applied to a class (they are mutually exclusive),
/// though they can be combined with the [abstract] modifier.
///
/// **Valid Modifier Order:**
/// ```dart
/// [abstract] [base|interface|final|sealed] [mixin] class Name
/// ```
///
/// **Valid Combinations:**
/// - `abstract base`
/// - `abstract interface`
/// - `abstract final`
/// - `base mixin`
///
/// **Invalid Combinations:**
/// - `abstract sealed` (redundant - sealed is implicitly abstract)
/// - `interface mixin` / `final mixin` / `sealed mixin`
///
/// See: https://dart.dev/language/class-modifiers
enum ClassModifier {
  /// The `base` modifier prevents classes from being implemented outside their library.
  ///
  /// A base class can be:
  /// - Extended within or outside its library
  /// - Mixed in (if it's also a mixin class)
  ///
  /// But CANNOT be:
  /// - Implemented outside its library
  ///
  /// Example:
  /// ```dart
  /// base class Vehicle {
  ///   void moveForward(int meters) { }
  /// }
  /// ```
  base,

  /// The `interface` modifier allows classes to be implemented but not extended outside their library.
  ///
  /// An interface class can be:
  /// - Implemented within or outside its library
  ///
  /// But CANNOT be:
  /// - Extended outside its library
  ///
  /// Example:
  /// ```dart
  /// interface class Repository {
  ///   Future<void> save(Object obj);
  /// }
  /// ```
  interface,

  /// The `final` modifier prevents classes from being extended or implemented outside their library.
  ///
  /// A final class CANNOT be:
  /// - Extended outside its library
  /// - Implemented outside its library
  ///
  /// Example:
  /// ```dart
  /// final class SealedImplementation {
  ///   void doSomething() { }
  /// }
  /// ```
  ///
  /// Note: Named `final_` because `final` is a reserved keyword in Dart.
  final_,

  /// The `sealed` modifier creates an abstract class that can only be extended or implemented
  /// within the same library. Sealed classes are implicitly abstract.
  ///
  /// A sealed class:
  /// - Is implicitly abstract (cannot be instantiated)
  /// - Can only be extended/implemented within its library
  /// - Enables exhaustive pattern matching on its subtypes
  ///
  /// Example:
  /// ```dart
  /// sealed class Shape { }
  /// class Circle extends Shape { }
  /// class Square extends Shape { }
  /// ```
  sealed,
}

/// Represents a generic type parameter with optional upper bound constraint.
///
/// Used in generic class declarations to define type parameters. Each type parameter
/// can have an optional upper bound that constrains what types can be used.
///
/// **Examples:**
/// ```dart
/// // Simple type parameter: T
/// TypeParameter('T')
/// // Output: T
///
/// // Bounded type parameter: E extends List
/// TypeParameter('E', 'List')
/// // Output: E extends List
///
/// // Complex bound: K extends Comparable<K>
/// TypeParameter('K', 'Comparable<K>')
/// // Output: K extends Comparable<K>
/// ```
///
/// **Usage in Class:**
/// ```dart
/// Class(
///   name: 'Box',
///   typeParameters: [TypeParameter('T')],
///   // ...
/// )
/// // Generates: class Box<T> { ... }
///
/// Class(
///   name: 'Pair',
///   typeParameters: [TypeParameter('K'), TypeParameter('V')],
///   // ...
/// )
/// // Generates: class Pair<K, V> { ... }
///
/// Class(
///   name: 'NumericContainer',
///   typeParameters: [TypeParameter('T', 'num')],
///   // ...
/// )
/// // Generates: class NumericContainer<T extends num> { ... }
/// ```
class TypeParameter {
  /// The name of the type parameter (e.g., 'T', 'E', 'K', 'V').
  ///
  /// This is the identifier used throughout the class to reference this type.
  final String name;

  /// The upper bound constraint for this type parameter, if any.
  ///
  /// When non-null, this represents the constraint that comes after the `extends` keyword.
  /// For example:
  /// - `'List'` for `T extends List`
  /// - `'Comparable<T>'` for `T extends Comparable<T>`
  /// - `'num'` for `T extends num`
  ///
  /// When null, the type parameter is unbounded (equivalent to `extends Object?`).
  final String? bound;

  /// Creates a type parameter with the given [name] and optional [bound].
  ///
  /// **Examples:**
  /// ```dart
  /// const TypeParameter('T')              // T
  /// const TypeParameter('E', 'List')      // E extends List
  /// const TypeParameter('K', 'Comparable<K>')  // K extends Comparable<K>
  /// ```
  const TypeParameter(this.name, [this.bound]);

  /// Converts this type parameter to its Dart source code representation.
  ///
  /// Returns just the name if there's no bound, or "name extends bound" if bounded.
  ///
  /// **Examples:**
  /// ```dart
  /// TypeParameter('T').toString()           // 'T'
  /// TypeParameter('E', 'List').toString()   // 'E extends List'
  /// ```
  @override
  String toString() => bound != null ? '$name extends $bound' : name;

  /// Checks equality based on both [name] and [bound].
  ///
  /// Two type parameters are equal if they have the same name and the same bound
  /// (or both have no bound).
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TypeParameter && runtimeType == other.runtimeType && name == other.name && bound == other.bound;

  /// Generates a hash code based on both [name] and [bound].
  @override
  int get hashCode => name.hashCode ^ bound.hashCode;
}

/// Represents a Dart class declaration with full support for all Dart class features.
///
/// This class provides a complete representation of Dart classes, supporting:
/// - All class modifiers (abstract, base, interface, final, sealed, mixin)
/// - Generic type parameters with bounds
/// - Inheritance (extends, with, implements)
/// - All member types (properties, getters, setters, constructors, methods)
///
/// **Examples:**
///
/// Simple class:
/// ```dart
/// Class(name: 'Person')
/// // Generates: class Person { }
/// ```
///
/// Abstract class with members:
/// ```dart
/// Class(
///   abstract: true,
///   name: 'Animal',
///   methods: [
///     Method(name: 'makeSound', body: (b) => b.write('print("sound");')),
///   ],
/// )
/// // Generates: abstract class Animal { void makeSound() { print("sound"); } }
/// ```
///
/// Generic class:
/// ```dart
/// Class(
///   name: 'Box',
///   typeParameters: [TypeParameter('T')],
///   properties: [Property(type: 'T', name: 'value')],
/// )
/// // Generates: class Box<T> { dynamic T value; }
/// ```
///
/// Class with inheritance:
/// ```dart
/// Class(
///   name: 'Dog',
///   superclass: 'Animal',
///   implementations: ['Comparable<Dog>'],
/// )
/// // Generates: class Dog extends Animal implements Comparable<Dog> { }
/// ```
///
/// Sealed class with modifiers:
/// ```dart
/// Class(
///   modifier: ClassModifier.sealed,
///   name: 'Result',
/// )
/// // Generates: sealed class Result { }
/// ```
///
/// Base mixin class:
/// ```dart
/// Class(
///   modifier: ClassModifier.base,
///   mixinClass: true,
///   name: 'Droppable',
/// )
/// // Generates: base mixin class Droppable { }
/// ```
class Class extends PublicBufferWritable {
  // ============================================================================
  // METADATA
  // ============================================================================

  /// The documentation comment for this class.
  ///
  /// Should be a multi-line string with `///` prefix for each line, following
  /// Dart documentation conventions. This appears directly above the class
  /// declaration and is used to generate API documentation.
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   docComment: '''
  /// /// A class representing a user.
  /// ///
  /// /// This class contains user information and authentication data.
  /// ''',
  ///   name: 'User',
  /// )
  /// ```
  final String? docComment;

  /// A list of metadata annotations to be applied to this class.
  ///
  /// Annotations are prefixed with `@` and appear before the class declaration.
  /// Common examples include:
  /// - `@deprecated` - marks this class as deprecated
  /// - `@immutable` - indicates this class is immutable
  /// - `@experimental` - marks this class as experimental
  /// - Custom annotations from your codebase
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   annotations: ['@deprecated', '@immutable'],
  ///   name: 'OldUser',
  /// )
  /// // Generates:
  /// // @deprecated
  /// // @immutable
  /// // class OldUser { }
  /// ```
  final List<String> annotations;

  // ============================================================================
  // MODIFIERS
  // ============================================================================

  /// Whether this is an abstract class (cannot be instantiated).
  ///
  /// Abstract classes can contain abstract members (methods without implementation)
  /// and must be extended/implemented to be used.
  ///
  /// **Note:** When [modifier] is [ClassModifier.sealed], this should be `false`
  /// because sealed classes are implicitly abstract.
  ///
  /// **Example:**
  /// ```dart
  /// Class(abstract: true, name: 'Shape')
  /// // Generates: abstract class Shape { }
  /// ```
  final bool abstract;

  /// The primary class modifier, if any.
  ///
  /// Can be one of: [ClassModifier.base], [ClassModifier.interface],
  /// [ClassModifier.final_], or [ClassModifier.sealed].
  ///
  /// These modifiers are mutually exclusive - only one can be used per class.
  /// They control how the class can be extended, implemented, or mixed in.
  ///
  /// **Examples:**
  /// ```dart
  /// Class(modifier: ClassModifier.base, name: 'Vehicle')
  /// // Generates: base class Vehicle { }
  ///
  /// Class(modifier: ClassModifier.sealed, name: 'Result')
  /// // Generates: sealed class Result { }
  /// ```
  final ClassModifier? modifier;

  /// Whether this is a mixin class (can be used both as a class and a mixin).
  ///
  /// Mixin classes were introduced in Dart 3.0 and can be both extended
  /// and mixed in. They combine the features of classes and mixins.
  ///
  /// **Valid combinations:** Can be combined with `abstract` or `base` modifiers.
  /// **Invalid combinations:** Cannot be combined with `interface`, `final`, or `sealed`.
  ///
  /// **Example:**
  /// ```dart
  /// Class(mixinClass: true, name: 'Musician')
  /// // Generates: mixin class Musician { }
  ///
  /// Class(modifier: ClassModifier.base, mixinClass: true, name: 'Droppable')
  /// // Generates: base mixin class Droppable { }
  /// ```
  final bool mixinClass;

  // ============================================================================
  // DECLARATION
  // ============================================================================

  /// The name of the class.
  ///
  /// This is the identifier used to reference the class throughout the code.
  final String name;

  /// The generic type parameters for this class, if any.
  ///
  /// When null or empty, the class is not generic. When provided, each
  /// [TypeParameter] represents a type variable with an optional upper bound.
  ///
  /// **Examples:**
  /// ```dart
  /// // Generic class with one parameter
  /// Class(
  ///   name: 'Box',
  ///   typeParameters: [TypeParameter('T')],
  /// )
  /// // Generates: class Box<T> { }
  ///
  /// // Generic class with multiple parameters
  /// Class(
  ///   name: 'Map',
  ///   typeParameters: [TypeParameter('K'), TypeParameter('V')],
  /// )
  /// // Generates: class Map<K, V> { }
  ///
  /// // Generic class with bounded parameter
  /// Class(
  ///   name: 'NumList',
  ///   typeParameters: [TypeParameter('T', 'num')],
  /// )
  /// // Generates: class NumList<T extends num> { }
  /// ```
  final List<TypeParameter>? typeParameters;

  // ============================================================================
  // INHERITANCE
  // ============================================================================

  /// The superclass that this class extends, if any.
  ///
  /// When non-null, this class inherits from the specified superclass.
  /// When null, the class implicitly extends `Object`.
  ///
  /// **Note:** A class can only extend one superclass (single inheritance).
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   name: 'Dog',
  ///   superclass: 'Animal',
  /// )
  /// // Generates: class Dog extends Animal { }
  /// ```
  final String? superclass;

  /// The list of mixins applied to this class using the `with` clause.
  ///
  /// Mixins add functionality to this class without using inheritance.
  /// They are applied in order from left to right.
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   name: 'Swan',
  ///   superclass: 'Bird',
  ///   mixins: ['Swimmer', 'Flyer'],
  /// )
  /// // Generates: class Swan extends Bird with Swimmer, Flyer { }
  /// ```
  final List<String> mixins;

  /// The list of interfaces this class implements using the `implements` clause.
  ///
  /// Implementing an interface creates a contract that this class must fulfill
  /// by providing implementations for all interface members.
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   name: 'Person',
  ///   implementations: ['Comparable<Person>', 'JsonSerializable'],
  /// )
  /// // Generates: class Person implements Comparable<Person>, JsonSerializable { }
  /// ```
  final List<String> implementations;

  // ============================================================================
  // MEMBERS
  // ============================================================================

  /// The list of field/property declarations in this class.
  ///
  /// Properties can be instance or static, final or const, and may have default values.
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   name: 'Point',
  ///   properties: [
  ///     Property(type: 'int', name: 'x'),
  ///     Property(type: 'int', name: 'y'),
  ///   ],
  /// )
  /// // Generates: class Point { int x; int y; }
  /// ```
  final List<Property> properties;

  /// The list of getter methods in this class.
  ///
  /// Getters provide computed properties or controlled access to internal state.
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   name: 'Rectangle',
  ///   getters: [
  ///     Getter(returnType: 'double', name: 'area', body: (b) => b.write('width * height')),
  ///   ],
  /// )
  /// // Generates: class Rectangle { double get area => width * height; }
  /// ```
  final List<Getter> getters;

  /// The list of setter methods in this class.
  ///
  /// Setters provide controlled modification of internal state.
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   name: 'Temperature',
  ///   setters: [
  ///     Setter(name: 'celsius', parameterType: 'double', body: (b) => b.write('_celsius = celsius')),
  ///   ],
  /// )
  /// // Generates: class Temperature { set celsius(double celsius) { _celsius = celsius; } }
  /// ```
  final List<Setter> setters;

  /// The list of constructors in this class.
  ///
  /// Includes the default constructor, named constructors, factory constructors, etc.
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   name: 'Person',
  ///   constructors: [
  ///     Constructor(parameters: [
  ///       ConstructorParameter(name: 'name', type: 'String'),
  ///     ]),
  ///   ],
  /// )
  /// // Generates: class Person { Person(String name); }
  /// ```
  final List<Constructor> constructors;

  /// The list of methods in this class.
  ///
  /// Methods can be instance or static, synchronous or asynchronous, and may be
  /// generators. They cannot include operators (operator overloading is not yet supported).
  ///
  /// **Example:**
  /// ```dart
  /// Class(
  ///   name: 'Calculator',
  ///   methods: [
  ///     Method(
  ///       returnType: 'int',
  ///       name: 'add',
  ///       parameters: [
  ///         MethodParameter(type: 'int', name: 'a'),
  ///         MethodParameter(type: 'int', name: 'b'),
  ///       ],
  ///       body: (b) => b.write('return a + b;'),
  ///     ),
  ///   ],
  /// )
  /// // Generates: class Calculator { int add(int a, int b) { return a + b; } }
  /// ```
  final List<Method> methods;

  /// Creates a new class declaration.
  ///
  /// All list parameters default to empty lists if not provided.
  ///
  /// **Validation Rules:**
  ///
  /// The constructor enforces several validation rules via assertions:
  ///
  /// 1. **Modifier Validation:**
  ///    - `abstract` + `sealed` is invalid (sealed is implicitly abstract)
  ///    - `mixinClass` cannot combine with `interface`, `final`, or `sealed`
  ///
  /// 2. **Inheritance Validation:**
  ///    - A class cannot extend itself
  ///    - Cannot mix in the same class being extended
  ///    - Cannot implement the same class being extended
  ///
  /// 3. **Mixin Validation:**
  ///    - A class cannot mix in itself
  ///    - Cannot implement a class that's already being mixed in
  ///
  /// 4. **Implementation Validation:**
  ///    - A class cannot implement itself
  ///
  /// **Examples:**
  ///
  /// ```dart
  /// // Simple class
  /// Class(name: 'Person')
  ///
  /// // Class with modifiers
  /// Class(
  ///   abstract: true,
  ///   modifier: ClassModifier.base,
  ///   name: 'Vehicle',
  /// )
  ///
  /// // Generic class with inheritance
  /// Class(
  ///   name: 'ArrayList',
  ///   typeParameters: [TypeParameter('E')],
  ///   implementations: ['List<E>'],
  ///   methods: [...],
  /// )
  /// ```
  ///
  /// **Parameters:**
  ///
  /// - [docComment]: Documentation comment for the class
  /// - [annotations]: Metadata annotations
  /// - [abstract]: Whether the class is abstract (default: false)
  /// - [modifier]: Optional primary modifier (base/interface/final/sealed)
  /// - [mixinClass]: Whether this is a mixin class (default: false)
  /// - [name]: The class name (required)
  /// - [typeParameters]: Generic type parameters
  /// - [superclass]: The class to extend
  /// - [mixins]: Classes to mix in
  /// - [implementations]: Interfaces to implement
  /// - [properties]: Field declarations
  /// - [getters]: Getter methods
  /// - [setters]: Setter methods
  /// - [constructors]: Constructor declarations
  /// - [methods]: Method declarations
  Class({
    this.docComment,
    List<String>? annotations,
    this.abstract = false,
    this.modifier,
    this.mixinClass = false,
    required this.name,
    this.typeParameters,
    this.superclass,
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
    // Validate modifier combinations
    assert(!abstract || modifier != ClassModifier.sealed,
        'Class "$name": sealed is implicitly abstract, cannot combine with abstract modifier');
    assert(
        !mixinClass ||
            (modifier != ClassModifier.interface &&
                modifier != ClassModifier.final_ &&
                modifier != ClassModifier.sealed),
        'Class "$name": mixin class cannot be combined with interface, final, or sealed');

    // Validate inheritance relationships
    assert(superclass == null || name != superclass, 'Class "$name": cannot extend itself');
    assert(superclass == null || !this.mixins.contains(superclass),
        'Class "$name": cannot mix in the same class it extends');
    assert(superclass == null || !this.implementations.contains(superclass),
        'Class "$name": cannot implement the same class it extends');

    // Validate mixin relationships
    assert(!this.mixins.contains(name), 'Class "$name": cannot mix in itself');
    assert(this.mixins.every((mixin) => !this.implementations.contains(mixin)),
        'Class "$name": cannot implement the same class it mixes in');

    // Validate implementation relationships
    assert(!this.implementations.contains(name), 'Class "$name": cannot implement itself');
  }

  /// Creates a [Class] instance from an analyzer [ClassElement].
  ///
  /// This static factory method extracts all class information from the analyzer's
  /// representation of a Dart class, including modifiers, type parameters,
  /// inheritance, and all members.
  ///
  /// **Extraction Logic:**
  ///
  /// - **Modifiers:** Detects `base`, `interface`, `final`, `sealed`, `abstract`, and `mixin class`
  /// - **Type Parameters:** Extracts generic type parameters with their bounds
  /// - **Superclass:** Excludes `Object` (implicit superclass)
  /// - **Members:** Asynchronously converts all fields, accessors, constructors, and methods
  ///
  /// **Note on Sealed Classes:**
  ///
  /// Sealed classes are implicitly abstract in Dart, so when a class is sealed,
  /// the [abstract] property is set to `false` to avoid redundancy in the output.
  ///
  /// **Parameters:**
  ///
  /// - [classElement]: The analyzer's representation of the class
  /// - [buildStep]: The build step providing access to resolution and AST nodes
  ///
  /// **Returns:**
  ///
  /// A [Class] instance representing the complete class declaration.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// // In a Builder
  /// final libraryElement = await buildStep.inputLibrary;
  /// for (final element in libraryElement.topLevelElements) {
  ///   if (element is ClassElement) {
  ///     final classDeclaration = await Class.from(element, buildStep);
  ///     // Use classDeclaration...
  ///   }
  /// }
  /// ```
  static Future<Class> from(
    ClassElement classElement,
    BuildStep buildStep,
  ) async {
    // Determine the primary modifier
    ClassModifier? modifier;
    if (classElement.isBase) {
      modifier = ClassModifier.base;
    } else if (classElement.isInterface) {
      modifier = ClassModifier.interface;
    } else if (classElement.isFinal) {
      modifier = ClassModifier.final_;
    } else if (classElement.isSealed) {
      modifier = ClassModifier.sealed;
    }

    return Class(
      docComment: classElement.documentationComment,
      annotations: classElement.metadata.map((e) => e.toSource()).toList(),
      abstract: classElement.isAbstract && modifier != ClassModifier.sealed, // Don't mark sealed as abstract
      modifier: modifier,
      mixinClass: classElement.isMixinClass,
      name: classElement.name,
      typeParameters: classElement.typeParameters.isEmpty
          ? null
          : classElement.typeParameters.map((tp) {
              String? bound = tp.bound != null ? tp.bound.toString() : null;
              return TypeParameter(tp.name, bound);
            }).toList(),
      superclass: classElement.supertype?.element.name != 'Object' ? classElement.supertype?.element.name : null,
      mixins: classElement.mixins.map((e) => e.element.name).toList(),
      implementations: classElement.interfaces.map((e) => e.element.name).toList(),
      properties: await classElement.fields.mapAsync((e) => Property.from(e, buildStep)),
      getters:
          await classElement.accessors.where((e) => e.isGetter).toList().mapAsync((e) => Getter.from(e, buildStep)),
      setters:
          await classElement.accessors.where((e) => e.isSetter).toList().mapAsync((e) => Setter.from(e, buildStep)),
      constructors:
          await classElement.constructors.mapAsync<Constructor>((e) async => await Constructor.from(e, buildStep)),
      methods: await classElement.methods.mapAsync((e) => Method.from(e, buildStep)),
    );
  }

  /// Creates a copy of this class with the specified properties replaced.
  ///
  /// This method creates a new [Class] instance with the same values as the current
  /// instance, except for the properties explicitly provided as parameters.
  /// Properties not provided will retain their current values.
  ///
  /// **Usage:**
  ///
  /// This is useful when you need to create a variation of an existing class
  /// or when building classes incrementally.
  ///
  /// **Parameters:**
  ///
  /// All parameters are optional. When a parameter is provided (non-null), it replaces
  /// the corresponding property in the new instance. When null, the original value is preserved.
  ///
  /// **Example:**
  ///
  /// ```dart
  /// final baseClass = Class(
  ///   name: 'Animal',
  ///   methods: [Method(name: 'eat', body: (b) => {})],
  /// );
  ///
  /// // Create an abstract version
  /// final abstractAnimal = baseClass.copyWith(abstract: true);
  /// // Result: abstract class Animal { ... }
  ///
  /// // Add a superclass
  /// final livingThing = baseClass.copyWith(superclass: 'LivingThing');
  /// // Result: class Animal extends LivingThing { ... }
  ///
  /// // Change name and add type parameters
  /// final genericContainer = baseClass.copyWith(
  ///   name: 'Container',
  ///   typeParameters: [TypeParameter('T')],
  /// );
  /// // Result: class Container<T> { ... }
  /// ```
  ///
  /// **Returns:**
  ///
  /// A new [Class] instance with the specified properties replaced.
  Class copyWith({
    String? docComment,
    List<String>? annotations,
    bool? abstract,
    ClassModifier? modifier,
    bool? mixinClass,
    String? name,
    List<TypeParameter>? typeParameters,
    String? superclass,
    List<String>? mixins,
    List<String>? implementations,
    List<Property>? properties,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Constructor>? constructors,
    List<Method>? methods,
  }) =>
      Class(
        docComment: docComment ?? this.docComment,
        annotations: annotations ?? this.annotations,
        abstract: abstract ?? this.abstract,
        modifier: modifier ?? this.modifier,
        mixinClass: mixinClass ?? this.mixinClass,
        name: name ?? this.name,
        typeParameters: typeParameters ?? this.typeParameters,
        superclass: superclass ?? this.superclass,
        mixins: mixins ?? this.mixins,
        implementations: implementations ?? this.implementations,
        properties: properties ?? this.properties,
        getters: getters ?? this.getters,
        setters: setters ?? this.setters,
        constructors: constructors ?? this.constructors,
        methods: methods ?? this.methods,
      );

  /// Writes the Dart source code representation of this class to the provided [StringBuffer].
  ///
  /// This is an internal method used by the [PublicBufferWritable] interface to generate
  /// the actual Dart code. It writes the complete class declaration including all modifiers,
  /// type parameters, inheritance clauses, and members.
  ///
  /// **Output Format:**
  ///
  /// The method follows the standard Dart class declaration syntax:
  /// ```
  /// [abstract] [base|interface|final|sealed] [mixin] class Name[<TypeParams>] [extends Super] [with Mixins] [implements Interfaces] {
  ///   [members]
  /// }
  /// ```
  ///
  /// **Writing Order:**
  ///
  /// 1. **Modifiers** (in order):
  ///    - `abstract` (if true)
  ///    - Primary modifier: `base`, `interface`, `final`, or `sealed` (if set)
  ///    - `mixin` (if mixinClass is true)
  ///
  /// 2. **Class keyword and name**: `class Name`
  ///
  /// 3. **Type parameters**: `<T, E extends List>` (if any)
  ///
  /// 4. **Inheritance clauses** (in order):
  ///    - `extends Superclass` (if superclass is set)
  ///    - `with Mixin1, Mixin2` (if mixins list is not empty)
  ///    - `implements Interface1, Interface2` (if implementations list is not empty)
  ///
  /// 5. **Body** (members in order):
  ///    - Properties
  ///    - Getters
  ///    - Setters
  ///    - Constructors
  ///    - Methods
  ///
  /// **Example Outputs:**
  ///
  /// ```dart
  /// // Simple class
  /// class Person { }
  ///
  /// // Abstract base class with generics
  /// abstract base class Container<T extends num> { }
  ///
  /// // Class with full inheritance
  /// class Swan extends Bird with Swimmer, Flyer implements Comparable<Swan> { }
  ///
  /// // Sealed class
  /// sealed class Result { }
  ///
  /// // Base mixin class
  /// base mixin class Droppable { }
  /// ```
  ///
  /// **Parameters:**
  ///
  /// - [b]: The StringBuffer to write the class declaration into
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment
    if (docComment != null && docComment!.isNotEmpty) {
      b.write('$docComment\n');
    }

    // Write annotations
    for (final annotation in annotations) {
      b.write('$annotation ');
    }

    // Write modifiers in correct order: [abstract] [base|interface|final|sealed] [mixin] class
    if (abstract) b.write('abstract ');
    if (modifier != null) {
      switch (modifier!) {
        case ClassModifier.base:
          b.write('base ');
          break;
        case ClassModifier.interface:
          b.write('interface ');
          break;
        case ClassModifier.final_:
          b.write('final ');
          break;
        case ClassModifier.sealed:
          b.write('sealed ');
          break;
      }
    }
    if (mixinClass) b.write('mixin ');

    b.write('class $name');

    // Write type parameters
    if (typeParameters != null && typeParameters!.isNotEmpty) {
      b.write('<');
      b.write(typeParameters!.map((tp) => tp.toString()).join(', '));
      b.write('>');
    }

    b.write(' ');

    // Write inheritance clauses
    if (superclass != null) b.write('extends $superclass ');
    if (mixins.isNotEmpty) b.write('with ${mixins.join(', ')} ');
    if (implementations.isNotEmpty) b.write('implements ${implementations.join(', ')} ');

    b.write('{');
    [
      ...properties,
      ...getters,
      ...setters,
      ...constructors,
      ...methods,
    ]._writeToBuffer(b);
    b.write('}');
  }
}
