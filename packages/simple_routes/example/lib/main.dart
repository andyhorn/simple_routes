// Once you have defined your routes (see routes.dart), you can use them
// in your GoRouter configuration.

import 'package:example/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Define your root-level routes and sub-routes in the same way.
final router = GoRouter(
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      // Use the [path] property to define the route's path.
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
        if (state.pathParameters['userId'] == null) {
          // When redirecting, use the `fullPath` method.
          return const RootRoute().fullPath();
        }

        return null;
      },
      builder: (context, state) {
        final profileData = state.profileData;

        return ProfilePage(userId: profileData.id);
      },
      routes: [
        GoRoute(
          path: const ProfileEditRoute().path,
          builder: (context, state) => const ProfileEditPage(),
        ),
        GoRoute(
          path: const AdditionalDataRoute().path,
          builder: (context, state) => AdditionalRouteDataPage(
            queryValue: state.additionalDataData.queryValue,
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
            data: const ProfileData(id: '123'),
          ),
          child: const Text('Go to profile'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => const ProfileEditRoute().go(
            context,
            data: const ProfileEditData(
              id: '123',
            ),
          ),
          child: const Text('Go to profile edit'),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => const AdditionalDataRoute().go(
            context,
            data: const AdditionalDataData(
              id: '123',
              queryValue: 'hello world!',
            ),
          ),
          child: const Text('Go to Additional Data route'),
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
  });

  @override
  Widget build(BuildContext context) {
    final profileData = GoRouterState.of(context).profileEditData;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Profile edit page for ${profileData.id}'),
        const NavButtons(),
      ],
    );
  }
}

class AdditionalRouteDataPage extends StatelessWidget {
  const AdditionalRouteDataPage({
    super.key,
    this.queryValue,
  });

  final String? queryValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Additional Data Route'),
        Text('Query value: $queryValue'),
        const NavButtons(),
      ],
    );
  }
}
