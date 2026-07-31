# KCD Argentina 2026 — Multicluster Connectivity Demo

30-minute laptop demo: **Envoy Gateway + Kuadrant + Linkerd + Skupper + CoreDNS** across `kind-west`, `kind-east`, and `podman-edge`.

Wow moments: RateLimit **429**, CoreDNS HA failover, meshed emojivoto, Skupper Kind↔Podman — plus optional **graphical UIs** (app browser, Linkerd Viz, Skupper network console).

Repo: [fmenesesg/multicluster-networking-demo](https://github.com/fmenesesg/multicluster-networking-demo)

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

Graphical surfaces for rehearsal/talk. Critical-path success remains RateLimit, mesh, Skupper, and failover. This demo does **not** install Kuadrant Grafana, Envoy admin, Kiali, or Kubernetes Dashboard.

Dashboards use **localhost port-forward only** (never CCM LB). Reserved host ports: `8080`, `8081`, `18080`, `45671`, `55671`.

### Phase A — Emojivoto (browser)

1. After `make up`, add once to `/etc/hosts`:

```text
127.0.0.1 emojivoto.demo.local
```

```bash
echo '127.0.0.1 emojivoto.demo.local' | sudo tee -a /etc/hosts
```

2. Open:

| Surface | URL |
|---------|-----|
| West Gateway (primary) | **http://emojivoto.demo.local:8080/** |
| East Gateway (optional) | **http://emojivoto.demo.local:8081/** |

Hostname is required — bare `http://127.0.0.1:8080/` without `Host` is not the documented path.

3. Validate:

```bash
make ui-app          # prints ACCESS_URL=http://emojivoto.demo.local:8080/
make ui-app-check    # hostname curl; expect 200 or 429
```

**Note:** RateLimit is **3 req / 10s**. Clicking lista/leaderboard quickly may return **429** — that is the N-S wow (expected).

### Phase B — Linkerd Viz (mesh topology)

West-only, pin `edge-26.6.3`, bundled Prometheus OK. Skip-inject on N-S/Skupper namespaces is unchanged.

```bash
make ui-linkerd          # install Viz + localhost PF (prefer :50750)
make ui-linkerd-check    # prints ACCESS_URL + probe
```

| Surface | URL |
|---------|-----|
| Linkerd dashboard | **http://127.0.0.1:50750/** (or the free port printed as `ACCESS_URL=`) |

If the preferred port is busy, the helper picks another and **prints the final URL** — that printed URL is the contract for the run.

### Phase C — Skupper network-observer (VAN console)

Opt-in observer **2.2.1**. Prefer podman-edge; if Helm cannot run there, **fallback is `kind-west` namespace `skupper`** (documented). Accepts a second Prometheus + RAM cost when used with Viz.

```bash
make ui-skupper          # install observer + HTTPS PF (prefer :8443)
make ui-skupper-check    # prints ACCESS_URL + auth hint
```

| Surface | URL |
|---------|-----|
| Skupper network console | **https://127.0.0.1:8443/** (or printed free port) |

Basic auth (generated once, **not committed**):

```bash
cat demo/.run/ui-skupper-basic-auth
# BASIC_AUTH_USER=skupper
# BASIC_AUTH_PASSWORD=…
```

Browser: accept the self-signed cert warning, then enter user/password from that file.

### Tear down UIs

```bash
make ui-down             # stop PF + uninstall Viz + observer (A is docs/hosts only)
```

`make down` calls `ui-down` best-effort before destroying demo sites.

### Quick UI rehearsal

```bash
make ui-app-check        # ACCESS_URL=http://emojivoto.demo.local:8080/
make ui-linkerd && make ui-linkerd-check   # ACCESS_URL=http://127.0.0.1:50750/
make ui-skupper && make ui-skupper-check   # ACCESS_URL=https://127.0.0.1:8443/ + auth
make ui-down
```

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

**Before the talk** (or cold start):

```bash
make prereq-check
make up                 # ~several minutes; re-run is idempotent
make smoke              # 200/429, mesh, Skupper, dig
```

**Live critical path** (prefer Make over typing YAML):

1. **N-S RateLimit** — `make demo-ratelimit` (burst → at least one **429**), or browse the app until 429
2. **E-W mesh** — `make demo-mesh` (`linkerd check` + emojivoto); optional Viz: `make ui-linkerd`
3. **Skupper** — `make demo-skupper` (3-site / VAN); optional console: `make ui-skupper`
4. **Failover** — `make failover`  
   - Scales west Envoy Gateway dataplane → 0 (`envoy-gateway-system`) and **deletes** west DNSPolicy  
     (do **not** set `weight: 0` — Kuadrant CoreDNS panics)  
   - Dual-site dig: **east** CoreDNS still answers with the east Gateway IP; **west** drops the primary  
   - Default wait: **120s** (`FAILOVER_TIMEOUT_SEC`); **exits non-zero** on timeout  
   - Restores west Envoy + DNSPolicy on script exit  
5. **Auth MAY (bonus only)** — optional Authorino API-key; **not** required (see `demo/kuadrant/README.md`)

**Rollback / teardown:**

```bash
make down               # best-effort ui-down, then demo sites only; kind-cluster untouched
```

`make up` is idempotent on re-run (Kind skip-create, Linkerd upgrade-when-present). It **fails** if the Skupper three-site VAN does not link (token issue / east redeem / podman-edge Option C).

## Make targets

| Target | Purpose |
|--------|---------|
| `make up` / `make down` | Lifecycle (allowlist-scoped) |
| `make smoke` / `make demo-smoke` | End-to-end probes (offline validates if no Kind) |
| `make failover` / `make demo-failover` | Kill-primary → east |
| `make demo-ratelimit` | 429 wow |
| `make demo-mesh` | Linkerd / emojivoto |
| `make demo-skupper` | Skupper / legacy-emoji |
| `make test-allowlist` | Refuse `kind-cluster` / unknown names |
| `make test-ui-foundation` | UI foundation + Phase A (offline) |
| `make test-ui-linkerd` | UI Phase B Viz (offline) |
| `make test-ui-skupper` | UI Phase C observer + teardown (offline) |
| `make ui-app` / `ui-app-check` | Phase A browser hosts + validation |
| `make ui-linkerd` / `ui-linkerd-check` | Phase B Viz west-only |
| `make ui-skupper` / `ui-skupper-check` | Phase C observer + basic-auth |
| `make ui-down` | Tear down B/C UI only |

Optional: `CLUSTER=kind-west` (etc.) scopes `up` / `down` / `demo-ratelimit` / `ui-*`.

## Pins & layout

- Versions: [`demo/VERSIONS.md`](demo/VERSIONS.md)
- Manifests: `demo/{kind,gateway,kuadrant,linkerd,skupper,apps}/`
- Scripts: `demo/scripts/` (lifecycle + `ui-*`)
- Runtime state: `demo/.run/` (gitignored — CCM pid, UI PF pids, Skupper basic-auth)
- SDD specs: `openspec/specs/`
- Archived changes:
  - `openspec/changes/archive/2026-07-31-multicluster-connectivity-demo/`
  - `openspec/changes/archive/2026-07-31-demo-product-uis/`

## Offline / CI-friendly checks

Without demo Kind clusters, `make smoke`, `make failover`, `make demo-*`, `make test-allowlist`, and `make test-ui-*` validate manifests and contracts and should stay green.
