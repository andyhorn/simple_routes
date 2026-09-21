#!/usr/bin/env bash
set -euo pipefail

if [ -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ] || [ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" ]; then
  echo "::error::GitHub OIDC is unavailable. Keep 'permissions: id-token: write' on this job and configure 'Automated publishing' on pub.dev for each package (repository andyhorn/simple_routes, workflow publish.yaml)."
  exit 1
fi
