#!/usr/bin/env bash
# Phase B validation — confirm Viz on west; print final ACCESS_URL; fail if down.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

PREFERRED_PORT="${UI_LINKERD_PORT:-50750}"
CURL_TIMEOUT="${UI_LINKERD_CURL_TIMEOUT:-5}"
URL_FILE_NAME="ui-linkerd-access-url"
PID_NAME="ui-linkerd-dashboard"

demo_ui_access_url_file() {
  printf '%s/%s\n' "$(demo_ui_run_dir)" "${URL_FILE_NAME}"
}

resolve_access_url() {
  local urlfile url
  urlfile="$(demo_ui_access_url_file)"
  if [[ -f "${urlfile}" ]]; then
    url="$(tr -d '[:space:]' <"${urlfile}" || true)"
    if [[ -n "${url}" ]]; then
      printf '%s\n' "${url}"
      return 0
    fi
  fi
  # Fallback: prefer preferred port if listening, else reported contract default.
  if demo_ui_port_in_use "${PREFERRED_PORT}"; then
    printf 'http://127.0.0.1:%s/\n' "${PREFERRED_PORT}"
    return 0
  fi
  printf 'http://127.0.0.1:%s/\n' "${PREFERRED_PORT}"
}

cluster="$(demo_ui_resolve_cluster_or_abort)" || exit 1
if [[ "${cluster}" != "kind-west" ]]; then
  printf 'error: Phase B Linkerd Viz is west-only (got %q); unset CLUSTER or use kind-west\n' \
    "${cluster}" >&2
  exit 1
fi

if ! command -v linkerd >/dev/null 2>&1; then
  printf 'error: linkerd CLI not found\n' >&2
  exit 1
fi

access_url="$(resolve_access_url)"
ctx="$(demo_kind_context "${cluster}")"

demo_print_access_url "phase B — Linkerd Viz check" "${access_url}" \
  "probe: linkerd viz check + HTTP GET ${access_url}" \
  "expect: Viz healthy after make ui-linkerd"

if ! demo_kind_exists "${cluster}"; then
  printf 'error: Kind cluster %s not present\n' "${cluster}" >&2
  exit 1
fi

if ! linkerd --context "${ctx}" viz check; then
  printf 'error: linkerd viz check failed on %s\n' "${ctx}" >&2
  exit 1
fi
printf 'ok: linkerd viz check passed on %s\n' "${ctx}"

code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout "${CURL_TIMEOUT}" \
  --max-time "${CURL_TIMEOUT}" "${access_url}" 2>/dev/null || true)"
case "${code}" in
  200|301|302|307|308)
    printf 'ok: Viz dashboard reachable at %s (HTTP %s)\n' "${access_url}" "${code}"
    ;;
  *)
    pidfile="$(demo_ui_pidfile "${PID_NAME}")"
    printf 'error: Viz dashboard not reachable at %s (HTTP %s)\n' "${access_url}" "${code:-none}" >&2
    printf 'hint: run make ui-linkerd; pidfile=%s\n' "${pidfile}" >&2
    exit 1
    ;;
esac

# Re-echo contract line for speaker scripts that grep ACCESS_URL=
printf 'ACCESS_URL=%s\n' "${access_url}"
