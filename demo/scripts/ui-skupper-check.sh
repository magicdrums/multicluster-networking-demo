#!/usr/bin/env bash
# Phase C validation — curl -k -u …; echo ACCESS_URL (+ auth hint); fail if down.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

PREFERRED_PORT="${UI_SKUPPER_PORT:-8443}"
CURL_TIMEOUT="${UI_SKUPPER_CURL_TIMEOUT:-5}"
URL_FILE_NAME="ui-skupper-access-url"
AUTH_FILE_NAME="ui-skupper-basic-auth"
PID_NAME="ui-skupper-observer"

demo_ui_access_url_file() {
  printf '%s/%s\n' "$(demo_ui_run_dir)" "${URL_FILE_NAME}"
}

demo_ui_auth_file() {
  printf '%s/%s\n' "$(demo_ui_run_dir)" "${AUTH_FILE_NAME}"
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
  printf 'https://127.0.0.1:%s/\n' "${PREFERRED_PORT}"
}

load_basic_auth() {
  local authfile="$1"
  local user="" pass=""
  if [[ ! -f "${authfile}" ]]; then
    printf 'error: missing basic-auth file %s (run make ui-skupper first)\n' "${authfile}" >&2
    return 1
  fi
  # shellcheck disable=SC1090
  source "${authfile}"
  user="${BASIC_AUTH_USER:-}"
  pass="${BASIC_AUTH_PASSWORD:-}"
  if [[ -z "${user}" || -z "${pass}" ]]; then
    printf 'error: %s missing BASIC_AUTH_USER / BASIC_AUTH_PASSWORD\n' "${authfile}" >&2
    return 1
  fi
  printf '%s\n%s\n' "${user}" "${pass}"
}

if [[ -n "${CLUSTER:-}" ]]; then
  demo_require_allowlisted "${CLUSTER}" "target" || exit 1
fi

access_url="$(resolve_access_url)"
auth_file="$(demo_ui_auth_file)"
auth_lines="$(load_basic_auth "${auth_file}")" || exit 1
auth_user="$(sed -n '1p' <<<"${auth_lines}")"
auth_pass="$(sed -n '2p' <<<"${auth_lines}")"

demo_print_access_url "phase C — Skupper network-observer check" "${access_url}" \
  "probe: curl -k -u <user>:<pass> ${access_url}" \
  "BASIC_AUTH_FILE=${auth_file}" \
  "hint: credentials printed once by make ui-skupper (never commit demo/.run/)"

code="$(curl -k -sS -o /dev/null -w '%{http_code}' --connect-timeout "${CURL_TIMEOUT}" \
  --max-time "${CURL_TIMEOUT}" -u "${auth_user}:${auth_pass}" "${access_url}" 2>/dev/null || true)"
case "${code}" in
  200|301|302|307|308)
    printf 'ok: network-observer reachable at %s (HTTP %s)\n' "${access_url}" "${code}"
    ;;
  *)
    pidfile="$(demo_ui_pidfile "${PID_NAME}")"
    printf 'error: network-observer not reachable at %s (HTTP %s)\n' "${access_url}" "${code:-none}" >&2
    printf 'hint: run make ui-skupper; pidfile=%s auth=%s\n' "${pidfile}" "${auth_file}" >&2
    exit 1
    ;;
esac

printf 'ACCESS_URL=%s\n' "${access_url}"
printf 'BASIC_AUTH_FILE=%s\n' "${auth_file}"
printf 'auth: use BASIC_AUTH_USER / BASIC_AUTH_PASSWORD from %s (printed once by ui-skupper)\n' \
  "${auth_file}"
