import 'package:meta/meta.dart';

/// Annotation to define a route blueprint.
///
/// ```dart
/// @SimpleRoute('path')
/// class MyRoute extends _$MyRoute {}
/// ```
@immutable
class SimpleRouteConfig {
  const SimpleRouteConfig(this.path);

  /// The path for this route.
  final String path;
}

/// Annotation to define a query parameter.
///
/// ```dart
/// @QueryParam()
/// final String? status;
/// ```
@immutable
class QueryParam {
  const QueryParam([this.name]);

  /// The name of the query parameter. If null, the field name is used.
  final String? name;
}
