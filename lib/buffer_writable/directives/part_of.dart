part of dart_source_builder;

abstract class PartOf extends Directive {
  factory PartOf.uriAbsolute(String path) => _PartOfUriStatement.absolute(path);

  factory PartOf.uriRelative(String path, {String? from}) => _PartOfUriStatement.relative(path, from: from);

  factory PartOf.uriPackage(String package, String path) => _PartOfUriStatement.package(package, path);

  factory PartOf.library(String library) => _PartOfLibraryStatement(library);

  factory PartOf.fromInputAbsolute([AssetId? inputId]) => _PartOfStatementFromInput('absolute', inputId);

  factory PartOf.fromInputRelative([AssetId? inputId]) => _PartOfStatementFromInput('relative', inputId);

  factory PartOf.fromInputPackage([AssetId? inputId]) => _PartOfStatementFromInput('package', inputId);
}

class _PartOfUriStatement extends UriDirective implements PartOf {
  _PartOfUriStatement.absolute(String path) : super('part of', UriReference.absolute(path));

  _PartOfUriStatement.relative(String path, {String? from}) : super('part of', UriReference.relative(path, from: from));

  _PartOfUriStatement.package(String package, String path) : super('part of', UriReference.package(package, path));
}

class _PartOfLibraryStatement extends Directive implements PartOf {
  _PartOfLibraryStatement(String library) : super('part of', library);
}

class _PartOfStatementFromInput extends Directive implements PartOf {
  final String _type;
  AssetId? _inputId;
  late AssetId _outputId;
  late PackageManager _packageManager;
  late LibraryElement _libraryElement;

  _PartOfStatementFromInput(this._type, this._inputId) : super(null, null);

  Future<void> _set(AssetId inputId, AssetId outputId, PackageManagers packageManagers) async {
    _inputId ??= inputId;
    _outputId = outputId;
    _packageManager = packageManagers[_inputId!.package]!;
    _libraryElement = (await _packageManager.getLibraryElements([_packageManager._pathFromLib(_inputId!)])).first;
  }

  @override
  void _writeToBuffer(StringBuffer b) {
    bool isNamedLibrary = _libraryElement.displayName != '';
    PartOf? partOf;
    if (isNamedLibrary)
      partOf = _PartOfLibraryStatement(_libraryElement.displayName);
    else {
      switch (_type) {
        case 'absolute':
          partOf = _PartOfUriStatement.absolute(_packageManager._pathAbsolute(_inputId!));
          break;
        case 'relative':
          partOf = _PartOfUriStatement.relative(_packageManager._pathFromLib(_inputId!), from: _packageManager._pathFromLib(_outputId, false));
          break;
        case 'package':
          partOf = _PartOfUriStatement.package(_inputId!.package, _packageManager._pathFromLib(_inputId!));
          break;
      }
    }
    partOf!._writeToBuffer(b);
  }
}