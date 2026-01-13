# Simple Routes

Simple, declarative route and navigation management for [go_router](https://pub.dev/packages/go_router).

`simple_routes` is a companion package to [GoRouter](https://pub.dev/packages/go_router) that provides a simple, declarative way to define your app's routes. By using `simple_routes`, you can eliminate magic strings, simplify your route definitions, and enforce type-safe routing requirements.

## Features

- **Code Generation**: Automatically generate route and data classes from simple abstract blueprints.
- **Type Safety**: Enforce required path parameters, query parameters, and extra data at compile time.
- **Declarative Hierarchy**: Define child routes easily and inherit path parameters automatically.
- **Explicit Data Extraction**: Extract route data from `GoRouterState` using generated factory constructors.
- **Advanced Matching**: Check if a route is currently active, a parent of the current route, or an exact match.

## Table of Contents

- [Getting Started](#getting-started)
- [Usage](#usage)
  - [Code Generation (Recommended)](#code-generation-features)
    - [Defining Routes](#defining-routes)
    - [Routes with Parameters](#routes-with-parameters)
    - [Child Routes and Inheritance](#child-routes-and-inheritance)
    - [Query Parameters](#query-parameters)
    - [Extra Data](#extra-data)
    - [Generating Code](#generating-code)
  - [Manual Route Definition](#manual-route-definition)
- [Navigation](#navigation)
- [Advanced Usage](#advanced-usage)
  - [Route Matching](#route-matching)

## Getting Started

Add `simple_routes` and `simple_routes_annotations` to your `pubspec.yaml`:

```yaml
dependencies:
  go_router: [latest]
  simple_routes: [latest]
  simple_routes_annotations: [latest]
```

Add `simple_routes_generator` and `build_runner` to your `dev_dependencies`:

```yaml
dev_dependencies:
  build_runner: [latest]
  simple_routes_generator: [latest]
```

## Usage

### Code Generation (Recommended)

Code generation is the recommended way to use `simple_routes`. It automates the creation of route and data classes, ensures type safety, and simplifies data extraction.

#### Defining Routes

Define your routes as "blueprint" classes and annotate them with `@Route`. These are simple abstract classes used as metadata for the generator.

```dart
import 'package:simple_routes/simple_routes.dart';

part 'routes.g.dart';

@Route('/')
abstract class Root {}

@Route('dashboard')
abstract class Dashboard {}
```

#### Routes with Parameters

For routes with path parameters, define them as abstract getters and annotate them with `@Path()`.

```dart
@Route('profile/:userId')
abstract class Profile {
  // If the name of the field matches the path segment, you can omit the name.
  // Otherwise, you must provide the name.
  // ```
  // @Path('userId')
  // String get id;
  // ```
  @Path()
  String get userId;
}
```

#### Child Routes and Inheritance

To define a child route, use the `parent` property in the `@Route` annotation. Child routes automatically inherit all path parameters from their ancestors.

```dart
@Route('edit', parent: Profile)
abstract class ProfileEdit {} // Inherits 'userId' from Profile
```

#### Query Parameters

Use the `@Query()` annotation to define query parameters.

```dart
@Route('search')
abstract class Search {
  @Query('q')
  String get query;
}
```

#### Extra Data

Use the `@Extra()` annotation to pass complex objects via GoRouter's `extra` property.

```dart
@Route('details')
abstract class Details {
  @Extra()
  MyData get data;
}
```

#### Generating Code

Run the build runner to generate your route classes:

```bash
dart run build_runner build
```

The generator creates a `[ClassName]Route` class for navigation and a `[ClassName]RouteData` class for holding parameters.

### Manual Route Definition

If you prefer not to use code generation, you can define your routes manually by extending `SimpleRoute` or `SimpleDataRoute`.

```dart
class UserRoute extends SimpleDataRoute<UserRouteData> {
  const UserRoute() : super('users/:userId');
}

class UserRouteData extends SimpleRouteData {
  const UserRouteData({required this.userId});
  final String userId;

  @override
  Map<String, String> get parameters => {'userId': userId};
}
```

## Navigation

Use the `go` and `push` methods on your route classes to initiate navigation.

```dart
// Simple route
const DashboardRoute().go(context);

// Route with data
const ProfileRoute().go(
  context,
  data: const ProfileRouteData(id: '123'),
);
```

## Advanced Usage

### Extracting Data

Each generated `RouteData` class includes a `fromState` factory constructor for easy extraction from `GoRouterState`:

```dart
builder: (context, state) {
  final data = ProfileRouteData.fromState(state);
  return ProfileScreen(userId: data.id);
}
```

### Route Matching

Use the following methods to determine the current navigation state:

- `isCurrentRoute(state)`: Returns `true` if the route is an exact match for the current location.
- `isParentRoute(state)`: Returns `true` if the route is a parent of the current location.
- `isActive(state)`: Returns `true` if the route is either the current route or a parent.

```dart
final state = GoRouterState.of(context);
if (const ProfileRoute().isActive(state)) {
  // Profile or a child of Profile is active
}
```
