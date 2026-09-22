#!/usr/bin/env bash
set -euo pipefail

# Fails fast if the GCP-issued identity token wasn't added as pub.dev
# credentials, instead of letting `dart pub publish` fall back to
# interactive OAuth and hang in CI.
if ! dart pub token list | grep -q 'https://pub.dev'; then
  echo "::error::No pub.dev credentials found. Check: the simple_routes vault's 'gcp' item still has gcp_wif_provider and pub_sa_email fields; the workload identity pool grants this repository access; and the service account is a registered publisher for each package on pub.dev."
  exit 1
fi
