# Tasks: KCD BA Talk Deck

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | ~280–420 (docs only) |
| 400-line budget risk | Medium |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 → PR 2 (optional docs) |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: No (resolved: ask-on-risk + feature-branch-chain; WU1 done; WU2 this batch)
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: Medium

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Core scripts + Gemini + design↔spec close | PR 1 | `rg -n 'kind-cluster\|demo-skupper\|demo-mesh\|demo-ratelimit\|failover' openspec/changes/kcd-ba-talk-deck/` | N/A — docs packaging; live rehearsal is off-PR | Revert `scripts.md`, `gemini-prompts.md`, `design.md` edits |
| 2 | Speaker cards + README pointer + polish | PR 2 (base=PR1 if chained) | `rg -n 'Talk deck\|speaker-cards\|Rehearsal' README.md openspec/changes/kcd-ba-talk-deck/` | N/A — checklist documents `make smoke`/`ui`/`failover`; no CI runner | Revert `speaker-cards.md`, README pointer |

## Phase 1: Align design ↔ spec

- [x] 1.1 In `design.md` Open Questions: mark spec present/aligned; lock `speaker-cards.md` = YES (thin A/B cue cards ≤1 screen each).
- [x] 1.2 Spot-fix any remaining design↔`specs/kcd-talk-deck/spec.md` drift (speakers, timing, UI A→B→C, outside-git video); keep edits tiny.

## Phase 2: Materialize talk artifacts

- [x] 2.1 Create `openspec/changes/kcd-ba-talk-deck/scripts.md`: slides 1–12 ES titles/points, A=Francisco/B=Sergio, timing, Make cues (`demo-skupper`, `demo-mesh`, `demo-ratelimit`→429, `failover`, `ui`); hybrid ES+EN tech terms; never `kind-cluster`.
- [x] 2.2 In `scripts.md`, add Rehearsal checklist: `prereq-check`→`up`→`smoke`; optional `ui` A→B→C; live `failover` + outside-git video contingency; ≤2m abandon; cut UI then Option-C.
- [x] 2.3 Create `gemini-prompts.md`: EN 16:9 community prompts for slides 1–12 refined from `exploration.md` (no proprietary copy).
- [x] 2.4 Create `speaker-cards.md`: thin one-pagers for A and B (cues + handoffs only).
- [x] 2.5 Optional: add README “Talk deck” one-line pointer → `openspec/changes/kcd-ba-talk-deck/` (or archived path later).

## Phase 3: Policy + verify

- [x] 3.1 State explicitly in `scripts.md` (or cards): MUST NOT commit PPTX/video binaries, `demo/.run` secrets, QR/bios, or proprietary workshop text.
- [x] 3.2 Offline check vs spec scenarios: 12 slides+owners; hybrid wording; Make cues 7–10; CTA `up`→`smoke`→optional `ui`→`down`; demo-stack specs untouched.
  - Result (WU2): PASS — 12 slides in `scripts.md`; A=Francisco / B=Sergio; hybrid ES+EN tech terms; cues `demo-skupper`/`demo-mesh`/`demo-ratelimit`→429/`failover`; CTA `up`→`smoke`→optional `ui`→`down`; `kind-cluster` only as exclusion; `git diff` vs PR1 shows no `openspec/specs/` or `demo/` changes.
- [x] 3.3 Dry-run staged-file review: no binaries/secrets; original narrative from README/`demo/` only.
  - Result (WU2): PASS — staged/new files are text-only (`speaker-cards.md`, README pointer, `scripts.md` rehearsal note, `tasks.md`); no PPTX/video binaries; no `demo/.run/` secrets; policy mentions only (no proprietary workshop copy).
