part of dart_source_builder;

class Export extends UriDirective {
  Export.absolute(String path) : super('export', UriReference.absolute(path));

  Export.relative(String path, {String? from}) : super('export', UriReference.relative(path, from: from));

  Export.package(String package, String path) : super('export', UriReference.package(package, path));

  factory Export.fromInputAbsolute([AssetId? inputId]) => _ExportFromInput('absolute', inputId);

  factory Export.fromInputRelative([AssetId? inputId]) => _ExportFromInput('relative', inputId);

  factory Export.fromInputPackage([AssetId? inputId]) => _ExportFromInput('package', inputId);
}

class _ExportFromInput extends UriDirective implements Export {
  final String _type;
  AssetId? _inputId;
  late AssetId _outputId;
  late PackageManager _packageManager;

  _ExportFromInput(this._type, this._inputId) : super(null, null);

  Future<void> _set(AssetId inputId, AssetId outputId, PackageManagers packageManagers) async {
    _inputId ??= inputId;
    _outputId = outputId;
    _packageManager = packageManagers[_inputId!.package]!;
  }

  @override
  void _writeToBuffer(StringBuffer b) {
    Export? export;

    switch (_type) {
      case 'absolute':
        export = Export.absolute(_packageManager._pathAbsolute(_inputId!));
        break;
      case 'relative':
        export = Export.relative(_packageManager._pathFromLib(_inputId!), from: _packageManager._pathFromLib(_outputId, false));
        break;
      case 'package':
        export = Export.package(_inputId!.package, _packageManager._pathFromLib(_inputId!));
        break;
    }

    export!._writeToBuffer(b);
  }
}

class ExportCollection extends _DirectiveCollection<Export> {
  ExportCollection.absolute(List<String> paths) : super(paths.map((e) => Export.absolute(e)).toList());

  ExportCollection.relative(List<String> paths, {String? from}) : super(paths.map((e) => Export.relative(e, from: from)).toList());

  ExportCollection.package(String package, List<String> paths) : super(paths.map((e) => Export.package(package, e)).toList());

  ExportCollection.fromInputAbsolute(List<AssetId?> inputIds) : super(inputIds.map((e) => Export.fromInputAbsolute(e)).toList());

  ExportCollection.fromInputRelative(List<AssetId?> inputIds) : super(inputIds.map((e) => Export.fromInputRelative(e)).toList());

  ExportCollection.fromInputPackage(List<AssetId?> inputIds) : super(inputIds.map((e) => Export.fromInputPackage(e)).toList());
}