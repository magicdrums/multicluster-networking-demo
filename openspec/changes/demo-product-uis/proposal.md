# Proposal: demo-product-uis

## Intent

Add a lean **graphical** UI surface for the KCD BA 2026 demo (today curl+Host / CLI-only) without bloating 30-min `make up`.

## Scope

### In Scope
- **A (Must):** `/etc/hosts` → `emojivoto.demo.local` → `127.0.0.1`; west `:8080`, east `:8081` if useful; optional Make hosts/open hint — no new ingress
- **B (Should):** Linkerd Viz opt-in **kind-west**, pin **edge-26.6.3**, bundled Prom OK; PF ~50750; `make ui-linkerd` / `ui-down`; never CCM LB or default `up`; skip-inject unchanged
- **C (Could):** network-observer **2.2.1** VAN single pane; prefer **podman-edge**, fallback west `skupper` NS; PF HTTPS ~8443 + generated basic-auth (never commit); accept 2nd Prom + RAM note

Each phase MUST include a **validation step** that prints (and smoke-checks) the **access URL** for that surface — see [Per-phase validation URLs](#per-phase-validation-urls).

### Out of Scope
Compose obs; shared Prom; Viz on east; Kuadrant Grafana / Envoy admin / Kiali / Dashboard; RateLimit/failover/Option C / `kind-cluster` changes.

## Per-phase validation URLs

Every phase delivers a Make/script validation target (or scripted check) that **prints the access URL** and fails if the surface is unreachable. Locked defaults:

| Phase | Validation target (proposed) | Access URL to print / open | Pass criteria |
|-------|------------------------------|----------------------------|---------------|
| **A** | `make ui-app` / `make ui-app-check` | **West:** `http://emojivoto.demo.local:8080/` · **East (optional):** `http://emojivoto.demo.local:8081/` | HTTP from host with that hostname (not bare `127.0.0.1` without Host); expect 200/429 after up; print exact URL(s) |
| **B** | `make ui-linkerd` (install+PF) then check | **`http://127.0.0.1:50750/`** (or next free port printed by the helper) | Helper MUST echo the final URL; `linkerd viz check` (or HTTP probe to dashboard) OK; never CCM-mapped |
| **C** | `make ui-skupper` (install+PF) then check | **`https://127.0.0.1:8443/`** (+ printed basic-auth user/password, not committed) | Helper MUST echo HTTPS URL and credentials path/stdout once; HTTPS probe or documented `curl -k -u …` OK |

Notes:
- If B/C bind a different free port, the **printed URL wins** as the contract for that run (defaults above are preferred).
- Validation is opt-in / post-`make up`; MUST NOT run inside default `make up`.
- `make ui-down` tears down B/C forwards/installs; A is docs/hosts only (no tear-down beyond reminder).

## Capabilities

### New Capabilities
- `talk-ui-surface`: Opt-in app/Viz/observer access; MUST NOT block lean `make up`; MUST avoid reserved ports / CCM LB for dashboards

### Modified Capabilities
- `failover-demo`: Runbook MUST document browser Host/`hosts`; UI out of critical path
- `east-west-linkerd`: MAY Viz west-only @ edge-26.6.3; skip-inject unchanged
- `skupper-van`: MAY observer 2.2.1 (podman-edge preferred; west fallback); PF + basic auth; ui-down
- `north-south-kuadrant`: NO product UI; RateLimit/failover stay CLI/HTTP

## Approach

Docs-first A on existing Gateway maps. Separate Make/scripts for B/C + free-port PF (not 8080/8081/18080/45671/55671). Pin in `demo/VERSIONS.md`. Design validates podman-edge observer; fallback west if blocked.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `README.md`, `Makefile` | Modified | Hosts/URLs; `ui-linkerd`/`ui-down` (+ app helper); not in `up` |
| `demo/VERSIONS.md`, `demo/scripts/` | Modified | Pins + opt-in UI helpers |
| `demo/linkerd/`, `demo/skupper/` | Modified | Viz notes; observer (podman-edge preferred) |
| `openspec/specs/*` | Modified | Caps above |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Browser without Host | High | Docs + Make hint; ban bare `127.0.0.1` |
| CCM/LB, dual Prom, `up` flake | Med | PF-only; opt-in; never in `up`; drop C if needed |
| podman-edge blocked / auth | Med | West fallback; print secret; rehearse |

## Rollback Plan

Skip A docs. `ui-down` removes Viz/Observer; `make down` tears demo sites only — `kind-cluster` untouched. Revert Makefile/docs/VERSIONS if needed.

## Dependencies

Gateway 8080/8081; Linkerd **edge-26.6.3**; Skupper **2.2.1**; Helm; Podman Kind + CCM unchanged.

## Success Criteria

- [ ] **A validate:** prints `http://emojivoto.demo.local:8080/` (+ east `:8081` if enabled); host HTTP check passes
- [ ] **B validate:** prints Viz URL (default `http://127.0.0.1:50750/`); dashboard reachable; not in `make up`
- [ ] **C validate:** prints `https://127.0.0.1:8443/` (+ basic-auth once); console reachable; VAN view
- [ ] Ports + skip-inject unchanged; RateLimit/failover/Option C still work
- [ ] `ui-down`/`down` clean UI extras; `kind-cluster` untouched
