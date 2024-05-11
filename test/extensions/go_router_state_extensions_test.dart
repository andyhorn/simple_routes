import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/src/extensions/go_router_state_extensions.dart';

import '../mocks.dart';

enum TestEnum {
  valueOne,
  valueTwo,
}

void main() {
  group('GoRouterStateExtensions', () {
    late GoRouterState state;

    setUp(() {
      state = MockGoRouterState();
    });

    group('#param', () {
      group('when the param exists', () {
        setUp(() {
          when(() => state.pathParameters).thenReturn({
            TestEnum.valueOne.name: 'value-one',
          });
        });

        test('returns the value', () {
          expect(state.param(TestEnum.valueOne.name), 'value-one');
        });
      });

      group('when the param does not exist', () {
        setUp(() {
          when(() => state.pathParameters).thenReturn({});
        });

        test('returns null', () {
          expect(state.param(TestEnum.valueOne.name), null);
        });
      });
    });

    group('#query', () {
      group('when the query value exists', () {
        setUp(() {
          when(() => state.uri).thenReturn(Uri.parse(
              'http://localhost:8080?${TestEnum.valueOne.name}=value-one'));
        });

        test('returns the value', () {
          expect(state.query(TestEnum.valueOne.name), 'value-one');
        });
      });
    });
  });
}
