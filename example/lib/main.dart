// Once you have defined your routes (see routes.dart), you can use them
// in your GoRouter configuration.

import 'package:example/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Define your root-level routes and sub-routes in the same way.
final router = GoRouter(
  routes: [
    GoRoute(
      // Use the route class' [path] property to define this segment of the
      // route path.
      path: const RootRoute().path,
      builder: (context, state) => const RootPage(),
      routes: [
        GoRoute(
          path: const DashboardRoute().path,
          builder: (context, state) => const DashboardPage(),
        ),
      ],
    ),
    GoRoute(
      path: const ProfileRoute().path,
      redirect: (context, state) {
        const factory = ProfileRouteDataFactory();

        // Use your factory class to validate the route data.
        if (factory.extractParam(state, RouteParams.userId) == null) {
          // When redirecting, use the `fullPath` property.
          // If your route has parameters, you should use the
          // `buildFullPath` method instead.
          return const RootRoute().fullPath;
        }

        return null;
      },
      builder: (context, state) {
        // Use a factory class to extract your route data.
        // This is especially useful if you have multiple routes that use the
        // same data class or if your route has multiple values.
        const factory = ProfileRouteDataFactory();
        final profileRouteData = factory.fromState(state);

        return ProfilePage(userId: profileRouteData.userId);
      },
      routes: [
        GoRoute(
          path: const ProfileEditRoute().path,
          builder: (context, state) => ProfileEditPage(
            query: const ProfileEditRouteDataFactory().fromState(state).query,
          ),
        ),
      ],
    ),
  ],
);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: router,
      theme: ThemeData.dark(),
      builder: (context, child) => Scaffold(body: child),
    );
  }
}

// Use the route class' [go] method to initiate navigation, supplying the route
// data when it is required.
class NavButtons extends StatelessWidget {
  const NavButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => const RootRoute().go(context),
          child: const Text('Go to root'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => const DashboardRoute().go(context),
          child: const Text('Go to dashboard'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => const ProfileRoute().go(
            context,
            data: const ProfileRouteData(userId: '123'),
          ),
          child: const Text('Go to profile'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => const ProfileEditRoute().go(
            context,
            data: const ProfileEditRouteData(userId: '123', query: 'myQuery'),
          ),
          child: const Text('Go to profile edit'),
        ),
      ],
    );
  }
}

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Root'),
        NavButtons(),
      ],
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Dashboard'),
        NavButtons(),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Profile for $userId'),
        const NavButtons(),
      ],
    );
  }
}

class ProfileEditPage extends StatelessWidget {
  const ProfileEditPage({
    super.key,
    required this.query,
  });

  final String? query;

  @override
  Widget build(BuildContext context) {
    final profileRouteData = const ProfileRouteDataFactory().fromState(
      GoRouterState.of(context),
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Profile edit page for ${profileRouteData.userId}'),
        Text('Query: ${query ?? 'none'}'),
        const NavButtons(),
      ],
    );
  }
}
