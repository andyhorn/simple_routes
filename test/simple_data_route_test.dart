import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/simple_routes.dart';

import 'mocks.dart';
import 'test_routes.dart';

void main() {
  late GoRouter router;

  group('$SimpleDataRoute', () {
    setUp(() {
      router = MockGoRouter();
    });

    group('#go', () {
      testWidgets('navigates to the correct route', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MockGoRouterProvider(
              goRouter: router,
              child: Builder(builder: (context) {
                return ElevatedButton(
                  onPressed: () => const TestDataRoute().go(
                    context,
                    data: const TestRouteData(
                      testValue: 'test-value',
                      testData: TestData(),
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
            '/test-value?query=test-query',
            extra: isA<TestData>(),
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
                  onPressed: () => const TestDataRoute().push(
                    context,
                    data: const TestRouteData(
                      testValue: 'test-value',
                      testData: TestData(),
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
            '/test-value?query=test-query',
            extra: isA<TestData>(),
          ),
        ).called(1);
      });
    });

    group('#fullPath', () {
      test('generates the correct path', () {
        const route = TestDataRoute();
        final generated = route.fullPath(
          const TestRouteData(
            testValue: 'test-value',
            testData: TestData(),
            testQuery: 'test query',
          ),
        );
        expect(generated, '/test-value?query=test%20query');
      });
    });
  });
}
