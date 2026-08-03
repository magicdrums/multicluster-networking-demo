# Archive Report: demo-script-consolidation

**Status**: DONE — change archived and closed  
**Date**: 2026-08-03  
**Mode**: hybrid (openspec + Engram)  
**Archive performed**: YES — main specs already promoted at apply; change folder moved  
**Branch tip at close**: `demo-script-consolidation-pr3-readme` @ `fbe1d47` (PR #8)

## Gate outcomes

| Gate | Result |
|------|--------|
| Task Completion | PASS — 17/17 tasks `[x]` in archived `tasks.md` and Engram #709 |
| CRITICAL in verify | PASS — 0 critical (filesystem verify-report.md; Engram #712) |
| Verify verdict (snapshot at verify time) | PASS WITH WARNINGS — 7/7 requirements, 16/16 scenarios COMPLIANT; archive allowed by verify |
| Native Review Receipt | PASS — `reviewGate.result: allow`; lineage `review-902d347a10e24d2c`; `terminal_state: approved` |
| Action context | PASS — repo-local; edits inside `/home/fmeneses/demos/kcd-argentina2026` |
| Post-apply validate | PASS — result=`allow` (orchestrator launch fact) |

## Final-state authority (at close)

Highest-ranked sources at archive time:

1. **Native review** — `reviewGate.result: allow`; receipt `terminal_state: approved` for lineage `review-902d347a10e24d2c`; post-apply gate allow. Native `review-state.json` nested `state: approved`.
2. **Tasks** — 17/17 complete; no unchecked implementation tasks in filesystem or Engram #709.
3. **Launch-prompt final-state facts** — verify was PASS WITH WARNINGS; PF pidfile warning fixed in `0bb8f12` (`fix(demo-script-consolidation): persist UI PF pid/port and port-fallback teardown`); specs `talk-ui-surface` and `skupper-van` already promoted during apply; sdd-status `next: archive`, `archive: ready`; tip `fbe1d47` on PR3 branch.
4. **verify-report** (intermediate snapshot, Engram #712 / filesystem, written ~2026-07-31 against tip `b004371`) — PASS WITH WARNINGS; 0 CRITICAL; offline 124/124; live `make ui`/`ui-down` exercised. At verify time WARNING noted missing `ui-skupper-observer` pidfile / brief orphan `:8443` listener. **Final state**: that warning is closed by `0bb8f12` (pid/port persistence + port-fallback teardown in `ui-common.sh` / `ui-down.sh`). Do not treat the verify-time WARNING as still open.

No CRITICAL findings. No unrankable contradictions.

## Specs synced

At archive time, delta requirements were already present in main specs (promoted during apply task 3.5). Archive performed confirmation only — no additional merge edits, no REMOVED/RENAMED, no destructive merge.

| Domain | Action | Details |
|--------|--------|---------|
| talk-ui-surface | Confirmed (pre-promoted) | 2 ADDED + 4 MODIFIED requirements already in `openspec/specs/talk-ui-surface/spec.md` (6 requirements total) |
| skupper-van | Confirmed (pre-promoted) | 1 MODIFIED (`Optional network-observer for VAN visualization`); prior 3 requirements preserved |

**Totals for this change**: 7 requirements / 16 scenarios across 2 domains.

## Archive filesystem

- **Archived to**: `openspec/changes/archive/2026-08-03-demo-script-consolidation/`
- **Active change path**: removed (`openspec/changes/demo-script-consolidation/` no longer present)
- Archive contents: proposal.md, design.md, exploration.md, tasks.md (17/17), verify-report.md, specs/ (talk-ui-surface, skupper-van), this archive-report.md

## Source of truth updated

- `openspec/specs/talk-ui-surface/spec.md` (already reflected new behavior from apply)
- `openspec/specs/skupper-van/spec.md` (already reflected new behavior from apply)

## Observation IDs (traceability)

| Artifact | Engram ID | Notes |
|----------|-----------|-------|
| proposal | #706 | topic `sdd/demo-script-consolidation/proposal` |
| design | #707 | topic `sdd/demo-script-consolidation/design` |
| spec | #708 | topic `sdd/demo-script-consolidation/spec` |
| tasks | #709 | topic `sdd/demo-script-consolidation/tasks`; 17/17 complete |
| verify-report | #712 | topic `sdd/demo-script-consolidation/verify-report` (intermediate; PF warning later fixed in `0bb8f12`) |
| apply-progress | — | not persisted as Engram topic for this change |
| review/transaction | native path | `.git/gentle-ai/review-transactions/v2/review-902d347a10e24d2c/` |
| review/receipt | native file | `review-receipt.json` — `terminal_state: approved` |
| review/state | native file | nested `state: approved` |
| review/gate-context | status / launch | `reviewGate.result: allow`; post-apply validate allow |

## Delivery

Feature-branch chain delivered:

| PR | Scope | Notes |
|----|-------|-------|
| PR1 #6 | `lib/` move + callers | tip ancestors |
| PR2 #7 | `ui.sh` + hard-cut + tests + spec promotion | |
| PR3 #8 | README happy path | tip `fbe1d47`; plus `0bb8f12` pidfile fix |

## SDD cycle complete

The change has been fully planned, implemented, verified, natively reviewed (approved), and archived.
Ready for the next change.
