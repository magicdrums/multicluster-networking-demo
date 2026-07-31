# Design: demo-product-uis

## Technical Approach

Opt-in Make → `demo/scripts/ui-*.sh` (same pattern as `demo-mesh` / `check-*.sh`). Default `make up` / `up.sh` unchanged. Aligns with `talk-ui-surface` and deltas on `failover-demo`, `east-west-linkerd`, `skupper-van`, `north-south-kuadrant`.

Each phase install/check **must** print `ACCESS_URL=…` (speaker-visible) and fail if the probe fails. If a free port is used, the printed URL is the run contract.

## Architecture Decisions

| Decision | Rejected | Choice | Why |
|----------|----------|--------|-----|
| UI in `up` | Bake Viz/observer into `up.sh` | Separate `ui-*` only | Protect 30-min / RateLimit / Option C |
| App access | New ingress / bare IP | Hosts → `emojivoto.demo.local`; west `:8080` (+ east `:8081`) | Existing Gateway; Host required |
| Viz | CCM LB; east Viz | West-only `linkerd viz` + PF prefer **50750** | Reserved ports; full mesh on west |
| Observer site | Always west; Compose | Prefer **podman-edge**; fallback west `skupper` | Locked single-pane; west if blocked |
| Observer access | LB / committed password | HTTPS PF prefer **8443** + auth in `demo/.run/` | Secrets never committed |
| Metrics | Shared Prom | Bundled Prom OK; 2nd Prom + RAM note | Least glue |
| Teardown | Only `make down` | `ui-down` for B/C; A = docs reminder | Lean; allowlist untouched |

## Data Flow

```
ui-app[-check]  → http://emojivoto.demo.local:8080/ (+ :8081)
ui-linkerd      → Viz install (west) → PF :50750 → ACCESS_URL
ui-skupper      → observer 2.2.1 → PF :8443 → ACCESS_URL + auth once
ui-down         → stop PF pids; uninstall Viz/observer
```

```mermaid
sequenceDiagram
  participant M as Make ui-*
  participant S as ui-*.sh
  participant C as Site
  M->>S: install/check
  S->>C: ensure surface
  S->>S: free PF port (skip reserved)
  S->>C: port-forward (pid in demo/.run)
  S-->>M: ACCESS_URL=… (+ auth for C)
  S->>S: probe; non-zero if down
```

## Make / script wiring (URL contract)

| Target | Script | Must print | Probe |
|--------|--------|------------|-------|
| `ui-app` | `ui-app.sh` | Hosts hint + west URL (+ east optional) | Optional open |
| `ui-app-check` | `ui-app-check.sh` | Same URL(s) | Hostname curl; 200/429 |
| `ui-linkerd` | `ui-linkerd.sh` | `ACCESS_URL=http://127.0.0.1:<port>/` | Install+PF; prefer 50750 |
| `ui-linkerd-check` | wrapper | Final URL | `viz check` and/or HTTP |
| `ui-skupper` | `ui-skupper.sh` | HTTPS URL + user/pass once | Helm+PF; auth in `.run` |
| `ui-skupper-check` | wrapper | URL (+ auth file hint) | `curl -k -u …` |
| `ui-down` | `ui-down.sh` | What stopped | Kill PF; uninstall B/C |

Helpers in `ui-common.sh`: reserved denylist **8080, 8081, 18080, 18081, 45671, 55671**; `demo_pick_free_port`; `demo_print_access_url`; pidfiles under `demo/.run/`.

Banner:

```text
=== Talk UI (phase X) ===
ACCESS_URL=<url>
```

Phase C also: `BASIC_AUTH_USER=` / `BASIC_AUTH_PASSWORD=` once (or `BASIC_AUTH_FILE=`).

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `Makefile` | Modify | `ui-app`, `ui-app-check`, `ui-linkerd`, `ui-linkerd-check`, `ui-skupper`, `ui-skupper-check`, `ui-down`; not deps of `up` |
| `demo/scripts/ui-{app,app-check,linkerd,skupper,down,common}.sh` | Create | Phase helpers + URL/port helpers |
| `demo/VERSIONS.md` | Modify | Pin Viz / network-observer **2.2.1** |
| `demo/linkerd/README.md` | Modify | Opt-in Viz + URL |
| `demo/skupper/README.md` | Modify | Observer preference, PF, auth, RAM |
| `demo/skupper/network-observer/` | Create | Helm values (no password in git) |
| `README.md` | Modify | Hosts + phase validation URLs; UI off critical path |
| `demo/scripts/down.sh` | Modify | Best-effort non-fatal `ui-down` (preferred) |
| `openspec/specs/*` | Modify | Promote at archive |

## Interfaces / Contracts

- No LB for Viz/observer; reserved ports never for dashboard PF.
- Skip-inject unchanged; Viz NS must not alter N-S/Skupper inject policy.
- Observer chart `oci://quay.io/skupper/helm/network-observer` **2.2.1**. If podman-edge cannot host, print `SITE=kind-west` and fallback.
- Never target `kind-cluster`.

## Testing Strategy

| Layer | What | Approach |
|-------|------|----------|
| Unit | N/A | No runner |
| Integration | `ui-*` in Makefile; reserved-port refuse; `up` has no `ui-*` | Offline shell/grep |
| E2E | A/B/C print URL + probe; `ui-down` clears PF | Rehearsal post-`up` |

## Threat Matrix

| Boundary | Applicability | Design response | Planned RED tests |
|---|---|---|---|
| Documentation-like paths | N/A | — | — |
| Git / commit / push / PR | N/A | — | — |
| Cluster destroy scope | Applicable | Allowlist; uninstall Viz/observer only | (1) `ui-down` leaves CCM ports (2) bad CLUSTER aborts (3) `up` has no `ui-` |
| Port-forward process | Applicable | Pidfiles in `demo/.run/` | (4) `ui-down` kills only recorded PF |

## Migration / Rollout

No migration. Ship A → rehearse B → optional C. Rollback: `ui-down`; revert Makefile/docs/VERSIONS.

## Open Questions

- [ ] Exact podman-edge observer path if Helm-only — blocked → west (locked)
- [x] `make down` invokes `ui-down` best-effort, non-fatal — prefer yes
