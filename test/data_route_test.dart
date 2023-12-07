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

    group('#fullPath', () {
      test('generates the correct path', () {
        const route = _TestRoute();
        final generated = route.fullPath(
          const _TestRouteData(
            testValue: 'test-value',
            testData: _TestData(),
            testQuery: 'test query',
          ),
        );
        expect(generated, '/test-value?valueTwo=test%20query');
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
  Map<Enum, String> get parameters => {
        _TestEnum.valueOne: testValue,
      };

  @override
  Map<Enum, String?> get query => {
        _TestEnum.valueTwo: testQuery,
      };

  @override
  Object? get extra => testData;
}

class _TestRoute extends DataRoute<_TestRouteData> {
  const _TestRoute();

  @override
  String get path => _TestEnum.valueOne.prefixed;
}
