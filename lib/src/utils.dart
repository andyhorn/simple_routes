import 'package:go_router/go_router.dart';

/// Join segments into a forward slash-separated path.
String join(List<String> segments) {
  return segments.join('/').replaceAll('//', '/');
}

/// Returns the query parameters from the [state].
///
/// This is a convenience method that wraps
/// [GoRouterState.uri.queryParameters].
Map<String, String> getQueryParams(GoRouterState state) {
  return state.uri.queryParameters;
}
