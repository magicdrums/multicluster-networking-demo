# KCD Argentina 2026 — Multicluster Connectivity Demo

30-minute laptop demo: **Envoy Gateway + Kuadrant + Linkerd + Skupper + CoreDNS** across `kind-west`, `kind-east`, and `podman-edge`.

Wow moments: RateLimit **429**, CoreDNS HA failover, meshed emojivoto, Skupper Kind↔Podman — plus optional **graphical UIs** (app, Linkerd Viz, Skupper network console).

Repo: [fmenesesg/multicluster-networking-demo](https://github.com/fmenesesg/multicluster-networking-demo)

## Quick start

```bash
make prereq-check       # optional; make up already runs this
make up                 # stack only (no UIs) — re-run is idempotent
make smoke              # 200/429, mesh, Skupper, dig

# Optional talk UIs (after up) — always app → Viz → observer (A→B→C):
echo '127.0.0.1 emojivoto.demo.local' | sudo tee -a /etc/hosts   # once
make ui                 # start+validate each phase (fail-fast); prints ACCESS_URL=
make ui-down            # stop Viz + observer PFs (app is hosts/docs only)

make down               # best-effort ui-down, then demo sites only
```


That is the whole public path. Everything else below is detail for the talk and troubleshooting.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Fedora/Linux laptop with Podman | Kind uses `KIND_EXPERIMENTAL_PROVIDER=podman` |
| `fs.inotify.max_user_instances` ≥ **512** | `sudo sysctl -w fs.inotify.max_user_instances=512` |
| `podman`, `kind`, `kubectl`, `helm` | See `demo/VERSIONS.md` |
| `skupper` **2.2.1** | Matching controller YAML |
| `linkerd` **edge-26.6.3** | Max K8s 1.35 — Kind node pin **1.35.5** |
| `cloud-provider-kind` on `PATH` | Official Kind LoadBalancer (**not MetalLB**) |

```bash
go install sigs.k8s.io/cloud-provider-kind@latest
# ensure $(go env GOPATH)/bin or ~/.local/bin is on PATH
make prereq-check
```

## Topology

```
Client → EG (west) → web (meshed) → voting → emoji
              │            │            │
         RateLimit      Linkerd      Skupper
              │                         ├─ voting (east)
         CoreDNS west→east              └─ legacy-emoji (podman-edge)
```

| Site | Role |
|------|------|
| `kind-west` | Hub: EG, Kuadrant, Linkerd, full emojivoto, Skupper hub (`linkAccess`) |
| `kind-east` | Secondary: EG, Kuadrant, Linkerd, voting replica, Skupper spoke |
| `podman-edge` | Skupper Podman site + tiny `legacy-emoji` HTTP JSON |

**Never touch** the unrelated Kind cluster `kind-cluster`. Scripts refuse non-allowlisted names.

## LoadBalancer (first-class)

Local LB is **cloud-provider-kind** with `--enable-lb-port-mapping` (not MetalLB). `make up` starts a demo-owned CCM when Kind sites are targeted; host maps include west Gateway `:8080`, east `:8081`, and Skupper router ports used by Option C Podman linking. `make down` stops that CCM only if the demo started it.

**Kind ↔ Podman Skupper (Option C):** the host-networked Podman router cannot reach Kind LB VIPs (`10.89.0.x`). Redeem rewrites Link endpoints to `127.0.0.1` after CCM maps router ports — see `demo/skupper/README.md`.

## Talk UIs (opt-in — not part of `make up`)

One public entry: **`make ui`**. It always starts **app (A) → Linkerd Viz (B) → Skupper observer (C)** — each start+validate + `ACCESS_URL` — and **fails fast** if a phase fails (later phases do not start). There is no public single-phase Make target. Critical-path success remains RateLimit, mesh, Skupper, and failover — UIs are optional.

This demo does **not** install Kuadrant Grafana, Envoy admin, Kiali, or Kubernetes Dashboard.

Dashboards use **localhost port-forward only** (never CCM LB). Reserved host ports (never for UI PF): `8080`, `8081`, `18080`, `18081`, `45671`, `55671`. Teardown kills only loopback listeners (`127.0.0.1` / `::1`), never broad all-interface port kills.


### Hosts (once)

```text
127.0.0.1 emojivoto.demo.local
```

```bash
echo '127.0.0.1 emojivoto.demo.local' | sudo tee -a /etc/hosts
```

### ACCESS_URLs (printed by `make ui`)

| Phase | Surface | Typical URL |
|-------|---------|-------------|
| A | Emojivoto (west Gateway) | **http://emojivoto.demo.local:8080/** |
| A | East Gateway (optional) | **http://emojivoto.demo.local:8081/** |
| B | Linkerd Viz (west-only) | **http://127.0.0.1:50750/** (or printed free port) |
| C | Skupper network-observer | **https://127.0.0.1:8443/** (or printed free port) |

Hostname is required for the app — bare `http://127.0.0.1:8080/` without `Host` is not the documented path. If a preferred port is busy, the helper picks another and **prints the final `ACCESS_URL=`** — that printed URL is the contract for the run.

```bash
make ui                  # app + Viz + observer (A→B→C); fail-fast
make ui-down             # stop Viz + observer PFs + uninstall (app is hosts/docs only)
```

**Phase A (Browser):** `ACCESS_URL=http://emojivoto.demo.local:8080/` — expect **200** or **429**. RateLimit is **3 req / 10s** — clicking lista/leaderboard quickly may return **429** (that is the N-S wow).

**Phase B:** Linkerd Viz @ `edge-26.6.3`, west-only; bundled Prometheus OK; skip-inject on N-S/Skupper namespaces unchanged.

**Phase C:** network-observer **2.2.1**; prefer podman-edge, **fallback** `kind-west` namespace `skupper` (Helm needs Kubernetes). Accept the self-signed cert warning. Basic auth (once, gitignored):

```bash
cat demo/.run/ui-skupper-basic-auth
# BASIC_AUTH_USER=skupper
# BASIC_AUTH_PASSWORD=…
```

Port-forwards are recorded under `demo/.run/` (`.pid` + `.port` + `disown`). `make ui-down` stops them by pid, falls back to loopback port cleanup if a pidfile is missing, and verifies the port is free before claiming “cleared”. `make down` calls `ui-down` best-effort first.

Private knobs (not Make help): `UI_A_*` (app), `UI_B_*` (Viz), `UI_C_*` (observer) — e.g. `UI_B_PORT=50750`, `UI_C_PORT=8443`, `UI_C_SITE=podman-edge`.


## CLI probes (after `make up`)

```bash
# North-south (scripts/CI — Host header)
curl -sS -H 'Host: emojivoto.demo.local' http://127.0.0.1:8080/

# Rate-limit wow
make demo-ratelimit

# Hybrid outside-cluster service (Podman)
curl -sS http://127.0.0.1:18080/
```

## 30-minute runbook

**Before the talk** (or cold start): `make prereq-check` → `make up` → `make smoke` → optional `make ui`.

**Live critical path** (prefer Make over typing YAML):

1. **N-S RateLimit** — `make demo-ratelimit` (burst → at least one **429**), or browse the app until 429
2. **E-W mesh** — `make demo-mesh`; optional Viz comes with `make ui` (always A→B→C — not Viz-only)
3. **Skupper** — `make demo-skupper`; optional observer console comes with `make ui` (same A→B→C run)
4. **Failover** — `make failover`  
   - Scales west Envoy Gateway dataplane → 0 (`envoy-gateway-system`) and **deletes** west DNSPolicy  
     (do **not** set `weight: 0` — Kuadrant CoreDNS panics)  
   - Dual-site dig: **east** CoreDNS still answers with the east Gateway IP; **west** drops the primary  
   - Default wait: **120s** (`FAILOVER_TIMEOUT_SEC`); **exits non-zero** on timeout  
   - Restores west Envoy + DNSPolicy on script exit  
5. **Auth MAY (bonus only)** — optional Authorino API-key; **not** required (see `demo/kuadrant/README.md`)

**Rollback:**

```bash
make down               # best-effort ui-down, then demo sites only; kind-cluster untouched
```

`make up` is idempotent on re-run (Kind skip-create, Linkerd upgrade-when-present). It **fails** if the Skupper three-site VAN does not link (token issue / east redeem / podman-edge Option C).

## Make targets

| Target | Purpose |
|--------|---------|
| `make up` / `make down` | Lifecycle (allowlist-scoped); `up` stays UI-free |
| `make prereq-check` | Single host prerequisite gate (also invoked by `up`) |
| `make smoke` / `make demo-smoke` | End-to-end probes (offline validates if no Kind) |
| `make failover` / `make demo-failover` | Kill-primary → east |
| `make demo-ratelimit` | 429 wow |
| `make demo-mesh` | Linkerd / emojivoto |
| `make demo-skupper` | Skupper / legacy-emoji |
| `make ui` | Opt-in talk UIs: app + Linkerd Viz + Skupper observer (A→B→C; fail-fast) |
| `make ui-down` | Tear down Viz + observer PFs (app is hosts/docs only) |
| `make test-allowlist` | Refuse `kind-cluster` / unknown names |
| `make test-ui-foundation` | UI foundation + Phase A (offline) |
| `make test-ui-linkerd` | UI Phase B Viz (offline) |
| `make test-ui-skupper` | UI Phase C observer + teardown (offline) |

Optional: `CLUSTER=kind-west` (etc.) scopes `up` / `down` / `demo-ratelimit` / `ui*`.

## Pins & layout

- Versions: [`demo/VERSIONS.md`](demo/VERSIONS.md)
- Manifests: `demo/{kind,gateway,kuadrant,linkerd,skupper,apps}/`
- Operator scripts: `demo/scripts/` (`up`, `down`, `smoke`, `ui.sh`, …)
- Internals: `demo/scripts/lib/` (CCM, Skupper redeem/SAN, shared helpers)
- Phase helpers (private): `demo/scripts/ui/_phase_*.sh`
- Runtime state: `demo/.run/` (gitignored — CCM pid, UI PF pid/port, Skupper basic-auth)
- SDD specs: `openspec/specs/`
- Archived changes:
  - `openspec/changes/archive/2026-07-31-multicluster-connectivity-demo/`
  - `openspec/changes/archive/2026-07-31-demo-product-uis/`
  - `openspec/changes/archive/2026-08-03-demo-script-consolidation/`

## Offline / CI-friendly checks

Without demo Kind clusters, `make smoke`, `make failover`, `make demo-*`, `make test-allowlist`, and `make test-ui-*` validate manifests and contracts and should stay green.
