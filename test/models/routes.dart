import 'package:simple_routes/simple_routes.dart';

class Path1 extends SimpleRoute {
  const Path1();

  @override
  String get path => 'path1';
}

class Path2 extends SimpleRoute {
  const Path2();

  @override
  String get path => 'path2';
}

enum TestRouteParams {
  test,
}

class TestRouteData extends SimpleRouteData {
  const TestRouteData(this.value);

  final String value;

  @override
  String inject(String path) {
    return path.setParam(TestRouteParams.test, value);
  }
}

class DataPath extends DataRoute<TestRouteData> implements ChildRoute<Path2> {
  const DataPath();

  @override
  String get path => withPrefix(TestRouteParams.test);

  @override
  Path2 get parent => const Path2();
}
