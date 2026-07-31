# Tasks: demo-product-uis

## Review Workload Forecast

| Field | Value |
|-------|-------|
| Estimated changed lines | 550–900 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR1 A+foundation → PR2 B → PR3 C+teardown |
| Delivery strategy | feature-branch-chain |
| Chain strategy | feature-branch-chain (locked 2026-07-31 — same as multicluster-connectivity-demo) |

Decision needed before apply: No (locked)
Chained PRs recommended: Yes
Chain strategy: feature-branch-chain
400-line budget risk: High

### Suggested Work Units

| Unit | Goal | Likely PR | Focused test command | Runtime harness | Rollback boundary |
|------|------|-----------|----------------------|-----------------|-------------------|
| 1 | Foundation + Phase A | PR 1 (base=tracker) | `grep ui- Makefile; make -n ui-app-check` | Post-`up`: `make ui-app-check` → `ACCESS_URL=http://emojivoto.demo.local:8080/` | A scripts + README hosts |
| 2 | Phase B Viz | PR 2 (base=PR1) | `make -n ui-linkerd` | Post-`up`: `make ui-linkerd` → `http://127.0.0.1:50750/` (or printed free port) | `ui-linkerd*`, Viz pin, linkerd README |
| 3 | Phase C + ui-down | PR 3 (base=PR2) | `make -n ui-skupper ui-down` | Post-`up`: `make ui-skupper` → `https://127.0.0.1:8443/` + auth once; `ui-down` | observer Helm, `ui-skupper*`, `ui-down`, `down.sh` |

Delivery locked: **feature-branch-chain** (same as `multicluster-connectivity-demo`).

## Phase 1: Foundation

- [x] 1.1 RED: `Makefile` `up` has no `ui-*` deps
- [x] 1.2 Create `demo/scripts/ui-common.sh`: denylist 8080/8081/18080/18081/45671/55671; `demo_pick_free_port`; `demo_print_access_url`; pidfiles in `demo/.run/`
- [x] 1.3 RED→GREEN: refuse reserved ports; abort bad `CLUSTER` / never `kind-cluster`
- [x] 1.4 Wire Make: `ui-app` `ui-app-check` `ui-linkerd` `ui-linkerd-check` `ui-skupper` `ui-skupper-check` `ui-down` (not deps of `up`)

## Phase 2: A — App browser

- [x] 2.1 `ui-app.sh`: hosts hint; `ACCESS_URL=http://emojivoto.demo.local:8080/` (+ optional `:8081`); ban bare IP-without-Host
- [x] 2.2 `ui-app-check.sh`: hostname curl 200/429; print same URLs; fail if down
- [x] 2.3 `README.md` (+ failover runbook): hosts; Phase A URLs; UI off critical path; no Kuadrant Grafana/Envoy admin/Kiali/Dashboard

## Phase 3: B — Linkerd Viz

- [x] 3.1 Pin Viz/Linkerd edge-26.6.3 in `demo/VERSIONS.md`
- [x] 3.2 `ui-linkerd.sh`: west-only Viz; PF prefer 50750; print `ACCESS_URL=http://127.0.0.1:<port>/`; skip-inject unchanged; no CCM LB
- [x] 3.3 `ui-linkerd-check`: `viz check` and/or HTTP; echo final URL; fail if down
- [x] 3.4 `demo/linkerd/README.md`: opt-in Viz + URL contract

## Phase 4: C — Skupper observer

- [ ] 4.1 `demo/skupper/network-observer/` Helm values (chart `oci://quay.io/skupper/helm/network-observer` **2.2.1**; no password in git)
- [ ] 4.2 Pin observer **2.2.1** in `demo/VERSIONS.md`; RAM/2nd-Prom note
- [ ] 4.3 `ui-skupper.sh`: prefer podman-edge; fallback west `skupper` (`SITE=kind-west`); HTTPS PF prefer 8443; print URL + basic-auth once (`demo/.run/`)
- [ ] 4.4 `ui-skupper-check`: `curl -k -u …`; echo URL (+ auth hint); fail if down
- [ ] 4.5 `demo/skupper/README.md`: preference, PF, auth, RAM, fallback

## Phase 5: Teardown + threat checks

- [ ] 5.1 RED: (1) `ui-down` leaves CCM ports (2) bad CLUSTER aborts (3) `up` has no `ui-` (4) kills only recorded PF pids
- [ ] 5.2 `ui-down.sh`: stop PF/uninstall Viz+observer only; print what stopped; A=docs reminder
- [ ] 5.3 GREEN: 5.1 pass; `down.sh` best-effort non-fatal `ui-down`
- [ ] 5.4 Rehearsal: A→B→C print locked URLs (or printed free-port contracts); `make ui-down` clears B/C
