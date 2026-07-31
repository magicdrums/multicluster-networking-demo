#!/usr/bin/env bash
# Tear down Phase B/C UI surfaces only. Phase A is docs/hosts (reminder only).
# WU2: stop Viz dashboard PF (pidfile). Full Viz/observer uninstall lands in WU3.
# Never touches kind-cluster or CCM ports.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/ui-common.sh"

if [[ -n "${CLUSTER:-}" ]]; then
  demo_require_allowlisted "${CLUSTER}" "target" || exit 1
fi

printf 'ui-down: Phase A — no process teardown (hosts/docs only)\n'

# --- Phase B: stop recorded Viz dashboard PF ---
viz_pidfile="$(demo_ui_pidfile ui-linkerd-dashboard)"
viz_urlfile="$(demo_ui_run_dir)/ui-linkerd-access-url"
viz_logfile="$(demo_ui_run_dir)/ui-linkerd-dashboard.log"
stopped_viz=0
if [[ -f "${viz_pidfile}" ]]; then
  pid="$(tr -d '[:space:]' <"${viz_pidfile}" || true)"
  if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}" 2>/dev/null || true
    wait "${pid}" 2>/dev/null || true
    printf 'ui-down: stopped Linkerd Viz dashboard PF (pid %s)\n' "${pid}"
    stopped_viz=1
  else
    printf 'ui-down: Viz dashboard pidfile stale (pid %s) — cleaned\n' "${pid:-empty}"
  fi
  rm -f "${viz_pidfile}"
fi
rm -f "${viz_urlfile}"
if [[ -f "${viz_logfile}" ]]; then
  rm -f "${viz_logfile}"
fi
if [[ "${stopped_viz}" -eq 0 ]]; then
  printf 'ui-down: Phase B — no live Viz PF to stop (uninstall Viz NS deferred to PR3)\n'
fi

printf 'ui-down: Phase C teardown stub — observer stop/uninstall lands in PR3\n'
printf 'ui-down: CCM/Gateway ports 8080/8081/18080/18081/45671/55671 left untouched\n'
