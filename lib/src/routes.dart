import 'package:flutter/foundation.dart';
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
  ///
  /// In debug mode, an assertion error will be thrown if any duplicate
  /// segments are detected.
  String fromSegments(List<String> segments) {
    if (kDebugMode) {
      final duplicates = segments.where((s1) {
        return segments.where((s2) => s1 == s2).length > 1;
      }).toList();

      assert(
        duplicates.isEmpty,
        '[SimpleRoutes] WARNING: Path segments should be unique.\n'
        '$runtimeType: Duplicates of ${[
          ...Set.from(duplicates).map((x) => '"$x"'),
        ].join(', ')}',
      );
    }

    return segments.join('/');
  }

  /// Get the [GoRoute] `path` for this route.
  ///
  /// ```dart
  /// GoRoute(
  ///   path: const MyRoute().goPath,
  /// ),
  /// ```
  String get goPath {
    if (this is ChildRoute) {
      return _ensureNoLeadingSlash(path);
    } else {
      return _ensureLeadingSlash(path);
    }
  }

  /// Determine if this route is an exact match for the current location.
  ///
  /// This is useful for determining if a route is active.
  bool isCurrentRoute(GoRouterState state) {
    return state.fullPath == _fullPathTemplate;
  }

  /// Determine if this route is a parent of the current route.
  ///
  /// e.g. if this route is '/parent' and the current GoRouter location is
  /// '/parent/child', '/parent/child/sub-child', etc, this method will return
  /// true.
  ///
  /// This is useful for determining if a parent route is active.
  bool isParentRoute(GoRouterState state) {
    final location = state.fullPath;

    if (location == null || location == _fullPathTemplate) {
      return false;
    }

    return location.startsWith(_fullPathTemplate);
  }

  /// Determine if this route is active in any way.
  bool isActive(GoRouterState state) {
    return isCurrentRoute(state) || isParentRoute(state);
  }

  String get _fullPathTemplate {
    if (this is! ChildRoute) {
      return _ensureLeadingSlash(path);
    }

    final parentPath = _getParentPath();
    final normalized = _ensureLeadingSlash(parentPath);
    return _join(normalized, path);
  }

  static String _ensureLeadingSlash(String path) {
    return path.startsWith('/') ? path : '/$path';
  }

  static String _ensureNoLeadingSlash(String path) {
    return path.startsWith('/') ? path.substring(1) : path;
  }

  static String _join(String parent, String path) {
    return '$parent/$path'.replaceAll('//', '/');
  }

  String _getParentPath() {
    return (this as ChildRoute).parent._fullPathTemplate;
  }
}

/// A route that contains no parameters.
///
/// Override the `path` property to declare the path segment for this route.
///
/// ```dart
/// class MyRoute extends SimpleRoute {
///   const MyRoute();
///
///   @override
///   final String path = 'my-route';
/// }
/// ```
abstract class SimpleRoute extends BaseRoute {
  const SimpleRoute();

  /// Navigate to this route.
  void go(BuildContext context) {
    GoRouter.of(context).go(_fullPathTemplate);
  }

  /// Push this route onto the stack.
  Future<T?> push<T extends Object?>(BuildContext context) {
    return GoRouter.of(context).push(_fullPathTemplate);
  }

  /// Get the full path for this route.
  /// e.g. '/my-route'
  String fullPath() => _fullPathTemplate;
}

/// A route that contains one or more path and/or query parameters and/or
/// "extra" data.
///
/// When navigating, a data object must be supplied to populate the route.
///
/// In this example, the `MyRouteData` class should provide a value for the
/// `:id` path parameter (declared by the `RouteParams.id` enum value).
///
/// ```dart
/// class MyRoute extends DataRoute<MyRouteData> {
///   const MyRoute();
///
///   @override
///   String get path => joinSegments(['my-route', RouteParams.id.prefixed]);
/// }
/// ```
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
  Future<T?> push<T extends Object?>(
    BuildContext context, {
    required Data data,
  }) {
    return GoRouter.of(context).push(fullPath(data), extra: data.extra);
  }

  /// Generate the full, populated path for this route using the supplied [data].
  ///
  /// This method will inject the [data] parameters into the path template and
  /// append any query parameters.
  ///
  /// e.g. `/user/:userId` becomes `/user/123?query=my%20query`
  String fullPath(Data data) {
    return _injectParams(_fullPathTemplate, data).appendQuery(_getQuery(data));
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

/// A route that is a descendant of another route.
///
/// Implement this interface to declare a route as a child of another route
/// in the routing tree.
///
/// ```dart
/// class MyRoute extends SimpleRoute implements ChildRoute<ParentRoute> {
///   const MyRoute();
///
///   @override
///   String get path => 'my-route';
///
///   @override
///   ParentRoute get parent => const ParentRoute();
/// }
/// ```
///
/// Then, when navigating to this route, it will automatically construct the
/// full path using the parent route's path.
///
/// ```dart
/// const MyRoute().go(context);
/// ```
///
/// This will navigate to '/parent-route/my-route'.
abstract class ChildRoute<Parent extends BaseRoute> {
  /// The parent route of this route.
  Parent get parent;
}
