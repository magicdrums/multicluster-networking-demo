#!/usr/bin/env bash
# Offline suite: Phase B Linkerd Viz via make ui surface (Kind-free).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MAKEFILE="${ROOT}/Makefile"
VERSIONS="${ROOT}/demo/VERSIONS.md"
LINKERD_README="${ROOT}/demo/linkerd/README.md"
SKIP_NS="${ROOT}/demo/linkerd/skip-namespaces.yaml"
PHASE_B="${SCRIPT_DIR}/ui/_phase_b.sh"
UI_SH="${SCRIPT_DIR}/ui.sh"

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

# Viz must not be wired into up.sh
if grep -Eiq 'viz install|ui/_phase_b|linkerd viz' "${SCRIPT_DIR}/up.sh"; then
  printf 'FAIL: up.sh appears to install/start Viz\n'
  fail=$((fail + 1))
else
  printf 'PASS: up.sh does not install Viz\n'
  pass=$((pass + 1))
fi

assert_ok "make -n ui dry-runs" make -C "${ROOT}" -n ui

if [[ -f "${PHASE_B}" ]]; then
  printf 'PASS: phase B private script present\n'
  pass=$((pass + 1))
else
  printf 'FAIL: missing %s\n' "${PHASE_B}"
  fail=$((fail + 1))
fi

if [[ -e "${SCRIPT_DIR}/ui-linkerd.sh" || -e "${SCRIPT_DIR}/ui-linkerd-check.sh" ]]; then
  printf 'FAIL: old ui-linkerd*.sh still present\n'
  fail=$((fail + 1))
else
  printf 'PASS: old ui-linkerd*.sh removed\n'
  pass=$((pass + 1))
fi

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
  "linkerd README documents opt-in Viz via make ui" \
  "make ui" \
  "${LINKERD_README}"
assert_file_contains \
  "linkerd README URL contract 50750" \
  "http://127.0.0.1:50750/" \
  "${LINKERD_README}"

assert_fails_with \
  "phase B refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${PHASE_B}"

assert_fails_with \
  "phase B refuses east (west-only)" \
  "west-only" \
  env CLUSTER=kind-east "${PHASE_B}"

assert_fails_with \
  "ui PHASE=b refuses east (west-only)" \
  "west-only" \
  env CLUSTER=kind-east PHASE=b "${UI_SH}"

# Scripts must not mention CCM LB as the access path
if grep -Eiq 'cloud-provider-kind|LoadBalancer.*(viz|dashboard)|CCM.*LB.*viz' \
  "${PHASE_B}" 2>/dev/null; then
  if ! grep -Eq 'never CCM|no CCM' "${PHASE_B}"; then
    printf 'FAIL: phase B appears to use CCM LB for Viz\n'
    fail=$((fail + 1))
  else
    printf 'PASS: phase B documents never CCM LB\n'
    pass=$((pass + 1))
  fi
else
  printf 'PASS: phase B script does not wire CCM LB\n'
  pass=$((pass + 1))
fi

assert_file_contains \
  "phase B declares skip-inject unchanged" \
  "Does not change skip-inject" \
  "${PHASE_B}"
assert_file_contains \
  "linkerd README Viz contract keeps skip-inject unchanged" \
  "Skip-inject | Unchanged" \
  "${LINKERD_README}"
assert_file_contains \
  "linkerd README still skips EG / Kuadrant / CoreDNS / gateway-system / skupper" \
  "Skip-inject on EG / Kuadrant / CoreDNS / \`gateway-system\` / \`skupper\`" \
  "${LINKERD_README}"
assert_file_contains \
  "linkerd README coexistence skips envoy-gateway-system" \
  "envoy-gateway-system" \
  "${LINKERD_README}"
assert_file_contains \
  "linkerd README coexistence skips kuadrant-system" \
  "kuadrant-system" \
  "${LINKERD_README}"
assert_file_contains \
  "linkerd README coexistence skips kuadrant-coredns" \
  "kuadrant-coredns" \
  "${LINKERD_README}"
assert_file_contains \
  "linkerd README coexistence skips gateway-system" \
  "gateway-system" \
  "${LINKERD_README}"
assert_file_contains \
  "skip-namespaces disables inject on kuadrant-coredns" \
  "name: kuadrant-coredns" \
  "${SKIP_NS}"
assert_file_contains \
  "skip-namespaces disables inject on gateway-system" \
  "name: gateway-system" \
  "${SKIP_NS}"
assert_file_contains \
  "skip-namespaces disables inject on skupper" \
  "name: skupper" \
  "${SKIP_NS}"
for ns in kuadrant-coredns gateway-system skupper; do
  if awk -v ns="${ns}" '
    $0 ~ ("name: " ns) {found=1}
    found && /linkerd.io\/inject: disabled/ {ok=1; exit}
    found && /^---/ {exit}
    END {exit ok ? 0 : 1}
  ' "${SKIP_NS}"; then
    printf 'PASS: skip-namespaces %s keeps linkerd.io/inject: disabled\n' "${ns}"
    pass=$((pass + 1))
  else
    printf 'FAIL: skip-namespaces %s missing linkerd.io/inject: disabled\n' "${ns}"
    fail=$((fail + 1))
  fi
done

printf '\nUI linkerd suite: %s passed, %s failed\n' "${pass}" "${fail}"
if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi
