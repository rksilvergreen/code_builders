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
part 'uri_reference.dart';

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

typedef OutputAssetFunction = AssetId Function(List<AssetId> expectedOutputs);
// typedef OutputPathFunction = void Function(PathEditor pathEditor);
typedef DirectiveFunction<T extends Directive> = FutureOr<T> Function(PackageManagers packageManagers);
typedef PartOfFunction = FutureOr<PartOf>? Function(PackageManagers packageManagers);
typedef ImportsFunction = FutureOr<List<Import>>? Function(PackageManagers packageManagers);
typedef ExportsFunction = FutureOr<List<Export>>? Function(PackageManagers packageManagers);
typedef PartsFunction = FutureOr<List<Part>>? Function(PackageManagers packageManagers);
typedef BuildFunction = Future<void> Function(StringBuffer b, LibraryElement libraryElement, PackageManagers packageManagers, BuildStep buildStep);

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
        _buildExtensions = buildExtensions ?? {
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

  @override
  Map<String, List<String>> get buildExtensions => _buildExtensions;

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

  /// A new BuildStep is created for every source-builder combination in the target. They each have the same Resolver (and AnalysisDriver).
  /// The first time buildStep.resolver is called, it (asynchronously) resolves the source asset and its entire dependency tree.
  /// Every time a file is resolved for the first time, a new AnalysisSession begins. When this happens, all libraries and elements that were
  /// resolved in previous sessions are considered 'old', and therefore any call to

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

  bool _validate(AssetId inputId) => _inputValidators.map((globPath) => Glob(globPath)).any((glob) => glob.matches(inputId.path));

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

  Future<void> _writeDirectives(StringBuffer b, AssetId inputId, AssetId outputId, PackageManagers _packageManagers) async {
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