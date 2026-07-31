#!/usr/bin/env bash
# Tear down Phase B/C UI surfaces only. Phase A is docs/hosts (reminder only).
# Stub body for WU1; full PF/uninstall in WU3. Never touches kind-cluster or CCM ports.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

if [[ -n "${CLUSTER:-}" ]]; then
  demo_require_allowlisted "${CLUSTER}" "target" || exit 1
fi

printf 'ui-down: Phase A — no process teardown (hosts/docs only)\n'
printf 'ui-down: Phase B/C teardown stub — full stop/uninstall lands in PR3\n'
printf 'ui-down: CCM/Gateway ports 8080/8081/18080/18081/45671/55671 left untouched\n'
