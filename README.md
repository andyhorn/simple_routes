# Simple Routes (Workspace)

This is the Melos workspace for the `simple_routes` package.

## Structure

```text
packages/
  simple_routes/             - The core simple_routes package
  simple_routes_annotations/ - Annotations for code generation
  simple_routes_generator/   - Code generator for simple_routes
```

## Getting Started

This project uses [Melos](https://melos.invertase.dev/) to manage the monorepo.

To get started, install Melos:

```bash
dart pub global activate melos
```

Then, bootstrap the workspace:

```bash
melos bootstrap
```

## Common Scripts

- `melos run analyze`: Run analysis for all packages.
- `melos run test`: Run tests for all packages.
- `melos run format`: Format all packages.
- `melos run generate`: Run code generation (build_runner) for packages that use it.
