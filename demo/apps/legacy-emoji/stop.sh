#!/usr/bin/env bash
# Stop/remove legacy-emoji container so podman-edge network can be deleted cleanly.
set -euo pipefail

NAME="legacy-emoji"

if podman container exists "${NAME}" >/dev/null 2>&1; then
  printf 'legacy-emoji: removing container %s\n' "${NAME}"
  podman rm -f "${NAME}" >/dev/null
else
  printf 'legacy-emoji: container %s not present — skipping\n' "${NAME}"
fi
