part of code_builder;

/// Base class for all Dart directive statements (import, export, part, part of).
///
/// This abstract class provides the foundation for generating Dart directive code.
/// Directives are top-level statements that appear at the beginning of a Dart file
/// to manage dependencies and library structure.
///
/// The directive is written to a buffer in the format: `{type} {str};`
/// For example: `import 'package:foo/bar.dart';`
abstract class Directive extends BufferWritable {
  /// The directive keyword (e.g., 'import', 'export', 'part', 'part of').
  final String? _type;

  /// The content that follows the directive keyword.
  /// For URI-based directives, this will be the quoted URI string.
  final String? _str;

  /// Creates a directive with the specified [_type] and content [_str].
  Directive(this._type, this._str);

  /// Writes the directive statement to the provided string buffer.
  ///
  /// Output format: `{_type} {_str};`
  /// Example: `import 'dart:async';`
  void _writeToBuffer(StringBuffer b) {
    b.write('$_type $_str;');
  }
}

/// Base class for URI-based directives (import, export, part).
///
/// This class specializes [Directive] to handle directives that reference
/// external files or libraries via URIs. It uses [UriReference] to properly
/// format absolute, relative, and package URIs.
abstract class UriDirective extends Directive {
  /// The URI reference that will be formatted and quoted in the directive.
  UriReference? _uriReference;

  /// Creates a URI-based directive with the given [type] and [_uriReference].
  ///
  /// The URI reference is automatically wrapped in single quotes when passed
  /// to the parent [Directive] constructor.
  UriDirective(String? type, this._uriReference) : super(type, '\'$_uriReference\'');
}

/// Internal collection class for managing lists of URI-based directives.
///
/// This class extends [ListBase] to provide a full list interface for
/// collections of directives (imports, exports, or parts). It wraps an
/// underlying list and delegates all operations to it.
///
/// Type parameter [T] must extend [UriDirective], ensuring type safety
/// for directive collections.
class _DirectiveCollection<T extends UriDirective> extends ListBase<T> {
  /// The underlying list that stores the directive instances.
  final List<T> _list;

  /// Sets the length of the collection, truncating or extending as needed.
  void set length(int newLength) {
    _list.length = newLength;
  }

  /// Returns the number of directives in the collection.
  int get length => _list.length;

  /// Returns the directive at the given [index].
  T operator [](int index) => _list[index];

  /// Sets the directive at the given [index] to [value].
  void operator []=(int index, T value) {
    _list[index] = value;
  }

  /// Creates a directive collection wrapping the provided [_list].
  _DirectiveCollection(this._list);
}
