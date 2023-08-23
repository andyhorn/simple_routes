## 0.0.4

**Breaking Change**

- Change `go` method to use named parameters for `data` and `query`

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
