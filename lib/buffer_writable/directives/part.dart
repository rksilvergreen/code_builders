part of dart_source_builder;

class Part extends UriDirective {
  Part.absolute(String path) : super('part', UriReference.absolute(path));

  Part.relative(String path, {String? from}) : super('part', UriReference.relative(path, from: from));

  Part.package(String package, String path) : super('part', UriReference.package(package, path));

  factory Part.fromInputAbsolute([AssetId? inputId]) => _PartFromInput('absolute', inputId);

  factory Part.fromInputRelative([AssetId? inputId]) => _PartFromInput('relative', inputId);

  factory Part.fromInputPackage([AssetId? inputId]) => _PartFromInput('package', inputId);
}

class _PartFromInput extends UriDirective implements Part {
  final String _type;
  AssetId? _inputId;
  late AssetId _outputId;
  late PackageManager _packageManager;

  _PartFromInput(this._type, this._inputId) : super(null, null);

  Future<void> _set(AssetId inputId, AssetId outputId, PackageManagers packageManagers) async {
    _inputId ??= inputId;
    _outputId = outputId;
    _packageManager = packageManagers[_inputId!.package]!;
  }

  @override
  void _writeToBuffer(StringBuffer b) {
    Part? part;

    switch (_type) {
      case 'absolute':
        part = Part.absolute(_packageManager._pathAbsolute(_inputId!));
        break;
      case 'relative':
        part = Part.relative(_packageManager._pathFromLib(_inputId!), from: _packageManager._pathFromLib(_outputId, false));
        break;
      case 'package':
        part = Part.package(_inputId!.package, _packageManager._pathFromLib(_inputId!));
        break;
    }

    part!._writeToBuffer(b);
  }
}

class PartCollection extends _DirectiveCollection<Part> {
  PartCollection.absolute(List<String> paths) : super(paths.map((e) => Part.absolute(e)).toList());

  PartCollection.relative(List<String> paths, {String? from}) : super(paths.map((e) => Part.relative(e, from: from)).toList());

  PartCollection.package(String package, List<String> paths) : super(paths.map((e) => Part.package(package, e)).toList());

  PartCollection.fromInputAbsolute(List<AssetId?> inputIds) : super(inputIds.map((e) => Part.fromInputAbsolute(e)).toList());

  PartCollection.fromInputRelative(List<AssetId?> inputIds) : super(inputIds.map((e) => Part.fromInputRelative(e)).toList());

  PartCollection.fromInputPackage(List<AssetId?> inputIds) : super(inputIds.map((e) => Part.fromInputPackage(e)).toList());
}