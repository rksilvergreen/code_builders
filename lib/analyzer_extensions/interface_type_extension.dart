part of code_builders;

/// Extension on [InterfaceType] providing inheritance checking and member introspection methods.
///
/// This extension adds methods to work with interface types, including
/// inheritance checking, member existence verification, and type relationship
/// analysis. It's particularly useful for code generation scenarios where
/// you need to understand type hierarchies and member availability.
///
/// ## Features
///
/// - Inheritance checking (implements, extends, mixins)
/// - Recursive inheritance analysis
/// - Member existence checking (methods, fields, getters, setters, constructors)
/// - Type parameter support in inheritance checking
/// - Extended vs direct relationship checking
///
/// ## Usage
///
/// ```dart
/// // Check inheritance
/// if (interfaceType.doesImplementType<Serializable>()) {
///   // Type implements Serializable
/// }
///
/// if (interfaceType.doesExtendType<BaseClass>()) {
///   // Type extends BaseClass
/// }
///
/// // Check members
/// if (interfaceType.hasMethod('toString')) {
///   // Type has toString method
/// }
///
/// if (interfaceType.hasField('name')) {
///   // Type has name field
/// }
/// ```
extension InterfaceTypeExtensions on InterfaceType {
  /// Gets all interfaces that this type implements, including inherited ones.
  ///
  /// This method recursively traverses the inheritance hierarchy to collect
  /// all interfaces that this type implements, including those implemented
  /// by superclasses.
  ///
  /// ## Returns
  ///
  /// A list of [InterfaceType] instances representing all implemented interfaces.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allInterfaces = interfaceType.extendedInterfaces;
  /// for (final interface in allInterfaces) {
  ///   print('Implements: ${interface.element.name}');
  /// }
  /// ```
  List<InterfaceType> get extendedInterfaces {
    List<InterfaceType> allInterfaces = [];
    allInterfaces.addAll(interfaces);
    if (superclass != null) {
      allInterfaces.addAll(superclass!.extendedInterfaces);
    }
    return allInterfaces;
  }

  /// Gets all mixins that this type uses, including inherited ones.
  ///
  /// This method recursively traverses the inheritance hierarchy to collect
  /// all mixins that this type uses, including those used by superclasses.
  ///
  /// ## Returns
  ///
  /// A list of [InterfaceType] instances representing all used mixins.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final allMixins = interfaceType.extendedMixins;
  /// for (final mixin in allMixins) {
  ///   print('Uses mixin: ${mixin.element.name}');
  /// }
  /// ```
  List<InterfaceType> get extendedMixins {
    List<InterfaceType> allMixins = [];
    allMixins.addAll(mixins);
    if (superclass != null) {
      allMixins.addAll(superclass!.extendedMixins);
    }
    return allMixins;
  }

  /// Checks if this type implements the specified type [T].
  ///
  /// This method checks whether this type implements the specified interface [T].
  /// It can optionally include or exclude inherited interfaces in the check.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in type matching.
  ///                  If `false`, ignores type parameters (default).
  /// [extended]: If `true`, includes inherited interfaces in the check.
  ///            If `false`, only checks directly implemented interfaces (default: `true`).
  ///
  /// ## Returns
  ///
  /// `true` if this type implements [T], `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Check if type implements Serializable
  /// if (interfaceType.doesImplementType<Serializable>()) {
  ///   // Type implements Serializable (including inherited)
  /// }
  ///
  /// // Check only directly implemented interfaces
  /// if (interfaceType.doesImplementType<Serializable>(extended: false)) {
  ///   // Type directly implements Serializable
  /// }
  /// ```
  bool doesImplementType<T>({bool withTypeParams = false, bool extended = true}) =>
      (extended ? extendedInterfaces : interfaces)
          .any((interfaceType) => interfaceType.isType<T>(withTypeParams: withTypeParams));

  /// Checks if this type extends the specified type [T].
  ///
  /// This method checks whether this type extends the specified class [T].
  /// It recursively traverses the inheritance hierarchy to check all superclasses.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in type matching.
  ///                  If `false`, ignores type parameters (default).
  /// [extended]: If `true`, includes inherited superclasses in the check.
  ///            If `false`, only checks direct superclass (default: `true`).
  ///
  /// ## Returns
  ///
  /// `true` if this type extends [T], `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Check if type extends BaseClass
  /// if (interfaceType.doesExtendType<BaseClass>()) {
  ///   // Type extends BaseClass (including inherited)
  /// }
  ///
  /// // Check only direct superclass
  /// if (interfaceType.doesExtendType<BaseClass>(extended: false)) {
  ///   // Type directly extends BaseClass
  /// }
  /// ```
  bool doesExtendType<T>({bool withTypeParams = false, bool extended = true}) {
    if (isType<T>(withTypeParams: withTypeParams)) return true;
    if (superclass == null) return false;
    if (superclass!.isType<T>(withTypeParams: withTypeParams)) return true;
    return extended ? superclass!.doesExtendType<T>(withTypeParams: withTypeParams, extended: extended) : false;
  }

  /// Checks if this type uses the specified mixin [T].
  ///
  /// This method checks whether this type uses the specified mixin [T].
  /// It can optionally include or exclude inherited mixins in the check.
  ///
  /// [withTypeParams]: If `true`, includes type parameters in type matching.
  ///                  If `false`, ignores type parameters (default).
  /// [extended]: If `true`, includes inherited mixins in the check.
  ///            If `false`, only checks directly used mixins (default: `true`).
  ///
  /// ## Returns
  ///
  /// `true` if this type uses mixin [T], `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// // Check if type uses MyMixin
  /// if (interfaceType.doesMixinType<MyMixin>()) {
  ///   // Type uses MyMixin (including inherited)
  /// }
  ///
  /// // Check only directly used mixins
  /// if (interfaceType.doesMixinType<MyMixin>(extended: false)) {
  ///   // Type directly uses MyMixin
  /// }
  /// ```
  bool doesMixinType<T>({bool withTypeParams = false, bool extended = true}) => (extended ? extendedMixins : mixins)
      .any((interfaceType) => interfaceType.isType<T>(withTypeParams: withTypeParams));

  /// Checks if this type implements the specified [dartType].
  ///
  /// This method checks whether this type implements the specified [dartType].
  /// It can optionally include or exclude inherited interfaces in the check.
  ///
  /// [dartType]: The [DartType] to check for implementation.
  /// [withTypeParams]: If `true`, includes type parameters in type matching.
  ///                  If `false`, ignores type parameters (default).
  /// [extended]: If `true`, includes inherited interfaces in the check.
  ///            If `false`, only checks directly implemented interfaces (default: `true`).
  ///
  /// ## Returns
  ///
  /// `true` if this type implements [dartType], `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final otherType = element.thisType;
  /// if (interfaceType.doesImplementDartType(otherType)) {
  ///   // Type implements otherType
  /// }
  /// ```
  bool doesImplementDartType(DartType dartType, {bool withTypeParams = false, bool extended = true}) =>
      (extended ? extendedInterfaces : interfaces)
          .any((interfaceType) => interfaceType.isDartType(dartType, withTypeParams: withTypeParams));

  /// Checks if this type extends the specified [dartType].
  ///
  /// This method checks whether this type extends the specified [dartType].
  /// It recursively traverses the inheritance hierarchy to check all superclasses.
  ///
  /// [dartType]: The [DartType] to check for extension.
  /// [withTypeParams]: If `true`, includes type parameters in type matching.
  ///                  If `false`, ignores type parameters (default).
  /// [extended]: If `true`, includes inherited superclasses in the check.
  ///            If `false`, only checks direct superclass (default: `true`).
  ///
  /// ## Returns
  ///
  /// `true` if this type extends [dartType], `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final otherType = element.thisType;
  /// if (interfaceType.doesExtendDartType(otherType)) {
  ///   // Type extends otherType
  /// }
  /// ```
  bool doesExtendDartType(DartType dartType, {bool withTypeParams = false, bool extended = true}) {
    if (isDartType(dartType, withTypeParams: withTypeParams)) return true;
    if (superclass == null) return false;
    if (superclass!.isDartType(dartType, withTypeParams: withTypeParams)) return true;
    return extended
        ? superclass!.doesExtendDartType(dartType, withTypeParams: withTypeParams, extended: extended)
        : false;
  }

  /// Checks if this type uses the specified mixin [dartType].
  ///
  /// This method checks whether this type uses the specified mixin [dartType].
  /// It can optionally include or exclude inherited mixins in the check.
  ///
  /// [dartType]: The [DartType] to check for mixin usage.
  /// [withTypeParams]: If `true`, includes type parameters in type matching.
  ///                  If `false`, ignores type parameters (default).
  /// [extended]: If `true`, includes inherited mixins in the check.
  ///            If `false`, only checks directly used mixins (default: `true`).
  ///
  /// ## Returns
  ///
  /// `true` if this type uses mixin [dartType], `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final otherType = element.thisType;
  /// if (interfaceType.doesMixinDartType(otherType)) {
  ///   // Type uses otherType as mixin
  /// }
  /// ```
  bool doesMixinDartType(DartType dartType, {bool withTypeParams = false, bool extended = true}) =>
      (extended ? extendedMixins : mixins)
          .any((interfaceType) => interfaceType.isDartType(dartType, withTypeParams: withTypeParams));

  /// Checks if this type has a getter with the specified name.
  ///
  /// This method searches through the type's accessors to find a getter
  /// with the specified name.
  ///
  /// [name]: The name of the getter to check for.
  ///
  /// ## Returns
  ///
  /// `true` if this type has a getter with the specified name, `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (interfaceType.hasGetter('name')) {
  ///   // Type has a getter named 'name'
  /// }
  /// ```
  bool hasGetter(String name) => (element as ClassElement).getters.any((getter) => getter.name == name);

  /// Checks if this type has a setter with the specified name.
  ///
  /// This method searches through the type's accessors to find a setter
  /// with the specified name.
  ///
  /// [name]: The name of the setter to check for.
  ///
  /// ## Returns
  ///
  /// `true` if this type has a setter with the specified name, `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (interfaceType.hasSetter('name')) {
  ///   // Type has a setter named 'name'
  /// }
  /// ```
  bool hasSetter(String name) => (element as ClassElement).setters.any((setter) => setter.name == name);

  /// Checks if this type has a method with the specified name.
  ///
  /// This method searches through the type's methods to find a method
  /// with the specified name.
  ///
  /// [name]: The name of the method to check for.
  ///
  /// ## Returns
  ///
  /// `true` if this type has a method with the specified name, `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (interfaceType.hasMethod('toString')) {
  ///   // Type has a method named 'toString'
  /// }
  /// ```
  bool hasMethod(String name) => (element as ClassElement).methods.any((method) => method.name == name);

  /// Checks if this type has a field with the specified name.
  ///
  /// This method searches through the type's fields to find a field
  /// with the specified name.
  ///
  /// [name]: The name of the field to check for.
  ///
  /// ## Returns
  ///
  /// `true` if this type has a field with the specified name, `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (interfaceType.hasField('name')) {
  ///   // Type has a field named 'name'
  /// }
  /// ```
  bool hasField(String name) => (element as ClassElement).fields.any((field) => field.name == name);

  /// Checks if this type has a named constructor with the specified name.
  ///
  /// This method searches through the type's constructors to find a named
  /// constructor with the specified name.
  ///
  /// [name]: The name of the named constructor to check for.
  ///
  /// ## Returns
  ///
  /// `true` if this type has a named constructor with the specified name, `false` otherwise.
  ///
  /// ## Example
  ///
  /// ```dart
  /// if (interfaceType.hasNamedConstructor('fromJson')) {
  ///   // Type has a named constructor 'fromJson'
  /// }
  /// ```
  bool hasNamedConstructor(String name) =>
      (element as ClassElement).constructors.any((constructor) => constructor.name == name);
}
