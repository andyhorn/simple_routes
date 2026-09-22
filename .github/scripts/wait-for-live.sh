#!/usr/bin/env bash
set -euo pipefail

# Usage: wait-for-live.sh <package-name>
# Polls pub.dev until the package's current local version is resolvable,
# so a dependent package's `dart pub publish` doesn't fail against a
# version pub.dev hasn't indexed yet.

name="$1"
dir="packages/$name"
version="$(sed -n 's/^version: *//p' "$dir/pubspec.yaml")"

is_live() {
  curl -fsS "https://pub.dev/api/packages/$name" \
    | jq -e --arg v "$version" 'any(.versions[]?.version; . == $v)' > /dev/null
}

if is_live; then
  echo "$name@$version is live"
  exit 0
fi

echo "Waiting for $name@$version to appear on pub.dev..."
for i in $(seq 1 30); do
  if is_live; then
    echo "$name@$version is live"
    exit 0
  fi
  if [ "$i" -eq 30 ]; then
    echo "::error::Timed out waiting for $name@$version to appear on pub.dev"
    exit 1
  fi
  sleep 10
done
