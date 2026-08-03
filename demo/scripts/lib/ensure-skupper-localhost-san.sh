#!/usr/bin/env bash
# Option C helper: keep kind-west skupper-site-server SANs including 127.0.0.1/localhost
# so the host-networked podman-edge router can dial CCM-mapped LB ports on loopback.
#
# Skupper SecuredAccess rewrites Certificate hosts from LB endpoints only. We:
#   1) drop internal.skupper.io/controlled (so our hosts stick),
#   2) set the hosts-* annotation + spec.hosts to LB IP + 127.0.0.1 + localhost + svc names,
#   3) wait until the tls secret SAN includes 127.0.0.1,
#   4) restart west routers if the peer cert on :55671 is still stale.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

WEST_CTX="$(demo_kind_context kind-west)"
NS=skupper
CERT=skupper-site-server
WAIT_SEC="${SKUPPER_SAN_WAIT_SEC:-60}"

if ! demo_kind_exists "kind-west"; then
  printf 'error: kind-west not present\n' >&2
  exit 1
fi

secret_has_localhost_san() {
  WEST_CTX="${WEST_CTX}" python3 - <<'PY'
import base64, json, os, subprocess, sys
from cryptography import x509
from cryptography.hazmat.backends import default_backend

ctx = os.environ["WEST_CTX"]
out = subprocess.check_output(
    ["kubectl", "--context", ctx, "-n", "skupper",
     "get", "secret", "skupper-site-server", "-o", "json"],
    stderr=subprocess.DEVNULL,
)
cert = x509.load_pem_x509_certificate(
    base64.b64decode(json.loads(out)["data"]["tls.crt"]), default_backend()
)
text = " ".join(
    str(x) for x in cert.extensions.get_extension_for_class(x509.SubjectAlternativeName).value
)
sys.exit(0 if "127.0.0.1" in text else 1)
PY
}

peer_has_localhost_san() {
  python3 - <<'PY'
import socket, ssl, sys
from cryptography import x509
from cryptography.hazmat.backends import default_backend

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
try:
    with socket.create_connection(("127.0.0.1", 55671), timeout=3) as sock:
        with ctx.wrap_socket(sock, server_hostname="localhost") as ssock:
            cert = x509.load_der_x509_certificate(
                ssock.getpeercert(binary_form=True), default_backend()
            )
except OSError:
    sys.exit(1)
text = " ".join(
    str(x) for x in cert.extensions.get_extension_for_class(x509.SubjectAlternativeName).value
)
sys.exit(0 if "127.0.0.1" in text else 1)
PY
}

apply_hosts() {
  local sa_uid lb hosts_csv
  sa_uid="$(kubectl --context "${WEST_CTX}" -n "${NS}" get securedaccess skupper-router -o jsonpath='{.metadata.uid}')"
  lb="$(kubectl --context "${WEST_CTX}" -n "${NS}" get svc skupper-router -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
  if [[ -z "${sa_uid}" || -z "${lb}" ]]; then
    printf 'error: missing SecuredAccess uid or skupper-router EXTERNAL-IP (is cloud-provider-kind up?)\n' >&2
    return 1
  fi
  hosts_csv="${lb},127.0.0.1,localhost,skupper-router,skupper-router.skupper"
  printf 'ensure-skupper-localhost-san: LB=%s sa=%s\n' "${lb}" "${sa_uid}"

  # Allow our hosts list to persist (SecuredAccess otherwise reverts to LB-only).
  kubectl --context "${WEST_CTX}" -n "${NS}" annotate certificate "${CERT}" \
    internal.skupper.io/controlled- >/dev/null 2>&1 || true
  kubectl --context "${WEST_CTX}" -n "${NS}" annotate certificate "${CERT}" \
    "internal.skupper.io/hosts-${sa_uid}=${hosts_csv}" --overwrite >/dev/null
  kubectl --context "${WEST_CTX}" -n "${NS}" patch certificate "${CERT}" --type=merge \
    -p "{\"spec\":{\"hosts\":[\"${lb}\",\"127.0.0.1\",\"localhost\",\"skupper-router\",\"skupper-router.skupper\"]}}" \
    >/dev/null
}

apply_hosts

printf 'ensure-skupper-localhost-san: waiting up to %ss for secret SAN 127.0.0.1\n' "${WAIT_SEC}"
deadline=$((SECONDS + WAIT_SEC))
while (( SECONDS < deadline )); do
  if secret_has_localhost_san; then
    printf 'ensure-skupper-localhost-san: secret SAN ready\n'
    break
  fi
  apply_hosts || true
  sleep 2
done
if ! secret_has_localhost_san; then
  printf 'error: skupper-site-server secret never gained 127.0.0.1 SAN\n' >&2
  exit 1
fi

if ! peer_has_localhost_san; then
  printf 'ensure-skupper-localhost-san: restarting west routers to present new cert\n'
  kubectl --context "${WEST_CTX}" -n "${NS}" delete pod -l skupper.io/component=router --wait=false >/dev/null
  kubectl --context "${WEST_CTX}" -n "${NS}" rollout status deploy/skupper-router --timeout=90s >/dev/null
  sleep 2
fi

if peer_has_localhost_san; then
  printf 'ensure-skupper-localhost-san: peer :55671 presents 127.0.0.1 SAN\n'
else
  printf 'warn: peer :55671 still missing 127.0.0.1 SAN — link may stay Pending until CCM refreshes\n' >&2
fi
