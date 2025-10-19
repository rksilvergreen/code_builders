part of code_builders;

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
