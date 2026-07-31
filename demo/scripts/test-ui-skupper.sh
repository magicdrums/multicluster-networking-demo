#!/usr/bin/env bash
# Focused offline suite for demo-product-uis WU3 (Phase C observer + teardown threats).
# Includes threat-matrix RED checks from design: CCM ports, bad CLUSTER, up has no ui-, PF pidfiles.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MAKEFILE="${ROOT}/Makefile"
VERSIONS="${ROOT}/demo/VERSIONS.md"
SKUPPER_README="${ROOT}/demo/skupper/README.md"
VALUES="${ROOT}/demo/skupper/network-observer/values.yaml"
CHECK_SKUPPER="${SCRIPT_DIR}/check-skupper.sh"
UI_COMMON="${SCRIPT_DIR}/ui-common.sh"
UI_SKUPPER="${SCRIPT_DIR}/ui-skupper.sh"
UI_CHECK="${SCRIPT_DIR}/ui-skupper-check.sh"
UI_DOWN="${SCRIPT_DIR}/ui-down.sh"
DOWN_SH="${SCRIPT_DIR}/down.sh"
UI_APP="${SCRIPT_DIR}/ui-app.sh"
UI_LINKERD="${SCRIPT_DIR}/ui-linkerd.sh"

pass=0
fail=0

assert_ok() {
  local desc="$1"
  shift
  local out rc
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  if [[ "${rc}" -ne 0 ]]; then
    printf 'FAIL: %s (exit %s)\n' "${desc}" "${rc}"
    printf '  output: %s\n' "${out}"
    fail=$((fail + 1))
    return
  fi
  printf 'PASS: %s\n' "${desc}"
  pass=$((pass + 1))
}

assert_fails_with() {
  local desc="$1"
  local needle="$2"
  shift 2
  local out rc
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  if [[ "${rc}" -eq 0 ]]; then
    printf 'FAIL: %s (expected non-zero exit)\n' "${desc}"
    printf '  output: %s\n' "${out}"
    fail=$((fail + 1))
    return
  fi
  if ! grep -qiE "${needle}" <<<"${out}"; then
    printf 'FAIL: %s (exit %s but missing /%s/)\n' "${desc}" "${rc}" "${needle}"
    printf '  output: %s\n' "${out}"
    fail=$((fail + 1))
    return
  fi
  printf 'PASS: %s\n' "${desc}"
  pass=$((pass + 1))
}

assert_file_contains() {
  local desc="$1"
  local needle="$2"
  local file="$3"
  if grep -qF "${needle}" "${file}"; then
    printf 'PASS: %s\n' "${desc}"
    pass=$((pass + 1))
  else
    printf 'FAIL: %s (missing %q in %s)\n' "${desc}" "${needle}" "${file}"
    fail=$((fail + 1))
  fi
}

assert_file_lacks() {
  local desc="$1"
  local needle="$2"
  local file="$3"
  if grep -qF "${needle}" "${file}"; then
    printf 'FAIL: %s (unexpected %q in %s)\n' "${desc}" "${needle}" "${file}"
    fail=$((fail + 1))
  else
    printf 'PASS: %s\n' "${desc}"
    pass=$((pass + 1))
  fi
}

assert_output_contains() {
  local desc="$1"
  local needle="$2"
  shift 2
  local out rc
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  if [[ "${rc}" -ne 0 ]]; then
    printf 'FAIL: %s (exit %s)\n' "${desc}" "${rc}"
    printf '  output: %s\n' "${out}"
    fail=$((fail + 1))
    return
  fi
  if ! grep -qF "${needle}" <<<"${out}"; then
    printf 'FAIL: %s (missing %q)\n' "${desc}" "${needle}"
    printf '  output: %s\n' "${out}"
    fail=$((fail + 1))
    return
  fi
  printf 'PASS: %s\n' "${desc}"
  pass=$((pass + 1))
}

# --- 5.1 (3) / foundation: up has no ui-* deps ---
up_recipe="$(awk '/^up:/{flag=1; next} /^[^[:space:]#]/{flag=0} flag' "${MAKEFILE}")"
if grep -E 'ui-' <<<"${up_recipe}" >/dev/null 2>&1; then
  printf 'FAIL: Makefile up recipe references ui-*\n'
  fail=$((fail + 1))
else
  printf 'PASS: Makefile up has no ui-* deps\n'
  pass=$((pass + 1))
fi

assert_ok "make -n ui-skupper dry-runs" make -C "${ROOT}" -n ui-skupper
assert_ok "make -n ui-skupper-check dry-runs" make -C "${ROOT}" -n ui-skupper-check
assert_ok "make -n ui-down dry-runs" make -C "${ROOT}" -n ui-down

# --- Helm values present; no password committed ---
assert_file_contains \
  "network-observer values exist" \
  "auth:" \
  "${VALUES}"
assert_file_contains \
  "values pin ClusterIP (no LB)" \
  "ClusterIP" \
  "${VALUES}"
assert_file_lacks \
  "values have no hardcoded password" \
  "BASIC_AUTH_PASSWORD=" \
  "${VALUES}"
assert_file_lacks \
  "values have no plaintext password key" \
  "password:" \
  "${VALUES}"

assert_file_contains \
  "VERSIONS.md pins network-observer 2.2.1" \
  "network-observer" \
  "${VERSIONS}"
assert_file_contains \
  "VERSIONS.md observer version 2.2.1" \
  "2.2.1" \
  "${VERSIONS}"
assert_file_contains \
  "VERSIONS.md prefers 8443" \
  "127.0.0.1:8443" \
  "${VERSIONS}"
assert_file_contains \
  "VERSIONS.md notes 2nd Prometheus / RAM" \
  "Prometheus" \
  "${VERSIONS}"

assert_file_contains \
  "skupper README documents ui-skupper" \
  "make ui-skupper" \
  "${SKUPPER_README}"
assert_file_contains \
  "skupper README HTTPS URL contract" \
  "https://127.0.0.1:8443/" \
  "${SKUPPER_README}"
assert_file_contains \
  "skupper README mentions podman-edge preference" \
  "podman-edge" \
  "${SKUPPER_README}"
assert_file_contains \
  "skupper README mentions west fallback" \
  "kind-west" \
  "${SKUPPER_README}"

# Script contracts
assert_file_contains \
  "ui-skupper prints ACCESS_URL contract style" \
  "ACCESS_URL" \
  "${UI_SKUPPER}"
assert_file_contains \
  "ui-skupper prefers 8443" \
  "8443" \
  "${UI_SKUPPER}"
assert_file_contains \
  "ui-skupper-check uses curl -k" \
  "curl -k" \
  "${UI_CHECK}"
assert_file_contains \
  "ui-down uninstalls observer" \
  "helm uninstall" \
  "${UI_DOWN}"
assert_file_contains \
  "ui-down uninstalls Viz" \
  "viz uninstall" \
  "${UI_DOWN}"
assert_file_contains \
  "down.sh best-effort ui-down" \
  "ui-down" \
  "${DOWN_SH}"

# --- 5.1 (2) bad CLUSTER aborts ---
assert_fails_with \
  "ui-skupper refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${UI_SKUPPER}"

assert_fails_with \
  "ui-skupper-check refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${UI_CHECK}"

assert_fails_with \
  "ui-down refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${UI_DOWN}"

# --- 5.1 (1) ui-down leaves CCM ports — script must document + not kill CCM ---
assert_file_contains \
  "ui-down documents CCM ports untouched" \
  "8080/8081/18080/18081/45671/55671" \
  "${UI_DOWN}"
if grep -Eiq 'cloud-provider-kind|kill.*8080|fuser.*8080' "${UI_DOWN}"; then
  printf 'FAIL: ui-down appears to touch CCM / reserved host ports\n'
  fail=$((fail + 1))
else
  printf 'PASS: ui-down does not touch CCM process or reserved host ports\n'
  pass=$((pass + 1))
fi

# --- 5.1 (4) ui-down kills only recorded PF pids (pidfile-driven) ---
assert_file_contains \
  "ui-down uses pidfiles for PF stop" \
  "demo_ui_pidfile" \
  "${UI_DOWN}"
# shellcheck disable=SC1091
source "${UI_COMMON}"
run_dir="$(demo_ui_ensure_run_dir)"
fake_pidfile="$(demo_ui_pidfile ui-skupper-observer)"
# Record a dead pid that is not our shell — ui-down must only consult pidfile.
printf '1\n' >"${fake_pidfile}"
out="$(CLUSTER= "${UI_DOWN}" 2>&1 || true)"
if [[ -f "${fake_pidfile}" ]]; then
  printf 'FAIL: ui-down did not remove observer pidfile after run\n'
  fail=$((fail + 1))
else
  printf 'PASS: ui-down clears recorded observer pidfile\n'
  pass=$((pass + 1))
fi
if grep -qE 'ui-skupper-observer|Skupper network-observer|pidfile stale' <<<"${out}"; then
  printf 'PASS: ui-down reports observer PF teardown from pidfile\n'
  pass=$((pass + 1))
else
  printf 'FAIL: ui-down did not mention observer PF teardown\n'
  printf '  output: %s\n' "${out}"
  fail=$((fail + 1))
fi
rm -f "${fake_pidfile}"

# --- Rehearsal offline URL contracts A→B→C ---
assert_output_contains \
  "Phase A ACCESS_URL contract" \
  "ACCESS_URL=http://emojivoto.demo.local:8080/" \
  "${UI_APP}"

assert_file_contains \
  "Phase B script prefers 50750 URL shape" \
  "http://127.0.0.1:" \
  "${UI_LINKERD}"

assert_file_contains \
  "Phase C script builds https://127.0.0.1 URL" \
  "https://127.0.0.1:" \
  "${UI_SKUPPER}"

# Prefer exact preferred-port string in ui-skupper for speaker contract
if grep -qE 'https://127\.0\.0\.1:\$\{port\}/|PREFERRED_PORT=.*8443' "${UI_SKUPPER}"; then
  printf 'PASS: Phase C prefers port 8443 for ACCESS_URL\n'
  pass=$((pass + 1))
else
  printf 'FAIL: Phase C missing preferred 8443 ACCESS_URL construction\n'
  fail=$((fail + 1))
fi

# --- Verify PARTIAL close: VAN works without observer ---
# default make up / demo-skupper path must not require ui-skupper
demo_skupper_recipe="$(awk '/^demo-skupper:/{flag=1; next} /^[^[:space:]#]/{flag=0} flag' "${MAKEFILE}")"
if grep -E 'ui-skupper' <<<"${demo_skupper_recipe}" >/dev/null 2>&1; then
  printf 'FAIL: Makefile demo-skupper recipe references ui-skupper\n'
  printf '  recipe: %s\n' "${demo_skupper_recipe}"
  fail=$((fail + 1))
else
  printf 'PASS: Makefile demo-skupper has no ui-skupper dep\n'
  pass=$((pass + 1))
fi
assert_file_contains \
  "demo-skupper invokes check-skupper (VAN path)" \
  "check-skupper.sh" \
  "${MAKEFILE}"
if grep -Eiq 'ui-skupper|network-observer' "${CHECK_SKUPPER}"; then
  printf 'FAIL: check-skupper.sh requires ui-skupper / network-observer\n'
  fail=$((fail + 1))
else
  printf 'PASS: check-skupper.sh has no ui-skupper / observer dependency\n'
  pass=$((pass + 1))
fi
assert_file_contains \
  "skupper README says observer not part of make up" \
  "Not** part of \`make up\`" \
  "${SKUPPER_README}"
assert_file_contains \
  "skupper README says VAN works without observer" \
  "VAN critical path works without it" \
  "${SKUPPER_README}"
assert_file_contains \
  "skupper README marks observer opt-in only" \
  "Opt-in only" \
  "${SKUPPER_README}"

printf '\nUI skupper/teardown suite: %s passed, %s failed\n' "${pass}" "${fail}"
if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi
