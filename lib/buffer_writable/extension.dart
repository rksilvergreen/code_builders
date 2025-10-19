part of code_builder;

/// Represents a Dart extension declaration with full support for all extension features.
///
/// This class provides a complete representation of Dart extensions, supporting:
/// - Named or unnamed extensions
/// - Generic type parameters with bounds
/// - Any extended type (classes, built-in types, generic types, etc.)
/// - Instance and static members (getters, setters, methods)
///
/// **Examples:**
///
/// Simple extension:
/// ```dart
/// Extension(
///   extensionName: 'StringExtensions',
///   extendedType: 'String',
///   methods: [
///     Method(name: 'capitalize', body: (b) => b.write('...')),
///   ],
/// )
/// // Generates: extension StringExtensions on String { void capitalize() { ... } }
/// ```
///
/// Unnamed extension:
/// ```dart
/// Extension(
///   extendedType: 'int',
///   getters: [Getter(returnType: 'bool', name: 'isEven', body: (b) => b.write('...'))],
/// )
/// // Generates: extension on int { bool get isEven { ... } }
/// ```
///
/// Generic extension:
/// ```dart
/// Extension(
///   extensionName: 'ListExtensions',
///   typeParameters: [TypeParameter('T')],
///   extendedType: 'List<T>',
///   methods: [
///     Method(returnType: 'T?', name: 'firstOrNull', body: (b) => b.write('...')),
///   ],
/// )
/// // Generates: extension ListExtensions<T> on List<T> { T? firstOrNull() { ... } }
/// ```
///
/// Extension with static members:
/// ```dart
/// Extension(
///   extensionName: 'StringUtils',
///   extendedType: 'String',
///   methods: [
///     Method(name: 'helper', static: true, body: (b) => b.write('...')),
///   ],
/// )
/// // Generates: extension StringUtils on String { static void helper() { ... } }
/// ```
class Extension extends PublicBufferWritable {
  /// The documentation comment for this extension.
  ///
  /// This is the comment that appears above the extension declaration, typically
  /// in the form of triple-slash (`///`) doc comments. Include the leading `///`
  /// and any newlines as needed.
  ///
  /// **Note:** The docComment should include its own line breaks and formatting.
  ///
  /// **Example:**
  /// ```dart
  /// Extension(
  ///   docComment: '''
  /// /// Provides utility methods for String manipulation.
  /// ///
  /// /// These methods help with common string operations.
  /// ''',
  ///   extensionName: 'StringUtils',
  ///   extendedType: 'String',
  /// )
  /// // Generates:
  /// // /// Provides utility methods for String manipulation.
  /// // ///
  /// // /// These methods help with common string operations.
  /// // extension StringUtils on String { }
  /// ```
  final String? docComment;

  /// A list of metadata annotations to be applied to this extension.
  ///
  /// Annotations are prefixed with `@` and appear before the extension declaration.
  /// Each annotation should include the `@` symbol.
  ///
  /// Common examples include:
  /// - `@deprecated` - marks this extension as deprecated
  /// - `@Deprecated('Use NewExtension instead')` - deprecated with message
  /// - `@experimental` - marks this extension as experimental
  /// - Custom annotations from your codebase
  ///
  /// **Example:**
  /// ```dart
  /// Extension(
  ///   annotations: ['@deprecated', '@experimental'],
  ///   extensionName: 'OldStringUtils',
  ///   extendedType: 'String',
  /// )
  /// // Generates:
  /// // @deprecated
  /// // @experimental
  /// // extension OldStringUtils on String { }
  /// ```
  final List<String> annotations;

  /// The name of the extension, or null for an unnamed extension.
  ///
  /// Named extensions can be used explicitly and can be imported with show/hide.
  /// Unnamed extensions are always applied when in scope.
  ///
  /// **Examples:**
  /// ```dart
  /// Extension(extensionName: 'MyExt', ...)  // extension MyExt on ...
  /// Extension(extendedType: 'String', ...)  // extension on String ...
  /// ```
  final String? extensionName;

  /// The type being extended (the type that comes after `on`).
  ///
  /// This can be any type: class names, built-in types, generic types, function types, etc.
  ///
  /// **Examples:**
  /// - `'String'`
  /// - `'List<int>'`
  /// - `'Map<String, dynamic>'`
  /// - `'int Function(String)'`
  final String extendedType;

  /// The generic type parameters for this extension, if any.
  ///
  /// Type parameters allow the extension to work with generic types.
  ///
  /// **Examples:**
  /// ```dart
  /// Extension(
  ///   typeParameters: [TypeParameter('T')],
  ///   extendedType: 'List<T>',
  ///   ...
  /// )
  /// // Generates: extension<T> on List<T> { ... }
  ///
  /// Extension(
  ///   typeParameters: [TypeParameter('T', 'num')],
  ///   extendedType: 'List<T>',
  ///   ...
  /// )
  /// // Generates: extension<T extends num> on List<T> { ... }
  /// ```
  final List<TypeParameter>? typeParameters;

  /// Getters defined in this extension.
  ///
  /// Can include both instance and static getters. Set `static: true` on the
  /// `Getter` object for static getters.
  ///
  /// **Examples:**
  /// ```dart
  /// getters: [
  ///   Getter(name: 'instance', body: (b) => b.write('...')),      // instance getter
  ///   Getter(name: 'helper', static: true, body: (b) => b.write('...')),  // static getter
  /// ]
  /// ```
  final List<Getter> getters;

  /// Setters defined in this extension.
  ///
  /// Can include both instance and static setters. Set `static: true` on the
  /// `Setter` object for static setters.
  final List<Setter> setters;

  /// Methods defined in this extension.
  ///
  /// Can include both instance and static methods. Set `static: true` on the
  /// `Method` object for static methods.
  ///
  /// **Examples:**
  /// ```dart
  /// methods: [
  ///   Method(name: 'capitalize', body: (b) => b.write('...')),           // instance method
  ///   Method(name: 'helper', static: true, body: (b) => b.write('...')), // static method
  /// ]
  /// ```
  final List<Method> methods;

  /// Creates a new [Extension] with the specified properties.
  ///
  /// **Parameters:**
  /// - [docComment]: Optional documentation comment for the extension
  /// - [annotations]: Optional metadata annotations. Defaults to empty list
  /// - [extensionName]: Optional name for the extension. If null, creates an unnamed extension
  /// - [extendedType]: Required. The type being extended (e.g., 'String', 'List<int>')
  /// - [typeParameters]: Optional generic type parameters for the extension
  /// - [getters]: Optional list of getter methods. Defaults to empty list
  /// - [setters]: Optional list of setter methods. Defaults to empty list
  /// - [methods]: Optional list of methods. Defaults to empty list
  ///
  /// **Example:**
  /// ```dart
  /// Extension(
  ///   docComment: '/// String utilities',
  ///   annotations: ['@experimental'],
  ///   extensionName: 'StringExt',
  ///   extendedType: 'String',
  ///   typeParameters: [TypeParameter('T')],
  ///   methods: [Method(name: 'test', body: (b) => b.write('...'))],
  /// )
  /// ```
  Extension({
    this.docComment,
    List<String>? annotations,
    this.extensionName,
    required this.extendedType,
    this.typeParameters,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Method>? methods,
  })  : annotations = annotations ?? [],
        getters = getters ?? [],
        setters = setters ?? [],
        methods = methods ?? [];

  /// Creates an [Extension] from an [ExtensionElement] during code generation.
  ///
  /// This static factory method is used primarily by code generators (like `build_runner`)
  /// to parse existing Dart extension declarations and convert them into [Extension] objects.
  ///
  /// **Process:**
  /// 1. Extracts the extension name (null if unnamed)
  /// 2. Captures the extended type as a string representation
  /// 3. Parses all accessors (getters and setters) including their static/instance status
  /// 4. Parses all methods including their static/instance status
  ///
  /// **Parameters:**
  /// - [extensionElement]: The analyzer's representation of an extension declaration
  /// - [buildStep]: Provides access to the resolver for parsing AST nodes
  ///
  /// **Returns:** A [Future] that completes with a fully-populated [Extension] object.
  ///
  /// **Note:** The [Getter], [Setter], and [Method] objects will automatically have their
  /// `static` property set based on the original extension members.
  ///
  /// **Example:**
  /// ```dart
  /// final extension = await Extension.from(extensionElement, buildStep);
  /// ```
  static Future<Extension> from(
    ExtensionElement extensionElement,
    BuildStep buildStep,
  ) async =>
      Extension(
        docComment: extensionElement.documentationComment,
        annotations: extensionElement.metadata.map((e) => e.toSource()).toList(),
        extensionName: extensionElement.name,
        extendedType: '${extensionElement.extendedType}',
        getters: await extensionElement.accessors
            .where((e) => e.isGetter)
            .toList()
            .mapAsync((e) => Getter.from(e, buildStep)),
        setters: await extensionElement.accessors
            .where((e) => e.isSetter)
            .toList()
            .mapAsync((e) => Setter.from(e, buildStep)),
        methods: await extensionElement.methods.mapAsync((e) => Method.from(e, buildStep)),
      );

  /// Creates a copy of this [Extension] with some properties replaced.
  ///
  /// This method implements the "copy-with" pattern, allowing you to create a new
  /// [Extension] instance based on an existing one, selectively overriding specific
  /// properties while preserving the rest.
  ///
  /// **Parameters:** All parameters are optional. Any parameter that is null will use
  /// the value from the current instance.
  ///
  /// - [docComment]: New documentation comment (or null to keep current)
  /// - [annotations]: New annotations list (or null to keep current)
  /// - [extensionName]: New extension name (or null to keep current)
  /// - [extendedType]: New extended type (or null to keep current)
  /// - [typeParameters]: New type parameters (or null to keep current)
  /// - [getters]: New getters list (or null to keep current)
  /// - [setters]: New setters list (or null to keep current)
  /// - [methods]: New methods list (or null to keep current)
  ///
  /// **Returns:** A new [Extension] instance with the specified changes.
  ///
  /// **Example:**
  /// ```dart
  /// final original = Extension(
  ///   extensionName: 'MyExt',
  ///   extendedType: 'String',
  ///   methods: [method1],
  /// );
  ///
  /// final modified = original.copyWith(
  ///   annotations: ['@deprecated'],
  ///   methods: [method1, method2], // Add another method
  /// );
  /// // modified has same name and extendedType, but different annotations and methods
  /// ```
  Extension copyWith({
    String? docComment,
    List<String>? annotations,
    String? extensionName,
    String? extendedType,
    List<TypeParameter>? typeParameters,
    List<Getter>? getters,
    List<Setter>? setters,
    List<Method>? methods,
  }) =>
      Extension(
        docComment: docComment ?? this.docComment,
        annotations: annotations ?? this.annotations,
        extensionName: extensionName ?? this.extensionName,
        extendedType: extendedType ?? this.extendedType,
        typeParameters: typeParameters ?? this.typeParameters,
        getters: getters ?? this.getters,
        setters: setters ?? this.setters,
        methods: methods ?? this.methods,
      );

  /// Writes the Dart source code representation of this extension to a [StringBuffer].
  ///
  /// This internal method generates the actual Dart extension declaration syntax,
  /// following the proper Dart grammar for extensions:
  ///
  /// **Syntax Format:**
  /// ```
  /// [docComment]
  /// [annotations]
  /// extension [name][<typeParams>] on <extendedType> {
  ///   <members>
  /// }
  /// ```
  ///
  /// **Process:**
  /// 1. Writes the documentation comment (if present)
  /// 2. Writes annotations (if any), each on its own line
  /// 3. Writes the `extension` keyword
  /// 4. Writes the extension name (if present)
  /// 5. Writes generic type parameters (if present) in angle brackets
  /// 6. Writes the `on` keyword followed by the extended type
  /// 7. Writes opening brace `{`
  /// 8. Writes all members (getters, setters, methods in that order)
  /// 9. Writes closing brace `}`
  ///
  /// **Member Order:**
  /// Members are written in the following order for consistency:
  /// - Getters (static first, then instance - determined by each Getter's `static` property)
  /// - Setters (static first, then instance - determined by each Setter's `static` property)
  /// - Methods (static first, then instance - determined by each Method's `static` property)
  ///
  /// **Examples of Generated Code:**
  ///
  /// Simple unnamed extension:
  /// ```dart
  /// extension on String { ... }
  /// ```
  ///
  /// Named extension:
  /// ```dart
  /// extension StringExtensions on String { ... }
  /// ```
  ///
  /// With documentation and annotations:
  /// ```dart
  /// /// Provides string utilities.
  /// @deprecated
  /// extension StringExtensions on String { ... }
  /// ```
  ///
  /// Generic extension:
  /// ```dart
  /// extension ListExtensions<T> on List<T> { ... }
  /// ```
  ///
  /// Generic extension with bounds:
  /// ```dart
  /// extension NumExtensions<T extends num> on T { ... }
  /// ```
  ///
  /// **Parameters:**
  /// - [b]: The [StringBuffer] to write the extension declaration to
  ///
  /// **Note:** This is an internal method (prefixed with `_`) and is called automatically
  /// by the public `writeToBuffer` method inherited from [PublicBufferWritable].
  void _writeToBuffer(StringBuffer b) {
    // Write documentation comment
    if (docComment != null && docComment!.isNotEmpty) {
      b.write(docComment);
    }

    // Write annotations
    for (final annotation in annotations) {
      b.write('$annotation ');
    }

    b.write('extension ');

    // Write extension name if present
    if (extensionName != null) b.write('$extensionName');

    // Write type parameters if present
    if (typeParameters != null && typeParameters!.isNotEmpty) {
      b.write('<');
      b.write(typeParameters!.map((tp) => tp.toString()).join(', '));
      b.write('>');
    }

    // Add space before 'on' if we wrote a name or type parameters
    if (extensionName != null || (typeParameters != null && typeParameters!.isNotEmpty)) {
      b.write(' ');
    }

    b.write('on $extendedType ');
    b.write('{');

    // Write all members
    [
      ...getters,
      ...setters,
      ...methods,
    ]._writeToBuffer(b);

    b.write('}');
  }
}
