import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/src/extensions/go_router_state_extensions.dart';

import '../mocks.dart';

enum TestEnum {
  valueOne,
  valueTwo,
}

class TestClassOne {}

class TestClassTwo {}

void main() {
  group('GoRouterStateExtensions', () {
    late GoRouterState state;

    setUp(() {
      state = MockGoRouterState();
    });

    group('#getParam', () {
      group('when the param exists', () {
        setUp(() {
          when(() => state.pathParameters).thenReturn({
            TestEnum.valueOne.name: 'value-one',
          });
        });

        test('returns the value', () {
          expect(state.getParam(TestEnum.valueOne), 'value-one');
        });
      });

      group('when the param does not exist', () {
        setUp(() {
          when(() => state.pathParameters).thenReturn({});
        });

        test('returns null', () {
          expect(state.getParam(TestEnum.valueOne), null);
        });
      });
    });

    group('#getQuery', () {
      group('when the query value exists', () {
        setUp(() {
          when(() => state.uri).thenReturn(Uri.parse(
              'http://localhost:8080?${TestEnum.valueOne.name}=value-one'));
        });

        test('returns the value', () {
          expect(state.getQuery(TestEnum.valueOne), 'value-one');
        });
      });
    });

    group('#getExtra', () {
      group('when the extra data is present', () {
        setUp(() {
          when(() => state.extra).thenReturn(TestClassOne());
        });

        test('returns the extra data', () {
          expect(state.getExtra<TestClassOne>(), isA<TestClassOne>());
        });
      });

      group('when the extra data is null', () {
        setUp(() {
          when(() => state.extra).thenReturn(null);
        });

        test('returns null', () {
          expect(state.getExtra<TestClassOne>(), null);
        });
      });

      group('when the extra data is of the wrong type', () {
        setUp(() {
          when(() => state.extra).thenReturn(TestClassTwo());
        });

        test('returns null', () {
          expect(state.getExtra<TestClassOne>(), isNull);
        });
      });

      group('when the generic argument is not provided', () {
        setUp(() {
          when(() => state.extra).thenReturn(TestClassOne());
        });

        test('returns null', () {
          expect(state.getExtra(), isNull);
        });
      });
    });
  });
}
