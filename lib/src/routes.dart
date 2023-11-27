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
        ? [(this as ChildRoute).parent.fullPath, this.path].toPath()
        : this.path;

    if (!path.startsWith('/')) {
      path = '/$path';
    }

    return path;
  }

  /// Get the [GoRoute] path for this route.
  ///
  /// ```dart
  /// GoRoute(
  ///   path: const MyRoute().goPath,
  /// ),
  /// ```
  String get goPath {
    var path = this.path;

    if (this is ChildRoute) {
      return path.startsWith('/') ? path.substring(1) : path;
    } else {
      return path.startsWith('/') ? path : '/$path';
    }
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

/// A route that contains no parameters.
abstract class SimpleRoute extends BaseRoute {
  const SimpleRoute();

  /// Navigate to this route.
  void go(BuildContext context) {
    GoRouter.of(context).go(fullPath);
  }

  /// Push this route onto the stack.
  void push(BuildContext context) {
    GoRouter.of(context).push(fullPath);
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
  }) {
    GoRouter.of(context).go(generate(data), extra: data.extra);
  }

  /// Push this route onto the stack using the supplied [data].
  void push(
    BuildContext context, {
    required Data data,
  }) {
    GoRouter.of(context).push(generate(data), extra: data.extra);
  }

  /// Generate a populated path for this route using the supplied [data].
  String generate(Data data) {
    return _injectParams(fullPath, data).appendQuery(_getQuery(data));
  }

  String _injectParams(String path, Data data) {
    return data.parameters.entries.fold(path, (path, entry) {
      return path.setParam(entry.key, entry.value);
    });
  }

  Map<String, String> _getQuery(Data data) {
    return data.query.entries.fold({}, (query, entry) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        query[entry.key.name] = entry.value!;
      }

      return query;
    });
  }
}

abstract class ChildRoute<Parent extends BaseRoute> {
  /// The parent route of this route.
  Parent get parent;
}
