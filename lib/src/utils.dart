import 'package:go_router/go_router.dart';

/// Join segments into a forward slash-separated path.
String join(List<String> segments) {
  return segments.join('/').replaceAll('//', '/');
}

/// Convert an enum value into a path template parameter.
///
/// For example, `withPrefix(MyEnum.value)` returns `':value'`.
String withPrefix(Enum value) => ':${value.name}';

/// Returns the query parameters from the [state].
///
/// This is a convenience method that wraps
/// [GoRouterState.uri.queryParameters].
Map<String, String> getQueryParams(GoRouterState state) {
  return state.uri.queryParameters;
}
