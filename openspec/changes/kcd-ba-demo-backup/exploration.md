# Exploration: kcd-ba-demo-backup

**Change:** `kcd-ba-demo-backup`  
**Project:** kcd-argentina2026  
**Mode:** hybrid (openspec + Engram)  
**Artifact language:** English  
**Related:** archived `openspec/changes/archive/2026-09-28-kcd-ba-talk-deck/` (`scripts.md`, `speaker-cards.md`, `design.md`); main spec `openspec/specs/kcd-talk-deck/spec.md`

---

## Exploration: Backup demo videos + stage command cheat sheet

### Current State

The laptop demo and 30-min dual-speaker talk packaging already exist on `main`:

| Fact | Value |
|------|-------|
| Sites | `kind-west`, `kind-east`, `podman-edge` — **never** operate `kind-cluster` |
| Stack | Envoy Gateway + Kuadrant + Linkerd + Skupper + CoreDNS |
| Public path | `make up` → `make smoke` → optional `make ui` (A→B→C) → `make down` |
| Critical-path Make | `demo-skupper` (B), `demo-mesh` (B), `demo-ratelimit`→429 (A), `failover` (A) |
| Speakers | A = Francisco Meneses · B = Sergio Canales |
| Timing | 0–5 open · 5–9 topo · 9–16 Skupper+mesh · 16–25 429+failover · 25–30 close |
| Abandon rule | Stuck demo ≤ ~2 min → skip UI / play local video / cut Option-C slide |
| Binary policy | **No** PPTX, video, proprietary RH workshop content, or `demo/.run/` secrets in git |

`kcd-talk-deck` already **requires** failover live-first with an **outside-git** backup video. This change expands that contingency to all stage wow moments and adds a **stage runbook MD** (commands + ownership) — docs/process only; no demo-stack redesign.

**Host recording discovery (Fedora 44, Wayland + GNOME, dry-run):**

| Tool | Status |
|------|--------|
| GNOME Screencast (`Ctrl+Shift+Alt+R`) | Available (gnome-shell 50.5 + PipeWire + xdg-desktop-portal-gnome) |
| `ffmpeg` 8.1.2 (`ffmpeg-free`) | Present — encode/trim helper, not ideal alone for interactive Wayland capture |
| `gnome-screenshot` | Present — stills only |
| OBS / obs-studio | **Missing** (not installed; Flatpak Obsidian only) |
| SimpleScreenRecorder, Peek, Kooha, `wf-recorder`, `wl-screenrec` | **Missing** |

Suggested off-repo media root (empty today): `/home/fmeneses/Videos/kcd-ba-demo-backup/` (~733 Gi free on `/home`).

### Affected Areas

- `openspec/changes/kcd-ba-demo-backup/` — this change (explore → propose → apply creates cheat sheet)
- `openspec/specs/kcd-talk-deck/spec.md` — may gain a delta widening backup clips beyond failover-only (proposal decides)
- `openspec/changes/archive/2026-09-28-kcd-ba-talk-deck/{scripts,speaker-cards}.md` — **read-only** sources for cue order/ownership (archive is audit trail; do not mutate)
- `Makefile` + `demo/scripts/{demo-ratelimit,check-east-west,check-skupper,failover,ui}.sh` — cue authority; **no code changes** expected
- `README.md` — optional one-line pointer to stage-commands / backup policy
- **Outside git:** video binaries under `~/Videos/kcd-ba-demo-backup/` (or sibling); never under the repo tree
- **Out of scope:** proprietary Red Hat workshop PPTX content; committing `.mp4`/`.webm`; showing `demo/.run/ui-skupper-basic-auth` on camera

### Approaches

1. **Per-cue short clips (recommended)** — Record 4–7 short MP4/WebM files aligned to live cues; on ≤2m abandon, play the matching clip.
   - Pros: Instant seek per wow; matches cut-order; failover flake does not force seeking a long reel; easy to re-record one cue
   - Cons: More files to manage on stage; need a clear naming convention + player playlist
   - Effort: Medium

2. **One continuous rehearsal reel** — Single 8–15 min capture of the full live block (slides 7–10 ± UI).
   - Pros: One file; captures handoffs/narrative continuity
   - Cons: Hard to jump to the failing cue under time pressure; re-record cost high; exceeds “≤2m abandon → play” UX
   - Effort: Low–Medium

3. **Failover-only + docs (minimal)** — Honor existing spec (failover video only); no other clips; only create `stage-commands.md`.
   - Pros: Smallest scope; already partially planned in talk deck
   - Cons: Leaves Skupper/mesh/429 without contingency; stage laptop risk remains for B’s block
   - Effort: Low

4. **OBS Studio Flatpak as primary capture + GNOME as zero-install fallback** — Tooling choice orthogonal to clip strategy.
   - Pros: OBS = scene layout (terminal + browser), mic, hotkeys; GNOME Screencast works today with zero install
   - Cons: OBS not installed yet (needs Flatpak/dnf install with user approval); GNOME capture is whole-screen/region with less control
   - Effort: Low (install) + Medium (rehearse capture)

| Approach | Pros | Cons | Complexity |
|----------|------|------|------------|
| Per-cue clips | Cue-aligned, ≤2m friendly | More files | Medium |
| One reel | Simple artifact | Bad mid-talk seek | Low–Med |
| Failover-only | Tiny | Incomplete safety net | Low |
| OBS + GNOME fallback | Best quality / zero-install backup | OBS install step | Low–Med |

### Recommendation

**Feasibility: YES.**

**Clip strategy:** Approach **1 — per-cue short clips**, with Approach **4** tooling.

**Recommended tools**

1. **Primary (install):** OBS Studio via Flatpak (`com.obsproject.Studio`) — Wayland-friendly, screen + mic, scenes for terminal vs browser.
2. **Zero-install fallback (already on host):** GNOME Screencast `Ctrl+Shift+Alt+R` → typically lands under `~/Videos/`.
3. **Post:** `ffmpeg` for trim/normalize (already installed). Do **not** rely on SSR/Peek/`wf-recorder` unless installed later.

**Proposed clip inventory** (target ≤45–90s each except failover ≤~2m wall clock of the wow):

| ID | Cue | Owner | Signal to show | Priority |
|----|-----|-------|----------------|----------|
| `01-skupper` | `make demo-skupper` (+ optional `curl :18080`) | B | Kind↔Podman / legacy-emoji OK | High |
| `02-mesh` | `make demo-mesh` | B | Mesh / emojivoto OK | High |
| `03-ratelimit-429` | `make demo-ratelimit` and/or UI A `:8080` burst | A | ≥1 HTTP **429** | **Must** |
| `04-failover` | `make failover` | A | East still answers / dig story | **Must** (spec) |
| `05-ui-a` (opt) | browser `:8080` | A | App + Host header path | Optional |
| `06-ui-b` (opt) | Viz `:50750` | B | Linkerd Viz | Optional |
| `07-ui-c` (opt) | observer `:8443` | B | Console UI only — **no** basic-auth password on screen | Optional |

**Capture / storage rules**

- Resolution: 1920×1080 (or native laptop scaled to 1080p); 30 fps; AAC mic if narrating, else silent OK with speaker live VO.
- Store at: `/home/fmeneses/Videos/kcd-ba-demo-backup/` (recommended) — **outside** the git worktree.
- Naming: `kcd-ba-{nn}-{cue}.mp4` (e.g. `kcd-ba-04-failover.mp4`).
- Stage behavior: live first → if flake ~2m → play matching clip → advance; never fight the laptop.
- Camera hygiene: never open `demo/.run/`; never show `kind-cluster`; accept observer cert warning off-clip or cropped.
- Git: keep binaries out; optionally later add `*.mp4` / `*.webm` to `.gitignore` as belt-and-suspenders (proposal/tasks).

**Cheat sheet MD (next apply — do not create in explore)**

- **Filename:** `openspec/changes/kcd-ba-demo-backup/stage-commands.md`
- **Why here (not archive / not `demo/docs`):** active change owns new talk-ops docs; archived talk deck is immutable; `demo/` stays stack-focused.
- **Ready for Proposal/Apply to create `stage-commands.md`.**

Outline for that file:

1. Header — speakers A=Francisco / B=Sergio; sites allowlist; never `kind-cluster`; binary policy one-liner
2. Pre-warm (off clock) — `prereq-check` → `up` → `smoke` → hosts → optional `ui` (print ACCESS_URLs)
3. Live ordered block — clock, owner, exact Make command, expected signal, backup clip ID
4. UI A→B→C optional — skip-first cut rule
5. Failover contingency — ≤2m → `04-failover` path outside git
6. Teardown — `ui-down` / `down`
7. Clip index — local path prefix + filenames (no binaries)

### Risks

- **Live flakiness remains primary risk** — videos reduce stage death but must be rehearsed with the same player/HDMI as the talk laptop.
- **Audio sync / dual VO** — if clips include mic narration, speakers may talk over them; prefer silent clips + live Spanish VO, or soft bed only.
- **Secrets on screen** — observer basic-auth from `demo/.run/ui-skupper-basic-auth` must never appear in recordings or live camera.
- **`kind-cluster` leakage** — scripts refuse it; speakers must not open wrong kube context in recordings.
- **OBS not installed yet** — install is a host step (user-approved); until then GNOME Screencast is sufficient for feasibility.
- **Failover duration** — live wait up to ~120s; clip should show the wow outcome, not a full timeout.
- **Proprietary creep** — do not paste RH workshop PPTX/video into repo or Engram artifacts.
- **Archive immutability** — do not edit archived talk-deck files; reference them and extend via this change + optional spec delta.

### Ready for Proposal

**Yes.** Orchestrator should tell the user:

- **Feasibility: yes** on this Fedora/GNOME Wayland laptop (GNOME Screencast now; OBS Flatpak recommended).
- **Recommended tools:** OBS Flatpak (primary) + GNOME Screencast (fallback) + `ffmpeg` (trim).
- **Clip list (per-cue), not one reel** — musts: 429 + failover; highs: Skupper + mesh; optional UI A/B/C.
- **Commands MD:** create in **next apply** as `openspec/changes/kcd-ba-demo-backup/stage-commands.md` (outline above); not written in explore.
- **Next:** run **`sdd-propose`** for `kcd-ba-demo-backup` (then design/tasks/apply for cheat sheet + optional gitignore + README pointer; recording itself stays an outside-git rehearsal task).
