import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/src/state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/simple_routes.dart';

enum _MyEnum {
  myKey,
}

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

class _ExtraData {
  const _ExtraData(this.value);

  final String value;
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

    group('#containsExtra', () {
      group('when it does not contain any extra data', () {
        late GoRouterState state;

        setUp(() {
          state = _MockGoRouterState();
          when(() => state.extra).thenReturn(null);
        });

        test('returns false', () {
          expect(_Factory().containsExtra<_ExtraData>(state), isFalse);
        });
      });

      group('when it contains extra data', () {
        late GoRouterState state;

        setUp(() {
          state = _MockGoRouterState();
          when(() => state.extra).thenReturn(const _ExtraData('hello world'));
        });

        test('returns true', () {
          expect(_Factory().containsExtra<_ExtraData>(state), isTrue);
        });
      });
    });

    group('#extractExtra', () {
      late GoRouterState state;

      setUp(() {
        state = _MockGoRouterState();
        when(() => state.extra).thenReturn(const _ExtraData('hello world'));
      });

      test('extracts the extra data', () {
        expect(_Factory().extractExtra<_ExtraData>(state).value, 'hello world');
      });
    });
  });
}
