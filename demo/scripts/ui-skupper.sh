#!/usr/bin/env bash
# Phase C stub (WU3) — Skupper network-observer opt-in. Not part of make up.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

if [[ -n "${CLUSTER:-}" ]]; then
  demo_require_allowlisted "${CLUSTER}" "target" || exit 1
fi

printf 'ui-skupper: stub — Phase C (network-observer) lands in PR3\n' >&2
printf 'hint: prefer HTTPS :8443; reserved CCM ports are refused by ui-common.sh\n' >&2
exit 0
