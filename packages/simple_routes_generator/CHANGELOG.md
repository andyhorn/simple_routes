# CHANGELOG

## [1.1.0](https://github.com/andyhorn/simple_routes/compare/simple_routes_generator-v1.0.1...simple_routes_generator-v1.1.0) (2026-04-04)


### Features

* codegen ([#41](https://github.com/andyhorn/simple_routes/issues/41)) ([f3cc696](https://github.com/andyhorn/simple_routes/commit/f3cc6966792e8a9744ae66089cd120b913607dc4))


### Bug Fixes

* annotation package references ([40a0bc3](https://github.com/andyhorn/simple_routes/commit/40a0bc3dd3033815978aef302b0dafd4b71ddd29))
* generator fixes ([#42](https://github.com/andyhorn/simple_routes/issues/42)) ([7073489](https://github.com/andyhorn/simple_routes/commit/707348985e4cc7e136c8c3c28473f6b14b2edb75))
* generator fixes and cleanup ([#44](https://github.com/andyhorn/simple_routes/issues/44)) ([d5e2bc1](https://github.com/andyhorn/simple_routes/commit/d5e2bc194b7f2bcab4543707211187e44cb0e088))
* null-check assertions ([755d7e8](https://github.com/andyhorn/simple_routes/commit/755d7e826622440b7ce92c8191524aa8545fa270))

## 1.0.1

- Patch version bump for latest release.

## 1.0.0

- Stable release

## 1.0.0+beta.2

- Fixed null-check assertions, extra parameter validation, type casting, and nullable handling
- Refactored code structure and improved maintainability
- Improved test coverage

## 1.0.0+beta.1

- Initial beta release
- Code generator for the `simple_routes` package
- Generate type-safe `Route` and `RouteData` classes from annotated blueprint classes
- Support for path parameters (`@Path`), query parameters (`@Query`), and extra data (`@Extra`)
- Automatic path parameter inheritance for child routes defined with `parent` property
- Generate `fromState` factory constructors for easy route data extraction from `GoRouterState`
