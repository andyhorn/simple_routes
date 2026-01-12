# Migration Guide

This document is a guide for migrating between major package versions.

## 1.x.x -> 2.0.0

The main impetus for this update was to simplify the API and consists, mostly, of removing restrictions.

I was trying to do too much in the previous versions, which actually made the package _more_ difficult to use.

This update brings SimpleRoutes more inline with its spirit: simplifying routing.

### Paths

In v2, defining a route's path is now done via the `super` constructor. Simply move your path from the `path` property override to the constructor.

```dart
@override
String get path => 'users/:userId';
```

becomes

```dart
const UserDetailsRoute() : super('users/:userId');
```

### GoRoute Config

The `goPath` property has been eliminated and replaced with the `path` property to more closely match the `GoRoute` API.

```dart
GoRoute(
    path: const UserDetailsRoute().goPath,
),
```

becomes

```dart
GoRoute(
    path: const UserDetailsRoute().path,
),
```

**Note**: I know I made you change from `path` to `goPath` in the previous major version bump. We all make mistakes, right?

### Route Data Properties

In an effort to make SimpleRoutes more simple, all of the route data properties have been changed from requiring an `Enum` key to accepting a `String` and trusting that you know what you're doing.

```dart
@override
Map<Enum, String> get properties => {
    RouteParams.userId: userId,
};
```

becomes

```dart
Map<String, String> get properties => {
    'userId': userId,
};
```

and

```dart
Map<Enum, String?> get query => {
    RouteParams.queryKey: query,
};
```

becomes

```dart
Map<String, String?> get query => {
    'queryKey': query,
};
```

### GoRouterState Extensions

All of the `GoRouterState` extensions have been removed. These were initially intended to provide some real value, but become nothing more than wrappers around the `GoRouterState` properties, so they were removed.

### Location

The route location methods (`isCurrentRoute`, `isParentRoute`, `isActive`) have been modified to accept a `GoRouterState` object instead of a `BuildContext`.

Requiring the `BuildContext` was supposed to make them easier to use, but they prevented these methods from being usable inside a `GoRoute` builder or redirect.

If you're using one of these inside a widget, just use `GoRouterState.of(context)` to acquire the state object.

```dart
const MyRoute().isActive(context);
```

becomes

```dart
const MyRoute().isActive(GoRouterState.of(context));
```

## 0.0.11 -> 1.0.0

This section will guide you through the breaking changes introduced in the 1.0.0 release and how to migrate your code.

### Full path

The `fullPath` property has been converted to a method.

This method will return the full path of the route, all the way to the root. For `DataRoute`'s, the method will require an instance of the route data class so that it can populate the path template with real values.

```dart
final link = const MyDataRoute().fullPath(MyRouteData('user-123'));
print(link); // /path/to/user-123
```

### GoRoute configuration

Version 1.0.0 introduces a new `goPath` property on the `SimpleRoute` class. This property should be used when defining your `GoRoute`s instead of the `path` property.

From this:

```dart
GoRoute(
  path: const MyRoute().path,
),
```

to this:

```dart
GoRoute(
  path: const MyRoute().goPath,
),
```

### Route definitions

#### DataRoute - Path and query parameters

In previous versions, the path and query parameters were injected into the path template within the `inject` method, which was left for you to override and implement. This has been replaced by a `parameters` property and a `query` property on the `DataRoute` class.

In the new version, you need only define what your parameters and their values are; injecting/appending them into the path is now handled for you.

To migrate to v1.0.0, remove any implementations of the `inject` method and replace them with the appropriate `parameters` and/or `query` properties.

From this:

```dart
class MyRouteData extends SimpleRouteData {
  const MyRouteData({
    required this.myPathParameter,
    this.myQueryParameter,
  });

  final String myPathParameter;
  final String? myQueryParameter;

  @override
  String inject(String path) {
    return path
      .setParam(RouteParams.myPathParameter, myPathParameter)
      .maybeAppendQuery({
        if (myQueryParameter != null) ...{
          RouteParams.myQueryParameter.name: myQueryParameter!,
        },
      })
  }
}
```

To this:

```dart
class MyRouteData extends SimpleRouteData {
  const MyRouteData({
    required this.myPathParameter,
    this.myQueryParameter,
  });

  final String myPathParameter;
  final String? myQueryParameter;

  @override
  Map<Enum, String> get parameters => {
    RouteParams.myPathParameter: myPathParameter,
  };

  @override
  Map<Enum, String?> get query => {
    RouteParams.myQueryParameter: myQueryParameter,
  };
}
```

This also means you no longer need to worry about the `setParam` or `maybeAppendQuery` extension methods, as all of the path-building is handled by the package.

### Route data factories

The `SimpleRouteDataFactory` base class has been removed in favor of using the new extension methods on `GoRouterState`. If you still want a "factory," it is recommended to add a factory constructor or static method to your route data class.

For example, in the previous versions, you would have used a factory to construct your route data, like this:

```dart
class MyRouteDataFactory extends SimpleRouteDataFactory<MyRouteData> {
  @override
  bool containsData(GoRouterState state) {
    // verify the presence of any necessary data in [state].
    return containsParam(state, RouteParams.myParam);
  }

  @override
  MyRouteData fromState(GoRouterState state) {
    // craft an instance of your route data class using the data in [state].
    final param = extractParam(state, RouteParams.myParam);
  }
}
```

In your GoRoute configuration, you may have checked for the presence of data like this:

```dart
GoRoute(
  redirect: (context, state) {
    // use your factory to validate the GoRouterState
    if (!const MyRouteDataFactory().containsData(state)) {
      return const MyOtherRoute().fullPath;
    }

    return null;
  },
),
```

In the v1.0.0 release, you would instead add a factory constructor to your data class:

```dart
class MyRouteData extends SimpleRouteData {
  const MyRouteData(this.myParam);
  final String myParam;

  // use a factory constructor to construct your route data from the state.
  factory MyRouteData.fromState(GoRouterState state) {
    // use the `getParam` extension method to extract the data from the state.
    return MyRouteData(state.getParam(RouteParams.myParam)!);
  }
}
```

And in your GoRoute configuration:

```dart
GoRoute(
  redirect: (context, state) {
    // use the extension methods to check for the presence of data
    // and redirect using fullPath(), if necessary
    if (state.getParam(RouteParams.myParam) == null) {
      return const MyOtherRoute().fullPath();
    }

    return null;
  },
),
```

### Navigation

In previous versions, the `go` method accepted a few different arguments, including `Map<String, String> query` and `bool push = false`. These have been removed from the method signature in favor of the `query` property on `DataRoute` and a discrete `push` method, respectively.

For example, if you had an invocation of `go` with a query parameter:

```dart
onPressed: () => const MyRoute().go(context, query: {'myQueryKey': 'myQueryValue' }),
```

You would now need to define the query parameter on your route data class:

```dart
class MyRouteData extends SimpleRouteData {
  const MyRouteData(this.myQueryValue);
  final String myQueryValue;

  @override
  Map<Enum, String?> get query => {
    RouteParams.myQueryKey: myQueryValue,
  };
}
```

And then invoke `go` without the `query` parameter:

```dart
onPressed: () => const MyRoute().go(context, data: const MyRouteData('myQueryValue')),
```

Additionally, if you had an invocation of `go` that used the `push` argument, you would now need to use the `push` method on your route class:

```dart
onPressed: () => const MyRoute().push(context),
```

### Helper methods

All of the free-floating helper methods have been removed in favor of extension methods.

#### `withPrefix`

The `withPrefix` helper, which prefixed an Enum value's name with a colon (:) has been replaced with the `prefixed` extension method on `Enum`.

From this:

```dart
withPrefix(RouteParams.myParam),
```

To this:

```dart
RouteParams.myParam.prefixed,
```

#### `join`

The free-floating `join` method, which joined strings with a forward slash (`/`), has been replaced with a `fromSegments` method on the base route class.

This was done to avoid leaking the method into the global namespace.

From this:

```dart
@override
String get path => join(['path', 'to', 'join']),
```

To this:

```dart
@override
String get path => fromSegments(['path', 'to', 'join']),
```

#### `setParam`

The `setParam` extension still exists, but you shouldn't need to use it anymore, as path-building is handled entirely by the package.
