part of dart_source_builder;

/// Represents a Dart `part of` directive that declares a file as part of a library.
///
/// The `part of` directive must appear at the top of a file that is included
/// as a part of another library (via the `part` directive in the main library file).
/// It establishes that this file belongs to the parent library and shares its scope.
///
/// There are two forms of `part of`:
/// 1. URI-based: `part of 'library_file.dart';` (modern, recommended)
/// 2. Name-based: `part of library_name;` (legacy, for named libraries)
///
/// This abstract class provides factory constructors for creating different
/// types of `part of` statements. The implementation is delegated to private
/// concrete classes based on the form being used.
abstract class PartOf extends Directive {
  /// Creates a URI-based `part of` statement with an absolute path.
  ///
  /// Example:
  /// ```dart
  /// PartOf.uriAbsolute('lib/main.dart')
  /// // Generates: part of 'lib/main.dart';
  /// ```
  factory PartOf.uriAbsolute(String path) => _PartOfUriStatement.absolute(path);

  /// Creates a URI-based `part of` statement with a relative path.
  ///
  /// The [path] is the target library file path, and optional [from] specifies
  /// the reference point for calculating the relative path.
  ///
  /// Example:
  /// ```dart
  /// PartOf.uriRelative('../main.dart')
  /// // Generates: part of '../main.dart';
  /// ```
  factory PartOf.uriRelative(String path, {String? from}) => _PartOfUriStatement.relative(path, from: from);

  /// Creates a URI-based `part of` statement with a package path.
  ///
  /// Example:
  /// ```dart
  /// PartOf.uriPackage('my_package', 'main.dart')
  /// // Generates: part of 'package:my_package/main.dart';
  /// ```
  factory PartOf.uriPackage(String package, String path) => _PartOfUriStatement.package(package, path);

  /// Creates a name-based `part of` statement for a named library.
  ///
  /// This is the legacy form used when the parent library has a `library` directive
  /// with a name.
  ///
  /// Example:
  /// ```dart
  /// PartOf.library('my_library')
  /// // Generates: part of my_library;
  /// ```
  factory PartOf.library(String library) => _PartOfLibraryStatement(library);

  /// Creates a `part of` with absolute path resolution deferred until build time.
  ///
  /// The [inputId] identifies the parent library asset. If null, it will be set
  /// during the build process.
  factory PartOf.fromInputAbsolute([AssetId? inputId]) => _PartOfStatementFromInput('absolute', inputId);

  /// Creates a `part of` with relative path resolution deferred until build time.
  ///
  /// The relative path is calculated during the build based on the input
  /// and output asset locations.
  factory PartOf.fromInputRelative([AssetId? inputId]) => _PartOfStatementFromInput('relative', inputId);

  /// Creates a `part of` with package path resolution deferred until build time.
  ///
  /// The package path is determined during the build from the asset's package.
  factory PartOf.fromInputPackage([AssetId? inputId]) => _PartOfStatementFromInput('package', inputId);
}

/// Implementation of URI-based `part of` statements.
///
/// This class generates modern `part of 'uri';` statements that reference
/// the parent library by file path rather than library name.
///
/// Extends [UriDirective] to leverage URI reference handling for proper
/// formatting of absolute, relative, and package paths.
class _PartOfUriStatement extends UriDirective implements PartOf {
  /// Creates an absolute URI-based `part of` statement.
  ///
  /// Example: `part of 'dart:core';` or `part of 'file:///path/to/lib.dart';`
  _PartOfUriStatement.absolute(String path) : super('part of', UriReference.absolute(path));

  /// Creates a relative URI-based `part of` statement.
  ///
  /// Example: `part of '../main.dart';`
  _PartOfUriStatement.relative(String path, {String? from}) : super('part of', UriReference.relative(path, from: from));

  /// Creates a package URI-based `part of` statement.
  ///
  /// Example: `part of 'package:my_package/main.dart';`
  _PartOfUriStatement.package(String package, String path) : super('part of', UriReference.package(package, path));
}

/// Implementation of library name-based `part of` statements.
///
/// This class generates legacy-style `part of library_name;` statements
/// used when the parent library has an explicit `library` directive with a name.
///
/// Extends [Directive] directly (not [UriDirective]) since it doesn't use a URI.
class _PartOfLibraryStatement extends Directive implements PartOf {
  /// Creates a library name-based `part of` statement.
  ///
  /// Example input: `'my_library'`
  /// Generated output: `part of my_library;`
  _PartOfLibraryStatement(String library) : super('part of', library);
}

/// Internal implementation for `part of` directives with intelligent deferred resolution.
///
/// This class is unique among the `*FromInput` implementations because it must
/// determine at build time whether to use a library name or URI form, based on
/// whether the parent library has an explicit name.
///
/// The resolution happens in three phases:
/// 1. Construction: Store the part type and optional input asset ID
/// 2. Build time: Call [_set] to analyze the parent library and resolve paths
/// 3. Write time: Intelligently choose between name-based or URI-based form
///
/// This smart resolution ensures the generated `part of` statement matches
/// the style of the parent library.
class _PartOfStatementFromInput extends Directive implements PartOf {
  /// The type of URI to generate if using URI form: 'absolute', 'relative', or 'package'.
  final String _type;

  /// The asset ID of the parent library file. May be null until [_set] is called.
  AssetId? _inputId;

  /// The asset ID of the output file (the part file) that will contain this `part of`.
  /// Used for calculating relative paths. Set by [_set].
  late AssetId _outputId;

  /// The package manager for resolving file paths within the package structure.
  /// Set by [_set] during the build process.
  late PackageManager _packageManager;

  /// The analyzed library element of the parent library.
  /// Used to determine if the library has a name (for name-based `part of`)
  /// or is unnamed (for URI-based `part of`). Set by [_set].
  late LibraryElement _libraryElement;

  /// Creates a `part of` placeholder with the specified [_type] and optional [_inputId].
  ///
  /// The parent [Directive] is initialized with null values since the actual
  /// form isn't known until the library is analyzed at build time.
  _PartOfStatementFromInput(this._type, this._inputId) : super(null, null);

  /// Configures this `part of` directive with build context information and analyzes the library.
  ///
  /// Called by the build system to provide:
  /// - [inputId]: The parent library asset (used if not provided at construction)
  /// - [outputId]: The asset containing this `part of` statement (the part file)
  /// - [packageManagers]: Collection of package managers for path resolution
  ///
  /// This method retrieves the [LibraryElement] to determine if the parent library
  /// has a name, which affects whether to use name-based or URI-based form.
  Future<void> _set(AssetId inputId, AssetId outputId, PackageManagers packageManagers) async {
    _inputId ??= inputId;
    _outputId = outputId;
    _packageManager = packageManagers[_inputId!.package]!;
    // Analyze the parent library to check if it has a name
    _libraryElement = (await _packageManager.getLibraryElements([_packageManager._pathFromLib(_inputId!)])).first;
  }

  /// Intelligently generates the `part of` statement based on library analysis.
  ///
  /// Decision logic:
  /// 1. If the parent library has a display name (named library):
  ///    - Use name-based form: `part of library_name;`
  /// 2. If the parent library is unnamed:
  ///    - Use URI-based form based on [_type]:
  ///      - 'absolute': `part of 'absolute/path';`
  ///      - 'relative': `part of '../parent.dart';`
  ///      - 'package': `part of 'package:name/parent.dart';`
  ///
  /// This ensures compatibility with both modern and legacy library styles.
  @override
  void _writeToBuffer(StringBuffer b) {
    // Check if the parent library has an explicit name
    bool isNamedLibrary = _libraryElement.displayName != '';
    PartOf? partOf;

    if (isNamedLibrary) {
      // Use library name form for named libraries
      partOf = _PartOfLibraryStatement(_libraryElement.displayName);
    } else {
      // Use URI form for unnamed libraries, based on the requested type
      switch (_type) {
        case 'absolute':
          partOf = _PartOfUriStatement.absolute(_packageManager._pathAbsolute(_inputId!));
          break;
        case 'relative':
          partOf = _PartOfUriStatement.relative(_packageManager._pathFromLib(_inputId!),
              from: _packageManager._pathFromLib(_outputId, false));
          break;
        case 'package':
          partOf = _PartOfUriStatement.package(_inputId!.package, _packageManager._pathFromLib(_inputId!));
          break;
      }
    }

    partOf!._writeToBuffer(b);
  }
}
