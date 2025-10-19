part of code_builder;

/// Represents a URI reference used in Dart directive statements.
///
/// This abstract class provides a unified interface for handling different types
/// of URI references that appear in Dart directives (import, export, part, part of).
/// It ensures proper path formatting and normalization across platforms.
///
/// The class automatically normalizes path separators by converting backslashes
/// to forward slashes, ensuring consistent URI formatting regardless of the
/// operating system.
///
/// Three types of URI references are supported:
/// - **Absolute**: Direct paths like `dart:core` or `file:///path/to/file.dart`
/// - **Relative**: Paths relative to another file, like `../models/user.dart`
/// - **Package**: Package URIs like `package:flutter/material.dart`
///
/// Use the factory constructors to create the appropriate type of URI reference.
abstract class UriReference {
  /// The normalized URI string with forward slashes.
  ///
  /// This string is used when the URI reference is converted to a string
  /// for writing to generated code.
  final String _str;

  /// Internal constructor that normalizes path separators.
  ///
  /// Converts all backslashes to forward slashes to ensure consistent
  /// URI formatting across Windows and Unix-like systems. Dart URIs
  /// always use forward slashes, even on Windows.
  UriReference._(String str) : _str = str.replaceAll('\\', '/');

  /// Creates an absolute URI reference.
  ///
  /// Absolute URIs are used for:
  /// - Dart core libraries: `dart:core`, `dart:async`
  /// - File URIs: `file:///absolute/path/to/file.dart`
  /// - Other absolute paths
  ///
  /// Example:
  /// ```dart
  /// UriReference.absolute('dart:async')
  /// // Returns: dart:async
  /// ```
  factory UriReference.absolute(String path) => _AbsoluteUriReference(path);

  /// Creates a relative URI reference.
  ///
  /// Calculates the relative path from [from] to [path]. If [from] is not
  /// provided, it defaults to the current working directory.
  ///
  /// This is commonly used for imports/exports between files in the same package.
  ///
  /// Example:
  /// ```dart
  /// UriReference.relative('lib/models/user.dart', from: 'lib/controllers/')
  /// // Returns: ../models/user.dart
  /// ```
  ///
  /// Parameters:
  /// - [path]: The target file path
  /// - [from]: The reference point for calculating the relative path (optional)
  factory UriReference.relative(String path, {String? from}) => _RelativeUriReference(path, from: from);

  /// Creates a package URI reference.
  ///
  /// Package URIs follow the format: `package:{package_name}/{path_within_lib}`
  ///
  /// These are used to reference files in Dart packages, where the path is
  /// relative to the package's `lib/` directory.
  ///
  /// Example:
  /// ```dart
  /// UriReference.package('flutter', 'material.dart')
  /// // Returns: package:flutter/material.dart
  /// ```
  ///
  /// Parameters:
  /// - [package]: The package name
  /// - [path]: The path within the package's lib directory
  factory UriReference.package(String package, String path) => _PackageUriReference(package, path);

  /// Returns the normalized URI string.
  ///
  /// This string representation is used when the URI is written to generated
  /// Dart code in directive statements.
  @override
  String toString() => _str;
}

/// Implementation of absolute URI references.
///
/// This class handles absolute paths that don't require relative path calculation
/// or package URI formatting. The path is passed through as-is after normalization.
///
/// Common use cases:
/// - Dart built-in libraries: `dart:core`, `dart:async`, `dart:io`
/// - Absolute file paths (less common in practice)
class _AbsoluteUriReference extends UriReference {
  /// Creates an absolute URI reference with the given [path].
  ///
  /// The path is normalized (backslashes converted to forward slashes)
  /// by the parent constructor.
  _AbsoluteUriReference(String path) : super._(path);
}

/// Implementation of relative URI references.
///
/// This class calculates the relative path from one file to another using
/// the `path` package. It's essential for imports and exports between files
/// in the same package when you want to avoid package URIs.
///
/// The relative path calculation ensures that the generated import/export
/// statement correctly references the target file from the source file's location.
class _RelativeUriReference extends UriReference {
  /// Creates a relative URI reference from [from] to [path].
  ///
  /// Uses the `path` package's `relative` function to calculate the
  /// shortest relative path. If [from] is not provided, defaults to
  /// the current working directory.
  ///
  /// Parameters:
  /// - [path]: The target file path
  /// - [from]: The reference point (defaults to current directory if null)
  _RelativeUriReference(String path, {String? from}) : super._(p.relative(path, from: from ?? p.current));
}

/// Implementation of package URI references.
///
/// This class generates standard Dart package URIs in the format:
/// `package:{package_name}/{path_from_lib}`
///
/// Package URIs are the recommended way to reference files in Dart packages
/// because they are independent of the file system structure and work correctly
/// across different development environments.
class _PackageUriReference extends UriReference {
  /// The package name (e.g., 'flutter', 'dart', 'my_package').
  final String package;

  /// The path within the package's lib directory (e.g., 'material.dart', 'src/widgets.dart').
  final String path;

  /// Creates a package URI reference.
  ///
  /// Constructs a URI in the format: `package:{package}/{path}`
  ///
  /// The path separator is used to ensure proper formatting between the
  /// package name and path, though in practice this is always a forward slash
  /// after normalization.
  ///
  /// Example:
  /// ```dart
  /// _PackageUriReference('flutter', 'widgets.dart')
  /// // Generates: package:flutter/widgets.dart
  /// ```
  _PackageUriReference(this.package, this.path) : super._('package:$package${p.separator}$path');
}
