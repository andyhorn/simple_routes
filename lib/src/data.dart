import 'package:go_router/go_router.dart';

abstract class SimpleRouteData {
  const SimpleRouteData();

  /// Inject this route data into the path.
  String inject(String path);
}

abstract class SimpleRouteDataFactory<Data extends SimpleRouteData> {
  const SimpleRouteDataFactory();

  /// Create an instance of [Data] from the [state].
  Data fromState(GoRouterState state);

  /// Returns true if the [state] contains the data for this factory.
  bool containsData(GoRouterState state);

  /// Returns true if the [state] path parameters contains the [key].
  bool containsKey<E extends Enum>(GoRouterState state, E key) {
    return state.pathParameters.containsKey(key.name);
  }

  /// Extract the [key] from the [state] path parameters.
  String extractParam<E extends Enum>(GoRouterState state, E key) {
    return state.pathParameters[key.name]!;
  }
}
