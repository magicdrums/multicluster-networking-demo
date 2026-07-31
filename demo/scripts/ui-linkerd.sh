#!/usr/bin/env bash
# Phase B stub (WU2) — Linkerd Viz opt-in. Not part of make up.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

if [[ -n "${CLUSTER:-}" ]]; then
  demo_require_allowlisted "${CLUSTER}" "target" || exit 1
fi

printf 'ui-linkerd: stub — Phase B (Linkerd Viz) lands in PR2\n' >&2
printf 'hint: prefer free port 50750; reserved CCM ports are refused by ui-common.sh\n' >&2
exit 0
