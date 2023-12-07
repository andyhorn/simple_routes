import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/simple_routes.dart';

import 'mocks.dart';

void main() {
  late GoRouter router;
  late _TestRootRoute root;
  late _TestRoute route;
  late _TestChildRoute childRoute;

  group('Duplicate segments', () {
    test('throws an error', () {
      expect(
        () => const _DuplicateTestRoute().fullPath(),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          'Error in _DuplicateTestRoute - Segments should be unique. Found duplicates of: {test, :param}',
        )),
      );
    });
  });

  group('Empty route', () {
    setUp(() {
      router = MockGoRouter();
      root = const _TestRootRoute();
    });

    group('#fullPath', () {
      test('returns leading slash', () {
        expect(root.fullPath(), '/');
      });
    });
  });

  group('Root route', () {
    setUp(() {
      router = MockGoRouter();
      route = const _TestRoute();
      childRoute = const _TestChildRoute();
    });

    group('#fullPath', () {
      test('adds leading slash', () {
        expect(route.fullPath(), '/test');
      });
    });

    group('.goPath', () {
      test('returns correct path', () {
        expect(route.goPath, '/test');
      });
    });

    group('#go', () {
      testWidgets('navigates to the correct path', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MockGoRouterProvider(
              goRouter: router,
              child: Builder(builder: (context) {
                return ElevatedButton(
                  onPressed: () => const _TestRoute().go(context),
                  child: const Text('click me'),
                );
              }),
            ),
          ),
        );

        await tester.tap(find.text('click me'));

        verify(() => router.go('/test')).called(1);
      });
    });

    group('#push', () {
      testWidgets('pushed the correct path', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MockGoRouterProvider(
              goRouter: router,
              child: Builder(builder: (context) {
                return ElevatedButton(
                  onPressed: () => const _TestRoute().push(context),
                  child: const Text('click me'),
                );
              }),
            ),
          ),
        );

        await tester.tap(find.text('click me'));

        verify(() => router.push('/test')).called(1);
      });
    });
  });

  group('Child route', () {
    group('#fullPath', () {
      test('joins with parents', () {
        expect(childRoute.fullPath(), '/test/child');
      });
    });

    group('.goPath', () {
      test('returns correct route', () {
        expect(childRoute.goPath, 'child');
      });
    });
  });

  group('#isCurrentRoute', () {
    testWidgets('returns true when on current route', (tester) async {
      var isCurrentRoute = false;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home',
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => const _TestRoute().go(context),
                      child: const Text('click me'),
                    ),
                  );
                },
              ),
              GoRoute(
                path: const _TestRoute().goPath,
                builder: (context, state) {
                  isCurrentRoute = const _TestRoute().isCurrentRoute(context);
                  return const Scaffold(
                    body: Text('Test Route'),
                  );
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('click me'));
      await tester.pump();

      expect(isCurrentRoute, isTrue);
    });

    testWidgets('returns false when on a different route', (tester) async {
      var isCurrentRoute = true;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: const _TestRoute().fullPath(),
            routes: [
              GoRoute(
                path: const _TestRoute().goPath,
                builder: (context, state) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => context.go('/other-page'),
                      child: const Text('click me'),
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/other-page',
                builder: (context, state) {
                  isCurrentRoute = const _TestRoute().isCurrentRoute(context);
                  return const Scaffold(
                    body: Text('Test Route'),
                  );
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('click me'));
      await tester.pump();

      expect(isCurrentRoute, isFalse);
    });
  });

  group('#isParentRoute', () {
    testWidgets(
      'returns true when the route is a parent',
      (tester) async {
        var isParent = false;

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: const _TestRoute().fullPath(),
              routes: [
                GoRoute(
                  path: const _TestRoute().goPath,
                  builder: (context, state) {
                    return Scaffold(
                      body: ElevatedButton(
                        onPressed: () => const _TestChildRoute().go(context),
                        child: const Text('click me'),
                      ),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: const _TestChildRoute().goPath,
                      builder: (context, state) {
                        isParent = const _TestRoute().isParentRoute(context);
                        return const Scaffold(
                          body: Text('Test Route'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.text('click me'));
        await tester.pump();

        expect(isParent, isTrue);
      },
    );

    testWidgets(
      'returns false when the route is not a parent',
      (tester) async {
        var isParent = true;

        await tester.pumpWidget(
          MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: const _TestRoute().fullPath(),
              routes: [
                GoRoute(
                  path: const _TestRoute().goPath,
                  builder: (context, state) {
                    return Scaffold(
                      body: ElevatedButton(
                        onPressed: () => context.go('/other-path'),
                        child: const Text('click me'),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: '/other-path',
                  builder: (context, state) {
                    isParent = const _TestRoute().isParentRoute(context);
                    return const Scaffold(
                      body: Text('Test Route'),
                    );
                  },
                ),
              ],
            ),
          ),
        );

        await tester.tap(find.text('click me'));
        await tester.pump();

        expect(isParent, isFalse);
      },
    );
  });

  group('#isActive', () {
    testWidgets('returns true when on current route', (tester) async {
      var isActive = false;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home',
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => const _TestRoute().go(context),
                      child: const Text('click me'),
                    ),
                  );
                },
              ),
              GoRoute(
                path: const _TestRoute().goPath,
                builder: (context, state) {
                  isActive = const _TestRoute().isActive(context);
                  return const Scaffold(
                    body: Text('Test Route'),
                  );
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('click me'));
      await tester.pump();

      expect(isActive, isTrue);
    });

    testWidgets('returns false when on a different route', (tester) async {
      var isActive = true;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: const _TestRoute().fullPath(),
            routes: [
              GoRoute(
                path: const _TestRoute().goPath,
                builder: (context, state) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => context.go('/other-page'),
                      child: const Text('click me'),
                    ),
                  );
                },
              ),
              GoRoute(
                path: '/other-page',
                builder: (context, state) {
                  isActive = const _TestRoute().isCurrentRoute(context);
                  return const Scaffold(
                    body: Text('Test Route'),
                  );
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('click me'));
      await tester.pump();

      expect(isActive, isFalse);
    });

    testWidgets('returns true when on a parent route', (tester) async {
      var isActive = false;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: const _TestRoute().fullPath(),
            routes: [
              GoRoute(
                path: const _TestRoute().goPath,
                builder: (context, state) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => const _TestChildRoute().go(context),
                      child: const Text('click me'),
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: const _TestChildRoute().goPath,
                    builder: (context, state) {
                      isActive = const _TestRoute().isActive(context);
                      return const Scaffold(
                        body: Text('Test Route'),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('click me'));
      await tester.pump();

      expect(isActive, isTrue);
    });
  });
}

enum _TestRouteParams {
  param,
}

class _TestRootRoute extends SimpleRoute {
  const _TestRootRoute();

  @override
  String get path => '';
}

class _TestRoute extends SimpleRoute {
  const _TestRoute();

  @override
  String get path => 'test';
}

class _TestChildRoute extends SimpleRoute implements ChildRoute<_TestRoute> {
  const _TestChildRoute();

  @override
  _TestRoute get parent => const _TestRoute();

  @override
  String get path => 'child';
}

class _DuplicateTestRoute extends SimpleRoute {
  const _DuplicateTestRoute();

  @override
  String get path => joinSegments([
        'test',
        'test',
        _TestRouteParams.param.prefixed,
        _TestRouteParams.param.prefixed,
      ]);
}
