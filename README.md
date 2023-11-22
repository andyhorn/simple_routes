# Simple Routes

Simple, type-safe route and navigation management for [go_router](https://pub.dev/packages/go_router).

## Features

By defining your routes and route structure using Dart classes, you gain powerful tools to help you build and manage your app's navigation. 

- Eliminate "magic strings"
- Enforce route parameter requirements
- Inject and extract path parameters, query parameters, and "extra" route data
- Navigate anywhere without building strings or worrying about what data you need
- Determine the current route and its ancestors

The primary focus of this package is to provide a simple interface for triggering navigation within the app.

It boils down to a simple `go` method:

```dart
const MySimpleRoute().go(context);
```

Or, for more complicated routes:

```dart
const MyNestedRouteWithParams().go(context, data: MyRouteData('some-value'));
```

**Push**

The `go` method also supports the "push" navigation type. 

To use this, just set the `push` named argument to `true`.

```dart
const MySimpleRoute().go(context, push: true);
```

## Getting started

This package is intended to be used with the [GoRouter](https://pub.dev/packages/go_router) package.

```
dependencies:
  go_router: ^12.0.0
  simple_routes: ^0.0.12
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
  String get path => 'home';
}
```

When extending the `SimpleRoute` base class, you must override the `path` property. This sets the path for this route. You are not required to prefix the path with a leading slash - this is handled for you.

## GoRouter configuration

When defining your `GoRouter` structure, use the `goPath` property of your routes to properly set the path for each route.

This property will manage the leading slashes for you, based on whether or not your route is a `ChildRoute` or not (more on this below).

```dart
  GoRoute(
    path: const HomeRoute().goPath,
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

#### ChildRoute

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

Along with providing the `path` for this route, you must also implement the `parent` property. This tells your route how to find its parent in the route structure.

The `go` method will then automatically build the full path for your route, based on its `path` and the `path`s of its parent(s).

```dart
ElevatedButton(
  onPressed: () => const SettingsRoute().go(context),
  child: const Text('Go to Settings'),
),
```

**NOTE:** Any routes that do not implement `ChildRoute` will be treated as a root-level route (i.e. prefixed with a leading slash).

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

This helps eliminate "magic strings" and reduces the opportunity for typos and other hard-to-track-down bugs.

#### Data classes

Secondly, we need to define a class that represents the data needed by our new route. This new class should extend the `SimpleRouteData` class. 

```dart
class UserRouteData extends SimpleRouteData {
  const UserRouteData({required this.userId});

  final String userId;

  @override
  String inject(String path) {
    return path.setParam(
      RouteParams.userId,
      userId,
    );
  }
}
```

By extending the `SimpleRouteData` base class, we must implement the `inject` method. This is how the templated parameters in the path are replaced with their values at runtime. Note the `String.setParam` extension - it is recommended to utilize this extension method anytime you inject a value.

This extension takes an enum value as its first argument and a `String` value as its second argument.

```dart
String setParam<E extends Enum>(E enum, String value);
```

#### Dynamic routes

Finally, your route class should extend the `DataRoute` class, typed for the data class we just created.

```dart
class UserRoute extends DataRoute<UserRouteData> {
  const UserRoute();

  @override
  String get path => join(['user', withPrefix(RouteParams.userId)]);
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

  @override
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
    return containsParam(state, RouteParams.userId);
  }
}
```

The `fromState` method is required to be implemented and should return an instance of your data class, populated with the values from the `GoRouterState`.

The `containsData` method must also be implemented; it gives you a way to validate whether all necessary parameters are present in the `GoRouterState` before attempting to build your data class. This is often useful in a `redirect` method (see below).

The `containsParam` method is useful for checking if a path parameter (defined as an Enum value) exists in the `GoRouterState`.

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

### Query parameters

#### Using data classes

The recommended method of injecting and extracting query parameters is to use a `DataRoute` and a `SimpleRouteDataFactory`.

First, define your data class and have it add the query parameters as part of the `inject` method, using the `maybeAppendQuery` extension method.

```dart
class MyRouteData extends SimpleRouteData {
  const MyRouteData({required this.someValue});

  final String? someValue;

  @override
  String inject(String path) {
    return path.maybeAppendQuery({
      if (someValue != null) 'someKey': someValue!,
    });
  }
}
```

Then, define your factory class and use the `containsQuery` and `extractQuery` methods to build your data class.

```dart

class MyRouteDataFactory extends SimpleRouteDataFactory<MyRouteData> {
  static const queryKey = 'someKey';

  @override
  MyRouteData fromState(GoRouterState state) {
    return MyRouteData(
      someValue: containsQuery(state, queryKey) 
        ? extractQuery(state, queryKey) 
        : null,
    );
  }

  ...
}
```

#### Quick n' dirty

If you don't want to use a data class and factory, you can still inject and extract query parameters. The `go` method exposes a `query` named argument that accepts a `Map<String, String>`.

```dart
ElevatedButton(
  onPressed: () => const MyRoute().go(context, query: {'key': 'value'}),
),
```

Then, when building your screen, you can use extract your query parameters from the `GoRouterState`. The `getQueryParams` method takes in the state and returns a `Map<String, String>`.

```dart
builder: (context, state) {
  final queryParams = getQueryParams(state);

  return MyScreen(
    someValue: queryParams['key'],
  );
}
```

### Extra data

GoRouter provides a way of passing "extra" data to your routes. This is useful for passing data that is not part of the route itself, but is still needed by the screen.

You can utilize this "extra" data as part of a `DataRoute` by overriding the `extra` getter. Note that you do not have to use it in the `inject` method.

```dart
class MyRouteData extends SimpleRouteData {
  const MyRouteData({
    required this.parameterValue,
    required this.extraValue,
  });

  final String parameterValue;
  final String extraValue;

  @override
  Object? get extra => SomeOtherDataClass(someValue);

  @override
  String inject(String path) {
    return path.setParam(
      RouteParams.parameter,
      parameterValue,
    );
  }
}
```

Then, when building your screen, you can use a `SimpleRouteDataFactory` to extract the extra data from the `GoRouterState`.

```dart
class MyRouteDataFactory extends SimpleRouteDataFactory<MyRouteData> {
  @override
  MyRouteData fromState(GoRouterState state) {
    return MyRouteData(
      parameterValue: extractParam(state, RouteParams.parameter),
      extraValue: extractExtra<SomeOtherDataClass>(state).someValue,
    );
  }

  ...
}
```

### Route Checking

#### Current Route

As of 0.0.7, you can use the `isCurrentRoute` method, available on all SimpleRoutes, to check whether the current route is a match for the given route.

This works for DataRoutes, too!

For example, if we have a simple route structure like:

```dart
class BaseRoute extends SimpleRoute {
  const BaseRoute();

  @override
  String get path => '/base';
}

class SubRoute extends SimpleRoute implements ChildRoute<BaseRoute> {
  const SubRoute();

  @override
  String get path => 'sub';

  @override
  BaseRoute get parent => const BaseRoute();
}
```

And we are at the screen for the `SubRoute` with a location of `/base/sub`. We can easily check whether the current route is the `SubRoute` by calling `isCurrentRoute`:

```dart
// current location: '/base/sub'
if (const SubRoute().isCurrentRoute(context) /* true */) {
  debugPrint('We are at SubRoute!');
}
```

#### Ancestor Route

As of 0.0.7, you can use the `isAncestorRoute` method, available on all SimpleRoutes, to check whether the current route is an ancestor of the given route. This is similar to `isCurrentRoute` (see section above), except that the current route must be a descendant of the route in question.

For example, in our simple route structure from the previous section, we can check whether the current route is a descendant of `BaseRoute` by calling `isAncestorRoute`:

```dart
// current location: '/base/sub'
if (const BaseRoute().isAncestorRoute(context) /* true */) {
  debugPrint('We are at a descendant of BaseRoute!');
}
```

However, this method will return `false` if the current route is an exact match for the route in question.

For example, if we are at the screen for the `SubRoute` and use `isAncestor`, it will return `false`;

```dart
// current location: '/base/sub'
if (const SubRoute().isAncestor(context) /* false */) {
  ...
}
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
