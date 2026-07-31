#!/usr/bin/env bash
# Shared helpers for opt-in talk UI scripts (Phase A/B/C).
# Reserved ports must never be used for dashboard port-forwards.
# shellcheck source=common.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

# Gateway / CCM / Skupper host ports — never for UI PF.
DEMO_UI_RESERVED_PORTS=(8080 8081 18080 18081 45671 55671)

demo_ui_run_dir() {
  local root
  root="$(demo_repo_root)"
  printf '%s\n' "${root}/demo/.run"
}

demo_ui_ensure_run_dir() {
  local d
  d="$(demo_ui_run_dir)"
  mkdir -p "${d}"
  printf '%s\n' "${d}"
}

demo_ui_pidfile() {
  local name="$1"
  printf '%s/%s.pid\n' "$(demo_ui_run_dir)" "${name}"
}

demo_ui_is_reserved_port() {
  local port="${1:-}"
  local p
  for p in "${DEMO_UI_RESERVED_PORTS[@]}"; do
    if [[ "${port}" == "${p}" ]]; then
      return 0
    fi
  done
  return 1
}

demo_ui_refuse_reserved_port() {
  local port="${1:-}"
  if [[ -z "${port}" ]]; then
    printf 'error: empty port is not allowed\n' >&2
    return 1
  fi
  if ! [[ "${port}" =~ ^[0-9]+$ ]]; then
    printf 'error: invalid port %q\n' "${port}" >&2
    return 1
  fi
  if demo_ui_is_reserved_port "${port}"; then
    printf 'error: refusing reserved demo port %s (CCM/Gateway/Skupper: 8080 8081 18080 18081 45671 55671)\n' \
      "${port}" >&2
    return 1
  fi
}

# Prefer preferred_port when free and not reserved; otherwise scan upward.
# Usage: demo_pick_free_port [preferred_port] [start] [end]
demo_pick_free_port() {
  local preferred="${1:-}"
  local start="${2:-50000}"
  local end="${3:-50999}"
  local candidate

  if [[ -n "${preferred}" ]]; then
    demo_ui_refuse_reserved_port "${preferred}" || return 1
    if ! demo_ui_port_in_use "${preferred}"; then
      printf '%s\n' "${preferred}"
      return 0
    fi
  fi

  candidate="${start}"
  while (( candidate <= end )); do
    if ! demo_ui_is_reserved_port "${candidate}" && ! demo_ui_port_in_use "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
    candidate=$((candidate + 1))
  done
  printf 'error: no free port in range %s-%s (skipping reserved demo ports)\n' "${start}" "${end}" >&2
  return 1
}

demo_ui_port_in_use() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltn 2>/dev/null | grep -qE ":${port}\\s"
    return $?
  fi
  if command -v lsof >/dev/null 2>&1; then
    lsof -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi
  # Best-effort: try binding with bash /dev/tcp probe via timeout+curl not available;
  # assume free if we cannot probe.
  return 1
}

# Print speaker-visible banner. Usage: demo_print_access_url <phase-label> <url> [extra lines…]
demo_print_access_url() {
  local phase="${1:-}"
  local url="${2:-}"
  shift 2 || true
  printf '\n=== Talk UI (%s) ===\n' "${phase}"
  printf 'ACCESS_URL=%s\n' "${url}"
  local line
  for line in "$@"; do
    printf '%s\n' "${line}"
  done
  printf '\n'
}

# Validate CLUSTER when set (ui helpers that touch clusters). Never kind-cluster.
demo_ui_resolve_cluster_or_abort() {
  if [[ -n "${CLUSTER:-}" ]]; then
    demo_require_allowlisted "${CLUSTER}" "target" || return 1
    printf '%s\n' "${CLUSTER}"
    return 0
  fi
  printf '%s\n' "kind-west"
}
