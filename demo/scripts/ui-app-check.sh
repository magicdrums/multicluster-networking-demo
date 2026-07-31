#!/usr/bin/env bash
# Phase A validation — hostname curl to west (and optional east). Expect 200 or 429.
# Prints the same ACCESS_URL contract as ui-app.sh. Fails if the app is down.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

WEST_URL="http://emojivoto.demo.local:8080/"
EAST_URL="http://emojivoto.demo.local:8081/"
CHECK_EAST="${UI_APP_CHECK_EAST:-0}"
CURL_TIMEOUT="${UI_APP_CURL_TIMEOUT:-5}"

if [[ -n "${CLUSTER:-}" ]]; then
  demo_require_allowlisted "${CLUSTER}" "target" || exit 1
fi

probe_hostname() {
  local url="$1"
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout "${CURL_TIMEOUT}" --max-time "${CURL_TIMEOUT}" \
    "${url}" 2>/dev/null || true)"
  case "${code}" in
    200|429) return 0 ;;
    *) return 1 ;;
  esac
}

demo_print_access_url "phase A — app check" "${WEST_URL}" \
  "probe: HTTP GET ${WEST_URL} (hostname — not bare IP without Host)" \
  "expect: 200 or 429 after make up + hosts"

if ! probe_hostname "${WEST_URL}"; then
  printf 'error: west app not reachable at %s (need make up + /etc/hosts emojivoto.demo.local → 127.0.0.1)\n' \
    "${WEST_URL}" >&2
  exit 1
fi
printf 'ok: west %s reachable (200/429)\n' "${WEST_URL}"

if [[ "${CHECK_EAST}" == "1" ]]; then
  printf 'ACCESS_URL_EAST=%s\n' "${EAST_URL}"
  if ! probe_hostname "${EAST_URL}"; then
    printf 'error: east app not reachable at %s\n' "${EAST_URL}" >&2
    exit 1
  fi
  printf 'ok: east %s reachable (200/429)\n' "${EAST_URL}"
fi
