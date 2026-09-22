#!/usr/bin/env bash
set -euo pipefail

# Usage: wait-for-live.sh <package-name>
# Polls pub.dev until the package's current local version is resolvable,
# so a dependent package's `dart pub publish` doesn't fail against a
# version pub.dev hasn't indexed yet.

name="$1"
dir="packages/$name"
version="$(sed -n 's/^version: *//p' "$dir/pubspec.yaml")"

# set -u doesn't catch an empty capture, and an empty version matches nothing
# on pub.dev, so an unguarded parse miss polls the full timeout and then blames
# pub.dev for a malformed pubspec.
if [ -z "$version" ]; then
  echo "::error::Could not parse a version from $dir/pubspec.yaml"
  exit 1
fi

is_live() {
  curl -fsS "https://pub.dev/api/packages/$name" \
    | jq -e --arg v "$version" 'any(.versions[]?.version; . == $v)' > /dev/null
}

attempts=30
interval=10

for i in $(seq 1 "$attempts"); do
  if is_live; then
    echo "$name@$version is live"
    exit 0
  fi
  if [ "$i" -eq 1 ]; then
    echo "Waiting for $name@$version to appear on pub.dev..."
  fi
  if [ "$i" -lt "$attempts" ]; then
    sleep "$interval"
  fi
done

echo "::error::Timed out waiting for $name@$version to appear on pub.dev after $((attempts * interval))s"
exit 1
