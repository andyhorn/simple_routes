import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/simple_routes.dart';

class _MockBuildContext extends Mock implements BuildContext {}

class _ExtraData {
  const _ExtraData(this.value);

  final String value;
}

enum DataRouteParams {
  userId,
  someValue,
}

class RootRouteData extends SimpleRouteData {
  const RootRouteData({required this.userId});

  final String userId;

  @override
  String inject(String path) {
    return path.setParam(DataRouteParams.userId, userId);
  }
}

class ChildRouteData extends RootRouteData {
  const ChildRouteData({
    required super.userId,
    required this.someValue,
  });

  final String someValue;

  @override
  String inject(String path) {
    return super.inject(path).setParam(DataRouteParams.someValue, someValue);
  }

  @override
  Object? extra() => _ExtraData(someValue);
}

class _RootDataRoute extends DataRoute<RootRouteData> {
  _RootDataRoute(this.onGo);

  final void Function(String) onGo;

  @override
  String get path => join(['/', withPrefix(DataRouteParams.userId)]);

  // overriding for test purposes only
  @override
  void go(
    BuildContext context, {
    required RootRouteData data,
    Map<String, String>? query,
    push = false,
  }) {
    onGo(data.inject(fullPath));
  }
}

class _ChildDataRoute extends DataRoute<ChildRouteData>
    implements ChildRoute<_RootDataRoute> {
  _ChildDataRoute(this.onGo);

  final void Function(String, Object?) onGo;

  @override
  _RootDataRoute get parent => _RootDataRoute((_) {});

  @override
  String get path => join(['child', withPrefix(DataRouteParams.someValue)]);

  // overriding for test purposes only
  @override
  void go(
    BuildContext context, {
    required RootRouteData data,
    Map<String, String>? query,
    push = false,
  }) {
    onGo(data.inject(fullPath), data.extra());
  }
}

void main() {
  group('$DataRoute', () {
    test('path', () {
      final route = _RootDataRoute((_) {});
      expect(route.path, '/:userId');
    });

    test('fullPath', () {
      final route = _RootDataRoute((_) {});
      expect(route.fullPath, '/:userId');
    });

    test('injection', () {
      var injected = '';
      final route = _RootDataRoute((x) => injected = x);
      route.go(
        _MockBuildContext(),
        data: const RootRouteData(userId: 'user-id'),
      );
      expect(injected, '/user-id');
    });

    test('buildPath', () {
      final route = _RootDataRoute((_) {});
      expect(
        route.buildPath(
          const RootRouteData(userId: 'user-id'),
          query: {'key': 'value'},
        ),
        '/user-id?key=value',
      );
    });
  });

  group('Child $DataRoute', () {
    test('path', () {
      final child = _ChildDataRoute((_, __) {});
      expect(child.path, 'child/:someValue');
    });

    test('fullPath', () {
      final child = _ChildDataRoute((_, __) {});
      expect(child.fullPath, '/:userId/child/:someValue');
    });

    test('injection', () {
      var injected = '';
      final child = _ChildDataRoute((x, _) => injected = x);
      child.go(
        _MockBuildContext(),
        data: const ChildRouteData(userId: 'user-id', someValue: 'some-value'),
      );
      expect(injected, '/user-id/child/some-value');
    });

    test('injects extra data', () {
      _ExtraData? extra;
      final child = _ChildDataRoute((_, x) => extra = x as _ExtraData?);
      child.go(
        _MockBuildContext(),
        data: const ChildRouteData(userId: 'user-id', someValue: 'some-value'),
      );
      expect(extra?.value, 'some-value');
    });

    test('buildPath', () {
      final child = _ChildDataRoute((_, __) {});
      expect(
        child.buildPath(
          const ChildRouteData(
            userId: 'user-id',
            someValue: 'some-value',
          ),
          query: {'key': 'value'},
        ),
        '/user-id/child/some-value?key=value',
      );
    });
  });
}
