#!/usr/bin/env bash
# Focused offline suite for demo-product-uis WU2 (Phase B Linkerd Viz contract).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MAKEFILE="${ROOT}/Makefile"
VERSIONS="${ROOT}/demo/VERSIONS.md"
LINKERD_README="${ROOT}/demo/linkerd/README.md"
UI_LINKERD="${SCRIPT_DIR}/ui-linkerd.sh"
UI_CHECK="${SCRIPT_DIR}/ui-linkerd-check.sh"

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

# --- up still has no ui-* deps ---
up_recipe="$(awk '/^up:/{flag=1; next} /^[^[:space:]#]/{flag=0} flag' "${MAKEFILE}")"
if grep -E 'ui-' <<<"${up_recipe}" >/dev/null 2>&1; then
  printf 'FAIL: Makefile up recipe references ui-*\n'
  fail=$((fail + 1))
else
  printf 'PASS: Makefile up has no ui-* deps\n'
  pass=$((pass + 1))
fi

assert_ok "make -n ui-linkerd dry-runs" make -C "${ROOT}" -n ui-linkerd
assert_ok "make -n ui-linkerd-check dry-runs" make -C "${ROOT}" -n ui-linkerd-check

assert_file_contains \
  "VERSIONS.md pins Linkerd Viz edge-26.6.3" \
  "Linkerd Viz (opt-in)" \
  "${VERSIONS}"
assert_file_contains \
  "VERSIONS.md Viz pin text includes edge-26.6.3" \
  "edge-26.6.3" \
  "${VERSIONS}"
assert_file_contains \
  "VERSIONS.md Viz prefers 50750" \
  "127.0.0.1:50750" \
  "${VERSIONS}"

assert_file_contains \
  "linkerd README documents opt-in Viz" \
  "make ui-linkerd" \
  "${LINKERD_README}"
assert_file_contains \
  "linkerd README URL contract 50750" \
  "http://127.0.0.1:50750/" \
  "${LINKERD_README}"

assert_fails_with \
  "ui-linkerd refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${UI_LINKERD}"

assert_fails_with \
  "ui-linkerd refuses east (west-only)" \
  "west-only" \
  env CLUSTER=kind-east "${UI_LINKERD}"

assert_fails_with \
  "ui-linkerd-check refuses east (west-only)" \
  "west-only" \
  env CLUSTER=kind-east "${UI_CHECK}"

# Scripts must not mention CCM LB as the access path
if grep -Eiq 'cloud-provider-kind|LoadBalancer.*(viz|dashboard)|CCM.*LB.*viz' \
  "${UI_LINKERD}" "${UI_CHECK}" 2>/dev/null; then
  # Allow explicit "never CCM LB" wording only
  if ! grep -Eq 'never CCM|no CCM' "${UI_LINKERD}"; then
    printf 'FAIL: ui-linkerd appears to use CCM LB for Viz\n'
    fail=$((fail + 1))
  else
    printf 'PASS: ui-linkerd documents never CCM LB\n'
    pass=$((pass + 1))
  fi
else
  printf 'PASS: ui-linkerd scripts do not wire CCM LB\n'
  pass=$((pass + 1))
fi

printf '\nUI linkerd suite: %s passed, %s failed\n' "${pass}" "${fail}"
if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi
