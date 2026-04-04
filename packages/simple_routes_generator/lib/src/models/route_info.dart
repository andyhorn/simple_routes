import 'package:analyzer/dart/element/element.dart';

/// Information about a route extracted from an annotated class element.
class RouteInfo {
  /// Creates a new [RouteInfo].
  const RouteInfo(this.element, this.path);

  /// The blueprint class for this route.
  final ClassElement element;

  /// The path for this route.
  final String path;
}
