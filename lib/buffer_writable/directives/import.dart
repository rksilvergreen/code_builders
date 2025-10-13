part of dart_source_builder;

/// Represents a Dart `import` directive for including external libraries and files.
///
/// This class generates import statements in various formats:
/// - Absolute imports: `import 'dart:async';`
/// - Relative imports: `import '../models/user.dart';`
/// - Package imports: `import 'package:flutter/material.dart';`
///
/// For build-time code generation, use the `.fromInput*` factory constructors
/// to defer path resolution until the build process runs.
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

  /// Creates an import with absolute path resolution deferred until build time.
  ///
  /// The [inputId] identifies the asset to import. If null, it will be set
  /// during the build process. Uses [_ImportFromInput] for lazy resolution.
  factory Import.fromInputAbsolute([AssetId? inputId]) => _ImportFromInput('absolute', inputId);

  /// Creates an import with relative path resolution deferred until build time.
  ///
  /// The relative path is calculated during the build based on the input
  /// and output asset locations.
  factory Import.fromInputRelative([AssetId? inputId]) => _ImportFromInput('relative', inputId);

  /// Creates an import with package path resolution deferred until build time.
  ///
  /// The package path is determined during the build from the asset's package.
  factory Import.fromInputPackage([AssetId? inputId]) => _ImportFromInput('package', inputId);
}

/// Internal implementation for imports with deferred path resolution.
///
/// This class allows import paths to be determined at build time rather than
/// at construction time. It's particularly useful in code generation scenarios
/// where the actual file paths aren't known until the build system runs.
///
/// The resolution happens in two phases:
/// 1. Construction: Store the import type and optional input asset ID
/// 2. Build time: Call [_set] to resolve paths using the build system
/// 3. Write time: Generate the actual import statement in [_writeToBuffer]
class _ImportFromInput extends UriDirective implements Import {
  /// The type of import to generate: 'absolute', 'relative', or 'package'.
  final String _type;

  /// The asset ID of the file to import. May be null until [_set] is called.
  AssetId? _inputId;

  /// The asset ID of the output file that will contain this import.
  /// Used for calculating relative paths. Set by [_set].
  late AssetId _outputId;

  /// The package manager for resolving file paths within the package structure.
  /// Set by [_set] during the build process.
  late PackageManager _packageManager;

  /// Creates an import placeholder with the specified [_type] and optional [_inputId].
  ///
  /// The parent [UriDirective] is initialized with null values since the actual
  /// URI isn't known until build time.
  _ImportFromInput(this._type, this._inputId) : super(null, null);

  /// Configures this import with build context information.
  ///
  /// Called by the build system to provide:
  /// - [inputId]: The asset to import (used if not provided at construction)
  /// - [outputId]: The asset containing this import statement
  /// - [packageManagers]: Collection of package managers for path resolution
  ///
  /// This method sets up the [_packageManager] for the input asset's package.
  Future<void> _set(AssetId inputId, AssetId outputId, PackageManagers packageManagers) async {
    _inputId ??= inputId;
    _outputId = outputId;
    _packageManager = packageManagers[_inputId!.package]!;
  }

  /// Generates the import statement based on the type and resolved paths.
  ///
  /// Creates the appropriate [Import] instance using the package manager's
  /// path resolution methods, then writes it to the buffer.
  ///
  /// Path resolution differs by type:
  /// - 'absolute': Full absolute path from package manager
  /// - 'relative': Path relative to the output file's location
  /// - 'package': Package URI with path from lib directory
  @override
  void _writeToBuffer(StringBuffer b) {
    Import? import;

    switch (_type) {
      case 'absolute':
        import = Import.absolute(_packageManager._pathAbsolute(_inputId!));
        break;
      case 'relative':
        import = Import.relative(_packageManager._pathFromLib(_inputId!),
            from: _packageManager._pathFromLib(_outputId, false));
        break;
      case 'package':
        import = Import.package(_inputId!.package, _packageManager._pathFromLib(_inputId!));
        break;
    }

    import!._writeToBuffer(b);
  }
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

  /// Creates a collection of imports with absolute path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes an `Import.fromInputAbsolute()`.
  ImportCollection.fromInputAbsolute(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Import.fromInputAbsolute(e)).toList());

  /// Creates a collection of imports with relative path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes an `Import.fromInputRelative()`.
  ImportCollection.fromInputRelative(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Import.fromInputRelative(e)).toList());

  /// Creates a collection of imports with package path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes an `Import.fromInputPackage()`.
  ImportCollection.fromInputPackage(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Import.fromInputPackage(e)).toList());
}
