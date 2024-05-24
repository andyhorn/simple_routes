# Simple Routes

Simple, declarative route and navigation management for [go_router](https://pub.dev/packages/go_router).

## Migrations

See the [Migration Guide](doc/migration_guide.md) for more information on migrating between versions.

## Features

`simple_routes` is a companion package to [GoRouter](https://pub.dev/packages/go_router) that provides a simple, declarative way to define your app's routes.

By using `simple_routes`, you can eliminate magic strings, simplify your route definitions and navigation, and enforce type-safe routing requirements.

## Table of Contents

- [Getting started](#getting-started)
- [Usage](#usage)
  - [TL;DR](#tldr)
  - [Route definitions](#route-definitions)
    - [Basic routing with SimpleRoutes](#basic-routes)
      - [Route path segments](#route-path-segments)
    - [Path parameters and SimpleDataRoutes](#simple-data-routes)
      - [Parameters](#parameters)
      - [Query](#query)
      - [Extra](#extra)
    - [Child routes](#child-routes)
  - [GoRouter Configuration](#gorouter-configuration)
    - [Route redirection with DataRoute](#route-redirection-with-dataroute)
  - [Navigation](#navigation)
- [Advanced usage](#advanced-usage)
  - [Route matching](#route-matching)
    - [Current route](#current-route)
    - [Parent route](#parent-route)
    - [Active route](#active-route)

## Getting started

This package is intended to be used with the [GoRouter](https://pub.dev/packages/go_router) package.

```
dependencies:
  go_router: [latest]
  simple_routes: [latest]
```

## Usage

### TL;DR

Define your routes as children of `SimpleRoute`, then use `.go` or `.push` to navigate.

```dart
class HomeRoute extends SimpleRoute {
  const HomeRoute() : super('home');
}

...

const HomeRoute().go(context);
```

For routes with parameters, extend the `DataRoute` class and define an accompanying data class. Then, use the `.go` or `.push` method to navigate, providing an instance of your data class.

```dart
// Define your route
class UserRoute extends SimpleDataRoute<UserRouteData> {
  const UserRoute() : super('user/:userId');
}

// Define the route data
class UserRouteData extends SimpleRouteData {
  const UserRouteData({
    required this.userId,
  });

  final String userId;

  @override
  Map<String, String> get parameters => {
    'userId': userId,
  };
}

...

// Navigate to the route using the data class
const UserRoute().go(
  context,
  data: UserRouteData(
    userId: '123',
  ),
);
```

### Route definitions

<a id="basic-routes"></a>

#### Basic (simple) routes

Define your routes as classes that extend the `SimpleRoute` base class and supply its path segment to the `super` constructor.

```dart
class ProfileRoute extends SimpleRoute {
  const ProfileRoute() : super('profile');
}
```

No need to add the leading slash for a root-level route; if your route is not a child route (more on this below), the leading slash will automatically be added, when necessary.

<a id="simple-data-routes"></a>

#### Route parameters and SimpleDataRoutes

For routes that require parameters, extend `SimpleDataRoute` instead. This will allow you to define a data class that will be used to pass data to your route.

For example, say you have a route that requires a user ID - `users/123abc`.

First, define a data class that extends `SimpleRouteData` and accepts a `String userId`. Then, override the `parameters` property and provide a map that links the `userId` value to the `'userId'` key.

```dart
class UserRouteData extends SimpleRouteData {
  const UserRouteData({
    required this.userId,
  });

  // Tip: Define a factory or named constructor to easily create an instance of your data class.
  factory UserRouteData.fromState(GoRouterState state) {
    final userId = state.pathParameters['userId']!;

    return UserRouteData(
      userId: userId,
    );
  }

  final String userId;

  @override
  Map<String, String> get parameters => {
    'userId': userId,
  };
}
```

##### Parameters

Any values supplied in the `parameters` map will be mapped to the route template. For example, the `userId` value will be mapped to the `:userId` segment in the route path.

##### Query

Any values supplied in the `query` map will be added to the route as URL-encoded query parameters. For example, a `query` value of `{'search': 'some query'}` will be added to the route as `?search=some%20query`.

##### Extra

The `extra` property is a catch-all for any additional data you may need to pass to your route. This can be any object and will be added to the `GoRouterState` object for the route.

Finally, we can define our route, extending the `SimpleDataRoute` class.

```dart
// Define the route as a SimpleDataRoute, typed for your data class.
class UserRoute extends SimpleDataRoute<UserRouteData> {
  // Pass the path segment to the super constructor.
  const UserRoute() : super('users/:userId');
}
```

Because this route is a "data route," we must provide it with an instance of its route data class when navigating. More on this in the [Navigation](#navigation) section.

### Child routes

To define a route that is a child of another route, implement the `ChildRoute` interface.

```dart
class UserDetailsRoute extends SimpleDataRoute<UserRouteData> implements ChildRoute<UserRoute> {
  const UserDetailsRoute() : super('details');

  // Override the parent property and provide an instance of the parent route.
  @override
  final UserRoute parent = const UserRoute();
}
```

In the example above, the generated route will be `/user/:userId/details`.

**Note**: Routes that are children of a `SimpleDataRoute` must also be a `SimpleDataRoute` themselves, even if they don't require any data. In cases like these, you can re-use the parent's data class.

However, if they require their own data, the data class must provide its data **and** the data of its parent(s).

### GoRouter configuration

Configuring `GoRouter` is easy. When defining a `GoRoute`, create an instance of your class and pass the `path` property to the `path` argument.

```dart
GoRoute(
  path: const HomeRoute().path,
),
```

#### Example

Below is a full example of a GoRouter configuration, including a route protected by a redirect and extracting data from the `GoRouterState` in a builder callback.

```dart
GoRouter(
  // Note that the initialLocation should use the "fullPath" property
  // to include any parent routes, if applicable.
  initialLocation: const HomeRoute().fullPath(),
  routes: [
    GoRoute(
      path: const HomeRoute().path,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: const UserRoute().path,
      redirect: (context, state) {
        // Use the extension methods to validate that any and all
        // required values are present.

        if (state.pathParameters['userId'] == null) {
          // If the data is not present, redirect to another route
          // using the `fullPath` method.
          return const HomeRoute().fullPath();

          // Note: If you're redirecting to a data route, the `fullPath`
          // method will require an instance of your route data object.
          // For example:
          // return const UserRoute().fullPath(UserRouteData(...));
          //
          // See the "DataRoute generation" section below.
        }

        // If all of the data is present, return null to allow the
        // route to be built.
        return null;
      },
      builder: (context, state) {
        final routeData = UserRouteData.fromState(state);

        return UserScreen(
          userId: routeData.userId,
        );
      },
      routes: [
        // Define the child route, using the same data class as
        // the parent route.
        GoRoute(
          path: const UserDetailsRoute().path,
          builder: (context, state) {
            final routeData = UserRouteData.fromState(state);

            return UserDetailsScreen(
              userId: routeData.userId,
            );
          },
        ),
      ],
    ),
  ],
);
```

#### DataRoute generation

If you need the full path of a DataRoute, such as for generating a link or redirect, the `fullPath` method will require an instance of your route's data class.

For example, given the following route:

```dart
class MyRoute extends DataRoute<MyRouteData> {
  const MyRoute() : super('users/:userId');
}
```

The `fullPath` method will require an instance of the `MyRouteData` class.

```dart
redirect: (context, state) {
  return const MyRoute().fullPath(MyRouteData(userId: '123'));
}
```

This will return the full, populated path: `/user/123`.

### Navigation

Once your routes are defined and your router is configured, you can navigate between your routes using the `go` and `push` methods.

#### Go

Just like with GoRouter, the `go` method will navigate to a route, replacing the current route.

```dart
onPressed: () => const HomeRoute().go(context),
```

For your routes that require parameters, the `go` method will enforce that you pass an instance of your data class.

```dart
onPressed: () => const UserRoute().go(
  context,
  data: UserRouteData(
    userId: '123',
  ),
),
```

#### Push

The `push` method will navigate to a route, pushing it onto the navigation stack. The method arguments are identical to their `go` counterparts, but the `push` method allows for an optional value to be awaited and returned.

```dart
onPressed: () async {
  final result = await const HomeRoute().push(context);
  debugPrint('The result is: $result');
},
```

## Advanced usage

### Route matching

#### Current route

The `isCurrentRoute` method will determine if your app is at a particular route.

For example, given the following routes:

```dart
class BaseRoute extends SimpleRoute {
  const BaseRoute() : super('base');
}

class SubRoute extends SimpleRoute implements ChildRoute<BaseRoute> {
  const SubRoute() : super('sub');

  @override
  BaseRoute get parent => const BaseRoute();
}
```

and your app is at the location of `/base/sub`:

```dart
// current location: '/base/sub'
if (const SubRoute().isCurrentRoute(state)) {
  debugPrint('We are at SubRoute!');
}
```

Your app will print `We are at SubRoute!`.

#### Parent route

Similar to `isCurrentRoute`, you can use the `isParentRoute` method to check whether a route is a **parent** of the current location.

For example, if your app is at the location of `/base/sub`:

```dart
// current location: '/base/sub'
if (const BaseRoute().isParentRoute(state)) {
  debugPrint('We are at a child of BaseRoute!');
}
```

Your app will print `We are at a child of BaseRoute!`.

**Note:** this method will return `false` if the current route is an exact match for the route in question (i.e. `isCurrentRoute`).

For example, if we are at the `/base/sub` location and use `isParentRoute`, it will return `false`:

```dart
// current location: '/base/sub'
if (const SubRoute().isParentRoute(state)) {
  debugPrint('Success!'); // will not be executed
}
```

In this case, the print statement will _not_ be executed.

#### Active route

If you need to determine if a route is active, but not necessarily whether it is the _current_ route or a _parent_, you can use the `isActive` method.

This method will check that the route exists in the current location, but does not discern between being an exact match or a parent match.

For example, if your app is at the location of `/base/sub`:

```dart
// current location: '/base/sub'
if (const BaseRoute().isActive(state)) {
  debugPrint('BaseRoute is active!');
}
```

Your app will print `BaseRoute is active!`.

If your app is at the location of `/base`:

```dart
// current location: '/base'
if (const BaseRoute().isActive(state)) {
  debugPrint('BaseRoute is active!');
}
```

Your app will still print `BaseRoute is active!`.
