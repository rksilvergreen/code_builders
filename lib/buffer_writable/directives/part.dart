part of code_builder;

/// Represents a Dart `part` directive for splitting a library across multiple files.
///
/// The `part` directive is used in the main library file to include additional
/// source files that are part of the same library. Each included file must have
/// a corresponding `part of` directive pointing back to the main library.
///
/// This allows you to organize large libraries into multiple files while
/// maintaining a single library scope where all parts can access each other's
/// private members.
///
/// This class generates part statements in various formats:
/// - Absolute parts: `part 'dart:core';` (rare usage)
/// - Relative parts: `part 'src/models.dart';`
/// - Package parts: `part 'package:my_lib/internal.dart';`
///
class Part extends UriDirective {
  /// Creates an absolute part statement.
  ///
  /// Example:
  /// ```dart
  /// Part.absolute('src/internal.dart')
  /// // Generates: part 'src/internal.dart';
  /// ```
  Part.absolute(String path) : super('part', UriReference.absolute(path));

  /// Creates a relative part statement.
  ///
  /// The [path] is the target file path, and optional [from] specifies the
  /// reference point for calculating the relative path.
  ///
  /// Example:
  /// ```dart
  /// Part.relative('src/models.dart', from: 'lib/')
  /// // Generates: part 'src/models.dart';
  /// ```
  Part.relative(String path, {String? from}) : super('part', UriReference.relative(path, from: from));

  /// Creates a package part statement.
  ///
  /// Example:
  /// ```dart
  /// Part.package('my_package', 'src/internal.dart')
  /// // Generates: part 'package:my_package/src/internal.dart';
  /// ```
  Part.package(String package, String path) : super('part', UriReference.package(package, path));
}

/// A collection of part directives for batch creation.
///
/// This class provides convenience constructors for creating multiple part
/// statements at once, which is common when a library is split across many files.
///
/// Example:
/// ```dart
/// var parts = PartCollection.relative([
///   'src/models.dart',
///   'src/controllers.dart',
///   'src/views.dart',
/// ], from: 'lib/');
/// ```
class PartCollection extends _DirectiveCollection<Part> {
  /// Creates a collection of absolute part directives from a list of [paths].
  ///
  /// Each path in the list becomes a `Part.absolute()` statement.
  PartCollection.absolute(List<String> paths) : super(paths.map((e) => Part.absolute(e)).toList());

  /// Creates a collection of relative part directives from a list of [paths].
  ///
  /// The optional [from] parameter is applied to all parts for calculating
  /// relative paths.
  PartCollection.relative(List<String> paths, {String? from})
      : super(paths.map((e) => Part.relative(e, from: from)).toList());

  /// Creates a collection of package part directives for files within the same [package].
  ///
  /// Each path in [paths] becomes a part from the specified package.
  ///
  /// Example:
  /// ```dart
  /// PartCollection.package('my_lib', ['src/a.dart', 'src/b.dart'])
  /// ```
  PartCollection.package(String package, List<String> paths)
      : super(paths.map((e) => Part.package(package, e)).toList());
}
