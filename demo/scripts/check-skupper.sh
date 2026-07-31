#!/usr/bin/env bash
# Focused Skupper check (WU4): offline manifest validation, or site status if Kind exists.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

ROOT="$(demo_repo_root)"
SKUPPER_DIR="${ROOT}/demo/skupper"
LEGACY_DIR="${ROOT}/demo/apps/legacy-emoji"
EXPECTED_SKUPPER_CLIENT="${EXPECTED_SKUPPER_CLIENT:-2.2.1}"

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
  printf 'check-skupper: offline manifest validation (no kind-west)\n'
  require_file "${SKUPPER_DIR}/namespace.yaml"
  require_file "${SKUPPER_DIR}/sites/kind-west.yaml"
  require_file "${SKUPPER_DIR}/sites/kind-east.yaml"
  require_file "${SKUPPER_DIR}/sites/podman-edge.yaml"
  require_file "${SKUPPER_DIR}/connectors/voting-attached.yaml"
  require_file "${SKUPPER_DIR}/connectors/voting-binding.yaml"
  require_file "${SKUPPER_DIR}/connectors/legacy-emoji-podman.yaml"
  require_file "${SKUPPER_DIR}/listeners/voting-van.yaml"
  require_file "${SKUPPER_DIR}/listeners/legacy-emoji.yaml"
  require_file "${LEGACY_DIR}/server.py"
  require_file "${LEGACY_DIR}/Containerfile"
  require_file "${LEGACY_DIR}/run.sh"
  require_file "${LEGACY_DIR}/stop.sh"

  assert_grep "west site linkAccess" "linkAccess:\\s*default" "${SKUPPER_DIR}/sites/kind-west.yaml"
  assert_grep "site in skupper NS" "namespace:\\s*skupper" "${SKUPPER_DIR}/sites/kind-west.yaml"
  assert_grep "skupper inject disabled" "linkerd.io/inject:\\s*disabled" "${SKUPPER_DIR}/namespace.yaml"
  assert_grep "voting AttachedConnector" "kind:\\s*AttachedConnector" "${SKUPPER_DIR}/connectors/voting-attached.yaml"
  assert_grep "voting binding routingKey" "routingKey:\\s*voting" "${SKUPPER_DIR}/connectors/voting-binding.yaml"
  assert_grep "voting selector" "selector:\\s*app=voting-svc" "${SKUPPER_DIR}/connectors/voting-attached.yaml"
  assert_grep "voting-van listener" "host:\\s*voting-van" "${SKUPPER_DIR}/listeners/voting-van.yaml"
  assert_grep "legacy-emoji routingKey" "routingKey:\\s*legacy-emoji" "${SKUPPER_DIR}/connectors/legacy-emoji-podman.yaml"
  assert_grep "legacy-emoji listener host" "host:\\s*legacy-emoji" "${SKUPPER_DIR}/listeners/legacy-emoji.yaml"
  assert_grep "podman connector localhost" "host:\\s*127.0.0.1" "${SKUPPER_DIR}/connectors/legacy-emoji-podman.yaml"
  assert_grep "legacy-emoji JSON service" "legacy-emoji" "${LEGACY_DIR}/server.py"
  assert_grep "up.sh wires Skupper" "install_skupper_van|install_skupper" "${ROOT}/demo/scripts/up.sh"
  assert_grep "down.sh tears down Skupper" "teardown_skupper|destroy_skupper" "${ROOT}/demo/scripts/down.sh"
  assert_grep "VERSIONS pins Skupper 2.2.1" "2\\.2\\.1" "${ROOT}/demo/VERSIONS.md"
  assert_grep "VERSIONS pins cloud-provider-kind" "cloud-provider-kind" "${ROOT}/demo/VERSIONS.md"
  assert_grep "Skupper README documents CCM LB" "cloud-provider-kind" "${ROOT}/demo/skupper/README.md"
  assert_grep "README documents Option C localhost" "Option C" "${ROOT}/demo/skupper/README.md"
  require_file "${ROOT}/demo/scripts/redeem-podman-skupper.sh"
  require_file "${ROOT}/demo/scripts/ensure-skupper-localhost-san.sh"
  assert_grep "redeem rewrites Link to localhost" "rewriting Link endpoints" "${ROOT}/demo/scripts/redeem-podman-skupper.sh"
  assert_grep "ensure SAN helper drops controlled" "internal.skupper.io/controlled-" "${ROOT}/demo/scripts/ensure-skupper-localhost-san.sh"

  if ! command -v skupper >/dev/null 2>&1; then
    bad "skupper CLI missing"
  else
    local client
    client="$(skupper version 2>/dev/null | head -n1 | tr -d '[:space:]')"
    if [[ "${client}" == *"${EXPECTED_SKUPPER_CLIENT}"* ]]; then
      ok "skupper client ${EXPECTED_SKUPPER_CLIENT}"
    else
      bad "skupper client want ${EXPECTED_SKUPPER_CLIENT}, got ${client:-unknown}"
    fi
    if skupper site generate check-offline --enable-link-access -n skupper >/dev/null 2>&1; then
      ok "skupper site generate emits Site CR"
    else
      bad "skupper site generate failed"
    fi
  fi
}

live_check() {
  local cluster="kind-west"
  local ctx
  ctx="$(demo_kind_context "${cluster}")"
  printf 'check-skupper: live site status on %s\n' "${ctx}"
  if skupper --context "${ctx}" -n skupper site status; then
    ok "skupper site status ${ctx}"
  else
    bad "skupper site status ${ctx}"
  fi
  if kubectl --context "${ctx}" -n skupper get site,listener,attachedconnectorbinding >/dev/null 2>&1; then
    ok "west skupper CRs present"
  else
    bad "west skupper CRs missing"
  fi
  if kubectl --context "${ctx}" -n emojivoto get attachedconnector voting >/dev/null 2>&1; then
    ok "voting AttachedConnector present"
  else
    bad "voting AttachedConnector missing"
  fi
}

main() {
  if demo_kind_exists "kind-west"; then
    live_check
  else
    offline_validate
  fi
  printf '\nSkupper check: %s passed, %s failed\n' "${pass}" "${fail}"
  if [[ "${fail}" -ne 0 ]]; then
    exit 1
  fi
}

main "$@"
