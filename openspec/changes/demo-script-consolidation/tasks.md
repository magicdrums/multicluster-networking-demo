# Tasks: Demo Script Consolidation

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 450–700 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR1 `lib/` → PR2 `ui`+hard-cut+tests+specs → PR3 README if needed |
| Delivery strategy | ask-on-risk |
| Chain strategy | feature-branch-chain |

Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Relocate internals to `lib/` | PR1 (base=tracker) | three `test-ui-*` | N/A — path-only; old UI Make works | `demo/scripts/lib/` + callers |
| 2 | `ui.sh` + hard-cut + tests + specs | PR2 (base=PR1) | three `test-ui-*`; `make help` → `ui`/`ui-down` | Manual: `up`→`ui` (3 URLs); mid-B fail skips C; `ui-down` | Makefile, `ui.sh`, `ui/_phase_*`, deleted per-phase UI scripts, tests, specs |
| 3 | README remainder | PR3 (base=PR2) if over budget | README has `make ui`; no old UI names | N/A — docs | `README.md` |

Locks: `make ui` only; no `talk-up`; `lib/`; hard cut; `up` UI-free; keep `ui-down` + 3 suites; `ui/_phase_{a,b,c}.sh`; optional `PHASE=` (not help). Threats: all N/A.

## Phase 1: Foundation — `lib/` move (PR1)

- [x] 1.1 Create `demo/scripts/lib/`; move `common.sh`, `cloud-provider-kind.sh`, `ensure-skupper-localhost-san.sh`, `redeem-podman-skupper.sh` into it
- [x] 1.2 Retarget sources in `up.sh`, `down.sh`, `prereq-check.sh`, `ui-common.sh`, `ui-down.sh`, probes/`redeem` callers → `lib/`
- [x] 1.3 Update greps in `smoke.sh`, `check-skupper.sh`, any docs that hardcode old helper paths
- [x] 1.4 Verify: three `test-ui-*` still green; old per-phase UI Make targets still work

## Phase 2: Core — dispatcher + hard cut (PR2)

- [x] 2.1 Create `demo/scripts/ui/_phase_a.sh` — merge `ui-app`+`ui-app-check` (west ACCESS_URL + hostname 200|429)
- [x] 2.2 Create `demo/scripts/ui/_phase_b.sh` — merge `ui-linkerd`+`ui-linkerd-check` (Viz PF + URL)
- [x] 2.3 Create `demo/scripts/ui/_phase_c.sh` — merge `ui-skupper`+`ui-skupper-check` (observer HTTPS + basic-auth once)
- [x] 2.4 Create `demo/scripts/ui.sh` — A→B→C fail-fast; optional private `PHASE=all|a|b|c`; print ACCESS_URL each phase
- [x] 2.5 Makefile: add `ui` → `ui.sh`; delete `ui-app`, `ui-app-check`, `ui-linkerd`, `ui-linkerd-check`, `ui-skupper`, `ui-skupper-check`; keep `ui-down`; no `talk-up`; help lists `ui`/`ui-down` not old names
- [x] 2.6 Delete `demo/scripts/ui-{app,app-check,linkerd,linkerd-check,skupper,skupper-check}.sh`; ensure `up.sh` remains UI-free

## Phase 3: Testing + specs (PR2)

- [x] 3.1 Retarget `test-ui-foundation.sh` — assert `ui.sh`/`lib/`; refuse old Make/script names; Kind-free
- [x] 3.2 Retarget `test-ui-linkerd.sh` — Phase B via `ui` surface; Viz not in `up`/CCM
- [x] 3.3 Retarget `test-ui-skupper.sh` — Phase C via `ui` surface; observer not in `up`
- [x] 3.4 Assert fail-fast contract offline where feasible (B fail ⇒ C not started)
- [x] 3.5 Promote deltas: `openspec/specs/talk-ui-surface/spec.md`, `openspec/specs/skupper-van/spec.md`

## Phase 4: Docs (PR2 if fits; else PR3)

- [ ] 4.1 README happy path: `prereq-check` → `up` → `smoke` → optional `ui` → `down`; remove old UI target docs
- [x] 4.2 Spot-check `demo/**/*.md` for `ui-app`/`ui-linkerd`/`ui-skupper`/`talk-up` leftovers
