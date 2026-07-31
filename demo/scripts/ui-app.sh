#!/usr/bin/env bash
# Phase A — print hosts hint + ACCESS_URL for emojivoto browser access.
# Does not install ingress. Ban bare IP-without-Host paths in output.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

WEST_URL="http://emojivoto.demo.local:8080/"
EAST_URL="http://emojivoto.demo.local:8081/"
SHOW_EAST="${UI_APP_SHOW_EAST:-1}"

if [[ -n "${CLUSTER:-}" ]]; then
  demo_require_allowlisted "${CLUSTER}" "target" || exit 1
fi

demo_print_access_url "phase A — app" "${WEST_URL}" \
  "hosts: add '127.0.0.1 emojivoto.demo.local' to /etc/hosts (once)" \
  "browser: open ${WEST_URL} (hostname required — not bare http://127.0.0.1:8080/ without Host)" \
  "optional east Gateway: ${EAST_URL}" \
  "validate: make ui-app-check"

if [[ "${SHOW_EAST}" == "1" ]]; then
  printf 'ACCESS_URL_EAST=%s\n' "${EAST_URL}"
fi

if [[ "${UI_APP_OPEN:-0}" == "1" ]] && command -v xdg-open >/dev/null 2>&1; then
  xdg-open "${WEST_URL}" >/dev/null 2>&1 || true
fi
