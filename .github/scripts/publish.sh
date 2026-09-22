#!/usr/bin/env bash
set -euo pipefail

# Usage: publish.sh --scope=<package> [--scope=<package> ...]
# Validates the selected packages with a dry run before publishing them for
# real, so a bad pubspec fails before anything reaches pub.dev.

if [ "$#" -eq 0 ]; then
  echo "::error::publish.sh requires at least one --scope argument"
  exit 1
fi

melos publish "$@" --no-published --dry-run --yes
melos publish "$@" --no-published --no-dry-run --yes
