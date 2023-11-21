import 'package:flutter_test/flutter_test.dart';
import 'package:simple_routes/simple_routes.dart';

class _TestSimpleRoute extends SimpleRoute {
  @override
  String get path => '/test';
}

class _TestRouteNoSlash extends SimpleRoute {
  const _TestRouteNoSlash();

  @override
  String get path => 'test';
}

class _TestChildRouteNoSlash extends SimpleRoute
    implements ChildRoute<_TestRouteNoSlash> {
  const _TestChildRouteNoSlash();

  @override
  _TestRouteNoSlash get parent => const _TestRouteNoSlash();

  @override
  String get path => 'child';
}

class _TestSimpleChildRoute extends SimpleRoute
    implements ChildRoute<_TestSimpleRoute> {
  @override
  _TestSimpleRoute get parent => _TestSimpleRoute();

  @override
  String get path => 'child';
}

class _SecondLevelChildRoute extends SimpleRoute
    implements ChildRoute<_TestSimpleChildRoute> {
  @override
  _TestSimpleChildRoute get parent => _TestSimpleChildRoute();

  @override
  String get path => 'second-level';
}

void main() {
  group('$SimpleRoute', () {
    final route = _TestSimpleRoute();

    test('path', () {
      expect(route.path, '/test');
    });

    test('fullPath', () {
      expect(route.fullPath, '/test');
    });
  });

  group('Child $SimpleRoute', () {
    final child = _TestSimpleChildRoute();

    test('path', () {
      expect(child.path, 'child');
    });

    test('fullPath', () {
      expect(child.fullPath, '/test/child');
    });
  });

  group('Second-level child', () {
    final child = _SecondLevelChildRoute();

    test('path', () {
      expect(child.path, 'second-level');
    });

    test('fullPath', () {
      expect(child.fullPath, '/test/child/second-level');
    });
  });

  group('$_TestRouteNoSlash', () {
    group('#fullPath', () {
      test('adds leading slash', () {
        expect(const _TestRouteNoSlash().fullPath, '/test');
      });
    });
  });

  group('$_TestChildRouteNoSlash', () {
    group('#fullPath', () {
      test('adds leading slash', () {
        expect(const _TestChildRouteNoSlash().fullPath, '/test/child');
      });
    });
  });
}
