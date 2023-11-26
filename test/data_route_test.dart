import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/simple_routes.dart';

import 'mocks.dart';

void main() {
  late GoRouter router;

  group('$DataRoute', () {
    setUp(() {
      router = MockGoRouter();
    });

    group('#go', () {
      testWidgets('navigates to the correct path', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MockGoRouterProvider(
              goRouter: router,
              child: Builder(builder: (context) {
                return ElevatedButton(
                  onPressed: () => const _TestRoute().go(
                    context,
                    data: const _TestRouteData(
                      testValue: 'test-value',
                      testData: _TestData(),
                      testQuery: 'test-query',
                    ),
                  ),
                  child: const Text('click me'),
                );
              }),
            ),
          ),
        );

        await tester.tap(find.text('click me'));

        verify(
          () => router.go(
            '/test-value?valueTwo=test-query',
            extra: isA<_TestData>(),
          ),
        ).called(1);
      });
    });

    group('#push', () {
      testWidgets('pushed the correct route', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MockGoRouterProvider(
              goRouter: router,
              child: Builder(builder: (context) {
                return ElevatedButton(
                  onPressed: () => const _TestRoute().push(
                    context,
                    data: const _TestRouteData(
                      testValue: 'test-value',
                      testData: _TestData(),
                      testQuery: 'test-query',
                    ),
                  ),
                  child: const Text('click me'),
                );
              }),
            ),
          ),
        );

        await tester.tap(find.text('click me'));

        verify(
          () => router.push(
            '/test-value?valueTwo=test-query',
            extra: isA<_TestData>(),
          ),
        ).called(1);
      });
    });

    group('#generate', () {
      test('generates the correct path', () {
        const route = _TestRoute();
        final generated = route.generate(
          const _TestRouteData(
            testValue: 'test-value',
            testData: _TestData(),
            testQuery: 'test-query',
          ),
        );
        expect(generated, '/test-value?valueTwo=test-query');
      });
    });
  });
}

enum _TestEnum {
  valueOne,
  valueTwo,
}

class _TestData {
  const _TestData();
}

class _TestRouteData extends SimpleRouteData {
  const _TestRouteData({
    required this.testQuery,
    required this.testValue,
    required this.testData,
  });

  final String testValue;
  final String testQuery;
  final _TestData testData;

  @override
  Object? extra() => testData;

  @override
  String inject(String path) {
    return path.setParam(_TestEnum.valueOne, testValue).appendQuery({
      _TestEnum.valueTwo.name: testQuery,
    });
  }
}

class _TestRoute extends DataRoute<_TestRouteData> {
  const _TestRoute();

  @override
  String get path => _TestEnum.valueOne.prefixed;
}
