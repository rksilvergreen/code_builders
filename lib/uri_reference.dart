part of dart_source_builder;

abstract class UriReference {
  final String _str;

  UriReference._(String str) : _str = str.replaceAll('\\', '/');

  factory UriReference.absolute(String path) => _AbsoluteUriReference(path);
  factory UriReference.relative(String path, {String? from}) => _RelativeUriReference(path, from: from);
  factory UriReference.package(String package, String path) => _PackageUriReference(package, path);

  @override
  String toString() => _str;
}

class _AbsoluteUriReference extends UriReference {
  _AbsoluteUriReference(String path) : super._(path);
}

class _RelativeUriReference extends UriReference {
  _RelativeUriReference(String path, {String? from}) : super._(p.relative(path, from: from ?? p.current));
}

class _PackageUriReference extends UriReference {
  final String package;
  final String path;
  _PackageUriReference(this.package, this.path) : super._('package:$package${p.separator}$path');
}