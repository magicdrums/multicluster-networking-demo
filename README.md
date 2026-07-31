# KCD Argentina 2026 — Multicluster Connectivity Demo

30-minute laptop demo: **Envoy Gateway + Kuadrant + Linkerd + Skupper + CoreDNS** across `kind-west`, `kind-east`, and `podman-edge`.

Wow moments: RateLimit **429**, CoreDNS HA failover, meshed emojivoto, Skupper Kind↔Podman.

## Prerequisites

| Requirement | Notes |
|-------------|-------|
| Fedora/Linux laptop with Podman | Kind uses `KIND_EXPERIMENTAL_PROVIDER=podman` |
| `fs.inotify.max_user_instances` ≥ **512** | `sudo sysctl -w fs.inotify.max_user_instances=512` |
| `podman`, `kind`, `kubectl`, `helm` | See `demo/VERSIONS.md` |
| `skupper` **2.2.1** | Matching controller YAML |
| `linkerd` **edge-26.6.3** | Max K8s 1.35 — Kind node pin **1.35.5** |
| `cloud-provider-kind` on `PATH` | Official Kind LoadBalancer (**not MetalLB**) |

Install LoadBalancer CCM:

```bash
go install sigs.k8s.io/cloud-provider-kind@latest
# ensure $(go env GOPATH)/bin or ~/.local/bin is on PATH
```

Gate check:

```bash
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

## Access (after `make up`)

```bash
# North-south (west Gateway host-map :8080; east uses :8081 to avoid CCM port clash)
curl -sS -H 'Host: emojivoto.demo.local' http://127.0.0.1:8080/
# Secondary site (after make up includes kind-east):
# curl -sS -H 'Host: emojivoto.demo.local' http://127.0.0.1:8081/

# Rate-limit wow
make demo-ratelimit

# Hybrid outside-cluster service (Podman)
curl -sS http://127.0.0.1:18080/
```

`make up` starts `cloud-provider-kind --enable-lb-port-mapping` when Kind sites are targeted, writes `demo/.run/cloud-provider-kind.pid` + `.owned`, and clears `node.kubernetes.io/exclude-from-external-load-balancers` on each control-plane.

`make down` stops that CCM **only if the demo started it**. An external user CCM is left alone.

Skupper site Ready and Gateway `EXTERNAL-IP` depend on this path. Scripts wait for Ready; if LB is slow, they print actionable hints (not “ignore LB forever”).

**Kind ↔ Podman Skupper (Option C):** the host-networked Podman router cannot reach Kind LB VIPs (`10.89.0.x`). Redeem rewrites Link endpoints to `127.0.0.1` after CCM maps router ports on the host — see `demo/skupper/README.md`.

## 30-minute runbook

**Before the talk** (or cold start):

```bash
make prereq-check
make up                 # ~several minutes; re-run is idempotent
make smoke              # 200/429, mesh, Skupper, dig
```

**Live critical path** (prefer Make over typing YAML):

1. **N-S RateLimit** — `make demo-ratelimit` (burst → at least one **429**)
2. **E-W mesh** — `make demo-mesh` (`linkerd check` + emojivoto)
3. **Skupper** — `make demo-skupper` (3-site / VAN surface)
4. **Failover** — `make failover`  
   - Scales west Envoy Gateway dataplane → 0 (`envoy-gateway-system`) and **deletes** west DNSPolicy  
     (do **not** set `weight: 0` — Kuadrant CoreDNS panics)  
   - Dual-site dig: **east** CoreDNS still answers with the east Gateway IP; **west** CoreDNS drops the primary  
     (each Kind site has its own CoreDNS — not a shared resolver that flips west→east)  
   - Default wait bound: **120s** (`FAILOVER_TIMEOUT_SEC`); **exits non-zero** on timeout  
   - Restores west Envoy + DNSPolicy on script exit  
5. **Auth MAY (bonus only)** — optional Authorino API-key; **not** required for success (see `demo/kuadrant/README.md`)

**Rollback / teardown:**

```bash
make down               # demo sites only; kind-cluster untouched
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

Optional: `CLUSTER=kind-west` (etc.) scopes `up` / `down` / `demo-ratelimit`.

## Pins & layout

- Versions: [`demo/VERSIONS.md`](demo/VERSIONS.md)
- Manifests: `demo/{kind,gateway,kuadrant,linkerd,skupper,apps}/`
- Scripts: `demo/scripts/`
- Runtime state: `demo/.run/` (gitignored)
- SDD specs (source of truth): `openspec/specs/`
- Archived change: `openspec/changes/archive/2026-07-31-multicluster-connectivity-demo/`

## Offline / CI-friendly checks

Without demo Kind clusters, `make smoke`, `make failover`, `make demo-*`, and `make test-allowlist` validate manifests and contracts and should stay green.
