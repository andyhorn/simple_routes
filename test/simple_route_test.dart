import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:simple_routes/simple_routes.dart';

import 'mocks.dart';
import 'test_routes.dart';

void main() {
  late GoRouter router;
  late TestEmptyRoute root;
  late TestBaseRoute route;
  late TestChildRoute childRoute;

  group('Duplicate segments', () {
    test('throws an error', () {
      expect(
        () => const _DuplicateTestRoute().fullPath(),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          '[SimpleRoutes] WARNING: Path segments should be unique.\n_DuplicateTestRoute: Duplicates of "test", ":param"',
        )),
      );
    });
  });

  group('Empty route', () {
    setUp(() {
      router = MockGoRouter();
      root = const TestEmptyRoute();
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
      route = const TestBaseRoute();
      childRoute = const TestChildRoute();
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
                  onPressed: () => const TestBaseRoute().go(context),
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
                  onPressed: () => const TestBaseRoute().push(context),
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

  group('Slash route', () {
    group('#fullPath', () {
      test('returns slash', () {
        expect(const TestRootRoute().fullPath(), '/');
      });
    });
  });

  group('Slash child route', () {
    group('#fullPath', () {
      test('returns proper path', () {
        expect(const TestSlashChildRoute().fullPath(), '/child');
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
                      onPressed: () => const TestBaseRoute().go(context),
                      child: const Text('click me'),
                    ),
                  );
                },
              ),
              GoRoute(
                path: const TestBaseRoute().goPath,
                builder: (context, state) {
                  isCurrentRoute = const TestBaseRoute().isCurrentRoute(state);
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
            initialLocation: const TestBaseRoute().fullPath(),
            routes: [
              GoRoute(
                path: const TestBaseRoute().goPath,
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
                  isCurrentRoute = const TestBaseRoute().isCurrentRoute(state);
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
              initialLocation: const TestBaseRoute().fullPath(),
              routes: [
                GoRoute(
                  path: const TestBaseRoute().goPath,
                  builder: (context, state) {
                    return Scaffold(
                      body: ElevatedButton(
                        onPressed: () => const TestChildRoute().go(context),
                        child: const Text('click me'),
                      ),
                    );
                  },
                  routes: [
                    GoRoute(
                      path: const TestChildRoute().goPath,
                      builder: (context, state) {
                        isParent = const TestBaseRoute().isParentRoute(state);
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
              initialLocation: const TestBaseRoute().fullPath(),
              routes: [
                GoRoute(
                  path: const TestBaseRoute().goPath,
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
                    isParent = const TestBaseRoute().isParentRoute(state);
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
                      onPressed: () => const TestBaseRoute().go(context),
                      child: const Text('click me'),
                    ),
                  );
                },
              ),
              GoRoute(
                path: const TestBaseRoute().goPath,
                builder: (context, state) {
                  isActive = const TestBaseRoute().isActive(state);
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
            initialLocation: const TestBaseRoute().fullPath(),
            routes: [
              GoRoute(
                path: const TestBaseRoute().goPath,
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
                  isActive = const TestBaseRoute().isCurrentRoute(state);
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
            initialLocation: const TestBaseRoute().fullPath(),
            routes: [
              GoRoute(
                path: const TestBaseRoute().goPath,
                builder: (context, state) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () => const TestChildRoute().go(context),
                      child: const Text('click me'),
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: const TestChildRoute().goPath,
                    builder: (context, state) {
                      isActive = const TestBaseRoute().isActive(state);
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

  group('StatefulShellRoutes', () {
    final rootKey = GlobalKey<NavigatorState>();
    final shellKey = GlobalKey<NavigatorState>();

    testWidgets('Navigates', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            navigatorKey: rootKey,
            initialLocation: const TestEmptyRoute().fullPath(),
            routes: [
              GoRoute(
                path: const TestEmptyRoute().goPath,
                builder: (context, state) {
                  return Scaffold(
                    body: Column(
                      children: [
                        const Text('Root Route'),
                        ElevatedButton(
                          onPressed: () => const TestBaseRoute().go(context),
                          child: const Text('Click me'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              StatefulShellRoute.indexedStack(
                builder: (context, state, shell) {
                  return shell;
                },
                branches: [
                  StatefulShellBranch(
                    navigatorKey: shellKey,
                    routes: [
                      GoRoute(
                        path: const TestBaseRoute().goPath,
                        builder: (context, state) => const Scaffold(
                          body: Text('Test Route'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      expect(find.text('Root Route'), findsOneWidget);

      await tester.tap(find.text('Click me'));
      await tester.pumpAndSettle();

      expect(find.text('Test Route'), findsOneWidget);
    });
  });

  group('Push and Return Values', () {
    testWidgets('Push allows returned values', (tester) async {
      String? returnValue;

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: const TestBaseRoute().fullPath(),
            routes: [
              GoRoute(
                path: const TestBaseRoute().goPath,
                builder: (context, state) {
                  return Scaffold(
                    body: ElevatedButton(
                      onPressed: () async {
                        returnValue = await const TestChildRoute().push(
                          context,
                        );
                      },
                      child: const Text('Click me first!'),
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: const TestChildRoute().goPath,
                    builder: (context, state) {
                      return Scaffold(
                        body: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(
                            'hello world!',
                          ),
                          child: const Text('Click me second!'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Click me first!'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Click me second!'));
      await tester.pumpAndSettle();

      expect(returnValue, 'hello world!');
    });
  });
}

enum _TestRouteParams {
  param,
}

class _DuplicateTestRoute extends SimpleRoute {
  const _DuplicateTestRoute();

  @override
  String get path => fromSegments([
        'test',
        'test',
        _TestRouteParams.param.template,
        _TestRouteParams.param.template,
      ]);
}
