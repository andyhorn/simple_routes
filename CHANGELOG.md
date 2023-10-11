## 0.0.10

- Attempt to fix release workflow (again)

## 0.0.9

- Add support for pushing routes

## 0.0.8

- Version bump for release workflow fixes

## 0.0.7

- Add `isCurrentRoute` method
- Add `isAncestor` method
- Update description in pubspec.yaml
- Update README

## 0.0.6

- Add automated release workflow
- Update go_router to ^11.1.1

## 0.0.5

- Fix several small issues in README

## 0.0.4

**Breaking Change**

- Change `go` method to use named parameters for `data` and `query`

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

## 0.0.3

- Add support for injecting query parameters into route paths
- Add helper method for extracting query param map from GoRouterState
- Fix bug in route data factory
- Add and improve tests

## 0.0.2

- Improve README
- Remove static route getter from example for consistency

## 0.0.1

Initial Release

- SimpleRoute and DataRoute base classes for routes
  - `path` and generated `fullPath` properties for route configuration
  - `go` method for navigation via go_router
- SimpleRouteData base class for route data
  - `inject` method for injecting route data into the route path
- ChildRoute interface for structuring route hierarchy
- SimpleRouteDataFactory base class
  - `fromState` method for extracting route data from a `GoRouterState`
  - `containsData` method for validating `GoRouterState` has all necessary data components
  - `containsKey` helper for checking the existence of a parameter key in a `GoRouterState`
- Utility functions:
  - `join`
  - `withPrefix`
  - `setParam` extension
