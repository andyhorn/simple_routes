# Code Generation Guide

`simple_routes` uses code generation to bridge the gap between your route definitions and type-safe navigation. This guide covers how to use the code generation feature "as a whole."

## Overview

The code generation process involves three main components:
1. **Blueprints**: Abstract classes that define the "schema" of your routes.
2. **Route Classes**: Generated classes used for navigation (e.g., `ProfileRoute`).
3. **Route Data Classes**: Generated classes that hold the parameters for a route (e.g., `ProfileRouteData`).

## Defining Blueprints

Blueprints are abstract classes annotated with `@Route`. They serve as the source of truth for the generator.

```dart
@Route('profile/:userId')
abstract class Profile {
  @Path('userId')
  String get id;
}
```

### Path Parameters (`@Path`)

Any dynamic segment in your route path (e.g., `:userId`) must be represented in your blueprint.

- Use `@Path()` on a getter or field.
- If the name of the getter/field differs from the path segment, provide the name: `@Path('userId') String get id;`.
- If they match, you can omit the name: `@Path() String get userId;`.

### Query Parameters (`@Query`)

Query parameters are defined similarly but use the `@Query` annotation.

```dart
@Route('search')
abstract class Search {
  @Query('q')
  String? get query;
}
```

- Non-nullable types are generated as required parameters.
- Nullable types are generated as optional parameters.

### Extra Data (`@Extra`)

If you need to pass a complex object that isn't part of the URL, use `@Extra`.

```dart
@Route('details')
abstract class Details {
  @Extra()
  MyData get data;
}
```

## Child Routes and Inheritance

To nest routes, specify the `parent` blueprint in the `@Route` annotation.

```dart
@Route('edit', parent: Profile)
abstract class ProfileEdit {}
```

### Automatic Parameter Inheritance

Child routes automatically inherit all path parameters from their parent routes. In the example above, `ProfileEdit` will automatically have a `userId` parameter because its parent (`Profile`) requires one.

The generated `ProfileEditRouteData` will look like this:

```dart
class ProfileEditRouteData implements SimpleRouteData {
  const ProfileEditRouteData({required this.id});
  final String id;
  // ...
}
```

## Generating Code

Run the build runner to generate your route files:

```bash
dart run build_runner build
```

The generator will produce a `.g.dart` file. You should include `part 'your_file.g.dart';` at the top of your blueprint file.

## Navigation

For every blueprint `Name`, the generator produces a `NameRoute` class.

- If the route has no data (direct or inherited), it extends `SimpleRoute`.
- If the route has data, it extends `SimpleDataRoute<NameRouteData>`.

### Usage

```dart
// Navigating to a route without data
const DashboardRoute().go(context);

// Navigating to a route with data
const ProfileRoute().go(
  context,
  data: const ProfileRouteData(id: '123'),
);
```

The `go` and `push` methods are type-safe and will enforce providing a `data` object if required.

## Extracting Data from state

Instead of manually parsing `state.pathParameters` or `state.uri.queryParameters`, use the generated `fromState` factory on the `RouteData` class.

```dart
GoRoute(
  path: const ProfileRoute().path,
  builder: (context, state) {
    // Type-safe data extraction
    final data = ProfileRouteData.fromState(state);
    return ProfileScreen(userId: data.id);
  },
)
```

This factory handles:
- Fetching path parameters.
- Fetching and URI-decoding query parameters.
- Casting the `extra` object.
- Parsing types (e.g., `int.parse` for integer parameters).

## Type Support

The generator currently supports:
- `String`: Default type for parameters.
- `int`: Automatically parsed using `int.parse`.
- `double`: Automatically parsed using `double.parse`.
- `Enum`: (Handled as String, you can map them in your UI).
- `Custom Objects`: Supported via the `@Extra` annotation.
