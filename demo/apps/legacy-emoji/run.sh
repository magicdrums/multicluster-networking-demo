#!/usr/bin/env bash
# Run legacy-emoji on the allowlisted podman-edge network (Skupper connector target).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../../scripts/lib/common.sh
source "${SCRIPT_DIR}/../../scripts/lib/common.sh"

NAME="legacy-emoji"
NETWORK="podman-edge"
# Host-published port so the Podman Skupper connector can use 127.0.0.1 (bootstrap pattern).
HOST_PORT="${LEGACY_EMOJI_HOST_PORT:-18080}"
IMAGE="${LEGACY_EMOJI_IMAGE:-localhost/legacy-emoji:demo}"

demo_require_allowlisted "${NETWORK}" "attach container to" || exit 1

if ! podman network exists "${NETWORK}" >/dev/null 2>&1; then
  printf 'legacy-emoji: creating Podman network %s\n' "${NETWORK}"
  podman network create "${NETWORK}" >/dev/null
fi

if ! podman image exists "${IMAGE}" >/dev/null 2>&1; then
  printf 'legacy-emoji: building %s\n' "${IMAGE}"
  podman build -t "${IMAGE}" -f "${SCRIPT_DIR}/Containerfile" "${SCRIPT_DIR}"
fi

if podman container exists "${NAME}" >/dev/null 2>&1; then
  printf 'legacy-emoji: container %s already exists — restarting\n' "${NAME}"
  podman start "${NAME}" >/dev/null
else
  printf 'legacy-emoji: starting container %s on %s (host 127.0.0.1:%s→8080)\n' \
    "${NAME}" "${NETWORK}" "${HOST_PORT}"
  podman run -d --name "${NAME}" --network "${NETWORK}" \
    -p "127.0.0.1:${HOST_PORT}:8080" \
    --label demo.kcd.ar/plane=skupper \
    --label demo.kcd.ar/role=legacy-emoji \
    "${IMAGE}" >/dev/null
fi

printf 'legacy-emoji: ready (curl -s http://127.0.0.1:%s/)\n' "${HOST_PORT}"
