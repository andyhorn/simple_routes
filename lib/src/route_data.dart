import 'package:go_router/go_router.dart';
import 'package:simple_routes/src/utils/utils.dart';

abstract class SimpleRouteData<E extends Object> {
  const SimpleRouteData();

  /// Inject this route data into the path.
  String inject(String path);

  /// Inject data into the "extra" field of the [GoRouterState].
  E? extra() => null;
}

abstract class SimpleRouteDataFactory<Data extends SimpleRouteData> {
  const SimpleRouteDataFactory();

  /// Create an instance of [Data] from the [state].
  Data fromState(GoRouterState state);

  /// Extract the [key] from the [state] path parameters, if it exists.
  String? extractParam<E extends Enum>(GoRouterState state, E key) {
    return state.pathParameters[key.name];
  }

  /// Extract the [key] from the [state] query parameters, if it exists.
  String? extractQuery(GoRouterState state, String key) {
    return state.uri.queryParameters[key];
  }

  /// Extract the [Extra] data from the [state], if it exists.
  ///
  /// Make sure to provide the [Extra] type parameter, or it will return null.
  Extra? extractExtra<Extra>(GoRouterState state) {
    return state.extra?.runtimeType == typeOf<Extra>()
        ? state.extra as Extra
        : null;
  }
}
