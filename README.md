# Simple Routes

Simple, type-safe route and navigation management for [go_router](https://pub.dev/packages/go_router).

## Stable release

We have reached a stable release of Simple Routes with v1.0.0-beta.3! 🎉

This release includes several breaking changes from the 0.x.x versions. <br/> Please see the [Migration Guide](doc/migration_guide.md) for more info.

## Features

Simple Routes is a companion package to [GoRouter](https://pub.dev/packages/go_router) that provides a simple, type-safe way to define your app's routes and navigate between them.

- Eliminate "magic strings" and the bugs that come with them
- Simplify route definitions and navigation invocation
- Enforce type-safe routing requirements
- Inject and extract path parameters, query parameters, and "extra" route data

## Table of Contents
  * [Getting started](#getting-started)
  * [Usage](#usage)
    * [Route definitions](#route-definitions)
      * [Basic routing with SimpleRoutes](#basic-routes)
      * [Path parameters and DataRoutes](#data-routes)
      * [Child routes](#child-routes)
    * [GoRouter Configuration](#gorouter-configuration)
      * [Route redirection with DataRoute](#route-redirection-with-dataroute)
    * [Navigation](#navigation)
  * [Advanced usage](#advanced-usage)
    * [Route matching](#route-matching)
      * [Current route](#current-route)
      * [Parent route](#parent-route)

## Getting started

This package is intended to be used with the [GoRouter](https://pub.dev/packages/go_router) package.

```
dependencies:
  go_router: ^12.0.0
  simple_routes: ^1.0.0-beta.3
```

## Usage

### Route definitions

<a id="basic-routes"></a>

#### Basic (simple) routes

Define your routes as classes that extend the `SimpleRoute` base class and override the `path` property with the route's path segment.

```dart
class ProfileRoute extends SimpleRoute {
  const ProfileRoute();

  @override
  String get path => 'profile';
}
```

No need to add the leading slash for a root-level route; if your route is not a child route (more on this below), the leading slash will automatically be added when necessary.

<a id="data-routes"></a>

#### Route parameters and DataRoutes

For routes that require parameters, extend `DataRoute` instead. This will allow you to define a data class that will be used to pass data to your route.

For example, let's create a class that we want passed between routes using GoRouter's "extra" property.

```dart
// Some class or object that you want to pass with your route.
class MyExtraData {
  const MyExtraData(this.someValue);
  final String someValue;
}
```

Next, let's define our route data class.

```dart
// Define any route parameters and query parameters as enum values.
// These will be used to match path parameters in the template and 
// add query parameters to the URL.
enum RouteParams {
  userId,
  query,
}

// Define a data class that extends SimpleRouteData
//
// This class should carry any data that your route requires, 
// including path parameters, query parameters, and
// "extra" data that you want to pass to your route.
class UserRouteData extends SimpleRouteData {
  const UserRouteData({
    required this.userId,
    required this.extraData,
    this.queryValue,
  });

  // For example, a "user ID" parameter for the path
  // e.g. /user/:userId
  final String userId;

  // Or a query parameter
  final String? queryValue;

  // Or any other data that you want discretely passed to your route.
  final MyExtraData extraData;

  // Override the `parameters` property with a map of your
  // route's path parameters (identified by the Enum). 
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

  // Use a factory constructor to simplify extracting data from 
  // the GoRouterState in a redirect or builder callback.
  factory UserRouteData.fromState(GoRouterState state) {

    // Use the extension methods to simplify extracting 
    // data from the GoRouterState.
    final userId = state.getParam(RouteParams.userId)!;
    final queryValue = state.getQuery(RouteParams.query);
    final extraData = state.getExtra<MyExtraData>()!;

    return UserRouteData(
      userId: userId,
      queryValue: queryValue,
      extraData: extraData,
    );
  }
}

// Define the route as a DataRoute, typed for your data class.
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

### Child routes

To define a route that is a child of another route, implement the `ChildRoute` interface, providing the parent route type and overriding the `parent` property.

```dart
class UserDetailsRoute extends DataRoute<UserRouteData> implements ChildRoute<UserRoute> {
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

**Note**: Routes that are children of a `DataRoute` must also be a `DataRoute` themselves, even if they don't require any data. In cases like these, you can re-use the parent's data class and factory constructor.

However, if they require their own data, the data class must provide it **and** the data necessary for the parent(s).

### GoRouter configuration

Configuring `GoRouter` is easy. When defining a `GoRoute`, create an instance of your class and pass the `goPath` property to the `path` parameter.

```dart
GoRoute(
  path: const HomeRoute().goPath,
),
```

Below is a full example of a GoRouter configuration, including a route protected by a redirect and extracting data from the `GoRouterState` in a builder callback.

```dart
GoRouter(
  // Note that the initialLocation should use the "fullPath" property
  // to include any parent routes, if applicable.
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
          // using the `fullPath` property - this is important, as 
          // the `path` and `goPath` properties only include the 
          // route's segment(s), but not the fully-qualified path.
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
      routes: [
        // Define the child route, using the same data class as
        // the parent route.
        GoRoute(
          path: const UserDetailsRoute().goPath,
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

If you need to redirect to a DataRoute, or otherwise need the complete path for a DataRoute, you must use the `generate` method to generate the full path. The `fullPath` property will include the template values and will not route properly.

For example, given the following route:

```dart
class MyRoute extends DataRoute<MyRouteData> {
  const MyRoute();

  @override
  String get path => ['user', RouteParams.userId.prefixed].toPath();
}

...

// This will not work!
// The return value will be `/user/:userId`
redirect: (context, state) {
  return const MyRoute().fullPath;
}

...

// Instead, use `generate`, like so:
redirect: (context, state) {
  return const MyRoute().generate(MyRouteData(userId: '123'));
}
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

**Note**: The `push` method signatures are identical to their corresponding SimpleRoute/DataRoute `go` methods.

## Advanced usage

### Route matching

#### Current route

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

#### Parent route

Similar to `isCurrentRoute`, you can use the `isParentRoute` method to check whether a route is a **parent** of the current location.

For example, if your app is at the location of `/base/sub`:

```dart
// current location: '/base/sub'
if (const BaseRoute().isParentRoute(context)) {
  debugPrint('We are at a child of BaseRoute!');
}
```

Your app will print `We are at a child of BaseRoute!`.

**Note:** this method will return `false` if the current route is an exact match for the route in question (i.e. `isCurrentRoute`).

For example, if we are at the `/base/sub` location and use `isParentRoute`, it will return `false`:

```dart
// current location: '/base/sub'
if (const SubRoute().isParentRoute(context)) {
  debugPrint('We are at a child of SubRoute!');
}
```

In this case, the print statement will _not_ be executed.
