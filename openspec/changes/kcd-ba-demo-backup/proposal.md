# Proposal: KCD BA Demo Backup (stage commands + agent recordings)

## Intent

Expand talk contingency beyond failover-only: give speakers a stage command cheat sheet and agent-recorded per-cue backup media (CLI + browser) stored outside git, so a ≤2-minute demo stall becomes “play matching clip and advance” instead of fighting the laptop.

This is talk-ops / docs + small record helpers — not a demo-stack redesign.

## Scope

### In Scope

- `openspec/changes/kcd-ba-demo-backup/stage-commands.md` — ordered live cues, owners (A=Francisco, B=Sergio), Make targets, expected signals, backup clip IDs
- `openspec/changes/kcd-ba-demo-backup/recording-runbook.md` — how the agent records CLI (asciinema/script → ffmpeg/agg export) and browser UIs (Playwright `recordVideo`, no mic)
- Runnable helpers under `demo/scripts/record-talk-backup/` (optional thin wrappers; docs live in the change folder)
- Outside-git media root: `/home/fmeneses/Videos/kcd-ba-demo-backup/` (mkdir + naming convention; binaries never committed)
- Belt-and-suspenders: `.gitignore` entries and/or README one-liner that videos live outside the repo
- Per-cue clip inventory (musts: 429 + failover; highs: Skupper + mesh; optional UI A/B/C)
- Offline policy reminder: no proprietary RH PPTX; no video binaries in git; no `demo/.run/` secrets on camera
- Delivery: prefer single docs+scripts PR or local-only; **no push without explicit approval**

### Out of Scope

- OBS / GNOME Screencast as the primary capture path (superseded by locked agent-recording approach)
- Microphone / narrated audio in backup clips (silent media + live Spanish VO on stage)
- Demo stack changes (`Makefile` targets, Kuadrant/Linkerd/Skupper manifests, UI surface behavior)
- Mutating archived `openspec/changes/archive/2026-09-28-kcd-ba-talk-deck/`
- Committing PPTX, Keynote, `.mp4`/`.webm`/`.cast` binaries, or proprietary workshop content
- Operating or recording against `kind-cluster`
- Full separate `sdd-spec` / `sdd-design` artifacts for this thin docs change (requirements captured here + tasks; optional archive delta to `kcd-talk-deck` can land at apply if needed)

## Capabilities

### New Capabilities

- None (talk-ops docs and record helpers extend existing talk packaging; no new archived capability domain)

### Modified Capabilities

- `kcd-talk-deck`: Widen offline backup requirement from failover-only to per-cue wow moments (Skupper, mesh, 429, failover, optional UI); document agent-recorded capture (CLI asciinema/script + Playwright video) and outside-git storage path. Demo-stack specs remain unmodified.

## Approach

1. **Per-cue short clips** (not one long reel) aligned to live Make/UI cues; stage rule remains live-first → ≤~2m abandon → play matching clip.
2. **Agent records backups** (hybrid capture):
   - CLI cues → `asciinema` or `script` session; export gif/mp4 via `ffmpeg` and/or `agg` when available
   - Browser UIs → Playwright `recordVideo` (no microphone)
3. **Storage**: write all media under `/home/fmeneses/Videos/kcd-ba-demo-backup/` with names `kcd-ba-{nn}-{cue}.{ext}`; never under the git worktree.
4. **Docs in change folder**: `stage-commands.md` (talk cheat sheet) + `recording-runbook.md` (how to record/replay); helpers under `demo/scripts/record-talk-backup/`.
5. **Stack for recording**: orchestrator/`make up` brings the demo stack so record helpers can run against real cues; recording itself is rehearsal work, not a git artifact.
6. **Thin SDD path**: proposal + tasks → apply; skip full delta-spec/design docs for this change.

### Clip inventory

| ID | Cue | Owner | Capture | Priority |
|----|-----|-------|---------|----------|
| `01-skupper` | `make demo-skupper` | B | CLI | High |
| `02-mesh` | `make demo-mesh` | B | CLI | High |
| `03-ratelimit-429` | `make demo-ratelimit` / UI A burst | A | CLI (+ optional browser) | Must |
| `04-failover` | `make failover` | A | CLI | Must |
| `05-ui-a` | browser `:8080` | A | Playwright | Optional |
| `06-ui-b` | Viz `:50750` | B | Playwright | Optional |
| `07-ui-c` | observer `:8443` | B | Playwright (UI only; no basic-auth) | Optional |

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `openspec/changes/kcd-ba-demo-backup/stage-commands.md` | New | Stage cheat sheet (commands + ownership + clip IDs) |
| `openspec/changes/kcd-ba-demo-backup/recording-runbook.md` | New | Agent recording procedure (CLI + Playwright) |
| `demo/scripts/record-talk-backup/` | New | Thin record helper scripts (if needed beyond docs) |
| `openspec/specs/kcd-talk-deck/spec.md` | Modified (optional at apply) | Widen backup clips beyond failover-only |
| `.gitignore` / `README.md` | Modified | Point to outside-git video root; ignore video patterns |
| `/home/fmeneses/Videos/kcd-ba-demo-backup/` | New (host) | Media root outside git |
| `Makefile` + `demo/scripts/{demo-*,failover,ui}.sh` | Unchanged | Cue authority only (read-only) |
| Archive talk-deck files | Unchanged | Read-only references |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Live flakiness still primary | Med | Per-cue clips + ≤2m abandon rule; rehearse player/HDMI |
| Secrets / basic-auth on screen | Med | Runbook forbids `demo/.run/`; UI-C records console only |
| `kind-cluster` wrong context | Low | Sites allowlist in cheat sheet; scripts already refuse it |
| Missing asciinema/agg/Playwright on host | Med | Runbook documents prerequisites; degrade to `script` + ffmpeg; orchestrator `make up` for real cues |
| Accidental commit of media | Low | Outside-git path + `.gitignore` + offline policy in docs |
| Proprietary RH PPTX creep | Low | Explicit out-of-scope; no PPTX in repo |
| Oversized PR for docs+scripts | Low | Single-PR with size-exception; no push without approval |

## Rollback Plan

- Delete or revert the change-folder docs and `demo/scripts/record-talk-backup/` via git revert of the docs PR (or discard local branch).
- Remove optional `.gitignore` / README pointer lines the same way.
- Leave host media directory untouched or `rm -rf /home/fmeneses/Videos/kcd-ba-demo-backup/` if desired — it is not versioned.
- If a `kcd-talk-deck` delta was applied, revert that delta; failover-only requirement remains the prior baseline.

## Dependencies

- Demo stack available via `make up` (orchestrator responsibility) before agent recording runs
- Host tools: `asciinema` and/or `script`; `ffmpeg`; optional `agg`; Node/Playwright for browser clips
- Existing Make cues: `demo-skupper`, `demo-mesh`, `demo-ratelimit`, `failover`, optional `ui`
- Archived talk deck (`scripts.md`, `speaker-cards.md`) as read-only cue/ownership sources
- Disk space under `/home/fmeneses/Videos/` (already ample per explore)

## Success Criteria

- [ ] `stage-commands.md` lists ordered live cues with A/B owners, Make commands, expected signals, and backup clip IDs
- [ ] `recording-runbook.md` documents agent CLI + Playwright capture, output path, naming, and hygiene (no secrets, no `kind-cluster`, silent video)
- [ ] Media root exists at `/home/fmeneses/Videos/kcd-ba-demo-backup/` and is documented as outside git
- [ ] Repo has no committed video/PPTX binaries; offline policy is explicit in docs
- [ ] Record helpers (if present) write only under the outside-git path
- [ ] Delivery stays local or single docs PR; **no remote push without explicit user approval**
