import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    this.onPath1Load,
    this.onPath2Load,
    this.onDataPathLoad,
  });

  final ValueChanged<BuildContext>? onPath1Load;
  final ValueChanged<BuildContext>? onPath2Load;
  final ValueChanged<BuildContext>? onDataPathLoad;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: GoRouter(
        initialLocation: const Path1().fullPath,
        routes: [
          GoRoute(
            path: const Path1().goPath,
            builder: (context, state) => Scaffold(
              body: Builder(builder: (context) {
                onPath1Load?.call(context);
                return Center(
                  child: TextButton(
                    onPressed: () {
                      const Path2().go(context);
                    },
                    child: const Text('Click me'),
                  ),
                );
              }),
            ),
          ),
          GoRoute(
            path: const Path2().goPath,
            builder: (context, state) => Scaffold(
              body: Center(
                child: Builder(
                  builder: (context) {
                    onPath2Load?.call(context);
                    return TextButton(
                      onPressed: () {
                        const DataPath().go(
                          context,
                          data: const TestRouteData('test-value'),
                        );
                      },
                      child: const Text('Click me'),
                    );
                  },
                ),
              ),
            ),
            routes: [
              GoRoute(
                path: const DataPath().goPath,
                builder: (context, state) => Scaffold(
                  body: Builder(
                    builder: (context) {
                      onDataPathLoad?.call(context);
                      return TextButton(
                        onPressed: () {
                          const Path2().go(context);
                        },
                        child: const Text('Click me'),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
