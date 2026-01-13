import 'package:analyzer/dart/element/element.dart';

class RouteInfo {
  const RouteInfo(this.element, this.path);

  /// The blueprint class for this route.
  final ClassElement element;

  /// The path for this route.
  final String path;
}
