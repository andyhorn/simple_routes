<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->
# Simple Routes

Simple, class-based route management for [go_router](https://pub.dev/packages/go_router).

## Features

This package is intended to provide useful classes and a helpful structure for defining, managing, and using your app's routes.

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

This first section will describe how to use the `SimpleRoute` and `ChildRoute` classes to define routes that _do not_ require any dynamic variables.

For routing that requires path parameters, see the **Defining dynamic routes** section below.

#### Root-level routes

Any root-level routes (routes that are not nested within another route) should extend the `SimpleRoute` class.

**Note:** Root level routes should have a path that is prefixed with a leading slash.

```dart
class HomeRoute extends SimpleRoute {
  const HomeRoute();

  @override
  String get path => '/home';
}
```

By extending the `SimpleRoute` base class, you are required to implement the `path` property. This path is used to define the `path` of a `GoRoute`. 

```dart
  GoRoute(
    path: const HomeRoute().path,
    pageBuilder: (context, state) => const HomePage(),
  ),
```

Your route also inherits a `go` method that makes navigation, well, simple.


```dart
ElevatedButton(
  onPressed: () => const HomeRoute().go(context),
  child: const Text('Go to Home'),
),
```

#### Nested (child) routes

Any nested (AKA "Child") routes should extend the `SimpleRoute` class and implement the `ChildRoute` interface.

**Note:** Child routes should have a path that is _not_ prefixed with a leading slash.

```dart
class SettingsRoute extends SimpleRoute implements ChildRoute<HomeRoute> {
  const SettingsRoute();

  @override
  String get path => 'settings';

  @override
  HomeRoute get parent => const HomeRoute();
}
```

By implementing the `ChildRoute` interface, you are required to implement the `parent` property. This property provides an instance of the route's parent and is used behind-the-scenes to generate the `fullPath` property.

The `go` method will automatically build the full path for your route, based on its path and the `path` values of its parent routes.

```dart
ElevatedButton(
  onPressed: () => const SettingsRoute().go(context),
  child: const Text('Go to Settings'),
),
```


### Defining dynamic routes

Routes that require path parameters are also supported. 

Before we define our route, there is a little bit of setup to do;  This package adds helpful requirements for how dynamic data is captured and used by your routes. 

The first rule is that all path parameter names must be defined in an enum.

```dart
enum RouteParams {
  userId,
}
```

Second, we need to define a custom class that extends the `SimpleRouteData` class. This class will be used to store the dynamic data that is passed to the route.

```dart
class UserRouteData extends SimpleRouteData {
  const UserRouteData({required this.userId});

  final String userId;

  @override
  void inject(String path) {
    return path.setParams(
      RouteParams.userId,
      userId,
    );
  }
}
```

The `SimpleRouteData` base class requires us to implement the `inject` method. This is how the templated parameters in the path are replaced with the actual values. Note the `setParams` extension method - it is recommended to utilize this utility anytime you set a path parameter.

Finally, your dynamic route should extend the `DataRoute` class, typed for the relevant data class.

**Note:** Just like the `SimpleRoute`s above, any root-level paths should be prefixed with a leading slash; any child routes should **not** be prefixed.

```dart
class UserRoute extends DataRoute<UserRouteData> {
  const UserRoute();

  @override
  String get path => join(['/user', withPrefix(RouteParams.userId)]);
}
```

Let's take a moment to break this example down. 

The route class extends `DataRoute` with the appropriate `SimpleRouteData` subclass for this route's data. A mouthful, but easy enough. This will be useful in a moment.

The `path` value is a little more interesting. We are using the `join` utility method to join the path segments together - This is the recommend way of defining paths with multiple segments. 

The `withPrefix` extension method is used to convert the enum value to the path template. This is the recommended way of converting your enum values to their path template values. For example, this `path` would become `/user/:userId`.

Now that we have our route defined, let's see how we can use it.

```dart
ElevatedButton(
  onPressed: () => const UserRoute().go(
    context,
    UserRouteData(userId: '123'),
  ),
  child: const Text('Go to User'),
),
```

When the `go` method is invoked, the data will be injected into the fully-qualified route string.

#### Children of DataRoutes

One caveat with this structure is that any children of a `DataRoute` will need to also be a `DataRoute` that supplies the data to all of its parents.

For example, say we have a route `/users/:userId/settings/mfa` - the `settings` route _and_ the `mfa` route will both require the `userId` value to generate their full route; therefore they will need to accept a data object containing that value.

Defining these routes is simple, but it does require the extra boilerplate of `DataRoute<DataType>`. 

For cases like this example, where only one piece of data is needed, these child classes can simply re-use the parent's data class.

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
    UserRouteData(userId: '123'),
  ),
  child: const Text('Go to User Settings'),
),

ElevatedButton(
  onPressed: () => const MfaSettingsRoute().go(
    context,
    UserRouteData(userId: '123'),
  ),
  child: const Text('Go to MFA Settings'),
),
```

If one of the child routes requires its own parameter, you have one of two options:
  1. Create a new data class that extends the parent's data class and adds the value(s) you need
  2. Create a new data class that extends the `SimpleRouteData` class and add all necessary values

Option 1 is easy, as it will allow you to re-use the parent's data class and only add the values you need, but it is not recommended, as it can break the compiler-time type-checking and will not force you to implement the `inject` method, leaving extra room for error.

```dart
class MyRouteData extends UserRouteData {
  const MyRouteData({
    super.userId,
    required this.someValue;
  });

  final String someValue;
}
```

**Note:** If you are going to use Option 1, make sure to implement the `inject` method. You can call `super.inject(path)` to inject the parent's data into the path, then inject this class' values.

```dart
@override
String inject(String path) {
  return super.inject(path).setParam(
    RouteParams.someValue,
    someValue,
  );
}
```

### Data Factories

Another useful utility is the `SimpleRouteDataFactory` class. By extending this class, you can define a factory that can safely extract the route data from the `GoRouterState`.

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

The `fromState` method is useful within your route configuration for extracting the route data from the `GoRouterState` object to be passed into your screen widgets.

The `containsData` method should be implemented to give you a way to validate whether all parameters are present in the `GoRouterState` object.

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

### Other Tips

If you find it tedious or smelly to repeatedly create new instances of your routes, you can create a static instance of each route and use that instead.

```dart
class HomeRoute extends SimpleRoute {
  const HomeRoute();

  @override
  String get path => '/home';

  static const instance = HomeRoute();
}
```

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

