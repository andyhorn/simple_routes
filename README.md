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

This project uses [FVM](https://fvm.app/) to pin Flutter and [Melos](https://melos.invertase.dev/) to manage the monorepo.

To get started, install the configured Flutter SDK and Melos:

```bash
fvm install
fvm flutter pub global activate melos
```

Then, bootstrap the workspace:

```bash
fvm flutter pub global run melos bootstrap
```

## Common Scripts

- `fvm flutter pub global run melos run analyze`: Run analysis for all packages.
- `fvm flutter pub global run melos run test`: Run tests for all packages.
- `fvm flutter pub global run melos run format`: Format all packages.
- `fvm flutter pub global run melos run generate`: Run code generation (build_runner) for packages that use it.
