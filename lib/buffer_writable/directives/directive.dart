part of dart_source_builder;

abstract class Directive extends BufferWritable {
  final String? _type;
  final String? _str;

  Directive(this._type, this._str);

  void _writeToBuffer(StringBuffer b) {
    b.write('$_type $_str;');
  }
}

abstract class UriDirective extends Directive {
  UriReference? _uriReference;

  UriDirective(String? type, this._uriReference) : super(type, '\'$_uriReference\'');
}

class _DirectiveCollection<T extends UriDirective> extends ListBase<T> {
  final List<T> _list;

  void set length(int newLength) {
    _list.length = newLength;
  }

  int get length => _list.length;

  T operator [](int index) => _list[index];

  void operator []=(int index, T value) {
    _list[index] = value;
  }

  _DirectiveCollection(this._list);
}