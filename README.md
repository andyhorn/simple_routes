# Simple Routes

Simple, type-safe route and navigation management for [go_router](https://pub.dev/packages/go_router).

## Features

Simple Routes is a companion package to [GoRouter](https://pub.dev/packages/go_router) that provides a simple, type-safe way to define your app's routes and navigate between them.

- Eliminate "magic strings" and the bugs that come with them
- Enforce type-safe routing requirements
- Inject and extract path parameters, query parameters, and "extra" route data

## Table of Contents
  * [Getting Started](#getting-started)
  * [Usage](#usage)
    * [Route definitions](#route-definitions)
      * [Basic routing with SimpleRoutes](#basic-routes)
      * [Path parameters and DataRoutes](#data-routes)
    * [Configuration](#configuration)
    * [Navigation](#navigation)
  * [Advanced usage](#advanced)
    * [Child routes](#child-routes)
      * [Definition](#child-route-definition)
      * [Configuration](#child-route-configuration)
      * [Navigation](#child-route-navigation)
    * [Route matching](#route-matching)
      * [Current Route](#current-route)
      * [Ancestor Route](#ancestor-route)

## Getting started

This package is intended to be used with the [GoRouter](https://pub.dev/packages/go_router) package.

```
dependencies:
  go_router: ^12.0.0
  simple_routes: ^1.0.0
```

## Usage

### Route definitions

<a id="basic-routes"></a>

#### Basic (simple) routes

Define your routes as simple classes that extend the `SimpleRoute` base class.

```dart
class ProfileRoute extends SimpleRoute {
  const ProfileRoute();

  @override
  String get path => 'profile';
}
```

Override the `path` property with the route's path segment.

If your route is not a child of another route (more on this below), the path will automatically be prefixed with a leading slash, when appropriate.

<a id="data-routes"></a>

#### Route parameters and DataRoutes

For routes that require parameters, extend the `DataRoute` class.

```dart
// Some class or object that you want to pass with your route.
class MyExtraData {
  const MyExtraData(this.someValue);
  final String someValue;
}

// Define your route and/or query parameters as an enum
enum RouteParams {
  userId,
  query,
}

// Define a data class that extends SimpleRouteData
//
// This class should carry all of the data that your routing
// requires, including path parameters, query parameters, and
// "extra" data that you want to pass to your route.
class UserRouteData extends SimpleRouteData {
  const UserRouteData({
    required this.userId,
    required this.extraData,
    this.queryValue,
  });

  // Use a factory constructor to simplify extracting data from 
  // the GoRouterState.
  factory UserRouteData.fromState(GoRouterState state) {
    // Use the extension methods to simplify extracting data from 
    // the GoRouterState by providing the enum value or data type.
    //
    // It is recommended to use these same extensions to validate the 
    // presence of the required data in a `redirect` - more on this in 
    // the GoRouter configuration section below.
    final userId = state.getParam(RouteParams.userId)!;
    final queryValue = state.getQuery(RouteParams.query);
    final extraData = state.getExtra<MyExtraData>()!;

    return UserRouteData(
      userId: userId,
      queryValue: queryValue,
      extraData: extraData,
    );
  }

  // For example, a "user ID" parameter for the path
  // i.e. /user/:userId
  final String userId;

  // Or a query parameter
  final String? queryValue;

  // Or any other data that you want discretely passed to your route.
  final MyExtraData extraData;

  // Override the `parameters` property with a map of your
  // route's parameters. These will be automatically injected
  // into the route path.
  @override
  Map<Enum, String> get parameters => {
    RouteParams.userId: userId,
  };

  // Override the `query` property with a map of your route's 
  // query parameters. These will be automatically URL encoded
  // and appended to the end of your path.
  //
  // The query map allows null values, so you don't have to worry 
  // about whether or not to include a query parameter.
  @override
  Map<Enum, String?> get query => {
    RouteParams.query: queryValue,
  };

  // Override the `extra` property with any extra data that you 
  // want passed along with your route.
  @override
  MyExtraData get extra => extraData;
}

// Define the route as a DataRoute, typed with your data class
class UserRoute extends DataRoute<UserRouteData> {
  const UserRoute();

  // Define the route path using the appropriate enum value.
  // Use the `prefixed` property to automatically prefix the
  // enum value name with a colon (e.g. ":userId").
  //
  // To define a path with multiple segments, create an 
  // `Iterable<String>` and use the `toPath` extension method.
  @override
  String get path => ['user', RouteParams.userId.prefixed].toPath();
}
```

### GoRouter Configuration

Configure your `GoRouter` using your routes and factories.

```dart
GoRouter(
  initialLocation: const HomeRoute().fullPath,
  routes: [
    GoRoute(
      path: const HomeRoute().goPath,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: const UserRoute().goPath,
      redirect: (context, state) {
        // Use the extension methods to validate that any and all 
        // required values are present.

        if (state.getParam(RouteParams.userId) == null) {
          // If the data is not present, redirect to another route 
          // using the `fullPath` property.
          return const HomeRoute().fullPath;
        }

        // If all of the data is present, return null to allow the 
        // route to be built.
        return null;
      },
      builder: (context, state) {
        final routeData = UserRouteData.fromState(state);

        return UserScreen(
          userId: routeData.userId,
          query: routeData.queryValue,
          extra: routeData.extraData,
        );
      },
    ),
  ],
);
```

### Navigation

Once your routes are defined and your router is configured, you can navigate between your routes using the `go` and `push` methods.

```dart
onPressed: () => const HomeRoute().go(context),
```

For your routes that require parameters, the `go` method will enforce that you pass an instance of your data class.

```dart
onPressed: () => const UserRoute().go(
  context,
  data: UserRouteData(
    userId: '123',
    queryValue: 'some query value',
    extraData: MyExtraData('some extra data'),
  ),
),
```

**Note**: The `push` method signatures are identical to their corresponding `go` methods.

## Advanced usage

### Child routes

<a id="child-route-definition" ></a>

#### Definition

To define routes that are sub-routes or children of another route, implement the `ChildRoute` interface.

```dart
class UserDetailsRoute extends DataRoute<UserRouteData> 
  implements ChildRoute<UserRoute> {
  const UserDetailsRoute();

  // Define the route path segment. No need to worry about 
  // leading slashes - they will be added automatically.
  @override
  String get path => 'details';

  // Define the parent route. This will be used to 
  // construct the full path for this route.
  @override
  UserRoute get parent => const UserRoute();
}
```

<a id="child-route-configuration"></a>

#### Configuration

Configure your nested routes just like you would any other route.

```dart
GoRoute(
  path: const UserRoute().goPath,
  routes: [
    GoRoute(
      path: const UserDetailsRoute().goPath,
      builder: (context, state) => UserDetailsScreen(
        // Notice how this child route requires the same data as its parent.
        // We can easily re-use the data class and factory constructor.
        userId: UserRouteData.fromState(state).userId,
      ),
    ),
  ],
),
```

**Note**: Routes that are children of a `DataRoute` must also be a `DataRoute`, even if they don't require any data themselves. In cases like these, you can re-use the parent's data class and factory constructor.

However, if they require their own data, the data class must also provide the data necessary for the parent route(s).

<a id="child-route-navigation"></a>

#### Navigation

Navigate to your nested routes just like you would any other route.

```dart
onPressed: () => const UserDetailsRoute.go(
  context,
  data: UserRouteData(
    userId: '123',
    extraData: MyExtraData('more extra data'),
  ),
),
```

### Route matching

#### Current Route

The `isCurrentRoute` method will determine if your app is at a particular route.

For example, given the following routes:

```dart
class BaseRoute extends SimpleRoute {
  const BaseRoute();

  @override
  String get path => 'base';
}

class SubRoute extends SimpleRoute implements ChildRoute<BaseRoute> {
  const SubRoute();

  @override
  String get path => 'sub';

  @override
  BaseRoute get parent => const BaseRoute();
}
```

and your app is at the location of `/base/sub`:

```dart
// current location: '/base/sub'
if (const SubRoute().isCurrentRoute(context)) {
  debugPrint('We are at SubRoute!');
}
```

Your app will print `We are at SubRoute!`.

#### Ancestor Route

Similar to `isCurrentRoute`, you can use the `isAncestorRoute` method to check whether a route is an **ancestor** of the current location.

For example, if your app is at the location of `/base/sub`:

```dart
if (const BaseRoute().isAncestorRoute(context) /* true */) {
  debugPrint('We are at a descendant of BaseRoute!');
}
```

Your app will print `We are at a descendant of BaseRoute!`.

**Note:** this method will return `false` if the current route is an exact match for the route in question (i.e. `isCurrentRoute`).

For example, if we are at the `/base/sub` location and use `isAncestor`, it will return `false`:

```dart
// current location: '/base/sub'
if (const SubRoute().isAncestor(context) /* false */) {
  debugPrint('We are at a descendant of SubRoute!');
}
```

In this case, the print statement will _not_ be executed.
