#!/usr/bin/env bash
# Scoped demo teardown — destroys only allowlisted sites. NEVER touches kind-cluster.
# Tears down Skupper + legacy-emoji before Kind/Podman network delete so re-up is clean.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
# shellcheck source=cloud-provider-kind.sh
source "${SCRIPT_DIR}/cloud-provider-kind.sh"

ROOT="$(demo_repo_root)"
LEGACY_DIR="${ROOT}/demo/apps/legacy-emoji"
SKUPPER_TOKEN_FILE="${SKUPPER_TOKEN_FILE:-${ROOT}/demo/skupper/.tokens/west.token}"

export KIND_EXPERIMENTAL_PROVIDER="${KIND_EXPERIMENTAL_PROVIDER:-podman}"

teardown_skupper_kind() {
  local name="$1"
  local ctx
  ctx="$(demo_kind_context "${name}")"
  if ! demo_kind_exists "${name}"; then
    printf 'down: Skupper Kind teardown skip %s — cluster not present\n' "${name}"
    return 0
  fi
  printf 'down: [%s] removing Skupper site/resources in skupper + AttachedConnector\n' "${ctx}"
  # Best-effort: delete site first so routers unwind, then remaining CRs.
  skupper --context "${ctx}" -n skupper site delete --wait none 2>/dev/null || true
  kubectl --context "${ctx}" -n skupper delete site,listener,connector,link,accessgrant,accesstoken,attachedconnectorbinding \
    --all --ignore-not-found >/dev/null 2>&1 || true
  kubectl --context "${ctx}" -n emojivoto delete attachedconnector --all --ignore-not-found >/dev/null 2>&1 || true
  kubectl --context "${ctx}" delete ns skupper --ignore-not-found --wait=false >/dev/null 2>&1 || true
}

teardown_skupper_podman() {
  printf 'down: stopping Podman Skupper site podman-edge\n'
  skupper system stop -p podman -n podman-edge 2>/dev/null || true
  skupper site delete -p podman -n podman-edge --wait none 2>/dev/null || true
}

teardown_legacy_emoji() {
  "${LEGACY_DIR}/stop.sh"
}

destroy_kind_cluster() {
  local name="$1"
  demo_require_allowlisted "${name}" "destroy" || return 1
  teardown_skupper_kind "${name}"
  if demo_kind_exists "${name}"; then
    printf 'down: deleting Kind cluster %s\n' "${name}"
    kind delete cluster --name "${name}"
  else
    printf 'down: Kind cluster %s not present — skipping\n' "${name}"
  fi
  demo_remove_kube_context "${name}"
}

destroy_podman_edge() {
  local name="podman-edge"
  demo_require_allowlisted "${name}" "destroy" || return 1
  teardown_skupper_podman
  teardown_legacy_emoji
  if podman network exists "${name}" >/dev/null 2>&1; then
    # Detach any leftover containers before network rm.
    local cid
    while IFS= read -r cid; do
      [[ -z "${cid}" ]] && continue
      printf 'down: removing container %s from %s\n' "${cid}" "${name}"
      podman rm -f "${cid}" >/dev/null 2>&1 || true
    done < <(podman ps -aq --filter "network=${name}" 2>/dev/null || true)
    printf 'down: removing Podman network %s\n' "${name}"
    podman network rm "${name}" >/dev/null
  else
    printf 'down: Podman network %s not present — skipping\n' "${name}"
  fi
}

tear_down_target() {
  local target="$1"
  case "${target}" in
    kind-west | kind-east)
      destroy_kind_cluster "${target}"
      ;;
    podman-edge)
      destroy_podman_edge
      ;;
    *)
      demo_require_allowlisted "${target}" "destroy"
      ;;
  esac
}

main() {
  local targets=()
  local target resolved
  # Capture via command substitution so allowlist failures abort (process substitution does not).
  if ! resolved="$(demo_resolve_targets)"; then
    exit 1
  fi
  while IFS= read -r target; do
    [[ -n "${target}" ]] && targets+=("${target}")
  done <<<"${resolved}"

  printf 'down: destroying demo targets only: %s\n' "${targets[*]}"
  # Always attempt demo-owned CCM cleanup if we tore Kind sites, even when a
  # tear_down_target fails under set -e (otherwise host LB process can leak).
  local tore_kind=0
  for target in "${targets[@]}"; do
    if demo_is_kind_site "${target}"; then
      tore_kind=1
      break
    fi
  done
  if [[ "${tore_kind}" -eq 1 ]]; then
    trap '
      if ! demo_kind_exists "kind-west" && ! demo_kind_exists "kind-east"; then
        demo_stop_cloud_provider_kind_if_ours || true
      fi
    ' EXIT
  fi
  for target in "${targets[@]}"; do
    tear_down_target "${target}"
  done
  rm -f "${SKUPPER_TOKEN_FILE}" 2>/dev/null || true

  # Stop cloud-provider-kind only when this demo started it (pidfile + owned marker).
  # Never kill an unrelated user CCM.
  if [[ "${tore_kind}" -eq 1 ]]; then
    # If any demo Kind cluster still exists (scoped CLUSTER=…), keep CCM for the remainder.
    if demo_kind_exists "kind-west" || demo_kind_exists "kind-east"; then
      printf 'down: demo Kind site still present — leaving cloud-provider-kind running\n'
    else
      demo_stop_cloud_provider_kind_if_ours
    fi
  fi

  printf 'down: done (kind-cluster intentionally untouched)\n'
}

main "$@"
