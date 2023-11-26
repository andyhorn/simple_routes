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
    * [Route data factory](#route-data-factory)
    * [Configuration](#configuration)
    * [Navigation](#navigation)
  * [Advanced usage](#advanced)
    * [Child routes](#child-routes)
      * [Definition](#child-route-definition)
      * [Configuration](#child-route-configuration)
      * [Navigation](#child-route-navigation)
    * [Query parameters](#query-parameters)
    * ["Extra" route data](#extra-route-data)
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

#### Path parameters and DataRoutes

For routes that require parameters, extend the `DataRoute` class.

```dart
// Define your route parameters as an enum
enum RouteParams {
  userId,
}

// Define a data class that extends SimpleRouteData
//
// This class should carry all of the data that your routing
// requires, including path parameters, query parameters, and
// "extra" data that you want to pass to your route builders.
class UserRouteData extends SimpleRouteData {
  const UserRouteData(this.userId);

  final String userId;

  // Override the `inject` method to inject the route parameters
  // into the path.
  //
  // Use the `setParam` method to replace the parameter in the 
  // path template with the value from your data class.
  @override
  String inject(String path) {
    return path.setParam(RouteParams.userId, userId);
  }
}

// Define the route as a DataRoute, typed with your data class
class UserRoute extends DataRoute<UserRouteData> {
  const UserRoute();

  // Define the route path using the same enum value.
  // Use the `prefixed` getter to automatically prefix the
  // enum value with a colon (how go_router defines template values).
  //
  // To define a path with multiple segments, create a 
  // `List<String>` and use the `toPath` extension method.
  @override
  String get path => ['user', RouteParams.userId.prefixed].toPath();
}
```

### Route data factory

While creating a factory for your route data is optional, it can be very 
helpful for extracting the data from the `GoRouterState` and passing it to your route builders.

Define a factory class that extends the `SimpleRouteDataFactory` class, typed for your data class, to help extract the route data from the `GoRouterState`.

```dart
class UserRouteDataFactory extends SimpleRouteDataFactory<UserRouteData> {
  const UserRouteDataFactory();

  // Implement the `containsData` method to validate that all
  // necessary parameters are present in the `GoRouterState`.
  //
  // This method is useful in a redirect scenario, allowing you 
  // to easily validate the data before redirecting to a new route
  // or allowing the route to be built.
  @override
  bool containsData(GoRouterState state) {
    // Use the `containsParam` method to check if a particular key,
    // identified by the enum value, exists in the GoRouterState's 
    // "pathParameters" map.
    return containsParam(state, RouteParams.userId);
  }

  // Implement the `fromState` method to extract the data from
  // the GoRouterState and return an instance of your data class.
  @override
  UserRouteData fromState(GoRouterState state) {
    return UserRouteData(
      // Use the `extractParam` method to extract a parameter,
      // identified by the enum value, from the GoRouterState's 
      // "pathParameters" map.
      userId: extractParam(state, RouteParams.userId),
    );
  }
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
        // Use the `containsData` method to validate that all
        // necessary values are present in the GoRouterState.
        if (!const UserRouteDataFactory().containsData(state)) {
          // If the data is not present, redirect to another route 
          // using the `fullPath` property.
          return const HomeRoute().fullPath;
        }

        // If the data is present, return null to allow the route
        // to be built.
        return null;
      },
      builder: (context, state) => UserScreen(
        // Use your factory to extract the data from the state
        userId: const UserRouteDataFactory().fromState(state).userId,
      ),
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
  data: UserRouteData(userId: '123'),
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
        // We can easily re-use the data class and factory.
        userId: const UserRouteDataFactory().fromState(state).userId,
      ),
    ),
  ],
),
```

**Note**: Routes that are children of a `DataRoute` must also be a `DataRoute`, even if they don't require any data, themselves. In cases like these, you can re-use the parent's data class and factory.

However, if they require their own data, the data class must also provide the data necessary for the parent route(s).

<a id="child-route-navigation"></a>

#### Navigation

Navigate to your nested routes just like you would any other route.

```dart
onPressed: () => const UserDetailsRoute.go(
  context,
  data: UserRouteData(userId: '123'),
),
```

### Query parameters

Along with injecting path parameters, your data routes can also inject query parameters into the route path using `appendQuery` - this function will append URL encoded query parameters to the end of the path. Plus, it handles empty and null Strings, so you don't have to.

```dart
class LoginRouteData extends SimpleRouteData {
  const LoginRouteData({
    this.redirect,
  });

  final String? redirect;

  @override
  String inject(String path) {
    return path.appendQuery({
      'redirect': redirect,
    });
  }
}

class LoginRoute extends DataRoute<LoginRouteData> {
  const LoginRoute();

  @override
  String get path => 'login';
}
```

Extract your query parameters using the `containsQuery` and `extractQuery` methods - available on all `SimpleRouteDataFactory` classes.

```dart
class LoginRouteDataFactory extends SimpleRouteDataFactory<LoginRouteData> {
  const LoginRouteDataFactory();

  @override
  bool containsData(GoRouterState state) {
    // returning true since the query parameter is optional
    return true;
  }

  @override
  LoginRouteData fromState(GoRouterState state) {
    return LoginRouteData(
      redirect: containsQuery(state, 'redirect') 
        ? extractQuery(state, 'redirect') 
        : null,
    );
  }
}
```

Then, in your route configuration:

```dart
GoRoute(
  builder: (context, state) => LoginScreen(
    redirect: const LoginRouteDataFactory().fromState(state).redirect,
  ),
),
```

### "Extra" route data

In addition to path parameters and query parameters, you can also inject data into the `extra` property of the `GoRouterState` by overriding the `extra` property of your route data class.

```dart
class MyRouteData extends SimpleRouteData<MyDataClass> {
  const MyRouteData({
    this.extraData,
  });

  final MyDataClass extraData;

  @override
  MyDataClass get extra => extraData;
}
```

Then, extend your factory class with the `ExtraDataMixin` to gain access to the `containsExtra` and `extractExtra` methods.

```dart
class MyRouteDataFactory extends SimpleRouteDataFactory<MyRouteData> 
  with ExtraDataMixin<MyDataClass> {
  const MyRouteDataFactory();

  @override
  bool containsData(GoRouterState state) {
    // Checks for the existence of the extra data in the state,
    // using the type provided to the mixin (MyDataClass).
    return containsExtra(state);
  }

  @override
  MyRouteData fromState(GoRouterState state) {
    return MyRouteData(
      // Extracts the extra data from the state, using the type
      // provided to the mixin (MyDataClass).
      extraData: extractExtra(state),
    );
  }
}
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
