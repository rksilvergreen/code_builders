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
/// For build-time code generation, use the `.fromInput*` factory constructors
/// to defer path resolution until the build process runs.
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

  /// Creates an export with absolute path resolution deferred until build time.
  ///
  /// The [inputId] identifies the asset to export. If null, it will be set
  /// during the build process. Uses [_ExportFromInput] for lazy resolution.
  factory Export.fromInputAbsolute([AssetId? inputId]) => _ExportFromInput('absolute', inputId);

  /// Creates an export with relative path resolution deferred until build time.
  ///
  /// The relative path is calculated during the build based on the input
  /// and output asset locations.
  factory Export.fromInputRelative([AssetId? inputId]) => _ExportFromInput('relative', inputId);

  /// Creates an export with package path resolution deferred until build time.
  ///
  /// The package path is determined during the build from the asset's package.
  factory Export.fromInputPackage([AssetId? inputId]) => _ExportFromInput('package', inputId);
}

/// Internal implementation for exports with deferred path resolution.
///
/// This class allows export paths to be determined at build time rather than
/// at construction time. It's particularly useful in code generation scenarios
/// where the actual file paths aren't known until the build system runs.
///
/// The resolution happens in three phases:
/// 1. Construction: Store the export type and optional input asset ID
/// 2. Build time: Call [_set] to resolve paths using the build system
/// 3. Write time: Generate the actual export statement in [_writeToBuffer]
class _ExportFromInput extends UriDirective implements Export {
  /// The type of export to generate: 'absolute', 'relative', or 'package'.
  final String _type;

  /// The asset ID of the file to export. May be null until [_set] is called.
  AssetId? _inputId;

  /// The asset ID of the output file that will contain this export.
  /// Used for calculating relative paths. Set by [_set].
  late AssetId _outputId;

  /// The package manager for resolving file paths within the package structure.
  /// Set by [_set] during the build process.
  late PackageManager _packageManager;

  /// Creates an export placeholder with the specified [_type] and optional [_inputId].
  ///
  /// The parent [UriDirective] is initialized with null values since the actual
  /// URI isn't known until build time.
  _ExportFromInput(this._type, this._inputId) : super(null, null);

  /// Configures this export with build context information.
  ///
  /// Called by the build system to provide:
  /// - [inputId]: The asset to export (used if not provided at construction)
  /// - [outputId]: The asset containing this export statement
  /// - [packageManagers]: Collection of package managers for path resolution
  ///
  /// This method sets up the [_packageManager] for the input asset's package.
  Future<void> _set(AssetId inputId, AssetId outputId, PackageManagers packageManagers) async {
    _inputId ??= inputId;
    _outputId = outputId;
    _packageManager = packageManagers[_inputId!.package]!;
  }

  /// Generates the export statement based on the type and resolved paths.
  ///
  /// Creates the appropriate [Export] instance using the package manager's
  /// path resolution methods, then writes it to the buffer.
  ///
  /// Path resolution differs by type:
  /// - 'absolute': Full absolute path from package manager
  /// - 'relative': Path relative to the output file's location
  /// - 'package': Package URI with path from lib directory
  @override
  void _writeToBuffer(StringBuffer b) {
    Export? export;

    switch (_type) {
      case 'absolute':
        export = Export.absolute(_packageManager._pathAbsolute(_inputId!));
        break;
      case 'relative':
        export = Export.relative(_packageManager._pathFromLib(_inputId!),
            from: _packageManager._pathFromLib(_outputId, false));
        break;
      case 'package':
        export = Export.package(_inputId!.package, _packageManager._pathFromLib(_inputId!));
        break;
    }

    export!._writeToBuffer(b);
  }
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

  /// Creates a collection of exports with absolute path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes an `Export.fromInputAbsolute()`.
  ExportCollection.fromInputAbsolute(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Export.fromInputAbsolute(e)).toList());

  /// Creates a collection of exports with relative path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes an `Export.fromInputRelative()`.
  ExportCollection.fromInputRelative(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Export.fromInputRelative(e)).toList());

  /// Creates a collection of exports with package path resolution deferred to build time.
  ///
  /// Each asset ID in [inputIds] becomes an `Export.fromInputPackage()`.
  ExportCollection.fromInputPackage(List<AssetId?> inputIds)
      : super(inputIds.map((e) => Export.fromInputPackage(e)).toList());
}
