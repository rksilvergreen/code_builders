/// A code generation library for Dart that provides a flexible framework for
/// creating custom builders with the Dart build system.
///
/// This library extends the [build] package to simplify code generation by
/// providing utilities for working with directives, creating code structures,
/// and managing package dependencies.
///
/// ## Key Features
///
/// - Customizable input matching with glob patterns
/// - Automatic code formatting with dart_style
/// - Support for imports, exports, parts, and part-of directives
/// - Generated file headers and error handling
///
/// ## Usage
///
/// ```dart
/// final builder = DartSourceBuilder(
///   name: 'my_generator',
///   buildExtensions: {
///     'lib/models/*.dart': ['lib/generated/*.g.dart']
///   },
///   build: (buildStep) async {
///     final buffer = StringBuffer();
///     buffer.writeln('// Generated code');
///     return buffer;
///   },
/// );
/// ```
///
/// ## File Types
///
/// - **Library files**: Use [imports], [exports], [parts] parameters
/// - **Part files**: Use [partOf] parameter (mutually exclusive with library directives)
///
/// ## Output Paths
///
/// Default pattern: `{{dir}}/gen/{{file}}.gen.{{name}}.dart`
///
/// Supports placeholders: `{{dir}}`, `{{file}}`, `{{name}}`
library code_builder;

import 'dart:collection';
import 'dart:async';
import 'package:build/build.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:path/path.dart' as p;
import 'package:dart_style/dart_style.dart';
import 'package:dart_extensions/dart_extensions.dart';

part  'analyzer_extensions/dart_object_converter.dart';
part  'analyzer_extensions/dart_object_extension.dart';
part  'analyzer_extensions/dart_type_extension.dart';
part  'analyzer_extensions/element_extension.dart';
part  'analyzer_extensions/function_typed_element_extension.dart';
part  'analyzer_extensions/interface_element_extension.dart';
part  'analyzer_extensions/interface_type_extension.dart';
part  'analyzer_extensions/library_element_extension.dart';

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

part 'analyzer_extensions/example/car_annotaions/car.dart';
part 'analyzer_extensions/example/car_gen/car_gen.dart';

/// The main build function that generates code content for a single input file.
///
/// Receives a [BuildStep] with access to the input file and resolver, returns
/// a [StringBuffer] containing generated code or `null` to skip generation.
///
/// ## Parameters
///
/// - **[buildStep]**: Provides access to:
///   - `buildStep.inputId`: Input file being processed
///   - `buildStep.resolver`: Library resolver for analysis
///   - `buildStep.readAsString()`: Read input file content
///   - `buildStep.allowedOutputs`: Expected output files
///
/// ## Return Value
///
/// Returns a [StringBuffer] with generated code, or `null` to skip generation.
/// The buffer will be prefixed with generation header and formatted automatically.
///
/// ## Example
///
/// ```dart
/// BuildFunction build = (BuildStep buildStep) async {
///   final library = await buildStep.resolver.libraryFor(buildStep.inputId);
///   final buffer = StringBuffer();
///
///   for (final element in library.topLevelElements) {
///     if (element is ClassElement) {
///       buffer.writeln('// Found class: ${element.name}');
///     }
///   }
///
///   return buffer;
/// };
/// ```
///
/// ## Notes
///
/// - First call to `buildStep.resolver` triggers async resolution
/// - Each file resolution creates a new AnalysisSession
/// - Exceptions are caught and reported by the build system
typedef BuildFunction = Future<StringBuffer?> Function(BuildStep buildStep);

/// A flexible builder for generating Dart source files.
///
/// Extends [Builder] to provide code generation with automatic formatting,
/// directive management, and package analysis capabilities.
///
/// ## Features
///
/// - Customizable input matching with glob patterns
/// - Automatic code formatting with dart_style
/// - Support for imports, exports, parts, and part-of directives
/// - Generated file headers and error handling
///
/// ## File Types
///
/// - **Library files**: Use [imports], [exports], [parts] parameters
/// - **Part files**: Use [partOf] parameter (mutually exclusive with library directives)
///
/// ## Usage Examples
///
/// ### Basic Builder
///
/// ```dart
/// final builder = DartSourceBuilder(
///   name: 'my_generator',
///   buildExtensions: {
///     'lib/models/*.dart': ['lib/generated/*.g.dart']
///   },
///   build: (buildStep) async {
///     final buffer = StringBuffer();
///     buffer.writeln('// Generated code');
///     return buffer;
///   },
/// );
/// ```
///
/// ### Builder with Directives
///
/// ```dart
/// final builder = DartSourceBuilder(
///   name: 'json_serializer',
///   buildExtensions: {
///     'lib/models/*.dart': ['lib/generated/*.json.dart']
///   },
///   imports: (packages) => [
///     Import.fromPackage('dart:convert'),
///   ],
///   build: (buildStep) async {
///     return StringBuffer('// JSON serialization code');
///   },
/// );
/// ```
///
/// ### Part File Builder
///
/// ```dart
/// final builder = DartSourceBuilder(
///   name: 'part_generator',
///   buildExtensions: {
///     'lib/main.dart': ['lib/main.g.dart']
///   },
///   partOf: PartOf.fromInputRelative(),
///   build: (buildStep) async {
///     return StringBuffer('// Part file content');
///   },
/// );
/// ```
class DartSourceBuilder extends Builder {
  final String _name;
  final Map<String, List<String>> _buildExtensions;
  final bool _genMessage;
  final bool _autoFormat;
  final DartFormatter _formatter;
  final BuildFunction _build;

  /// Creates a new [DartSourceBuilder] with the specified configuration.
  ///
  /// ## Required Parameters
  ///
  /// - **[name]**: Unique identifier for the builder (used in filenames and headers)
  /// - **[buildExtensions]**: Map of input glob patterns to output file patterns
  /// - **[build]**: Core build function that generates code content
  ///
  /// ## Optional Parameters
  ///
  /// - **[genMessage]**: Include "Do Not Modify" header (default: `true`)
  /// - **[autoFormat]**: Auto-format generated code (default: `true`)
  /// - **[formatter]**: Custom [DartFormatter] instance
  ///
  /// ## File Directive Parameters (mutually exclusive)
  ///
  /// - **[partOf]**: Makes generated file a part file
  /// - **[imports]**: List of [Import] directives for library files
  /// - **[exports]**: List of [Export] directives for library files
  /// - **[parts]**: List of [Part] directives for library files
  ///
  /// ## Example
  ///
  /// ```dart
  /// final builder = DartSourceBuilder(
  ///   name: 'json_serializer',
  ///   buildExtensions: {
  ///     'lib/models/*.dart': ['lib/generated/*.json.dart']
  ///   },
  ///   imports: (packages) => [
  ///     Import.fromPackage('dart:convert'),
  ///   ],
  ///   build: (buildStep) async {
  ///     return StringBuffer('// Generated code');
  ///   },
  /// );
  /// ```
  ///
  /// ## Throws
  ///
  /// - [AssertionError] if [name] is empty or [buildExtensions] is empty
  /// - [AssertionError] if both [partOf] and library directives are provided
  DartSourceBuilder({
    required String name,
    required Map<String, List<String>> buildExtensions,
    bool genMessage = true,
    bool autoFormat = true,
    DartFormatter? formatter,
    Map<Type, DartObjectConverter> dartObjectConverters = const {},
    required BuildFunction build,
  })  : _name = name,
        _buildExtensions = buildExtensions,
        _genMessage = genMessage,
        _autoFormat = autoFormat,
        _formatter = formatter ?? DartFormatter(pageWidth: 100),
        _build = build {
    DartObjectExtension._dartObjectConverters.addAll(dartObjectConverters);
  }

  /// Returns the build extensions map that defines input to output file mappings.
  ///
  /// Supports placeholders: `{{dir}}`, `{{file}}`, `{{name}}`
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'lib/models/*.dart': ['lib/generated/{{file}}.gen.{{name}}.dart']
  /// }
  /// ```
  @override
  Map<String, List<String>> get buildExtensions => _buildExtensions;

  /// Executes the build process for a single input file.
  ///
  /// Calls the custom [build] function, adds generation header, formats code,
  /// and writes the result to the output file.
  ///
  /// [buildStep]: Provides access to input file, resolver, and output writing.
  @override
  Future<void> build(BuildStep buildStep) async {
    StringBuffer? strBufferResult = await _build(buildStep);
    if (strBufferResult == null) return;

    final StringBuffer finalBuffer = StringBuffer();
    _writeGenMessage(finalBuffer);
    finalBuffer.write(strBufferResult.toString());

    String str = _autoFormat ? _formatter.format(finalBuffer.toString()) : finalBuffer.toString();
    AssetId outputId = buildStep.allowedOutputs.first;
    await buildStep.writeAsString(outputId, str);
  }

  /// Writes a "Do Not Modify" header message to the buffer.
  ///
  /// Creates a formatted comment header warning against manual editing.
  /// Only writes when [_genMessage] is `true`.
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
}
