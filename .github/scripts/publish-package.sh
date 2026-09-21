#!/usr/bin/env bash
set -euo pipefail

# Each run is triggered by exactly one package's tag (e.g. "simple_routes-v3.0.1").
# Scoping to that package - instead of looping over all packages on every run -
# is what stops release-please's simultaneous tag pushes from spawning multiple
# runs that each redundantly try to publish every package.
tag="${GITHUB_REF#refs/tags/}"
name="${tag%-v*}"

case "$name" in
  simple_routes | simple_routes_generator)
    dependency="simple_routes_annotations"
    ;;
  simple_routes_annotations)
    dependency=""
    ;;
  *)
    echo "::error::Unrecognized package in tag '$tag'"
    exit 1
    ;;
esac

is_live() {
  local pkg="$1" version="$2"
  curl -fsS "https://pub.dev/api/packages/$pkg" \
    | jq -e --arg v "$version" 'any(.versions[]?.version; . == $v)' > /dev/null
}

wait_for_live() {
  local pkg="$1" version="$2"
  echo "Waiting for $pkg@$version to appear on pub.dev..."
  for i in $(seq 1 30); do
    if is_live "$pkg" "$version"; then
      echo "$pkg@$version is live"
      return 0
    fi
    if [ "$i" -eq 30 ]; then
      echo "::error::Timed out waiting for $pkg@$version to appear on pub.dev"
      exit 1
    fi
    sleep 10
  done
}

dir="packages/$name"
version="$(sed -n 's/^version: *//p' "$dir/pubspec.yaml")"

if is_live "$name" "$version"; then
  echo "$name@$version is already on pub.dev, skipping"
  exit 0
fi

if [ -n "$dependency" ]; then
  dep_dir="packages/$dependency"
  dep_version="$(sed -n 's/^version: *//p' "$dep_dir/pubspec.yaml")"
  if ! is_live "$dependency" "$dep_version"; then
    wait_for_live "$dependency" "$dep_version"
  fi
fi

echo "Publishing $name@$version"
(cd "$dir" && timeout 5m dart pub publish --dry-run)
(cd "$dir" && timeout 5m dart pub publish --force)
wait_for_live "$name" "$version"
