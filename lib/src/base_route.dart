import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_routes/src/child_route.dart';
import 'package:simple_routes/src/utils.dart';

/// An abstract class to serve as the parent for all routes.
abstract class BaseRoute {
  const BaseRoute();

  /// The sub-path for this route. e.g. 'login'.
  abstract final String path;

  String get fullPath {
    if (this is ChildRoute) {
      return join([(this as ChildRoute).parent.fullPath, path]);
    }

    return path;
  }

  /// Determine if the current GoRouter location matches this route.
  ///
  /// This is useful for determining if a route is active.
  bool isCurrentRoute(BuildContext context) {
    return GoRouterState.of(context).fullPath == fullPath;
  }

  /// Determine if this route is an ancestor of the current GoRouter location.
  ///
  /// e.g. if this route is '/parent' and the current GoRouter location is
  /// '/parent/child', '/parent/child/sub-child', etc, this method will return
  /// true.
  ///
  /// This is useful for determining if a parent route is active.
  bool isAncestor(BuildContext context) {
    final location = GoRouterState.of(context).fullPath;
    return location != fullPath && (location?.startsWith(fullPath) ?? false);
  }
}
