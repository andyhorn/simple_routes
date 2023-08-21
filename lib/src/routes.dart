import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:simple_routes/src/base_route.dart';
import 'package:simple_routes/src/data.dart';

/// A route that contains no parameters.
abstract class SimpleRoute extends BaseRoute {
  const SimpleRoute();

  /// Navigate to this route.
  void go(BuildContext context) {
    GoRouter.of(context).go(fullPath);
  }
}

/// A route that contains a parameter. When navigating, data must be supplied
/// to populate the route.
abstract class DataRoute<Data extends SimpleRouteData> extends BaseRoute {
  const DataRoute();

  /// Navigate to this route using the supplied [data].
  void go(BuildContext context, Data data) {
    GoRouter.of(context).go(data.inject(fullPath));
  }
}
