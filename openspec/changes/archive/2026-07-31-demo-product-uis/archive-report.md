# Archive Report: demo-product-uis

**Status**: DONE — change archived and closed  
**Date**: 2026-07-31  
**Mode**: hybrid (openspec + Engram)  
**Archive performed**: YES — specs promoted, change folder moved

## Gate outcomes

| Gate | Result |
|------|--------|
| Task Completion | PASS — 25/25 tasks `[x]` in archived `tasks.md` and Engram #697 |
| CRITICAL in verify | PASS — 0 critical (filesystem verify-report.md; Engram #700) |
| Verify verdict (snapshot at verify time) | PASS WITH WARNINGS — 9/9 requirements, 16/16 scenarios COMPLIANT; archive allowed by verify |
| Native Review Receipt | PASS — `reviewGate.result: allow`; lineage `review-107ef92ff0509f69`; `terminal_state: approved` |
| Action context | PASS — repo-local; edits inside `/home/fmeneses/demos/kcd-argentina2026` |
| User confirmation | PASS — user confirmed archive after `review validate --gate post-apply: allow` |

## Final-state authority (at close)

Highest-ranked sources at archive time:

1. **Native review** — launch/status facts: `reviewGate.result: allow`; receipt `terminal_state: approved` for lineage `review-107ef92ff0509f69`; post-apply gate allow. Native state file `state: approved`; `fix_finding_ids: []` (findings classified info only — no required fixes).
2. **Tasks** — 25/25 complete; no unchecked implementation tasks.
3. **Launch-prompt final-state facts** — sdd-verify PASS WITH WARNINGS, 16/16 scenarios, archive allowed; native review APPROVED; sdd-status `nextRecommended=archive`, `archive=ready`; user confirmed archive after validate.
4. **verify-report** (intermediate snapshot, Engram #700 / filesystem, written 2026-07-31 ~17:26) — PASS WITH WARNINGS; 0 CRITICAL; offline 97/97; live A/B/C HTTP 200 at verification time. Non-blocking warnings at verify time (Linkerd Viz proxy not up-to-date ‼; offline test-ui-skupper side-effect on live PF) remain informational history, not reopen blockers.

Review findings at close remain informational only (e.g. R1-001 site-file allowlist, R1-002 auth-file sourcing, PF ready-fail leak, readability/reliability suggestions). No CRITICAL; no required fix delta.

## Specs synced

No REMOVED/RENAMED/MODIFIED requirement blocks. No destructive merge.

| Domain | Action | Details |
|--------|--------|---------|
| talk-ui-surface | Created | 4 requirements (Phase A/B/C validation, reserved ports + teardown); 8 scenarios |
| failover-demo | Updated | 2 ADDED (browser Host runbook; UI off critical path); preserved prior 3 |
| east-west-linkerd | Updated | 1 ADDED (optional west-only Viz); preserved prior 3 |
| skupper-van | Updated | 1 ADDED (optional network-observer); preserved prior 3 |
| north-south-kuadrant | Updated | 1 ADDED (no Kuadrant product UI); preserved prior 4 |

**Totals promoted this change**: 9 requirements / 16 scenarios across 5 domains (1 new + 4 deltas).

## Archive filesystem

- **Archived to**: `openspec/changes/archive/2026-07-31-demo-product-uis/`
- **Active change path**: removed (`openspec/changes/demo-product-uis/` no longer present)
- Archive contents: proposal.md, design.md, exploration.md, tasks.md (25/25), verify-report.md, specs/ (5 domains), this archive-report.md

## Source of truth updated

- `openspec/specs/talk-ui-surface/spec.md` (new)
- `openspec/specs/failover-demo/spec.md`
- `openspec/specs/east-west-linkerd/spec.md`
- `openspec/specs/skupper-van/spec.md`
- `openspec/specs/north-south-kuadrant/spec.md`

(`kind-podman-lifecycle` unchanged — out of this change's delta set.)

## Observation IDs (traceability)

| Artifact | Engram ID | Notes |
|----------|-----------|-------|
| proposal | filesystem + #694 | No dedicated Engram topic `sdd/demo-product-uis/proposal`; full text in archived `proposal.md`; #694 records locked validation URLs into proposal |
| explore | #693 | topic `sdd/demo-product-uis/explore` |
| spec | #695 | topic `sdd/demo-product-uis/spec` |
| design | #696 | topic `sdd/demo-product-uis/design` |
| tasks | #697 | topic `sdd/demo-product-uis/tasks`; 25/25 complete |
| apply-progress | #698 | topic `sdd/demo-product-uis/apply-progress` (intermediate) |
| delivery lock | #699 | feature-branch-chain decision |
| verify-report | #700 | topic `sdd/demo-product-uis/verify-report` |
| review/transaction | native path | `.git/gentle-ai/review-transactions/v2/review-107ef92ff0509f69/` |
| review/receipt | native file | `review-receipt.json` — `terminal_state: approved` |
| review/state | native file | nested `state: approved`; findings outcomes all `info` |
| review/gate-context | status / launch | `reviewGate.result: allow`; post-apply validate allow |

## SDD cycle complete

The change has been fully planned, implemented, verified, natively reviewed (approved), and archived.
Ready for the next change.
