import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';
import 'package:simple_routes/src/extensions/string_extensions.dart';

/// An abstract class to serve as the parent for all routes.
abstract class BaseRoute {
  const BaseRoute();

  /// The path segment for this route. e.g. 'verify-email'.
  abstract final String path;

  /// Join a List<String> of path segments into a forward slash-separated path.
  ///
  /// e.g. ['auth', 'register', 'verify-email'] -> '/auth/register/verify-email'
  String joinSegments(List<String> segments) {
    return segments.join('/');
  }

  /// Get the fully-qualified path template for this route.
  ///
  /// e.g. `/auth/register/verify-email` or `/auth/register/verify-email/:token`
  String get fullPathTemplate {
    var path = this is ChildRoute
        ? joinSegments([
            (this as ChildRoute).parent.fullPathTemplate,
            this.path,
          ])
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

  /// Determine if this route is an exact match for the current location.
  ///
  /// This is useful for determining if a route is active.
  bool isCurrentRoute(BuildContext context) {
    return GoRouterState.of(context).fullPath == fullPathTemplate;
  }

  /// Determine if this route is a parent of the current route.
  ///
  /// e.g. if this route is '/parent' and the current GoRouter location is
  /// '/parent/child', '/parent/child/sub-child', etc, this method will return
  /// true.
  ///
  /// This is useful for determining if a parent route is active.
  bool isParentRoute(BuildContext context) {
    final location = GoRouterState.of(context).fullPath;
    return location != fullPathTemplate &&
        (location?.startsWith(fullPathTemplate) ?? false);
  }

  /// Determine if this route is active in any way.
  bool isActive(BuildContext context) {
    return isCurrentRoute(context) || isParentRoute(context);
  }
}

/// A route that contains no parameters.
abstract class SimpleRoute extends BaseRoute {
  const SimpleRoute();

  /// Navigate to this route.
  void go(BuildContext context) {
    GoRouter.of(context).go(fullPathTemplate);
  }

  /// Push this route onto the stack.
  void push(BuildContext context) {
    GoRouter.of(context).push(fullPathTemplate);
  }

  String getFullPath() {
    return fullPathTemplate;
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
    GoRouter.of(context).go(fullPath(data), extra: data.extra);
  }

  /// Push this route onto the stack using the supplied [data].
  void push(
    BuildContext context, {
    required Data data,
  }) {
    GoRouter.of(context).push(fullPath(data), extra: data.extra);
  }

  /// Generate a populated path for this route using the supplied [data].
  String fullPath(Data data) {
    return _injectParams(fullPathTemplate, data).appendQuery(_getQuery(data));
  }

  String _injectParams(String path, Data data) {
    return data.parameters.entries.fold(path, (path, entry) {
      return path.setParam(entry.key, entry.value);
    });
  }

  Map<String, String> _getQuery(Data data) {
    return data.query.entries.fold({}, (query, entry) {
      if (entry.value != null && entry.value!.isNotEmpty) {
        query[entry.key.name] = (entry.value!);
      }

      return query;
    });
  }
}

abstract class ChildRoute<Parent extends BaseRoute> {
  /// The parent route of this route.
  Parent get parent;
}
