#!/usr/bin/env bash
# Phase B — opt-in Linkerd Viz on kind-west only. Not part of make up.
# Installs Viz (bundled Prometheus OK), port-forwards prefer 50750, prints ACCESS_URL.
# Never uses CCM LB. Does not change skip-inject / N-S namespaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

LINKERD_CLIENT_PIN="${LINKERD_CLIENT_PIN:-edge-26.6.3}"
PREFERRED_PORT="${UI_LINKERD_PORT:-50750}"
VIZ_WAIT="${UI_LINKERD_WAIT:-5m}"
PID_NAME="ui-linkerd-dashboard"
URL_FILE_NAME="ui-linkerd-access-url"

warn_linkerd_client_pin() {
  local client
  client="$(linkerd version --client --short 2>/dev/null || true)"
  if [[ "${client}" != "${LINKERD_CLIENT_PIN}" ]]; then
    printf 'ui-linkerd: warn: linkerd client is %q; pin is %s (see demo/VERSIONS.md)\n' \
      "${client:-unknown}" "${LINKERD_CLIENT_PIN}" >&2
  fi
}

demo_ui_access_url_file() {
  printf '%s/%s\n' "$(demo_ui_run_dir)" "${URL_FILE_NAME}"
}

stop_existing_dashboard() {
  local pidfile pid
  pidfile="$(demo_ui_pidfile "${PID_NAME}")"
  if [[ ! -f "${pidfile}" ]]; then
    return 0
  fi
  pid="$(tr -d '[:space:]' <"${pidfile}" || true)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    printf 'ui-linkerd: stopping previous dashboard pid %s\n' "${pid}"
    kill "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
  fi
  rm -f "${pidfile}"
}

cluster="$(demo_ui_resolve_cluster_or_abort)" || exit 1
if [[ "${cluster}" != "kind-west" ]]; then
  printf 'error: Phase B Linkerd Viz is west-only (got %q); unset CLUSTER or use kind-west\n' \
    "${cluster}" >&2
  exit 1
fi

if ! command -v linkerd >/dev/null 2>&1; then
  printf 'error: linkerd CLI not found (need %s)\n' "${LINKERD_CLIENT_PIN}" >&2
  exit 1
fi
if ! command -v kubectl >/dev/null 2>&1; then
  printf 'error: kubectl not found\n' >&2
  exit 1
fi

warn_linkerd_client_pin

if ! demo_kind_exists "${cluster}"; then
  printf 'error: Kind cluster %s not present (run make up first)\n' "${cluster}" >&2
  exit 1
fi

ctx="$(demo_kind_context "${cluster}")"
demo_ui_ensure_run_dir >/dev/null

printf 'ui-linkerd: installing Linkerd Viz on %s (context %s, CLI pin %s)\n' \
  "${cluster}" "${ctx}" "${LINKERD_CLIENT_PIN}"
linkerd --context "${ctx}" viz install \
  | kubectl --context "${ctx}" apply -f -

printf 'ui-linkerd: waiting for Viz (%s)\n' "${VIZ_WAIT}"
if ! linkerd --context "${ctx}" viz check --wait "${VIZ_WAIT}"; then
  printf 'error: linkerd viz check failed on %s\n' "${ctx}" >&2
  exit 1
fi

port="$(demo_pick_free_port "${PREFERRED_PORT}")" || exit 1
access_url="http://127.0.0.1:${port}/"

stop_existing_dashboard

printf 'ui-linkerd: starting dashboard PF on 127.0.0.1:%s (no CCM LB)\n' "${port}"
# --show url: print URLs, do not open a browser. Blocks until killed — background it.
linkerd --context "${ctx}" viz dashboard \
  --address 127.0.0.1 \
  --port "${port}" \
  --show url \
  --wait "${VIZ_WAIT}" \
  >"$(demo_ui_run_dir)/ui-linkerd-dashboard.log" 2>&1 &
dash_pid=$!
printf '%s\n' "${dash_pid}" >"$(demo_ui_pidfile "${PID_NAME}")"
printf '%s\n' "${access_url}" >"$(demo_ui_access_url_file)"

# Wait until HTTP responds (dashboard boots after PF).
ready=0
for _ in $(seq 1 60); do
  code="$(curl -sS -o /dev/null -w '%{http_code}' --connect-timeout 2 --max-time 3 \
    "${access_url}" 2>/dev/null || true)"
  case "${code}" in
    200|301|302|307|308) ready=1; break ;;
  esac
  if ! kill -0 "${dash_pid}" 2>/dev/null; then
    printf 'error: dashboard process exited early; see %s\n' \
      "$(demo_ui_run_dir)/ui-linkerd-dashboard.log" >&2
    exit 1
  fi
  sleep 1
done

if [[ "${ready}" -ne 1 ]]; then
  printf 'error: Viz dashboard not reachable at %s\n' "${access_url}" >&2
  exit 1
fi

demo_print_access_url "phase B — Linkerd Viz" "${access_url}" \
  "cluster: ${cluster} (west-only)" \
  "access: localhost port-forward only — never CCM LB" \
  "validate: make ui-linkerd-check" \
  "teardown PF: make ui-down"
