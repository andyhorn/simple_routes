import 'package:meta/meta.dart';

/// Annotation to define a route blueprint.
///
/// ```dart
/// @Route('path')
/// class MyRoute extends _$MyRoute {}
/// ```
@immutable
class Route {
  const Route(this.path, {this.parent});

  /// The path for this route.
  final String path;

  /// The parent route blueprint class.
  final Type? parent;
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
/// abstract class UserRoute with _$UserRoute {
///   const factory UserRoute({
///     @Path('userId') required String id,
///   }) = _UserRoute;
/// }
/// ```
@immutable
class Path {
  const Path([this.name]);

  /// The name of the path parameter in the template. If null, the field name is used.
  final String? name;
}

/// Annotation to define an extra parameter.
///
/// ```dart
/// @Extra()
/// final MyExtraData extra;
/// ```
@immutable
class Extra {
  const Extra();
}
