# Simple Routes

Simple, class-based route management for [go_router](https://pub.dev/packages/go_router).

## Features

This package is intended to provide useful classes and a helpful structure for defining, managing, and using your app's routes.

**Breaking Changes**
- Version 0.0.4 changed the signature of the `go` method to require any data or query parameters be passed as a named argument.

Instead of writing:

```dart
const MyRoute().go(
  context, 
  const MyRouteData('some-value'), 
  {'key': 'value'},
);
```

You will now need to write it as:

```dart
const MyRoute().go(
  context, 
  data: const MyRouteData('some-value'), 
  query: {'key': 'value'},
);
```

## Getting started

This package is intended to be used with the [GoRouter](https://pub.dev/packages/go_router) package.

Install both of these packages to your app's dependencies.

```yaml
dependencies:
  go_router: <version>
  simple_route: <version>
```

## Usage

### Defining simple routes 

This first section will describe how to use the `SimpleRoute` class and `ChildRoute` interface to define routes that _do not_ require any dynamic variables, i.e. "static" routes like `/home` or `/settings/notifications`.

For routing that requires path parameters, see the **Defining dynamic routes** section below.

Static routes should extend the `SimpleRoute` base class, such as the example `HomeRoute` below.

```dart
class HomeRoute extends SimpleRoute {
  const HomeRoute();

  @override
  String get path => '/home';
}
```

When extending the `SimpleRoute` base class, you must override the `path` property.

**Note:** Root level routes should have a path that is prefixed with a forward slash (`/`).

 This value is used to define the `path` of a `GoRoute`. 

```dart
  GoRoute(
    path: const HomeRoute().path,
    pageBuilder: (context, state) => const HomePage(),
  ),
```

By extending `SimpleRoute`, your route will inherit a `go` method that makes navigation, well, simple.


```dart
ElevatedButton(
  onPressed: () => const HomeRoute().go(context),
  child: const Text('Go to Home'),
),
```

#### Nested (child) routes

Any nested (AKA "Child") routes should implement the `ChildRoute` interface.

```dart
class SettingsRoute extends SimpleRoute implements ChildRoute<HomeRoute> {
  const SettingsRoute();

  @override
  String get path => 'settings';

  @override
  HomeRoute get parent => const HomeRoute();
}
```

**Note:** Child routes should have a path that is _not_ prefixed with a slash.

Along with providing the `path` for this route, when implementing the `ChildRoute` interface, you must also implement the `parent` property. 

The `go` method will automatically build the full path for your route, based on its `path` and the `path`s of its parents.

```dart
ElevatedButton(
  onPressed: () => const SettingsRoute().go(context),
  child: const Text('Go to Settings'),
),
```

Simple! Now let's look at how to handle routes that require dynamic data.

### Defining dynamic routes

Before we define our dynamic route, we need to do a little bit of setup:

#### Parameters

The first rule is that all parameters must be defined as an enum.

```dart
enum RouteParams {
  userId,
}
```

This helps eliminate "magic strings" and, therefore, reduce the opportunity for errors and hard-to-track-down bugs.

#### Data classes

Secondly, we need to define a class that represents the data needed by our new route. This new class should extend the `SimpleRouteData` class. 

```dart
class UserRouteData extends SimpleRouteData {
  const UserRouteData({required this.userId});

  final String userId;

  @override
  void inject(String path) {
    return path.setParam(
      RouteParams.userId,
      userId,
    );
  }
}
```

By extending the `SimpleRouteData` base class, we must implement the `inject` method. This is how the templated parameters in the path are replaced with the actual values. Note the `String.setParam` extension - it is recommended to utilize this function anytime you inject a value.

This extension takes an enum value as its first argument and a String value as its second argument.

```dart
String setParam<E extends Enum>(E enum, String value);
```

#### Dynamic routes

Finally, your route class should extend the `DataRoute` class, typed for the data class we just created.

```dart
class UserRoute extends DataRoute<UserRouteData> {
  const UserRoute();

  @override
  String get path => join(['/user', withPrefix(RouteParams.userId)]);
}
```

**Note:** Just like the `SimpleRoute`s above, any root-level paths should be prefixed with a forward slash; any child routes should **not** be prefixed.

##### Utility functions

We used a couple utility functions in this example, so let's take a moment to break it all down.

First, we can see that the route class itself extends `DataRoute` with the appropriate `SimpleRouteData` as the generic type.

Next, we create the `path` value in a more interesting way. We use the `join` utility method to build a path from the path segments - This is the recommend way of defining paths with multiple segments (again, to reduce the chance of error). 

Inside the `join` we use the `withPrefix` extension method to convert the enum value to the path template String. This is the recommended way of converting your enum values to their path template values. 

In this example, the `path` would become `/user/:userId`.

##### Using dynamic routes

Now that we have our route defined, let's see how to use it!

```dart
ElevatedButton(
  onPressed: () => const UserRoute().go(
    context,
    data: UserRouteData(userId: '123'),
  ),
  child: const Text('Go to User'),
),
```

As you can see, the `go` method now requires an instance of your route's data class. When invoked, the data will be injected into the full path (via your `inject` method).

#### Children of DataRoutes

One caveat with this structure is that any children of a `DataRoute` must also be a `DataRoute` to supply the data to its parents.

For example, if we have a route - `/users/:userId/settings/mfa` - the `settings` route _and_ the `mfa` route will both need the `userId` value to generate their full route; therefore, they will need to accept a data object containing that value.

For cases like this example, where the same piece of data is needed, these child classes can simply re-use the parent's data class.

```dart
class UserSettingsRoute extends DataRoute<UserRouteData> implements ChildRoute<UserRoute> {
  const UserSettingsRoute();

  @override
  String get path => 'settings';

  @override
  UserRoute get parent => const UserRoute();
}

class MfaSettingsRoute extends DataRoute<UserRouteData> implements ChildRoute<UserSettingsRoute> {
  const MfaSettingsRoute();

  @override
  String get path => 'mfa';

  @override
  UserSettingsRoute get parent => const UserSettingsRoute();
}
```

Then, when invoking navigation to either of these routes, you can pass the same data object.

```dart
ElevatedButton(
  onPressed: () => const UserSettingsRoute().go(
    context,
    data: UserRouteData(userId: '123'),
  ),
  child: const Text('Go to User Settings'),
),

ElevatedButton(
  onPressed: () => const MfaSettingsRoute().go(
    context,
    data: UserRouteData(userId: '123'),
  ),
  child: const Text('Go to MFA Settings'),
),
```

If a child route requires its own data in addition to its parent's data, you have two options:
  1. Create a new data class that extends the parent's data class and adds the value(s) you need
  2. Create a totally new data class

While option 1 is certainly easy, it is not recommended. By extending the parent's data class, you will lose some of the compile-time type-checking that the `DataRoute` class would otherwise provide.

If you do use Option 1, make sure to implement the `inject` method (the compiler will not yell at you if you do not). You can call `super.inject(path)` to inject the parent's data into the path, then inject your new value(s).

```dart
class MyRouteData extends UserRouteData {
  const MyRouteData({
    super.userId,
    required this.someValue;
  });

  final String someValue;

  String inject(String path) {
    return super.inject(path).setParam(
      RouteParams.someValue,
      someValue,
    );
  }
}
```

### Data Factories

Another useful utility is the `SimpleRouteDataFactory` class. By extending this class, you can define a factory that can safely extract the route data from `GoRouterState`.

```dart
class UserRouteDataFactory extends SimpleRouteDataFactory<UserRouteData> {
  const UserRouteDataFactory();

  @override
  UserRouteData fromState(GoRouterState state) {
    return UserRouteData(
      userId: state.params[RouteParams.userId]!,
    );
  }

  @override
  bool containsData(GoRouterState state) {
    return containsKey(state, RouteParams.userId);
  }
}
```

The `fromState` method is useful within your route configuration for extracting the route data from the `GoRouterState`.

The `containsData` method must also be implemented; it gives you a way to validate whether all necessary parameters are present in the `GoRouterState`.

Also note the `containsKey` helper method. This utility checks whether the `GoRouterState` contains a particular parameter key (i.e. enum value name).

#### Using a DataFactory

```dart
GoRoute(
  path: const UserRoute().path,
  redirect: (context, state) {
    if (!const UserRouteDataFactory().containsData(state)) {
      return const HomeRoute().path;
    }

    return null;
  },
  builder: (context, state) {
    final routeData = const UserRouteDataFactory().fromState(state);

    return UserScreen(
      userId: routeData.userId,
    );
  },
),
```

A useful pattern is to check the validity of the state in a `redirect`, thus ensuring that the state is valid before attempting to extract the route data object and build the screen in the `builder`.

### Query parameters

As of v0.0.3, this package supports injecting and extracting query parameters.

#### Injecting query parameters

Injecting query parameters into your route is easy. When calling the `go` method, just add a `Map<String, String>` to the `query` argument.

```dart
ElevatedButton(
  onPressed: () => const MyRoute().go(context, query: {'key': 'value'}),
),
```

#### Extracting query parameters

The query parameters live on a `Uri` instance on the `GoRouterState`. You can access this map yourself using `GoRouterState.uri.queryParameters`.

Or, you can use the `getQueryParams` convenience function. This method is a wrapper around the `queryParameters` property and just serves to make it easier to access.

```dart
GoRoute(
  path: const MyRoute().path,
  builder: (context, state) => MyScreen(data: getQueryParams(state)['someKey']),
),
```

## Useful Tips

### Static instances

If you don't liking creating instances of your routes all over the place, you can create a static instance of each route and use that instead.

```dart
class HomeRoute extends SimpleRoute {
  const HomeRoute();

  @override
  String get path => '/home';

  static const instance = HomeRoute();
}
```

Then:

```dart
GoRoute(
  path: HomeRoute.instance.path,
  ...
),
```
  
```dart
ElevatedButton(
  onPressed: () => HomeRoute.instance.go(context),
  child: const Text('Go to Home'),
),
```

### Route getters

Another useful pattern is to create a getter for each child route on its parent route.

```dart
class HomeRoute extends SimpleRoute {
  const HomeRoute();

  @override
  String get path => '/home';

  // make it static
  static DashboardRoute get dashboard => const DashboardRoute();

  // or make it an instance method
  SettingsRoute get settings => const SettingsRoute();
}
```

Then:

```dart
GoRoute(
  path: const HomeRoute().path,
  builder: (context, state) => const HomeScreen(),
  routes: [
    GoRoute(
      // static getter
      path: HomeRoute.dashboard.path,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      // instance method
      path: const HomeRoute().settings.path,
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
),
```

```dart
ElevatedButton(
  onPressed: () => HomeRoute.dashboard.go(context),
),
ElevatedButton(
  onPressed: () => const HomeRoute().settings.go(context),
),
```