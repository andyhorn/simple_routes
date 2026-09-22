#!/usr/bin/env bash
set -euo pipefail

# Fails fast if the GCP-issued identity token wasn't added as pub.dev
# credentials, instead of letting `dart pub publish` fall back to
# interactive OAuth and hang in CI.
if ! dart pub token list | grep -q 'https://pub.dev'; then
  echo "::error::No pub.dev credentials found. Check that GCP_WIF_PROVIDER/PUB_SA_EMAIL are set and that the service account is registered as a publisher for each package on pub.dev."
  exit 1
fi
