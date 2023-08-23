/// Join segments into a forward slash-separated path.
String join(List<String> segments) {
  return segments.join('/').replaceAll('//', '/');
}

/// Convert an enum value into a path template parameter.
///
/// For example, `withPrefix(MyEnum.value)` returns `':value'`.
String withPrefix(Enum value) => ':${value.name}';

/// Generate a query string from a map of parameters.
///
/// For example, `query({'key': 'my value'})` returns `'?key=my%20value'`.
///
/// **Note**: All keys and values are URI encoded.
String toQuery(Map<String, String> params) {
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

extension StringExtensions on String {
  /// Replace a path template parameter with a value.
  ///
  /// For example, `':value'.setParam(MyEnum.value, 'foo')` returns `'foo'`.
  String setParam<Param extends Enum>(Param param, String value) {
    return replaceAll(withPrefix(param), value);
  }

  /// Append a query string to this String, if the query is not empty.
  String maybeAppendQuery(Map<String, String>? query) {
    if (query == null || query.isEmpty) {
      return this;
    }

    return '$this${toQuery(query)}';
  }
}
