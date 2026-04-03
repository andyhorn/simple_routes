# CHANGELOG

## 2.1.1

- Patch version bump for latest release (`simple_routes` 2.1.1, `simple_routes_annotations` 1.0.1, `simple_routes_generator` 1.0.1).

## 2.1.0

- **Stable release: Code generation support**
- Code generation support across the workspace packages (`simple_routes` 2.1.0, `simple_routes_annotations` 1.0.0, `simple_routes_generator` 1.0.0).

## 2.1.0+beta.1

- **Initial Beta Release of Code Generation Tooling!**
- Added code generation support across the workspace packages.
- Define routes using abstract "blueprint" classes and the `@Route` annotation.
- Automatically generate type-safe `Route` and `RouteData` classes.
- Support for path parameters (`@Path`), query parameters (`@Query`), and extra data (`@Extra`).
- Automatic path parameter inheritance for child routes.
- Simplified data extraction with generated `fromState` factory constructors.
