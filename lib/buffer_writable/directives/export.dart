part of dart_source_builder;

/// Represents a Dart `export` directive for re-exporting symbols from other libraries.
///
/// Export directives make the public API of one library available through another
/// library, allowing you to create a unified public interface that aggregates
/// multiple internal libraries.
///
/// This class generates export statements in various formats:
/// - Absolute exports: `export 'dart:async';`
/// - Relative exports: `export '../models/user.dart';`
/// - Package exports: `export 'package:flutter/material.dart';`
///
class Export extends UriDirective {
  /// Creates an absolute export statement.
  ///
  /// Example:
  /// ```dart
  /// Export.absolute('dart:async')
  /// // Generates: export 'dart:async';
  /// ```
  Export.absolute(String path) : super('export', UriReference.absolute(path));

  /// Creates a relative export statement.
  ///
  /// The [path] is the target file path, and optional [from] specifies the
  /// reference point for calculating the relative path.
  ///
  /// Example:
  /// ```dart
  /// Export.relative('models/user.dart', from: 'lib/')
  /// // Generates: export 'models/user.dart';
  /// ```
  Export.relative(String path, {String? from}) : super('export', UriReference.relative(path, from: from));

  /// Creates a package export statement.
  ///
  /// Example:
  /// ```dart
  /// Export.package('my_package', 'src/internal.dart')
  /// // Generates: export 'package:my_package/src/internal.dart';
  /// ```
  Export.package(String package, String path) : super('export', UriReference.package(package, path));
}

/// A collection of export directives for batch creation.
///
/// This class provides convenience constructors for creating multiple export
/// statements at once, reducing boilerplate code when exporting several files
/// of the same type.
///
/// Example:
/// ```dart
/// var exports = ExportCollection.package('my_package', [
///   'src/models.dart',
///   'src/controllers.dart',
///   'src/utils.dart',
/// ]);
/// ```
class ExportCollection extends _DirectiveCollection<Export> {
  /// Creates a collection of absolute exports from a list of [paths].
  ///
  /// Each path in the list becomes an `Export.absolute()` statement.
  ExportCollection.absolute(List<String> paths) : super(paths.map((e) => Export.absolute(e)).toList());

  /// Creates a collection of relative exports from a list of [paths].
  ///
  /// The optional [from] parameter is applied to all exports for calculating
  /// relative paths.
  ExportCollection.relative(List<String> paths, {String? from})
      : super(paths.map((e) => Export.relative(e, from: from)).toList());

  /// Creates a collection of package exports for files within the same [package].
  ///
  /// Each path in [paths] becomes an export from the specified package.
  ///
  /// Example:
  /// ```dart
  /// ExportCollection.package('my_lib', ['models.dart', 'utils.dart'])
  /// ```
  ExportCollection.package(String package, List<String> paths)
      : super(paths.map((e) => Export.package(package, e)).toList());
}
