# Design: `make install` host prerequisites

Approved 2026-10-09. Installs demo host CLIs so `make prereq-check` passes.

## Contract

- `make install` → `demo/scripts/install-prereqs.sh`
- Pins from `demo/VERSIONS.md` (script constants kept in sync)
- CLIs → `~/.local/bin`; podman + inotify via sudo when needed
- Force-overwrite pins with **warn** when replacing another version
- Does **not** edit shell rc files; prints `export PATH=…` + optional idempotent zsh snippet
- Ends by running `prereq-check` with `PATH` prepended

## Out of scope

`make up`, clusters, `make uninstall`, non-linux/amd64 (fail clearly).
