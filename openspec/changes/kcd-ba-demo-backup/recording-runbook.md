# Recording runbook — agent backup clips

Silent, outside-git media for talk contingency. Live Spanish VO on stage; **no microphone** in recordings.

**Orchestrator prerequisite:** run `make up` (and usually `make smoke`) before recording live cues. This runbook does not bring the stack up.

**Stage cheat sheet:** [stage-commands.md](./stage-commands.md)  
**Helpers:** `demo/scripts/record-talk-backup/`

### Spec note (archive widened operationally)

The archived talk-deck packaging originally required failover-only offline video. This change **widens** backup contingency to **per-cue wow moments** (Skupper, mesh, RateLimit 429, failover, optional UI A/B/C) with agent-recorded media under the outside-git path below. See also the thin delta in `openspec/specs/kcd-talk-deck/spec.md`.

---

## Media root and naming

| Item | Value |
|------|-------|
| Output directory | `/home/fmeneses/Videos/kcd-ba-demo-backup/` |
| Basename pattern | `kcd-ba-{nn}-{cue}.{ext}` |
| Audio | Silent (no mic, no voiceover in file) |
| Git | **Never** commit `.cast` / `.mp4` / `.webm` / `.gif` / PPTX |

Examples: `kcd-ba-03-ratelimit-429.cast`, `kcd-ba-04-failover.mp4`, `kcd-ba-05-ui-a.webm`.

Clip IDs MUST match [stage-commands.md](./stage-commands.md): `01-skupper` … `07-ui-c`.

---

## CLI capture (cues 01–04)

### Preferred: asciinema

```bash
# From repo root, after make up:
./demo/scripts/record-talk-backup/record-cli.sh 01-skupper -- make demo-skupper
./demo/scripts/record-talk-backup/record-cli.sh 02-mesh -- make demo-mesh
./demo/scripts/record-talk-backup/record-cli.sh 03-ratelimit-429 -- make demo-ratelimit
./demo/scripts/record-talk-backup/record-cli.sh 04-failover -- make failover
```

Writes `/home/fmeneses/Videos/kcd-ba-demo-backup/kcd-ba-{id}.cast` when `asciinema` is on `PATH`.

### Fallback: `script(1)`

If `asciinema` is missing, the helper uses `script` (util-linux) and writes a typescript log as `kcd-ba-{id}.typescript` (still under the Videos path). Install util-linux / asciinema on the host before rehearsal if either is missing.

### Export to mp4 / gif (optional)

When tools exist:

```bash
# asciinema → gif (agg) or mp4 (ffmpeg via intermediate)
agg /home/fmeneses/Videos/kcd-ba-demo-backup/kcd-ba-03-ratelimit-429.cast \
    /home/fmeneses/Videos/kcd-ba-demo-backup/kcd-ba-03-ratelimit-429.gif

# Or ffmpeg from a capture you already have as video; keep audio track silent/absent
ffmpeg -y -i input.mov -an /home/fmeneses/Videos/kcd-ba-demo-backup/kcd-ba-04-failover.mp4
```

`record-cli.sh` may invoke `agg` or `ffmpeg` when `EXPORT=1` and the tool is available; otherwise export manually after rehearsal.

---

## Browser capture (optional UI 05–07)

Playwright **`recordVideo`** only — **no microphone**.

Prerequisite: `make up` then `make ui` so ACCESS_URLs are live. Prefer printed `ACCESS_URL=` over guessing ports.

```bash
# Install once (host): npx playwright install chromium
ACCESS_URL='http://emojivoto.demo.local:8080/' \
  OUT_FILE='/home/fmeneses/Videos/kcd-ba-demo-backup/kcd-ba-05-ui-a.webm' \
  node demo/scripts/record-talk-backup/record-ui.mjs

ACCESS_URL='http://127.0.0.1:50750/' \
  OUT_FILE='/home/fmeneses/Videos/kcd-ba-demo-backup/kcd-ba-06-ui-b.webm' \
  node demo/scripts/record-talk-backup/record-ui.mjs

ACCESS_URL='https://127.0.0.1:8443/' \
  OUT_FILE='/home/fmeneses/Videos/kcd-ba-demo-backup/kcd-ba-07-ui-c.webm' \
  IGNORE_HTTPS_ERRORS=1 \
  node demo/scripts/record-talk-backup/record-ui.mjs
```

Env:

| Variable | Required | Meaning |
|----------|----------|---------|
| `ACCESS_URL` | yes | Page to open |
| `OUT_FILE` | yes | Absolute path under the Videos media root |
| `IGNORE_HTTPS_ERRORS` | no | Set `1` for observer self-signed cert |
| `HOLD_MS` | no | How long to keep the page open (default 8000) |

---

## Hygiene (MUST)

- Never open or display `demo/.run/` (basic-auth, tokens, pid files).
- Never show basic-auth credentials on camera for UI C — record the console view only after already authenticated off-camera if needed, or record a public/anonymous surface.
- Never use context `kind-cluster`; only `kind-west` / `kind-east` / `podman-edge`.
- Never write media into the git worktree; helpers refuse non-Videos destinations.
- No proprietary RH PPTX paths or marketing in docs or on screen.

---

## Inventory checklist

| Clip ID | Priority | Tool | Done? |
|---------|----------|------|-------|
| `01-skupper` | High | CLI | [ ] |
| `02-mesh` | High | CLI | [ ] |
| `03-ratelimit-429` | Must | CLI | [ ] |
| `04-failover` | Must | CLI | [ ] |
| `05-ui-a` | Optional | Playwright | [ ] |
| `06-ui-b` | Optional | Playwright | [ ] |
| `07-ui-c` | Optional | Playwright | [ ] |

After recording: `git status` in the repo MUST NOT list media; host dir may contain files.
