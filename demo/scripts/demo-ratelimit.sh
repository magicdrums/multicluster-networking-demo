#!/usr/bin/env bash
# Focused N-S wow: burst requests through the demo Gateway and expect HTTP 429.
# Default site: kind-west. Override with CLUSTER=kind-east.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

CLUSTER="${CLUSTER:-kind-west}"
demo_require_allowlisted "${CLUSTER}" "demo-ratelimit" || exit 1
if ! demo_is_kind_site "${CLUSTER}"; then
  printf 'error: demo-ratelimit requires a Kind site (kind-west|kind-east), got %q\n' "${CLUSTER}" >&2
  exit 1
fi

CTX="$(demo_kind_context "${CLUSTER}")"
HOST="${DEMO_HOST:-emojivoto.demo.local}"
BURST="${BURST:-12}"
GATEWAY_NS="${GATEWAY_NS:-gateway-system}"
GATEWAY_NAME="${GATEWAY_NAME:-demo}"
# East uses 8081 so CCM can publish both Gateways on the host.
if [[ -z "${DEMO_GW_PORT:-}" ]]; then
  if [[ "${CLUSTER}" == "kind-east" ]]; then
    DEMO_GW_PORT=8081
  else
    DEMO_GW_PORT=8080
  fi
fi

if ! demo_kind_exists "${CLUSTER}"; then
  printf 'demo-ratelimit: cluster %s not present — pass focused check as dry (manifests only)\n' "${CLUSTER}"
  ROOT="$(demo_repo_root)"
  test -f "${ROOT}/demo/kuadrant/ratelimitpolicy.yaml"
  test -f "${ROOT}/demo/gateway/gateway.yaml"
  printf 'demo-ratelimit: OK (offline — RateLimitPolicy + Gateway manifests present)\n'
  exit 0
fi

if ! kubectl --context "${CTX}" -n "${GATEWAY_NS}" get gateway "${GATEWAY_NAME}" >/dev/null 2>&1; then
  printf 'error: Gateway %s/%s missing on %s — run make up first\n' "${GATEWAY_NS}" "${GATEWAY_NAME}" "${CTX}" >&2
  exit 1
fi

ADDR="$(kubectl --context "${CTX}" -n "${GATEWAY_NS}" get gateway "${GATEWAY_NAME}" \
  -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || true)"

PF_PID=""
cleanup() {
  if [[ -n "${PF_PID}" ]] && kill -0 "${PF_PID}" 2>/dev/null; then
    kill "${PF_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT

BASE_URL=""
# Prefer host publish (CCM --enable-lb-port-mapping) — Kind LB IPs (10.89.0.x) are often
# unreachable from the host under rootless Podman.
if [[ -n "${DEMO_GW_URL:-}" ]]; then
  BASE_URL="${DEMO_GW_URL}"
  printf 'demo-ratelimit: using DEMO_GW_URL=%s\n' "${BASE_URL}"
elif curl -sS -o /dev/null --connect-timeout 2 -H "Host: ${HOST}" \
  "http://127.0.0.1:${DEMO_GW_PORT}/" >/dev/null 2>&1; then
  BASE_URL="http://127.0.0.1:${DEMO_GW_PORT}"
  printf 'demo-ratelimit: using host-mapped Gateway http://127.0.0.1:%s\n' "${DEMO_GW_PORT}"
elif [[ -n "${ADDR}" ]] && curl -sS -o /dev/null --connect-timeout 2 -H "Host: ${HOST}" \
  "http://${ADDR}:${DEMO_GW_PORT}/" >/dev/null 2>&1; then
  BASE_URL="http://${ADDR}:${DEMO_GW_PORT}"
  printf 'demo-ratelimit: using Gateway address %s:%s\n' "${ADDR}" "${DEMO_GW_PORT}"
else
  # Fallback: port-forward envoy service behind the Gateway.
  SVC="$(kubectl --context "${CTX}" -n envoy-gateway-system get svc \
    -l gateway.envoyproxy.io/owning-gateway-name="${GATEWAY_NAME}" \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
  if [[ -z "${SVC}" ]]; then
    printf 'error: no reachable Gateway URL and no Envoy Service to port-forward\n' >&2
    exit 1
  fi
  LOCAL_PORT="${LOCAL_PORT:-18081}"
  printf 'demo-ratelimit: port-forward svc/%s → localhost:%s\n' "${SVC}" "${LOCAL_PORT}"
  kubectl --context "${CTX}" -n envoy-gateway-system port-forward "svc/${SVC}" \
    "${LOCAL_PORT}:${DEMO_GW_PORT}" >/dev/null 2>&1 &
  PF_PID=$!
  sleep 2
  BASE_URL="http://127.0.0.1:${LOCAL_PORT}"
fi

ok=0
limited=0
i=0
while (( i < BURST )); do
  code="$(curl -s -o /dev/null -w '%{http_code}' -H "Host: ${HOST}" "${BASE_URL}/" || printf '000')"
  printf 'demo-ratelimit: request %d → %s\n' "$((i + 1))" "${code}"
  case "${code}" in
    429) limited=$((limited + 1)) ;;
    200|404|503) ok=$((ok + 1)) ;; # 404/503 OK before emojivoto (Phase 3); still rate-limited
  esac
  i=$((i + 1))
done

if (( limited < 1 )); then
  printf 'error: expected at least one HTTP 429 in %d requests (got ok-ish=%d limited=%d)\n' \
    "${BURST}" "${ok}" "${limited}" >&2
  printf 'hint: RateLimitPolicy is 3/10s; ensure Kuadrant/Limitador reconciled on %s\n' "${CTX}" >&2
  exit 1
fi

printf 'demo-ratelimit: OK (%d × 429 in %d requests on %s)\n' "${limited}" "${BURST}" "${CLUSTER}"
