# Apply Progress: multicluster-connectivity-demo

**Mode**: Standard (strict_tdd: false)
**Batch**: WU5 / PR5-failover-docs-lb (tasks 5.1–5.3 + 6.1–6.2 + cloud-provider-kind LB)
**Delivery**: feature-branch-chain
**Updated**: 2026-07-30

## Completed Tasks

### WU1–WU4 (prior)
- [x] 1.1–1.5, 2.1–2.5, 3.1–3.3, 4.1–4.3

### WU5 (this batch)
- [x] 5.1 Create `demo/scripts/smoke.sh` + `make smoke`
- [x] 5.2 Create `demo/scripts/failover.sh` + `make failover`
- [x] 5.3 Wire remaining `Makefile` `demo-*` targets
- [x] 6.1 Complete `demo/VERSIONS.md` (incl. cloud-provider-kind)
- [x] 6.2 Create `README.md` 30-min runbook

**Plus:** cloud-provider-kind LoadBalancer lifecycle (prereq, up start, down stop-if-owned, Kind exclude label clear).

## Remaining

None — **21/21 tasks complete**. Ready for `sdd-verify`.

## Work Unit Evidence (WU5)

| Evidence | Result |
|----------|--------|
| Focused test command | `make smoke` → exit 0 (23 passed offline); `make failover` → exit 0 (8 passed offline); allowlist 4/4; demo-mesh 16/16; demo-skupper 31/31 |
| Runtime harness | Live kill-primary→east **not** run (no demo Kind). Live paths in smoke/failover scripts. CCM install documented; not on PATH yet. |
| Rollback boundary | `demo/scripts/{smoke,failover,cloud-provider-kind}.sh`, `README.md`; restore prior Makefile/up/down/prereq/VERSIONS/skupper README/.gitignore/tasks; uncheck 5.1–6.2 |

## Deviations

- LB locked to **cloud-provider-kind** (not MetalLB); Skupper Ready waits with actionable hints.
- Live smoke/failover deferred (offline preferred).
