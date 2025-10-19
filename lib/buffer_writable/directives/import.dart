part of code_builders;

/// Represents a Dart `import` directive for including external libraries and files.
///
/// This class generates import statements in various formats:
/// - Absolute imports: `import 'dart:async';`
/// - Relative imports: `import '../models/user.dart';`
/// - Package imports: `import 'package:flutter/material.dart';`
///
class Import extends UriDirective {
  /// Creates an absolute import statement.
  ///
  /// Example:
  /// ```dart
  /// Import.absolute('dart:async')
  /// // Generates: import 'dart:async';
  /// ```
  Import.absolute(String path) : super('import', UriReference.absolute(path));

  /// Creates a relative import statement.
  ///
  /// The [path] is the target file path, and optional [from] specifies the
  /// reference point for calculating the relative path.
  ///
  /// Example:
  /// ```dart
  /// Import.relative('models/user.dart', from: 'lib/controllers/')
  /// // Generates: import '../models/user.dart';
  /// ```
  Import.relative(String path, {String? from}) : super('import', UriReference.relative(path, from: from));

  /// Creates a package import statement.
  ///
  /// Example:
  /// ```dart
  /// Import.package('flutter', 'material.dart')
  /// // Generates: import 'package:flutter/material.dart';
  /// ```
  Import.package(String package, String path) : super('import', UriReference.package(package, path));
}

/// A collection of import directives for batch creation.
///
/// This class provides convenience constructors for creating multiple import
/// statements at once, reducing boilerplate code when importing several files
/// of the same type.
///
/// Example:
/// ```dart
/// var imports = ImportCollection.package('flutter', [
///   'material.dart',
///   'widgets.dart',
///   'gestures.dart',
/// ]);
/// ```
class ImportCollection extends _DirectiveCollection<Import> {
  /// Creates a collection of absolute imports from a list of [paths].
  ///
  /// Each path in the list becomes an `Import.absolute()` statement.
  ImportCollection.absolute(List<String> paths) : super(paths.map((e) => Import.absolute(e)).toList());

  /// Creates a collection of relative imports from a list of [paths].
  ///
  /// The optional [from] parameter is applied to all imports for calculating
  /// relative paths.
  ImportCollection.relative(List<String> paths, {String? from})
      : super(paths.map((e) => Import.relative(e, from: from)).toList());

  /// Creates a collection of package imports for files within the same [package].
  ///
  /// Each path in [paths] becomes an import from the specified package.
  ///
  /// Example:
  /// ```dart
  /// ImportCollection.package('dart', ['async', 'io', 'convert'])
  /// ```
  ImportCollection.package(String package, List<String> paths)
      : super(paths.map((e) => Import.package(package, e)).toList());
}
