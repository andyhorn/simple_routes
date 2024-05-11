import 'package:go_router/go_router.dart';

extension GoRouterStateExtensions on GoRouterState {
  /// Extract the value for [key] from the path parameters, if it exists.
  String? param(String key) {
    return pathParameters[key];
  }

  /// Extract the value for [key] from the query parameters, if it exists.
  String? query(String key) {
    return uri.queryParameters[key];
  }
}
