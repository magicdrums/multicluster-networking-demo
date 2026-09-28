#!/usr/bin/env bash
# Record a Make/curl (or any) cue to the outside-git Videos media root.
# Prefer asciinema (.cast); fall back to script(1) (.typescript).
# Usage: record-cli.sh <clip-id> -- <command...>
# Optional: EXPORT=1 to try agg/ffmpeg after capture when available.
# Env: MEDIA_ROOT (default /home/fmeneses/Videos/kcd-ba-demo-backup)
set -euo pipefail

MEDIA_ROOT="${MEDIA_ROOT:-/home/fmeneses/Videos/kcd-ba-demo-backup}"
CLIP_ID="${1:-}"
shift || true

if [[ -z "${CLIP_ID}" || "${1:-}" != "--" ]]; then
  printf 'usage: %s <clip-id> -- <command...>\n' "${0##*/}" >&2
  printf 'example: %s 03-ratelimit-429 -- make demo-ratelimit\n' "${0##*/}" >&2
  exit 2
fi
shift # --

if [[ "${#}" -lt 1 ]]; then
  printf 'error: missing command after --\n' >&2
  exit 2
fi

case "${CLIP_ID}" in
  *[!a-zA-Z0-9_-]* | "")
    printf 'error: invalid clip-id %q (use kcd-ba naming stem, e.g. 01-skupper)\n' "${CLIP_ID}" >&2
    exit 2
    ;;
esac

# Refuse writing into a git worktree path accidentally pointed via MEDIA_ROOT.
if [[ "${MEDIA_ROOT}" == *"/demos/kcd-argentina2026"* ]] || [[ "${MEDIA_ROOT}" == *"/multicluster-networking-demo"* ]]; then
  printf 'error: MEDIA_ROOT %q looks like the git worktree — use /home/fmeneses/Videos/kcd-ba-demo-backup\n' \
    "${MEDIA_ROOT}" >&2
  exit 1
fi

mkdir -p "${MEDIA_ROOT}"
BASE="${MEDIA_ROOT}/kcd-ba-${CLIP_ID}"

export_optional() {
  local cast_file="$1"
  [[ "${EXPORT:-0}" == "1" ]] || return 0
  if command -v agg >/dev/null 2>&1 && [[ -f "${cast_file}" ]]; then
    agg "${cast_file}" "${BASE}.gif" && printf 'exported %s\n' "${BASE}.gif"
  elif command -v ffmpeg >/dev/null 2>&1 && [[ -f "${cast_file}" ]]; then
    # Best-effort: many hosts lack cast→mp4 without intermediate tools.
    if ffmpeg -y -i "${cast_file}" -an "${BASE}.mp4" 2>/dev/null; then
      printf 'exported %s\n' "${BASE}.mp4"
    else
      printf 'note: EXPORT=1 set but ffmpeg could not decode %s; use agg or manual export\n' "${cast_file}" >&2
    fi
  else
    printf 'note: EXPORT=1 set but neither agg nor usable ffmpeg export available\n' >&2
  fi
}

# Preserve argv quoting for -c shells.
CMD_QUOTED=$(printf '%q ' "$@")

if command -v asciinema >/dev/null 2>&1; then
  OUT="${BASE}.cast"
  printf 'recording with asciinema → %s\n' "${OUT}"
  asciinema rec --overwrite -c "${CMD_QUOTED}" "${OUT}"
  export_optional "${OUT}"
  printf 'wrote %s\n' "${OUT}"
  exit 0
fi

SCRIPT_BIN=""
if command -v script >/dev/null 2>&1; then
  SCRIPT_BIN="$(command -v script)"
elif [[ -x /usr/bin/script ]]; then
  SCRIPT_BIN=/usr/bin/script
fi

if [[ -n "${SCRIPT_BIN}" ]]; then
  OUT="${BASE}.typescript"
  printf 'asciinema missing; falling back to script → %s\n' "${OUT}"
  # util-linux: script -c 'cmd' file
  "${SCRIPT_BIN}" -c "${CMD_QUOTED}" "${OUT}"
  printf 'wrote %s\n' "${OUT}"
  exit 0
fi

printf 'error: neither asciinema nor script(1) found on PATH\n' >&2
printf 'hint: install asciinema (preferred) or util-linux (script), then retry\n' >&2
exit 1
