part of dart_source_builder;

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
/// For build-time code generation, use the `.fromInput*` factory constructors
/// to defer path resolution until the build process runs.
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

  /// Creates a part with absolute path resolution deferred until build time.
  ///
  /// The [inputId] identifies the asset to include as a part. If null, it will
  /// be set during the build process. Uses [_PartFromInput] for lazy resolution.
  factory Part.fromInputAbsolute([AssetId? inputId]) => _PartFromInput('absolute', inputId);

  /// Creates a part with relative path resolution deferred until build time.
  ///
  /// The relative path is calculated during the build based on the input
  /// and output asset locations.
  factory Part.fromInputRelative([AssetId? inputId]) => _PartFromInput('relative', inputId);

  /// Creates a part with package path resolution deferred until build time.
  ///
  /// The package path is determined during the build from the asset's package.
  factory Part.fromInputPackage([AssetId? inputId]) => _PartFromInput('package', inputId);
}

/// Internal implementation for part directives with deferred path resolution.
///
/// This class allows part paths to be determined at build time rather than
/// at construction time. It's particularly useful in code generation scenarios
/// where the actual file paths aren't known until the build system runs.
///
/// The resolution happens in three phases:
/// 1. Construction: Store the part type and optional input asset ID
/// 2. Build time: Call [_set] to resolve paths using the build system
/// 3. Write time: Generate the actual part statement in [_writeToBuffer]
class _PartFromInput extends UriDirective implements Part {
  /// The type of part to generate: 'absolute', 'relative', or 'package'.
  final String _type;

  /// The asset ID of the file to include as a part. May be null until [_set] is called.
  AssetId? _inputId;

  /// The asset ID of the output file that will contain this part directive.
  /// Used for calculating relative paths. Set by [_set].
  late AssetId _outputId;

  /// The package manager for resolving file paths within the package structure.
  /// Set by [_set] during the build process.
  late PackageManager _packageManager;

  /// Creates a part placeholder with the specified [_type] and optional [_inputId].
  ///
  /// The parent [UriDirective] is initialized with null values since the actual
  /// URI isn't known until build time.
  _PartFromInput(this._type, this._inputId) : super(null, null);

  /// Configures this part directive with build context information.
  ///
  /// Called by the build system to provide:
  /// - [inputId]: The asset to include as a part (used if not provided at construction)
  /// - [outputId]: The asset containing this part statement (the main library file)
  /// - [packageManagers]: Collection of package managers for path resolution
  ///
  /// This method sets up the [_packageManager] for the input asset's package.
  Future<void> _set(AssetId inputId, AssetId outputId, PackageManagers packageManagers) async {
    _inputId ??= inputId;
    _outputId = outputId;
    _packageManager = packageManagers[_inputId!.package]!;
  }

  /// Generates the part statement based on the type and resolved paths.
  ///
  /// Creates the appropriate [Part] instance using the package manager's
  /// path resolution methods, then writes it to the buffer.
  ///
  /// Path resolution differs by type:
  /// - 'absolute': Full absolute path from package manager
  /// - 'relative': Path relative to the output file's location (the main library)
  /// - 'package': Package URI with path from lib directory
  @override
  void _writeToBuffer(StringBuffer b) {
    Part? part;

    switch (_type) {
      case 'absolute':
        part = Part.absolute(_packageManager._pathAbsolute(_inputId!));
        break;
      case 'relative':
        part = Part.relative(_packageManager._pathFromLib(_inputId!),
            from: _packageManager._pathFromLib(_outputId, false));
        break;
      case 'package':
        part = Part.package(_inputId!.package, _packageManager._pathFromLib(_inputId!));
        break;
    }

    part!._writeToBuffer(b);
  }
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

  /// Creates a collection of parts with absolute path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes a `Part.fromInputAbsolute()`.
  PartCollection.fromInputAbsolute(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Part.fromInputAbsolute(e)).toList());

  /// Creates a collection of parts with relative path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes a `Part.fromInputRelative()`.
  PartCollection.fromInputRelative(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Part.fromInputRelative(e)).toList());

  /// Creates a collection of parts with package path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes a `Part.fromInputPackage()`.
  PartCollection.fromInputPackage(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Part.fromInputPackage(e)).toList());
}
