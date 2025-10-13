/// A comprehensive code generation library for Dart that provides a flexible
/// framework for creating custom builders with the build system.
///
/// This library extends the build package to simplify the creation of code
/// generators that can analyze source code, generate new Dart files, and
/// manage package dependencies. It provides utilities for working with
/// directives, creating code structures, and managing the package graph.
///
/// ## Main Components
///
/// - [DartSourceBuilder]: The core builder class for creating custom code generators
/// - [PackageManagers]: Manages access to package information and library elements
/// - [BufferWritable]: Base class for all code generation components
/// - Directive classes: Import, Export, Part, PartOf for managing file directives
/// - Code structure classes: Class, Method, Property, Constructor, etc.
///
/// ## Example
///
/// ```dart
/// class MyBuilder extends DartSourceBuilder {
///   MyBuilder() : super(
///     name: 'my_builder',
///     build: (buffer, library, packages, buildStep) async {
///       buffer.writeln('// Generated code here');
///     },
///   );
/// }
/// ```
library dart_source_builder;

import 'dart:collection';
import 'dart:io';
import 'dart:async';
import 'package:build/build.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build_runner_core/build_runner_core.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;
import 'package:recase/recase.dart';

import 'package:glob/glob.dart';
import 'package:dart_style/dart_style.dart';
import 'package:dart_extensions/dart_extensions.dart';
import 'package:build_runner_core/src/package_graph/package_graph.dart';

export 'package:build/build.dart';
export 'package:analyzer/dart/element/element.dart';
export 'package:analyzer/dart/element/type.dart';
export 'package:analyzer/dart/constant/value.dart';
export 'package:yaml/yaml.dart';
export 'package:build_runner_core/src/package_graph/package_graph.dart';

part 'package_mananger.dart';
part 'buffer_writable/directives/uri_reference.dart';

part 'buffer_writable/directives/directive.dart';
part 'buffer_writable/directives/export.dart';
part 'buffer_writable/directives/import.dart';
part 'buffer_writable/directives/part.dart';
part 'buffer_writable/directives/part_of.dart';
part 'buffer_writable/buffer_writable.dart';
part 'buffer_writable/class.dart';
part 'buffer_writable/property.dart';
part 'buffer_writable/constructor.dart';
part 'buffer_writable/method.dart';
part 'buffer_writable/getter.dart';
part 'buffer_writable/setter.dart';
part 'buffer_writable/enum.dart';
part 'buffer_writable/extension.dart';
part 'buffer_writable/mixin.dart';
part 'buffer_writable/global_function.dart';
part 'buffer_writable/global_variable.dart';

/// Function type for determining the output asset from expected outputs.
///
/// Takes a list of [expectedOutputs] and returns the [AssetId] to use
/// for the generated file. Typically returns the first output.
typedef OutputAssetFunction = AssetId Function(List<AssetId> expectedOutputs);

// typedef OutputPathFunction = void Function(PathEditor pathEditor);

/// Function type for creating a directive with access to package managers.
///
/// Used internally for directive creation during the build process.
typedef DirectiveFunction<T extends Directive> = FutureOr<T> Function(PackageManagers packageManagers);

/// Function type for creating a part-of directive.
///
/// Returns a [PartOf] directive or null. When provided, the generated file
/// will be a part file. This is mutually exclusive with imports, exports,
/// and parts.
typedef PartOfFunction = FutureOr<PartOf>? Function(PackageManagers packageManagers);

/// Function type for creating import directives.
///
/// Returns a list of [Import] directives to add to the generated file.
/// Cannot be used if a [PartOfFunction] is provided.
typedef ImportsFunction = FutureOr<List<Import>>? Function(PackageManagers packageManagers);

/// Function type for creating export directives.
///
/// Returns a list of [Export] directives to add to the generated file.
/// Cannot be used if a [PartOfFunction] is provided.
typedef ExportsFunction = FutureOr<List<Export>>? Function(PackageManagers packageManagers);

/// Function type for creating part directives.
///
/// Returns a list of [Part] directives to add to the generated file.
/// Cannot be used if a [PartOfFunction] is provided.
typedef PartsFunction = FutureOr<List<Part>>? Function(PackageManagers packageManagers);

/// The main build function that generates code content.
///
/// Parameters:
/// - [b]: The string buffer to write generated code to
/// - [libraryElement]: The analyzed library element from the input file
/// - [packageManagers]: Access to package information and library elements
/// - [buildStep]: The current build step for accessing assets and resolver
///
/// This is where the actual code generation logic is implemented.
typedef BuildFunction = Future<void> Function(
    StringBuffer b, LibraryElement libraryElement, PackageManagers packageManagers, BuildStep buildStep);

/// A flexible and configurable builder for generating Dart source files.
///
/// [DartSourceBuilder] extends the [Builder] class from the build package to
/// provide a comprehensive framework for code generation. It handles file
/// directives, formatting, validation, and provides access to package information
/// and library analysis.
///
/// ## Features
///
/// - Customizable input validation with glob patterns
/// - Configurable output file paths and extensions
/// - Automatic code formatting with dart_style
/// - Support for imports, exports, parts, and part-of directives
/// - Generated file header messages
/// - Access to package graph and library elements
///
/// ## Usage
///
/// ```dart
/// final builder = DartSourceBuilder(
///   name: 'my_generator',
///   inputValidators: ['lib/**/*.dart'],
///   autoFormat: true,
///   imports: (packages) => [
///     Import.fromPackage('dart:async'),
///   ],
///   build: (buffer, library, packages, buildStep) async {
///     buffer.writeln('// Generated code');
///     for (final element in library.topLevelElements) {
///       buffer.writeln('// Found: ${element.name}');
///     }
///   },
/// );
/// ```
///
/// ## Directives
///
/// You can configure the generated file to be either:
/// - A **part file** by providing [partOf] (cannot use with imports/exports/parts)
/// - A **library file** by providing [imports], [exports], and/or [parts]
///
/// ## Output Path
///
/// By default, generates files in a `gen/` subdirectory with the pattern:
/// `{{dir}}/gen/{{file}}.gen.{{name}}.dart`
///
/// You can customize this with [buildExtensions] or [outputAssetFunction].
class DartSourceBuilder extends Builder {
  final String _name;
  final List<String> _inputValidators;
  final Map<String, List<String>> _buildExtensions;
  final OutputAssetFunction _outputAssetFunction;
  // final OutputPathFunction _outputPathFun;
  final bool _genMessage;
  final bool _autoFormat;
  final DartFormatter _formatter;
  final PartOfFunction _partOf;
  final ImportsFunction? _imports;
  final ExportsFunction? _exports;
  final PartsFunction? _parts;
  final BuildFunction _buildFun;

  /// Creates a new [DartSourceBuilder] with the specified configuration.
  ///
  /// Parameters:
  ///
  /// - [name]: Required. The name of the builder, used in output filenames and
  ///   generated messages.
  ///
  /// - [inputValidators]: Optional. List of glob patterns to match input files.
  ///   Defaults to `['**/*.dart']` (all Dart files). Example: `['lib/models/**/*.dart']`
  ///
  /// - [buildExtensions]: Optional. Map defining the build extension mapping.
  ///   Defaults to generating files in a `gen/` folder with pattern:
  ///   `'{{dir}}/{{file}}.dart': ['{{dir}}/gen/{{file}}.gen.{{name}}.dart']`
  ///
  /// - [outputAssetFunction]: Optional. Function to select which output asset
  ///   to use from expected outputs. Defaults to the first output.
  ///
  /// - [genMessage]: Optional. Whether to include a "Do Not Modify" header in
  ///   generated files. Defaults to `true`.
  ///
  /// - [autoFormat]: Optional. Whether to automatically format generated code
  ///   with dart_style. Defaults to `true`.
  ///
  /// - [formatter]: Optional. Custom [DartFormatter] instance. Defaults to a
  ///   formatter with pageWidth of 100.
  ///
  /// - [partOf]: Optional. Function that returns a [PartOf] directive, making
  ///   the generated file a part file. Cannot be used with [imports], [exports],
  ///   or [parts]. Defaults to `PartOf.fromInputRelative()`.
  ///
  /// - [imports]: Optional. Function returning a list of [Import] directives
  ///   for the generated file. Cannot be used with [partOf].
  ///
  /// - [exports]: Optional. Function returning a list of [Export] directives
  ///   for the generated file. Cannot be used with [partOf].
  ///
  /// - [parts]: Optional. Function returning a list of [Part] directives
  ///   for the generated file. Cannot be used with [partOf].
  ///
  /// - [build]: Required. The main build function that generates the code content.
  ///   Receives a buffer, library element, package managers, and build step.
  ///
  /// Throws an [AssertionError] if both [partOf] and any of [imports], [exports],
  /// or [parts] are provided, since a part file cannot have these directives.
  DartSourceBuilder({
    required String name,
    List<String>? inputValidators,
    Map<String, List<String>>? buildExtensions,
    OutputAssetFunction? outputAssetFunction,
    // OutputPathFunction outputPath,
    bool genMessage = true,
    bool autoFormat = true,
    DartFormatter? formatter,
    PartOfFunction? partOf,
    ImportsFunction? imports,
    ExportsFunction? exports,
    PartsFunction? parts,
    required BuildFunction build,
  })  : assert((partOf == null) || (imports == null && exports == null && parts == null)),
        _name = name,
        _inputValidators = inputValidators ?? ['**/*.dart'],
        _buildExtensions = buildExtensions ??
            {
              '{{dir}}/{{file}}.dart': ['{{dir}}/gen/{{file}}.gen.${name.snakeCase}.dart']
            },
        _outputAssetFunction = outputAssetFunction ?? ((List<AssetId> expectedOutputs) => expectedOutputs[0]),
        // _outputPathFun = outputPath ??
        //     ((PathEditor pathEditor) {
        //       pathEditor.folders.add('gen');
        //       pathEditor.extensions.insert(0, name.snakeCase);
        //       pathEditor.extensions.insert(0, 'gen');
        //     }),
        _genMessage = genMessage,
        _autoFormat = autoFormat,
        _formatter = formatter ?? DartFormatter(pageWidth: 100),
        _partOf = partOf ?? ((PackageManagers packageManagers) => PartOf.fromInputRelative()),
        _imports = imports,
        _exports = exports,
        _parts = parts,
        _buildFun = build;

  /// Returns the build extensions map that defines input to output file mappings.
  ///
  /// This is required by the [Builder] interface. The map uses placeholder syntax
  /// like `{{dir}}` and `{{file}}` that the build system replaces with actual
  /// file paths during the build process.
  @override
  Map<String, List<String>> get buildExtensions => _buildExtensions;

  /// Gets the output [AssetId] for a given input asset.
  ///
  /// Uses the [_outputAssetFunction] to select from the expected outputs
  /// based on the build extensions configuration.
  ///
  /// [inputId]: The asset ID of the input file being processed.
  ///
  /// Returns the [AssetId] where the generated code will be written.
  AssetId _getOutputAssetId(AssetId inputId) => _outputAssetFunction(expectedOutputs(this, inputId).toList());

  // @override
  // Map<String, List<String>> get buildExtensions => {
  //   '.dart': ['.dart']
  // };

  // @override
  // AssetId getOutputAssetId(AssetId inputId) {
  //   PathEditor pathEditor = PathEditor(inputId.path);
  //   _outputPathFun(pathEditor);
  //   pathEditor.setPath();
  //   String outputPath = pathEditor.path;
  //   return AssetId(inputId.package, outputPath);
  // }

  // void printWrapped(String text) {
  //   final pattern = RegExp('.{1,800}'); // 800 is the size of each chunk
  //   pattern.allMatches(text).forEach((match) => print(match.group(0)));
  // }

  /// Executes the build process for a single input file.
  ///
  /// This is the main entry point called by the build system for each input
  /// file that matches the build extensions. The build process:
  ///
  /// 1. Creates a [PackageManagers] instance for accessing package information
  /// 2. Validates the input file against the configured glob patterns
  /// 3. Determines the output file path
  /// 4. Analyzes the input library to get its [LibraryElement]
  /// 5. Writes the generation message header (if enabled)
  /// 6. Writes file directives (part-of, imports, exports, parts)
  /// 7. Executes the custom build function to generate code
  /// 8. Formats the output (if enabled)
  /// 9. Writes the result to the output asset
  ///
  /// **Important Notes:**
  ///
  /// - A new BuildStep is created for every source-builder combination
  /// - The first time `buildStep.resolver` is called, it asynchronously resolves
  ///   the source asset and its entire dependency tree
  /// - Each file resolution creates a new AnalysisSession, which invalidates
  ///   previously resolved libraries and elements
  ///
  /// [buildStep]: The build step providing access to the input asset, resolver,
  /// and output writing capabilities.
  @override
  Future<void> build(BuildStep buildStep) async {
    PackageManagers _packageManagers = PackageManagers(await PackageGraph.forThisPackage(), buildStep);
    AssetId inputId = buildStep.inputId;
    if (!_validate(inputId)) return;
    AssetId outputId = _getOutputAssetId(inputId);
    LibraryElement libraryElement = await buildStep.inputLibrary;
    final StringBuffer b = StringBuffer();
    _writeGenMessage(b);
    await _writeDirectives(b, inputId, outputId, _packageManagers);
    await _buildFun(b, libraryElement, _packageManagers, buildStep);
    String str = _autoFormat ? _formatter.format(b.toString()) : b.toString();
    await buildStep.writeAsString(outputId, str);
  }

  /// Validates whether the input asset should be processed by this builder.
  ///
  /// Checks if the input file path matches any of the configured glob patterns
  /// in [_inputValidators].
  ///
  /// [inputId]: The asset ID to validate.
  ///
  /// Returns `true` if the file should be processed, `false` otherwise.
  bool _validate(AssetId inputId) =>
      _inputValidators.map((globPath) => Glob(globPath)).any((glob) => glob.matches(inputId.path));

  /// Writes a "Do Not Modify" header message to the buffer.
  ///
  /// Creates a formatted comment header that warns developers not to manually
  /// edit the generated file. The header includes the builder name and is
  /// centered with hash marks for visibility.
  ///
  /// Only writes the message if [_genMessage] is `true`.
  ///
  /// Example output:
  /// ```dart
  /// //##################################################
  /// //####### Generated by my_builder - Do Not Modify ########
  /// //##################################################
  /// ```
  ///
  /// [b]: The string buffer to write the header to.
  void _writeGenMessage(StringBuffer b) {
    if (_genMessage) {
      const int len = 50;
      String str = ' Generated by $_name - Do Not Modify ';
      int firstPoundsLen = ((len - str.length) / 2).floor();
      int lastPoundsLen = ((len - str.length) / 2).ceil();

      b.write('///');
      b.write('#' * len);
      b.newLine();
      b.write('///');
      b.write('#' * firstPoundsLen);
      b.write(str);
      b.write('#' * lastPoundsLen);
      b.newLine();
      b.write('///');
      b.write('#' * len);
      b.newLine();
    }
  }

  /// Writes all configured directives to the buffer.
  ///
  /// Processes and writes file directives in the following order:
  /// 1. `part of` directive (if configured)
  /// 2. `import` directives (if configured)
  /// 3. `export` directives (if configured)
  /// 4. `part` directives (if configured)
  ///
  /// For directives that reference the input file (like `_ImportFromInput`),
  /// this method sets up the proper URI references before writing them to the
  /// buffer.
  ///
  /// Parameters:
  /// - [b]: The string buffer to write directives to
  /// - [inputId]: The asset ID of the input file being processed
  /// - [outputId]: The asset ID of the output file being generated
  /// - [_packageManagers]: Package managers for accessing package information
  Future<void> _writeDirectives(
      StringBuffer b, AssetId inputId, AssetId outputId, PackageManagers _packageManagers) async {
    PartOf? partOf = await _partOf.call(_packageManagers);
    if (partOf != null) {
      if (partOf is _PartOfStatementFromInput) await partOf._set(inputId, outputId, _packageManagers);
      partOf._writeToBuffer(b);
    }

    List<Import>? imports = await _imports?.call(_packageManagers);
    if (imports != null) {
      await Future.forEach(imports, (Import import) async {
        if (import is _ImportFromInput) await import._set(inputId, outputId, _packageManagers);
      });
      imports._writeToBuffer(b);
    }

    List<Export>? exports = await _exports?.call(_packageManagers);
    if (exports != null) {
      await Future.forEach(exports, (Export export) async {
        if (export is _ExportFromInput) await export._set(inputId, outputId, _packageManagers);
      });
      exports._writeToBuffer(b);
    }

    List<Part>? parts = await _parts?.call(_packageManagers);
    if (parts != null) {
      await Future.forEach(parts, (Part part) async {
        if (part is _PartFromInput) await part._set(inputId, outputId, _packageManagers);
      });
      parts._writeToBuffer(b);
    }
  }
}
