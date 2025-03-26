part of dart_source_builder;

class Import extends UriDirective {
  Import.absolute(String path) : super('import', UriReference.absolute(path));

  Import.relative(String path, {String? from}) : super('import', UriReference.relative(path, from: from));

  Import.package(String package, String path) : super('import', UriReference.package(package, path));

  factory Import.fromInputAbsolute([AssetId? inputId]) => _ImportFromInput('absolute', inputId);

  factory Import.fromInputRelative([AssetId? inputId]) => _ImportFromInput('relative', inputId);

  factory Import.fromInputPackage([AssetId? inputId]) => _ImportFromInput('package', inputId);
}

class _ImportFromInput extends UriDirective implements Import {
  final String _type;
  AssetId? _inputId;
  late AssetId _outputId;
  late PackageManager _packageManager;

  _ImportFromInput(this._type, this._inputId) : super(null, null);

  Future<void> _set(AssetId inputId, AssetId outputId, PackageManagers packageManagers) async {
    _inputId ??= inputId;
    _outputId = outputId;
    _packageManager = packageManagers[_inputId!.package]!;
  }

  @override
  void _writeToBuffer(StringBuffer b) {
    Import? import;

    switch (_type) {
      case 'absolute':
        import = Import.absolute(_packageManager._pathAbsolute(_inputId!));
        break;
      case 'relative':
        import = Import.relative(_packageManager._pathFromLib(_inputId!), from: _packageManager._pathFromLib(_outputId, false));
        break;
      case 'package':
        import = Import.package(_inputId!.package, _packageManager._pathFromLib(_inputId!));
        break;
    }

    import!._writeToBuffer(b);
  }
}

class ImportCollection extends _DirectiveCollection<Import> {
  ImportCollection.absolute(List<String> paths) : super(paths.map((e) => Import.absolute(e)).toList());

  ImportCollection.relative(List<String> paths, {String? from}) : super(paths.map((e) => Import.relative(e, from: from)).toList());

  ImportCollection.package(String package, List<String> paths) : super(paths.map((e) => Import.package(package, e)).toList());

  ImportCollection.fromInputAbsolute(List<AssetId?> inputIds) : super(inputIds.map((e) => Import.fromInputAbsolute(e)).toList());

  ImportCollection.fromInputRelative(List<AssetId?> inputIds) : super(inputIds.map((e) => Import.fromInputRelative(e)).toList());

  ImportCollection.fromInputPackage(List<AssetId?> inputIds) : super(inputIds.map((e) => Import.fromInputPackage(e)).toList());
}