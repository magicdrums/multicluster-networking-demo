#!/usr/bin/env bash
# Focused allowlist suite for kind-podman-lifecycle (threat matrix RED/GREEN).
# Asserts: down refuses kind-cluster; unknown CLUSTER aborts; up never creates non-demo names.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOWN="${SCRIPT_DIR}/down.sh"
UP="${SCRIPT_DIR}/up.sh"

pass=0
fail=0

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
    printf 'FAIL: %s (exit %s but missing message matching /%s/)\n' "${desc}" "${rc}" "${needle}"
    printf '  output: %s\n' "${out}"
    fail=$((fail + 1))
    return
  fi
  printf 'PASS: %s\n' "${desc}"
  pass=$((pass + 1))
}

if [[ ! -x "${DOWN}" ]]; then
  printf 'FAIL: %s missing or not executable (RED until down.sh exists)\n' "${DOWN}"
  exit 1
fi
if [[ ! -x "${UP}" ]]; then
  printf 'FAIL: %s missing or not executable (RED until up.sh exists)\n' "${UP}"
  exit 1
fi

# (1) down must refuse kind-cluster
assert_fails_with \
  "down refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${DOWN}"

# (2) unknown cluster env aborts
assert_fails_with \
  "down aborts unknown CLUSTER" \
  "refusing|allowlist" \
  env CLUSTER=not-a-demo-site "${DOWN}"

# (3) up must never create non-demo names (allowlist before create/prereq side effects)
assert_fails_with \
  "up refuses CLUSTER=kind-cluster" \
  "refusing|allowlist|kind-cluster" \
  env CLUSTER=kind-cluster "${UP}"

assert_fails_with \
  "up aborts unknown CLUSTER" \
  "refusing|allowlist" \
  env CLUSTER=evil-cluster "${UP}"

# (4) low inotify blocks bring-up (injectable path — no host sysctl mutation)
low_inotify="$(mktemp -t inotify-low.XXXXXX)"
printf '128\n' > "${low_inotify}"
assert_fails_with \
  "prereq blocks low inotify max_user_instances" \
  "inotify|max_user_instances|512" \
  env INOTIFY_MAX_USER_INSTANCES_PATH="${low_inotify}" "${SCRIPT_DIR}/prereq-check.sh"
rm -f "${low_inotify}"

printf '\nAllowlist suite: %s passed, %s failed\n' "${pass}" "${fail}"
if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi
exit 0
