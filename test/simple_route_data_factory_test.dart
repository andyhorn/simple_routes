import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/src/state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/src/data.dart';

enum _MyEnum {
  myKey,
}

class ExtraData {}

class ExtraDataTwo {}

class TestClass with ExtraDataMixin<ExtraData> {}

class _Factory extends SimpleRouteDataFactory {
  @override
  bool containsData(GoRouterState state) {
    return containsParam(state, _MyEnum.myKey);
  }

  @override
  SimpleRouteData fromState(GoRouterState state) {
    throw UnimplementedError();
  }
}

class _MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('$SimpleRouteDataFactory', () {
    group('#containsData', () {
      group('when it contains the key', () {
        final state = _MockGoRouterState();

        setUp(() {
          final params = {
            _MyEnum.myKey.name: 'myValue',
          };

          when(() => state.pathParameters).thenReturn(params);
        });

        test('it returns true', () {
          expect(_Factory().containsData(state), isTrue);
        });
      });

      group('when it does not contain the key', () {
        final state = _MockGoRouterState();

        setUp(() {
          final params = {
            'someOtherKey': 'myValue',
          };

          when(() => state.pathParameters).thenReturn(params);
        });

        test('it returns false', () {
          expect(_Factory().containsData(state), isFalse);
        });
      });
    });

    group('#containsQuery', () {
      group('when it contains the key', () {
        final state = _MockGoRouterState();

        setUp(() {
          final uri = Uri.parse('http://example.com?key=value');
          when(() => state.uri).thenReturn(uri);
        });

        test('it returns true', () {
          expect(_Factory().containsQuery(state, 'key'), isTrue);
        });
      });

      group('when it does not contain the key', () {
        final state = _MockGoRouterState();

        setUp(() {
          final uri = Uri.parse('http://example.com?key=value');
          when(() => state.uri).thenReturn(uri);
        });

        test('it returns false', () {
          expect(_Factory().containsQuery(state, 'someOtherKey'), isFalse);
        });
      });
    });

    group('#containsParam', () {
      group('when it contains the key', () {
        final state = _MockGoRouterState();

        setUp(() {
          final params = {
            _MyEnum.myKey.name: 'myValue',
          };

          when(() => state.pathParameters).thenReturn(params);
        });

        test('it returns true', () {
          expect(_Factory().containsParam(state, _MyEnum.myKey), isTrue);
        });
      });

      group('when it does not contain the key', () {
        final state = _MockGoRouterState();

        setUp(() {
          final params = {
            'someOtherKey': 'myValue',
          };

          when(() => state.pathParameters).thenReturn(params);
        });

        test('it returns false', () {
          expect(_Factory().containsParam(state, _MyEnum.myKey), isFalse);
        });
      });
    });

    group('#extractParam', () {
      final state = _MockGoRouterState();

      setUp(() {
        final params = {
          _MyEnum.myKey.name: 'myValue',
        };

        when(() => state.pathParameters).thenReturn(params);
      });

      test('it returns the value', () {
        expect(_Factory().extractParam(state, _MyEnum.myKey), 'myValue');
      });
    });
  });

  group('$ExtraDataMixin', () {
    late GoRouterState state;
    final testClass = TestClass();

    setUp(() {
      state = _MockGoRouterState();
    });

    group('#containsExtra', () {
      group('when state does not contain extra data', () {
        setUp(() {
          when(() => state.extra).thenReturn(null);
        });

        test('returns false', () {
          expect(testClass.containsExtra(state), isFalse);
        });
      });

      group('when state contains an object of a different type', () {
        setUp(() {
          when(() => state.extra).thenReturn(ExtraDataTwo());
        });

        test('returns false', () {
          expect(testClass.containsExtra(state), isFalse);
        });
      });

      group('when state contains the extra data', () {
        setUp(() {
          when(() => state.extra).thenReturn(ExtraData());
        });

        test('returns true', () {
          expect(testClass.containsExtra(state), isTrue);
        });
      });
    });

    group('#extractExtra', () {
      setUp(() {
        when(() => state.extra).thenReturn(ExtraData());
      });

      test('returns the extra data', () {
        expect(testClass.extractExtra(state), isA<ExtraData>());
      });
    });
  });
}
