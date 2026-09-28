# Tasks: KCD BA Demo Backup (stage commands + agent recordings)

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~180–320 (docs + thin scripts + gitignore/README) |
| 400-line budget risk | Low |
| Chained PRs recommended | No |
| Suggested split | Single PR (docs + scripts) |
| Delivery strategy | ask-on-risk |
| Chain strategy | size-exception |

Decision needed before apply: No
Chained PRs recommended: No
Chain strategy: size-exception
400-line budget risk: Low

User locked: continue all; prefer **single docs+scripts PR** (or local-only). **No push without explicit approval.**

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Stage docs + recording runbook + record helpers + outside-git policy | Single PR (or local-only) | `test -f openspec/changes/kcd-ba-demo-backup/stage-commands.md && test -f openspec/changes/kcd-ba-demo-backup/recording-runbook.md` | Orchestrator `make up` then dry-run record helpers writing under `/home/fmeneses/Videos/kcd-ba-demo-backup/` (N/A until stack up); verify no media under git `git status --ignored` | Revert PR / discard branch; host media dir independent |

## Phase 1: Foundation (host path + offline policy)

- [x] 1.1 Create host directory `/home/fmeneses/Videos/kcd-ba-demo-backup/` (outside git; not an edit target in-repo)
- [x] 1.2 Add or update `.gitignore` with patterns for `*.mp4`, `*.webm`, `*.cast`, `*.gif` (and any local `Videos/` symlink) so media cannot land in commits by accident
- [x] 1.3 Add a short README pointer (one or two lines) that backup videos live at `/home/fmeneses/Videos/kcd-ba-demo-backup/` and must not be committed; restate no proprietary RH PPTX / no video binaries in git

## Phase 2: Stage cheat sheet

- [x] 2.1 Create `openspec/changes/kcd-ba-demo-backup/stage-commands.md` with header: A=Francisco Meneses, B=Sergio Canales; sites allowlist `kind-west`/`kind-east`/`podman-edge`; never `kind-cluster`; binary/offline policy one-liner
- [x] 2.2 In `openspec/changes/kcd-ba-demo-backup/stage-commands.md`, document pre-warm off-clock: `prereq-check` → `up` → `smoke` → hosts → optional `ui` (ACCESS_URLs)
- [x] 2.3 In `openspec/changes/kcd-ba-demo-backup/stage-commands.md`, document live ordered block with clock, owner, exact Make command, expected signal, and backup clip ID for `01-skupper`, `02-mesh`, `03-ratelimit-429`, `04-failover`
- [x] 2.4 In `openspec/changes/kcd-ba-demo-backup/stage-commands.md`, document optional UI A→B→C, skip-first cut rule, ≤2m abandon → play clip, teardown (`ui-down`/`down`), and clip index pointing at the outside-git path (filenames only, no binaries)

## Phase 3: Recording runbook + helpers

- [x] 3.1 Create `openspec/changes/kcd-ba-demo-backup/recording-runbook.md` documenting agent CLI capture via asciinema or `script`, export to mp4/gif with `ffmpeg`/`agg` when available, silent audio, output under `/home/fmeneses/Videos/kcd-ba-demo-backup/`, naming `kcd-ba-{nn}-{cue}.*`
- [x] 3.2 In `openspec/changes/kcd-ba-demo-backup/recording-runbook.md`, document Playwright `recordVideo` for UI A/B/C (no mic), hygiene (never open `demo/.run/`, never show basic-auth, never use `kind-cluster`), and prerequisite that orchestrator has run `make up`
- [x] 3.3 Create `demo/scripts/record-talk-backup/` with thin helpers: CLI record wrapper (asciinema/`script` + optional export) writing only to the outside-git media root
- [x] 3.4 Add Playwright record helper under `demo/scripts/record-talk-backup/` for optional UI clips (`05-ui-a`, `06-ui-b`, `07-ui-c`) with `recordVideo` and no microphone

## Phase 4: Spec touch-up (optional, thin)

- [x] 4.1 If applying a minimal delta: update `openspec/specs/kcd-talk-deck/spec.md` so backup contingency covers per-cue wow moments (not failover-only) and outside-git agent-recorded media; otherwise leave a note in `openspec/changes/kcd-ba-demo-backup/recording-runbook.md` that the archive requirement is widened operationally

## Phase 5: Verification + delivery gate

- [x] 5.1 Verify docs exist and cross-link: `stage-commands.md` clip IDs match `recording-runbook.md` inventory; no secrets or proprietary RH PPTX paths in new files
- [x] 5.2 Confirm `git status` shows no media under the worktree; host dir may contain recordings after rehearsal
- [x] 5.3 Package as one work unit on a feature branch for a **single docs+scripts PR** (size-exception) **or keep local-only**; **do not `git push` or open a remote PR without explicit user approval**
