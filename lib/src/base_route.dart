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
}
