# Tasks: Multicluster Connectivity Demo

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 900–1400 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR1 infra → PR2 N-S → PR3 E-W → PR4 Skupper → PR5 failover+docs |
| Delivery strategy | feature-branch-chain (resolved from ask-on-risk) |
| Chain strategy | feature-branch-chain |

Decision needed before apply: No
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test | Runtime harness | Rollback |
|------|------|-----------|--------------|-----------------|----------|
| 1 | Lifecycle + allowlist RED | PR1 | refuse `CLUSTER=kind-cluster` | `prereq-check.sh` | `Makefile`, `demo/scripts/{prereq,up,down}.sh`, `demo/kind/` |
| 2 | EG+Kuadrant+CoreDNS+RL | PR2 | `make demo-ratelimit` | curl 200/429; dig CoreDNS | `demo/gateway/`, `demo/kuadrant/` |
| 3 | Linkerd+emojivoto | PR3 | `linkerd check` west | meshed web→voting | `demo/linkerd/`, `demo/apps/emojivoto/` |
| 4 | Skupper+legacy-emoji | PR4 | 3-site status | Kind↔Podman emoji | `demo/skupper/`, `demo/apps/legacy-emoji/` |
| 5 | Smoke+failover+docs | PR5 | `make smoke && make failover` | kill-primary→east | smoke/failover scripts, README, VERSIONS |

Caps: lifecycle | N-S | E-W | skupper | failover

## Phase 1: Infra / lifecycle (`kind-podman-lifecycle`)

- [x] 1.1 RED: `demo/scripts/test-allowlist.sh` — `down` refuses non-allowlist (`kind-cluster`); unknown cluster aborts; `up` never creates non-demo names
- [x] 1.2 Create `demo/kind/{west,east}.yaml` (1-node, Podman provider)
- [x] 1.3 Create `demo/scripts/prereq-check.sh` (inotify≥512; CLIs fail-fast)
- [x] 1.4 Create `demo/scripts/{up,down}.sh` allowlist-only; stub `Makefile` `up`/`down`
- [x] 1.5 GREEN: pass allowlist suite; live `up`/`down` leaves `kind-cluster` — deps: 1.1–1.4

## Phase 2: North-south (`north-south-kuadrant`)

- [x] 2.1 Add `demo/gateway/` EG values + Gateway/HTTPRoute→web (both Kind) — deps: 1.4
- [x] 2.2 Add `demo/kuadrant/` ops+Limitador; RateLimitPolicy (429 wow) — deps: 2.1
- [x] 2.3 Add CoreDNS HA + DNSPolicy `emojivoto.demo.local` — deps: 2.2
- [x] 2.4 Optional Authorino API-key AuthPolicy (MAY) — deps: 2.2 — stub: deferred in `demo/kuadrant/README.md` (not on critical path)
- [x] 2.5 Extend `up.sh` EG→Kuadrant/CoreDNS; `Makefile` `demo-ratelimit` — deps: 2.1–2.3

## Phase 3: East-west (`east-west-linkerd`)

- [x] 3.1 Add `demo/linkerd/` install; skip EG/Kuadrant NS; inject `emojivoto` — deps: 2.5
- [x] 3.2 Add `demo/apps/emojivoto/` west full + east voting, meshed — deps: 3.1
- [x] 3.3 Extend `up.sh` Linkerd→apps; verify Gateway+mesh coexist — deps: 3.1–3.2

## Phase 4: Connectivity (`skupper-van`)

- [x] 4.1 Add `demo/apps/legacy-emoji/` HTTP JSON + Podman unit — deps: 1.4
- [x] 4.2 Add `demo/skupper/` sites/links; voting west↔east; Kind↔Podman connector — deps: 3.3, 4.1
- [x] 4.3 Extend `up.sh`/`down.sh` Skupper teardown for clean re-up — deps: 4.2

## Phase 5: Failover + smoke (`failover-demo`)

- [x] 5.1 Create `demo/scripts/smoke.sh` + `make smoke` (200/429/mesh/Skupper/dig) — deps: 2.5, 3.3, 4.3
- [x] 5.2 Create `demo/scripts/failover.sh` + `make failover` (hurt west; wait; east; timeout≠0) — deps: 2.3, 5.1
- [x] 5.3 Wire remaining `Makefile` `demo-*` targets — deps: 5.1–5.2

## Phase 6: Docs

- [x] 6.1 Create `demo/VERSIONS.md` pinned CLI/chart/image versions
- [x] 6.2 Create `README.md` 30-min runbook (prereqs, topology, waits, Auth MAY, `make down`) — deps: 5.3
