import 'package:go_router/go_router.dart';
import 'package:simple_routes/src/utils.dart';

abstract class SimpleRouteData {
  const SimpleRouteData();

  String inject(String path);
}

abstract class SimpleRouteDataFactory<Data extends SimpleRouteData> {
  const SimpleRouteDataFactory();

  Data fromState(GoRouterState state);
  bool containsData(GoRouterState state);

  bool containsKey<E extends Enum>(GoRouterState state, E key) {
    return state.pathParameters.containsKey(withPrefix(key));
  }
}
