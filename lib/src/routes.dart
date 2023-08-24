import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_routes/simple_routes.dart';
import 'package:simple_routes/src/base_route.dart';

/// A route that contains no parameters.
abstract class SimpleRoute extends BaseRoute {
  /// Create a simple route with the supplied [path].
  SimpleRoute(String? path) : super(AtomicPath.from(path));

  /// Create a root route ('/').
  SimpleRoute.root() : super(const AtomicPath.root());

  /// Create a route path from the provided [segments].
  SimpleRoute.join(List<String> segments) : super(SegmentedPath(segments));

  /// Navigate to this route.
  void go(BuildContext context, {Map<String, String>? query}) {
    GoRouter.of(context).go(fullPath.maybeAppendQuery(query));
  }
}

/// A route that contains a parameter. When navigating, data must be supplied
/// to populate the route.
abstract class DataRoute<Data extends SimpleRouteData> extends BaseRoute {
  /// Create a DataRoute with the provided [path].
  DataRoute(String? path) : super(AtomicPath.from(path));

  /// Create a data route path from the provided [segments].
  DataRoute.join(List<String> segments) : super(SegmentedPath(segments));

  /// Navigate to this route using the supplied [data].
  void go(
    BuildContext context, {
    required Data data,
    Map<String, String>? query,
  }) {
    GoRouter.of(context).go(data.inject(fullPath).maybeAppendQuery(query));
  }
}
