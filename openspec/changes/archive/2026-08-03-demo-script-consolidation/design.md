# Design: Demo Script Consolidation

## Technical Approach

Proposal + deltas (`talk-ui-surface`, `skupper-van`): lean `make up`; one public `make ui` = A→B→C start+validate+ACCESS_URLs; hard-cut old UI names; move internals to `demo/scripts/lib/`; offline `test-ui-*` stay Kind-free. No critical-path logic beyond path fixes.

## Architecture Decisions

| Decision | Options | Tradeoff | Choice |
|----------|---------|----------|--------|
| Public UI | Per-phase Make vs one `ui` | Clarity vs granularity | **`make ui` only**; private helpers OK, not help-primary |
| Composition | Mega-`up`/`talk-up` vs `up`→`ui` | One cmd vs lean path | **`up` then optional `ui`**; no `talk-up` |
| Dispatcher | 6 Make scripts vs `ui.sh` | Chaos vs one entry | **`demo/scripts/ui.sh`** |
| Phase impl | All inline vs private modules | Size vs `ls` noise | **Private merged start+check** modules |
| Mid-`ui` fail | Continue vs fail-fast | Partial URLs vs stop | **Fail-fast** (spec): exit≠0; skip later; keep earlier until `ui-down`/`down` |
| Internals | Flat vs `lib/` | Discoverability | **`lib/`**: common, CCM, SAN, redeem |
| `ui-common.sh` | `lib/` vs peer | Declutter vs UI cohesion | **Peer** of `ui.sh`/`ui-down.sh` |
| Hard cut | Aliases vs delete | Memory vs chaos | **Hard cut** — no aliases |
| Offline tests | Merge 3→1 vs keep 3 | Count vs isolation | **Keep 3**; retarget paths (spec-named) |
| Prereq | Extra gate vs existing | Redundancy | **Single** `prereq-check` |

## Data Flow

```text
make up → up.sh (+prereq) → stack [NO UI]
make ui → ui.sh
            ├─ A: ACCESS_URL + hostname probe (200|429)
            ├─ B: Viz start+validate ──fail──► exit≠0 (skip C)
            └─ C: observer start+validate + auth
make ui-down → tear B/C; make down → best-effort ui-down + lib CCM
```

### Tree

```text
BEFORE                         AFTER
demo/scripts/                  demo/scripts/
  common, CCM, SAN, redeem       lib/{common,cloud-provider-kind,
  ui-{app,linkerd,skupper}           ensure-skupper-localhost-san,
    {,-check}.sh                     redeem-podman-skupper}.sh
  ui-common, ui-down             ui.sh, ui-common, ui-down
  up/down/smoke/…                ui/_phase_{a,b,c}.sh  # private
                                 up/down/… → source lib/
```

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `Makefile` | Modify | Add `ui`; drop per-phase UI/help; keep `ui-down` |
| `demo/scripts/ui.sh` | Create | A→B→C fail-fast dispatcher |
| `demo/scripts/ui/_phase_{a,b,c}.sh` | Create | Merged start+validate |
| `ui-app*.sh`, `ui-linkerd*.sh`, `ui-skupper*.sh` | Delete | Hard cut |
| `ui-common.sh`, `ui-down.sh` | Modify | Source `lib/common.sh` |
| `demo/scripts/lib/*` | Create | Relocated internals |
| `up.sh`/`down.sh`/`prereq-check.sh`/probes/redeem | Modify | Paths → `lib/` |
| `test-ui-*.sh`, `smoke.sh`, `check-skupper.sh` | Modify | Assert new surface |
| `README.md` | Modify | Happy path `up`→optional `ui`→`down` |
| `openspec/specs/talk-ui-surface`, `skupper-van` | Modify | Apply deltas |

## Interfaces / Contracts

```bash
ui: $(SCRIPTS)/ui.sh          # fail-fast A→B→C
ui-down: $(SCRIPTS)/ui-down.sh
# Optional private: PHASE=all|a|b|c on ui.sh — not Make help
LIB_DIR="${SCRIPT_DIR}/lib"; source "${LIB_DIR}/common.sh"
```

ACCESS_URL, reserved ports, never-in-`up`, allowlist unchanged.

## Testing Strategy

| Layer | What | Approach |
|-------|------|----------|
| Offline | A/B/C contracts | Keep `test-ui-{foundation,linkerd,skupper}`; assert `ui`/`lib/`; refuse old names |
| Offline | Probes | Update greps in smoke/`check-skupper` |
| Live | Manual | `ui` prints 3 URLs; mid-B fail skips C; `ui-down` clears B/C |

## Threat Matrix

| Boundary | Applicability | Design response | Planned RED tests |
|---|---|---|---|
| Documentation-like paths | N/A — no executable-doc class | — | — |
| Git repository selection | N/A — no repo picker | — | — |
| Commit / push / PR cmds | N/A — no VCS/PR automation | — | — |

## Migration / Rollout

README + help: `prereq-check` → `up` → `smoke` → optional `ui` → `down`. Hard cut with tests/specs same land. `delivery_strategy: ask-on-risk`; **High** 400-line risk → Feature Branch Chain:

| PR | Scope |
|----|-------|
| 1 | `lib/` move + all callers/greps (old UI still works) |
| 2 | `ui.sh` + hard-cut Make + `test-ui-*` + promote specs |
| 3 | README remainder if PR2 over budget |

Ask before apply: chain vs `size:exception`.

## Open Questions

- [ ] Private path: `ui/_phase_*.sh` vs flat `ui-phase-*.sh` (prefer subdir)
- [ ] Private `PHASE=a|b|c` on `ui.sh` for rehearsal (recommend yes; not Make help)
- [ ] Confirm chain vs exception at apply (`ask-on-risk`)
