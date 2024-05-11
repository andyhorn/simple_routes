# CHANGELOG

## 2.0.0-rc.1

- Change location helpers (`isCurrentRoute`, `isParentRoute`, `isActive`) to accept a `GoRouterState` instead of a `BuildContext`
- Change the `DataRoute` `parameters` and `query` properties from `Map<Enum, String>` to `Map<String, String>`
- Rename `DataRoute` to `SimpleDataRoute`
- Rename `Enum#prefixed` to `Enum#template` to be more clear
- Remove the `GoRouterState` extension methods as they were not providing much value

## 1.1.3

- Improvements made to the README

## 1.1.2

- Update go_router

## 1.1.1

- Fix a typo in the "go-router" topic in the pubspec file

## 1.1.0

- Fix typos in README and example project
- Fix a bug in the `fullPath` method causing duplicate leading slashes in some scenarios
- Add support for returning values when using the `push` method
- Move `mocktail` to the dev dependencies
- Add topics to the `pubspec.yaml` for `pub.dev`
- Upgrade fvm Flutter version and add entry to .gitignore

## 1.0.0

- First stable release!
- No changes from 1.0.0-beta.9 except to move from beta to stable

## 1.0.0-beta.9

- Rename `joinSegments` to `fromSegments`
- Only use the duplicate segment detection when in debug mode
- Improve the duplicate segment error message

## 1.0.0-beta.8

- Hide the full path template and expose a `fullPath` method on both route classes

## 1.0.0-beta.7

- Improve migration guide
- Improve README

## 1.0.0-beta.6

- Rename `fullPath` property to `fullPathTemplate`
- Rename `generate` to `populatedWith`
- Add `joinSegments` method to base class and remove `toPath` extension method
- Add and improve doc comments

## 1.0.0-beta.5

- Add `isActive` method

## 1.0.0-beta.2 - 4

Minor fixes to documentation.

## 1.0.0-beta.1

We have finally reached a stable release! 🎉

Granted, this is just a beta release for the moment, we are confident that it is stable enough to be classified as version 1.

This release includes a significant rework of the API to improve the developer experience and standardize our package conventions.

Please see the [Migration Guide](doc/migration_guide.md) for information on how to migrate your code to this version from the pre-release versions.

### New Features
  * Path parameters are now injected automatically, based on the `parameters` property
  * Query parameters are now appended automatically, based on the `query` property
  * Extra data is now injected automatically, based on the `extra` property
  * Automatic leading-slash management - no more worrying about whether or not to add a leading slash to your route's `path`
  * Get the full path of a `DataRoute`, with all template parameters populated, using the new `generate` method

### Breaking Changes

This release includes a few breaking changes.

  * The `query` parameter of the `go` method has been removed
  * The `push` argument of the `go` method has been removed
  * A new `goPath` property has been added to the `SimpleRoute` class and should be used when defining your `GoRoute`s
  * The `inject` method has been removed from the `DataRoute` class
  * The helper methods have all been removed in favor of extensions and class methods

## 0.0.11

- Update GoRouter to ^12.0.0

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
