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
    return containsKey(state, _MyEnum.myKey);
  }

  @override
  SimpleRouteData fromState(GoRouterState state) {
    throw UnimplementedError();
  }
}

class _MockGoRouterState extends Mock implements GoRouterState {}

void main() {
  group(SimpleRouteDataFactory, () {
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
  });
}
