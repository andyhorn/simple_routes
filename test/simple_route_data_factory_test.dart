import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/src/state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/src/route_data.dart';

enum _MyEnum {
  myKey,
}

class ExtraData {
  final String value;

  const ExtraData(this.value);
}

class ExtraDataTwo {}

class _Factory extends SimpleRouteDataFactory {
  @override
  SimpleRouteData fromState(GoRouterState state) {
    throw UnimplementedError();
  }
}

class _MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group('$SimpleRouteDataFactory', () {
    group('#extractParam', () {
      group('when the parameter is present', () {
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

      group('when the parameter is not present', () {
        final state = _MockGoRouterState();

        setUp(() {
          final params = {
            'otherKey': 'otherValue',
          };

          when(() => state.pathParameters).thenReturn(params);
        });

        test('it returns null', () {
          expect(_Factory().extractParam(state, _MyEnum.myKey), isNull);
        });
      });
    });

    group('#extractQuery', () {
      group('when the parameter is present', () {
        final state = _MockGoRouterState();

        setUp(() {
          final uri = Uri.parse('http://example.com?myKey=myValue');

          when(() => state.uri).thenReturn(uri);
        });

        test('it returns the value', () {
          expect(_Factory().extractQuery(state, 'myKey'), 'myValue');
        });
      });

      group('when the parameter is not present', () {
        final state = _MockGoRouterState();

        setUp(() {
          final uri = Uri.parse('http://example.com?otherKey=otherValue');

          when(() => state.uri).thenReturn(uri);
        });

        test('it returns null', () {
          expect(_Factory().extractQuery(state, 'myKey'), isNull);
        });
      });
    });

    group('#extractExtra', () {
      group('when the extra data is present', () {
        final state = _MockGoRouterState();

        setUp(() {
          when(() => state.extra).thenReturn(const ExtraData('hello world!'));
        });

        test('it returns the extra data', () {
          expect(_Factory().extractExtra<ExtraData>(state), isA<ExtraData>());
        });
      });
      group('when the extra data is null', () {
        final state = _MockGoRouterState();

        setUp(() {
          when(() => state.extra).thenReturn(null);
        });

        test('it returns null', () {
          expect(_Factory().extractExtra(state), isNull);
        });
      });

      group('when the extra data is not of the specified type', () {
        final state = _MockGoRouterState();

        setUp(() {
          when(() => state.extra).thenReturn(ExtraDataTwo());
        });

        test('it returns null', () {
          expect(_Factory().extractExtra<ExtraData>(state), isNull);
        });
      });

      group('when the type is not provided', () {
        final state = _MockGoRouterState();

        setUp(() {
          when(() => state.extra).thenReturn(const ExtraData('hello world!'));
        });

        test('it returns null', () {
          expect(_Factory().extractExtra(state), isNull);
        });
      });
    });
  });
}
