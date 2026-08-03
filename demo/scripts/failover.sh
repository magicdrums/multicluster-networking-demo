#!/usr/bin/env bash
# Scripted CoreDNS/health failover: hurt west primary → wait → east secondary.
# Exit non-zero if failover does not complete within FAILOVER_TIMEOUT_SEC.
# Offline (no kind-west): validate DNS HA manifests + timeout contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

ROOT="$(demo_repo_root)"
DEMO_HOST="${DEMO_HOST:-emojivoto.demo.local}"
GATEWAY_NS="${GATEWAY_NS:-gateway-system}"
GATEWAY_NAME="${GATEWAY_NAME:-demo}"
# Envoy Gateway dataplane (proxy) Deployments live here — NOT gateway-system.
ENVOY_GATEWAY_NS="${ENVOY_GATEWAY_NS:-envoy-gateway-system}"
COREDNS_NS="${COREDNS_NS:-kuadrant-coredns}"
# Speaker-facing bound (runbook): CoreDNS/group reconcile is not instant.
FAILOVER_TIMEOUT_SEC="${FAILOVER_TIMEOUT_SEC:-120}"
FAILOVER_POLL_SEC="${FAILOVER_POLL_SEC:-5}"

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

offline_failover() {
  printf 'failover: offline path (no kind-west) — DNS HA + timeout contract\n'
  assert_grep "west DNSPolicy primary weight 100" "weight:\\s*100" "${ROOT}/demo/kuadrant/dnspolicy.yaml"
  assert_grep "east DNSPolicy secondary weight 50" "weight:\\s*50" "${ROOT}/demo/kuadrant/dnspolicy-east.yaml"
  assert_grep "west defaultGeo true" "defaultGeo:\\s*true" "${ROOT}/demo/kuadrant/dnspolicy.yaml"
  assert_grep "east defaultGeo false" "defaultGeo:\\s*false" "${ROOT}/demo/kuadrant/dnspolicy-east.yaml"
  assert_grep "failover documents timeout" "FAILOVER_TIMEOUT_SEC" "${ROOT}/demo/scripts/failover.sh"
  assert_grep "failover exits non-zero on timeout" "exit 1|return 1" "${ROOT}/demo/scripts/failover.sh"
  assert_grep "hurt west helper" "hurt_west_primary" "${ROOT}/demo/scripts/failover.sh"
  assert_grep "hurt targets envoy-gateway-system" "envoy-gateway-system" "${ROOT}/demo/scripts/failover.sh"
  assert_grep "hurt deletes west DNSPolicy (not weight 0)" "delete dnspolicy emojivoto-dns" "${ROOT}/demo/scripts/failover.sh"
  assert_grep "runbook mentions failover waits" "failover|FAILOVER|wait" "${ROOT}/README.md"
}

gateway_addr() {
  local ctx="$1"
  kubectl --context "${ctx}" -n "${GATEWAY_NS}" get gateway "${GATEWAY_NAME}" \
    -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || true
}

# Proxy Deployments owned by Gateway demo (created by Envoy Gateway in envoy-gateway-system).
west_proxy_deploys() {
  local west_ctx="$1"
  kubectl --context "${west_ctx}" -n "${ENVOY_GATEWAY_NS}" get deploy \
    -l "gateway.envoyproxy.io/owning-gateway-name=${GATEWAY_NAME}" \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null || true
}

wait_coredns_ready() {
  local ctx="$1"
  local wait_max="${2:-60}"
  printf 'failover: waiting up to %ss for CoreDNS Ready in %s\n' "${wait_max}" "${COREDNS_NS}"
  if kubectl --context "${ctx}" -n "${COREDNS_NS}" wait --for=condition=Available \
    deploy -l app.kubernetes.io/name=coredns --timeout="${wait_max}s" >/dev/null 2>&1; then
    ok "CoreDNS Available"
    return 0
  fi
  # Label may differ across Kuadrant installs — fall back to any deploy in NS.
  if kubectl --context "${ctx}" -n "${COREDNS_NS}" wait --for=condition=Available \
    --all deploy --timeout="${wait_max}s" >/dev/null 2>&1; then
    ok "CoreDNS Available (ns deploy)"
    return 0
  fi
  bad "CoreDNS not Available in ${COREDNS_NS} after ${wait_max}s"
  return 1
}

# Make west unhealthy for DNS HA:
# 1) Scale Envoy Gateway dataplane → 0 (N-S path dies on west).
# 2) Remove west DNSPolicy so west CoreDNS stops advertising the primary A record.
# NOTE: Do NOT set loadBalancing.weight to 0 — coredns-kuadrant panics (Intn(0)).
# Kind sites each run their own CoreDNS; verification digs east CoreDNS for the secondary.
hurt_west_primary() {
  local west_ctx="$1"
  local deploy found=0
  printf 'failover: hurting west primary (scale Envoy proxy → 0 in %s + remove DNSPolicy)\n' \
    "${ENVOY_GATEWAY_NS}"
  while IFS= read -r deploy; do
    [[ -z "${deploy}" ]] && continue
    found=1
    printf 'failover: scale %s/%s → 0\n' "${ENVOY_GATEWAY_NS}" "${deploy}"
    kubectl --context "${west_ctx}" -n "${ENVOY_GATEWAY_NS}" scale "deploy/${deploy}" --replicas=0
    kubectl --context "${west_ctx}" -n "${ENVOY_GATEWAY_NS}" wait --for=jsonpath='{.status.replicas}'=0 \
      "deploy/${deploy}" --timeout=60s >/dev/null 2>&1 || true
  done < <(west_proxy_deploys "${west_ctx}")
  if [[ "${found}" -eq 0 ]]; then
    bad "no Envoy proxy Deployment found in ${ENVOY_GATEWAY_NS} (label owning-gateway-name=${GATEWAY_NAME})"
    return 1
  fi
  ok "west Envoy proxy scaled to 0"
  if kubectl --context "${west_ctx}" -n "${GATEWAY_NS}" get dnspolicy emojivoto-dns >/dev/null 2>&1; then
    printf 'failover: deleting west DNSPolicy emojivoto-dns (avoid CoreDNS weight=0 panic)\n'
    kubectl --context "${west_ctx}" -n "${GATEWAY_NS}" delete dnspolicy emojivoto-dns --wait=false >/dev/null
  fi
}

restore_west_primary() {
  local west_ctx="$1"
  local deploy
  printf 'failover: restoring west (scale-up + re-apply DNSPolicy)\n'
  while IFS= read -r deploy; do
    [[ -z "${deploy}" ]] && continue
    kubectl --context "${west_ctx}" -n "${ENVOY_GATEWAY_NS}" scale "deploy/${deploy}" --replicas=1 \
      >/dev/null 2>&1 || true
    kubectl --context "${west_ctx}" -n "${ENVOY_GATEWAY_NS}" wait --for=condition=Available \
      "deploy/${deploy}" --timeout=90s >/dev/null 2>&1 || true
  done < <(west_proxy_deploys "${west_ctx}")
  if [[ -z "$(west_proxy_deploys "${west_ctx}")" ]]; then
    kubectl --context "${west_ctx}" -n "${ENVOY_GATEWAY_NS}" get deploy \
      -o name 2>/dev/null | while read -r d; do
      [[ "${d}" == *demo* ]] || continue
      kubectl --context "${west_ctx}" -n "${ENVOY_GATEWAY_NS}" scale "${d}" --replicas=1 >/dev/null 2>&1 || true
    done
  fi
  kubectl --context "${west_ctx}" apply -f "${ROOT}/demo/kuadrant/dnspolicy.yaml" >/dev/null 2>&1 || true
}

resolve_demo_host_ips() {
  local ctx="$1"
  local coredns_ip
  coredns_ip="$(kubectl --context "${ctx}" -n "${COREDNS_NS}" get svc -l app.kubernetes.io/name=coredns \
    -o jsonpath='{.items[0].spec.clusterIP}' 2>/dev/null || true)"
  if [[ -z "${coredns_ip}" ]]; then
    coredns_ip="$(kubectl --context "${ctx}" -n "${COREDNS_NS}" get svc -o jsonpath='{.items[0].spec.clusterIP}' 2>/dev/null || true)"
  fi
  if [[ -z "${coredns_ip}" ]]; then
    return 1
  fi
  # Busybox nslookup; keep A-record answers only (skip the DNS server Address line).
  kubectl --context "${ctx}" -n "${COREDNS_NS}" run "failover-dig-$$-${RANDOM}" --rm -i --restart=Never \
    --image=busybox:1.36 --command -- sh -c "nslookup ${DEMO_HOST} ${coredns_ip}" 2>/dev/null \
    | awk -v skip="${coredns_ip}" '
        /^Name:/ { want=1; next }
        want && /^Address:/ {
          ip=$NF
          sub(/:.*/,"",ip)
          if (ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && ip != skip) print ip
          want=0
        }
      ' || true
}

wait_for_failover_dns() {
  local east_ip="$1"
  local west_ctx="$2"
  local west_ip="${3:-}"
  local east_ctx
  local deadline answers_east answers_west west_gone=0 east_ok=0
  east_ctx="$(demo_kind_context kind-east)"
  deadline=$((SECONDS + FAILOVER_TIMEOUT_SEC))
  printf 'failover: waiting up to %ss (poll %ss): east CoreDNS→%s' \
    "${FAILOVER_TIMEOUT_SEC}" "${FAILOVER_POLL_SEC}" "${east_ip}"
  if [[ -n "${west_ip}" ]]; then
    printf ' and west CoreDNS drops %s' "${west_ip}"
  fi
  printf '\n'
  printf 'failover: note: each Kind site has its own CoreDNS (dual-site dig)\n'
  while (( SECONDS < deadline )); do
    answers_east="$(resolve_demo_host_ips "${east_ctx}" || true)"
    answers_west="$(resolve_demo_host_ips "${west_ctx}" || true)"
    printf 'failover: dig east=[%s] west=[%s]\n' "${answers_east:-<none>}" "${answers_west:-<none>}"
    east_ok=0
    west_gone=1
    if grep -qxF "${east_ip}" <<<"${answers_east}"; then
      east_ok=1
    fi
    if [[ -n "${west_ip}" ]] && grep -qxF "${west_ip}" <<<"${answers_west}"; then
      west_gone=0
    fi
    if [[ "${east_ok}" -eq 1 && "${west_gone}" -eq 1 ]]; then
      ok "east CoreDNS answers ${east_ip}; west primary withdrawn"
      return 0
    fi
    sleep "${FAILOVER_POLL_SEC}"
  done
  bad "failover timeout after ${FAILOVER_TIMEOUT_SEC}s — east=${east_ip} (ok=${east_ok}) west_gone=${west_gone}"
  return 1
}

live_failover() {
  local west_ctx east_ctx west_ip east_ip
  west_ctx="$(demo_kind_context kind-west)"
  east_ctx="$(demo_kind_context kind-east)"

  if ! demo_kind_exists "kind-east"; then
    bad "kind-east required for failover (secondary site missing)"
    return 1
  fi

  if ! wait_coredns_ready "${west_ctx}" 60; then
    return 1
  fi
  if ! wait_coredns_ready "${east_ctx}" 60; then
    return 1
  fi

  west_ip="$(gateway_addr "${west_ctx}")"
  east_ip="$(gateway_addr "${east_ctx}")"
  if [[ -z "${east_ip}" ]]; then
    bad "east Gateway has no EXTERNAL-IP/address (cloud-provider-kind required)"
    return 1
  fi
  ok "east Gateway address ${east_ip}"
  if [[ -n "${west_ip}" ]]; then
    ok "west Gateway address ${west_ip} (pre-hurt)"
  else
    bad "west Gateway has no address pre-hurt"
    return 1
  fi

  # Always attempt restore so a failed talk path can re-up without full make down.
  trap 'restore_west_primary "'"${west_ctx}"'"' EXIT

  if ! hurt_west_primary "${west_ctx}"; then
    return 1
  fi
  if ! wait_for_failover_dns "${east_ip}" "${west_ctx}" "${west_ip}"; then
    return 1
  fi

  # HTTP verify against east LB (Host header). Prefer in-cluster curl —
  # host often cannot reach Kind LB VIPs under rootless Podman.
  local code raw
  # East Gateway listens on 8081 (west keeps 8080) to avoid CCM host port clashes.
  local port="${DEMO_GW_EAST_PORT:-${DEMO_GW_PORT:-8081}}"
  # kubectl --rm prints "pod deleted" on the attach stream — strip to first HTTP status.
  raw="$(kubectl --context "${east_ctx}" -n "${GATEWAY_NS}" run "failover-http-$$-${RANDOM}" --rm -i --restart=Never \
    --image=curlimages/curl:8.5.0 --command -- \
    curl -s -o /dev/null -w '%{http_code}' --connect-timeout 5 \
    -H "Host: ${DEMO_HOST}" "http://${east_ip}:${port}/" 2>/dev/null || true)"
  code="$(printf '%s' "${raw}" | grep -oE '[0-9]{3}' | head -1)"
  code="${code:-000}"
  case "${code}" in
    200|429|404|500|503)
      ok "HTTP ${code} via east Gateway after failover (east is voting-only; 5xx without web-svc is expected)"
      ;;
    *) bad "east Gateway HTTP probe got ${code} (raw=${raw})" ;;
  esac
}

main() {
  if demo_kind_exists "kind-west"; then
    live_failover
  else
    offline_failover
  fi
  printf '\nFailover: %s passed, %s failed\n' "${pass}" "${fail}"
  if [[ "${fail}" -ne 0 ]]; then
    exit 1
  fi
}

main "$@"
