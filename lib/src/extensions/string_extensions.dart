import 'package:simple_routes/simple_routes.dart';

final _queryRegex = RegExp(r'\?.+$');

extension StringExtensions on String {
  /// Replace a path template parameter with a value.
  ///
  /// For example, `':value'.setParam(MyEnum.value, 'foo')` returns `'foo'`.
  String setParam<Param extends Enum>(Param param, String value) {
    return replaceAll(param.prefixed, value);
  }

  /// Append a query string to this String, if [query] is not empty.
  String appendQuery(Map<String, String?> query) {
    final filtered = query.entries
        .where((e) => e.value?.isNotEmpty ?? false)
        .map((e) => MapEntry(e.key, e.value!));

    if (filtered.isEmpty) {
      return this;
    }

    var queryString = _toQueryString(Map.fromEntries(filtered));

    if (_queryRegex.hasMatch(this)) {
      // If this path already ends in a query string, append the new query
      // string to the existing one.
      queryString = queryString.replaceFirst('?', '&');
    }

    return '$this$queryString';
  }
}

extension StringIterableExtensions on Iterable<String> {
  /// Join a list of strings into a forward slash-separated path.
  String toPath() => join('/');
}

/// Generate a query string from a map of parameters.
///
/// For example, `query({'key': 'my value'})` returns `'?key=my%20value'`.
///
/// **Note**: All keys and values are URI encoded.
String _toQueryString(Map<String, String> params) {
  if (params.isEmpty) {
    return '';
  }

  final components = params.entries.map((e) {
    final key = Uri.encodeComponent(e.key);
    final value = Uri.encodeComponent(e.value);

    return '$key=$value';
  });

  return '?${components.join('&')}';
}
