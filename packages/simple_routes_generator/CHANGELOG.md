# CHANGELOG

## 1.0.0-beta.1

- Initial beta release
- Code generator for the `simple_routes` package
- Generate type-safe `Route` and `RouteData` classes from annotated blueprint classes
- Support for path parameters (`@Path`), query parameters (`@Query`), and extra data (`@Extra`)
- Automatic path parameter inheritance for child routes defined with `parent` property
- Generate `fromState` factory constructors for easy route data extraction from `GoRouterState`
