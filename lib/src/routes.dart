import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';

/// An abstract class to serve as the parent for all routes.
abstract class BaseRoute {
  const BaseRoute();

  /// The path for this route. e.g. 'verify-email'.
  abstract final String path;

  /// Get the fully-qualified path template for this route.
  ///
  /// e.g. `/auth/register/verify-email` or `/auth/register/verify-email/:token`
  String get fullPath {
    var path = this is ChildRoute
        ? join([(this as ChildRoute).parent.fullPath, this.path])
        : this.path;

    if (!path.startsWith('/')) {
      path = '/$path';
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

  void Function(
    String, {
    Object? extra,
  }) _getAction(BuildContext context, bool push) {
    final goRouter = GoRouter.of(context);
    return push ? goRouter.push : goRouter.go;
  }
}

/// A route that contains no parameters.
abstract class SimpleRoute extends BaseRoute {
  const SimpleRoute();

  /// Navigate to this route.
  void go(
    BuildContext context, {
    Map<String, String>? query,
    bool push = false,
  }) {
    final action = _getAction(context, push);
    action(fullPath.maybeAppendQuery(query));
  }
}

/// A route that contains a parameter. When navigating, data must be supplied
/// to populate the route.
abstract class DataRoute<Data extends SimpleRouteData> extends BaseRoute {
  const DataRoute();

  /// Navigate to this route using the supplied [data].
  void go(
    BuildContext context, {
    required Data data,
    Map<String, String>? query,
    bool push = false,
  }) {
    final action = _getAction(context, push);
    final path = buildPath(data, query: query);
    final extra = data.extra();

    action(path, extra: extra);
  }

  /// Build the path for this route using the supplied [data].
  ///
  /// This method allows you to build a path for a route without navigating.
  String buildPath(
    Data data, {
    Map<String, String>? query,
  }) {
    return data.inject(fullPath).maybeAppendQuery(query);
  }
}

abstract class ChildRoute<Parent extends BaseRoute> {
  /// The parent route of this route.
  Parent get parent;
}
