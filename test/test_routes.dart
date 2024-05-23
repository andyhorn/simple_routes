import 'package:simple_routes/simple_routes.dart';

class TestEmptyRoute extends SimpleRoute {
  const TestEmptyRoute() : super('');
}

class TestSlashRoute extends SimpleRoute {
  const TestSlashRoute() : super(SimpleRoute.root);
}

class TestSlashChildRoute extends SimpleRoute
    implements ChildRoute<TestSlashRoute> {
  const TestSlashChildRoute() : super('child');

  @override
  final TestSlashRoute parent = const TestSlashRoute();
}

class TestBaseRoute extends SimpleRoute {
  const TestBaseRoute() : super('base');
}

class TestChildRoute extends SimpleRoute implements ChildRoute<TestBaseRoute> {
  const TestChildRoute() : super('child');

  @override
  final TestBaseRoute parent = const TestBaseRoute();
}

class TestData {
  const TestData();
}

class TestRouteData extends SimpleRouteData {
  const TestRouteData({
    required this.testQuery,
    required this.testValue,
    required this.testData,
  });

  final String testValue;
  final String testQuery;
  final TestData testData;

  @override
  Map<String, String> get parameters => {
        'param': testValue,
      };

  @override
  Map<String, String?> get query => {
        'query': testQuery,
      };

  @override
  Object? get extra => testData;
}

class TestDataRoute extends SimpleDataRoute<TestRouteData> {
  const TestDataRoute() : super(':param');
}
