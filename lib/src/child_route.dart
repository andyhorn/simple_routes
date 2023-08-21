import 'package:simple_routes/src/base_route.dart';

abstract class ChildRoute<Parent extends BaseRoute> {
  /// The parent route of this route.
  Parent get parent;
}
