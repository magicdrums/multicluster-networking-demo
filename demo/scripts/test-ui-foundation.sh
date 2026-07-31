#!/usr/bin/env bash
# Focused foundation suite for demo-product-uis WU1 (threat + URL contract).
# Offline: no Kind required.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MAKEFILE="${ROOT}/Makefile"
UI_COMMON="${SCRIPT_DIR}/ui-common.sh"
UI_APP="${SCRIPT_DIR}/ui-app.sh"
UI_APP_CHECK="${SCRIPT_DIR}/ui-app-check.sh"

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

assert_output_lacks() {
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
  if grep -qF "${needle}" <<<"${out}"; then
    printf 'FAIL: %s (unexpected %q)\n' "${desc}" "${needle}"
    printf '  output: %s\n' "${out}"
    fail=$((fail + 1))
    return
  fi
  printf 'PASS: %s\n' "${desc}"
  pass=$((pass + 1))
}

# --- 1.1 RED: make up has no ui-* deps ---
up_recipe="$(awk '/^up:/{flag=1; next} /^[^[:space:]#]/{flag=0} flag' "${MAKEFILE}")"
if grep -E 'ui-' <<<"${up_recipe}" >/dev/null 2>&1; then
  printf 'FAIL: Makefile up recipe references ui-*\n'
  printf '  recipe: %s\n' "${up_recipe}"
  fail=$((fail + 1))
else
  printf 'PASS: Makefile up has no ui-* deps\n'
  pass=$((pass + 1))
fi

# Phony / help wiring must list ui targets but up itself must stay lean
if ! grep -qE '^ui-app:' "${MAKEFILE}"; then
  printf 'FAIL: Makefile missing ui-app target\n'
  fail=$((fail + 1))
else
  printf 'PASS: Makefile has ui-app target\n'
  pass=$((pass + 1))
fi

# --- 1.3 RED→GREEN: refuse reserved ports ---
# shellcheck disable=SC1091
source "${UI_COMMON}"

for port in 8080 8081 18080 18081 45671 55671; do
  assert_fails_with \
    "refuse reserved port ${port}" \
    "refusing reserved|reserved demo port" \
    bash -c "source '${UI_COMMON}'; demo_ui_refuse_reserved_port '${port}'"
done

assert_fails_with \
  "demo_pick_free_port refuses preferred 8080" \
  "refusing reserved|reserved demo port" \
  bash -c "source '${UI_COMMON}'; demo_pick_free_port 8080"

# Free preferred (non-reserved) should succeed when unbound — use high ephemeral
assert_ok \
  "demo_pick_free_port accepts preferred 50750 when free-or-next" \
  bash -c "source '${UI_COMMON}'; p=\$(demo_pick_free_port 50750); [[ -n \"\$p\" ]] && ! demo_ui_is_reserved_port \"\$p\""

# --- bad CLUSTER / never kind-cluster ---
assert_fails_with \
  "ui-app refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${UI_APP}"

assert_fails_with \
  "ui-app aborts unknown CLUSTER" \
  "refusing|allowlist" \
  env CLUSTER=evil-cluster "${UI_APP}"

assert_fails_with \
  "ui-down refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${SCRIPT_DIR}/ui-down.sh"

# --- 2.1 ACCESS_URL contract ---
assert_output_contains \
  "ui-app prints ACCESS_URL west contract" \
  "ACCESS_URL=http://emojivoto.demo.local:8080/" \
  "${UI_APP}"

assert_output_lacks \
  "ui-app does not prescribe bare IP URL without Host" \
  "ACCESS_URL=http://127.0.0.1:8080/" \
  "${UI_APP}"

assert_output_contains \
  "ui-app mentions /etc/hosts" \
  "emojivoto.demo.local" \
  "${UI_APP}"

# make -n wiring
assert_ok \
  "make -n ui-app-check dry-runs" \
  make -C "${ROOT}" -n ui-app-check

printf '\nUI foundation suite: %s passed, %s failed\n' "${pass}" "${fail}"
if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi
