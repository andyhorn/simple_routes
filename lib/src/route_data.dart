import 'package:go_router/go_router.dart';

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

  /// Returns true if the [state] contains the data for this factory.
  bool containsData(GoRouterState state);

  /// Returns true if the [state] path parameters contains the [key].
  bool containsParam<E extends Enum>(GoRouterState state, E key) {
    return state.pathParameters.containsKey(key.name);
  }

  /// Extract the [key] from the [state] path parameters.
  String extractParam<E extends Enum>(GoRouterState state, E key) {
    return state.pathParameters[key.name]!;
  }

  /// Returns true if the [state] query parameters contains the [key].
  bool containsQuery(GoRouterState state, String key) {
    return state.uri.queryParameters.containsKey(key);
  }

  /// Extract the [key] from the [state] query parameters.
  String extractQuery(GoRouterState state, String key) {
    return state.uri.queryParameters[key]!;
  }
}

mixin ExtraDataMixin<E extends Object> {
  /// Returns true if the [state]'s `extra` data is of type [T].
  bool containsExtra(GoRouterState state) {
    return state.extra is E;
  }

  /// Extract the [state] `extra` data as type [T].
  E extractExtra(GoRouterState state) {
    return state.extra as E;
  }
}
