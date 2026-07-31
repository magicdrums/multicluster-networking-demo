#!/usr/bin/env bash
# Link podman-edge → kind-west over CCM host port-mapping (Option C).
#
# Rootless Podman: grant/router EXTERNAL-IPs are 10.89.0.x (Kind netns). The
# host-networked Skupper router cannot route there, but cloud-provider-kind
# maps router ports to host *:45671/*:55671. We:
#   1) ensure west server cert SANs include 127.0.0.1,
#   2) redeem the grant from a helper on network `kind` (grant URL is 10.89.0.x),
#   3) rewrite Link endpoints to 127.0.0.1,
#   4) reload podman-edge and wait for Link Ready.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

ROOT="$(demo_repo_root)"
TOKEN_FILE="${SKUPPER_TOKEN_FILE:-${ROOT}/demo/skupper/.tokens/west.token}"
SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/podman/podman.sock"
IMG="${SKUPPER_REDEEM_IMAGE:-docker.io/library/fedora:40}"
LINK_WAIT_SEC="${SKUPPER_LINK_WAIT_SEC:-90}"
INPUT_LINKS="${HOME}/.local/share/skupper/namespaces/podman-edge/input/resources"

if [[ ! -f "${TOKEN_FILE}" ]]; then
  printf 'error: token file missing: %s (run make up / token issue on kind-west first)\n' "${TOKEN_FILE}" >&2
  exit 1
fi
if [[ ! -S "${SOCK}" ]]; then
  printf 'error: podman socket not found at %s\n' "${SOCK}" >&2
  exit 1
fi

printf 'redeem-podman-skupper: ensuring west TLS SANs include 127.0.0.1\n'
"${SCRIPT_DIR}/ensure-skupper-localhost-san.sh"

printf 'redeem-podman-skupper: pulling helper image %s\n' "${IMG}"
podman pull "${IMG}" >/dev/null

printf 'redeem-podman-skupper: redeem via --network kind (grant URL is 10.89.0.x)\n'
podman run --rm --network kind \
  -v "${SOCK}:/run/podman/podman.sock:Z" \
  -e CONTAINER_HOST=unix:///run/podman/podman.sock \
  -v "${HOME}/.local/share/skupper:/var/lib/skupper:Z" \
  -v "$(command -v skupper):/skupper.bin:ro,Z" \
  -v "$(dirname "${TOKEN_FILE}"):/tokens:Z" \
  --entrypoint /bin/bash \
  "${IMG}" \
  -lc "cp /skupper.bin /tmp/skupper && chmod +x /tmp/skupper && /tmp/skupper token redeem /tokens/$(basename "${TOKEN_FILE}") -p podman -n podman-edge --timeout 2m"

printf 'redeem-podman-skupper: rewriting Link endpoints → 127.0.0.1 (CCM host map)\n'
python3 - <<'PY'
from pathlib import Path
import re

root = Path.home() / ".local/share/skupper/namespaces/podman-edge/input/resources"
if not root.is_dir():
    raise SystemExit(f"missing {root}")
pat = re.compile(
    r"(^\s*host:\s*)(?:10\.89\.\d+\.\d+|127\.0\.0\.1)(\s*)$",
    re.MULTILINE,
)
for path in sorted(root.glob("Link-*.yaml")):
    text = path.read_text()
    new, n = pat.subn(r"\g<1>127.0.0.1\2", text)
    if n:
        path.write_text(new)
        print(f"rewrote {path.name} ({n} host(s))")
    else:
        # Fallback: any host adjacent to skupper router ports in endpoints blocks
        lines = text.splitlines(keepends=True)
        out = []
        changed = 0
        for line in lines:
            if re.match(r"^\s*host:\s*\S+", line) and "host:" in line:
                out.append(re.sub(r"(host:\s*)\S+", r"\g<1>127.0.0.1", line, count=1))
                if out[-1] != line:
                    changed += 1
            else:
                out.append(line)
        if changed:
            path.write_text("".join(out))
            print(f"rewrote {path.name} ({changed} host(s), fallback)")
        else:
            print(f"no host rewrite needed in {path.name}")
PY

printf 'redeem-podman-skupper: reload podman-edge site\n'
# Re-assert SANs right before reload (SecuredAccess may race).
"${SCRIPT_DIR}/ensure-skupper-localhost-san.sh" >/dev/null || true
skupper system reload -p podman -n podman-edge >/dev/null 2>&1 || true
skupper system start -p podman -n podman-edge >/dev/null 2>&1 || true

printf 'redeem-podman-skupper: waiting up to %ss for Link Ready\n' "${LINK_WAIT_SEC}"
deadline=$((SECONDS + LINK_WAIT_SEC))
ready=0
while (( SECONDS < deadline )); do
  if skupper -p podman -n podman-edge link status 2>/dev/null | grep -qiE 'Ready[[:space:]]+0[[:space:]]+OK|Ready[[:space:]].*OK'; then
    ready=1
    break
  fi
  # Keep SAN sticky while waiting for first successful dial.
  "${SCRIPT_DIR}/ensure-skupper-localhost-san.sh" >/dev/null 2>&1 || true
  sleep 3
done

skupper -p podman -n podman-edge link status || true
skupper -p podman -n podman-edge connector status || true

if [[ "${ready}" -eq 1 ]]; then
  printf '\nredeem-podman-skupper: Link Ready (host CCM path 127.0.0.1:45671/55671)\n'
  printf 'hybrid check: kubectl --context kind-kind-west -n skupper run -i --rm --restart=Never curl-legacy \\\n'
  printf '  --image=curlimages/curl --command -- curl -sS http://legacy-emoji.skupper:8080/\n'
  exit 0
fi

printf '\nerror: Link still not Ready after %ss — see demo/skupper/README.md (Option C)\n' "${LINK_WAIT_SEC}" >&2
exit 1
