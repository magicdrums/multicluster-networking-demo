#!/usr/bin/env bash
# Focused east-west check (WU3): offline manifest validation, or linkerd check if Kind exists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

ROOT="$(demo_repo_root)"
LINKERD_DIR="${ROOT}/demo/linkerd"
APP_DIR="${ROOT}/demo/apps/emojivoto"
GATEWAY_DIR="${ROOT}/demo/gateway"
EXPECTED_LINKERD_CLIENT="${EXPECTED_LINKERD_CLIENT:-edge-26.6.3}"

pass=0
fail=0

ok() {
  printf 'PASS: %s\n' "$1"
  pass=$((pass + 1))
}

bad() {
  printf 'FAIL: %s\n' "$1"
  fail=$((fail + 1))
}

require_file() {
  local f="$1"
  if [[ -f "${f}" ]]; then
    ok "present ${f#${ROOT}/}"
  else
    bad "missing ${f#${ROOT}/}"
  fi
}

assert_grep() {
  local desc="$1"
  local pattern="$2"
  local file="$3"
  if grep -qE "${pattern}" "${file}"; then
    ok "${desc}"
  else
    bad "${desc} (pattern /${pattern}/ in ${file#${ROOT}/})"
  fi
}

offline_validate() {
  printf 'check-east-west: offline manifest validation (no kind-west)\n'
  require_file "${LINKERD_DIR}/values.yaml"
  require_file "${LINKERD_DIR}/skip-namespaces.yaml"
  require_file "${APP_DIR}/namespace.yaml"
  require_file "${APP_DIR}/west.yaml"
  require_file "${APP_DIR}/east.yaml"

  assert_grep "proxyInit.runAsRoot in values" "runAsRoot:\\s*true" "${LINKERD_DIR}/values.yaml"
  assert_grep "skip kuadrant-coredns" "name:\\s*kuadrant-coredns" "${LINKERD_DIR}/skip-namespaces.yaml"
  assert_grep "emojivoto inject enabled" "linkerd.io/inject:\\s*enabled" "${APP_DIR}/namespace.yaml"
  assert_grep "west has web deployment" "name:\\s*web$" "${APP_DIR}/west.yaml"
  assert_grep "west has voting" "name:\\s*voting$" "${APP_DIR}/west.yaml"
  assert_grep "west has emoji" "name:\\s*emoji$" "${APP_DIR}/west.yaml"
  assert_grep "east has voting only role" "voting-replica" "${APP_DIR}/east.yaml"
  assert_grep "HTTPRoute → web-svc" "name:\\s*web-svc" "${GATEWAY_DIR}/gateway.yaml"
  assert_grep "gateway-system skip inject" "linkerd.io/inject:\\s*disabled" "${GATEWAY_DIR}/gateway.yaml"

  if ! command -v linkerd >/dev/null 2>&1; then
    bad "linkerd CLI missing"
  else
    local client
    client="$(linkerd version --client --short 2>/dev/null || linkerd version --client 2>/dev/null | awk '/Client/{print $NF}')"
    if [[ "${client}" == *"${EXPECTED_LINKERD_CLIENT}"* ]]; then
      ok "linkerd client ${EXPECTED_LINKERD_CLIENT}"
    else
      bad "linkerd client want ${EXPECTED_LINKERD_CLIENT}, got ${client:-unknown}"
    fi
    # Pure text install (no cluster) — proves CLI can emit CRDs + CP with our values.
    if linkerd install --crds --ignore-cluster >/dev/null 2>&1 \
      && linkerd install --ignore-cluster -f "${LINKERD_DIR}/values.yaml" >/dev/null 2>&1; then
      ok "linkerd install --ignore-cluster emits manifests with values.yaml"
    else
      bad "linkerd install --ignore-cluster failed"
    fi
  fi
}

live_check() {
  local cluster="kind-west"
  local ctx
  ctx="$(demo_kind_context "${cluster}")"
  printf 'check-east-west: live linkerd check on %s\n' "${ctx}"
  if linkerd --context "${ctx}" check; then
    ok "linkerd check ${ctx}"
  else
    bad "linkerd check ${ctx}"
  fi
  if kubectl --context "${ctx}" -n emojivoto get deploy web emoji voting >/dev/null 2>&1; then
    ok "west emojivoto deployments present"
  else
    bad "west emojivoto deployments missing"
  fi
}

main() {
  if demo_kind_exists "kind-west"; then
    live_check
  else
    offline_validate
  fi
  printf '\nEast-west check: %s passed, %s failed\n' "${pass}" "${fail}"
  if [[ "${fail}" -ne 0 ]]; then
    exit 1
  fi
}

main "$@"
