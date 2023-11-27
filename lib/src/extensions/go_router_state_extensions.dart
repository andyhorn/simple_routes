import 'package:go_router/go_router.dart';
import 'package:simple_routes/src/utils/utils.dart';

extension GoRouterStateExtensions on GoRouterState {
  /// Extract the value for [key] from the path parameters, if it exists.
  String? getParam<E extends Enum>(E key) {
    return pathParameters[key.name];
  }

  /// Extract the value for [key] from the query parameters, if it exists.
  String? getQuery<E extends Enum>(E key) {
    return uri.queryParameters[key.name];
  }

  /// Extract the [Extra] data, if it exists.
  ///
  /// Make sure to provide the [Extra] type parameter, or it will return null.
  Extra? getExtra<Extra>() {
    return extra?.runtimeType == typeOf<Extra>() ? extra as Extra : null;
  }
}
