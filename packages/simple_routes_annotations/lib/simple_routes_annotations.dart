import 'package:meta/meta.dart';

/// Annotation to define a route blueprint.
///
/// ```dart
/// @Route('path')
/// class MyRoute extends _$MyRoute {}
/// ```
@immutable
class Route {
  const Route(this.path);

  /// The path for this route.
  final String path;
}

/// Annotation to define a query parameter.
///
/// ```dart
/// @Query()
/// final String? status;
/// ```
@immutable
class Query {
  const Query([this.name]);

  /// The name of the query parameter. If null, the field name is used.
  final String? name;
}

/// Annotation to define a path parameter mapping.
///
/// ```dart
/// @Route('users/:userId')
/// class UserRoute extends _$UserRoute {
///   @Path('userId')
///   final String id;
/// }
/// ```
@immutable
class Path {
  const Path(this.name);

  /// The name of the path parameter in the template.
  final String name;
}
