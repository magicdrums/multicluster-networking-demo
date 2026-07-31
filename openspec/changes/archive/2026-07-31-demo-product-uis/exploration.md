## Exploration: demo-product-uis

**Change name (proposed):** `demo-product-uis`  
**Intent:** Expose a minimal graphical UI surface for the archived KCD BA 2026 stack so speakers/audience see products visually — not only CLI curls and Make targets.  
**Baseline:** Archived `openspec/changes/archive/2026-07-31-multicluster-connectivity-demo/` (promoted specs under `openspec/specs/`).  
**CodeGraph note:** Index covers YAML + `legacy-emoji` Python only (shell scripts not indexed); inventory used Grep/Read + product docs.

### Current State

Laptop demo already works end-to-end on `kind-west` / `kind-east` / `podman-edge`:

| Plane | Access today | Graphical? |
|-------|--------------|------------|
| App (emojivoto) | Gateway HTTPRoute → `web-svc` via host-mapped **`:8080`** (west) / **`:8081`** (east); docs show `curl -H 'Host: emojivoto.demo.local'` | **Partial** — web UI exists behind Gateway, but runbook is curl-only; browsers need SNI/Host = `emojivoto.demo.local` (no `/etc/hosts` guidance) |
| Edge JSON | `legacy-emoji` **`127.0.0.1:18080`** | JSON only (fine for Skupper proof; not a product dashboard) |
| Mesh | `make demo-mesh` → `linkerd check` / manifests | **No** Linkerd Viz |
| VAN | `make demo-skupper` + curl to VAN services | **No** Skupper Network Console |
| N-S policies | `make demo-ratelimit` → HTTP **429**; CoreDNS dig in failover | **No** Kuadrant UI (CRDs + optional metrics only) |
| LB | `cloud-provider-kind --enable-lb-port-mapping` | Host ports reserved: **8080, 8081, 45671, 55671**; ratelimit fallback **18081** |

Design locks that constrain UIs:

- Skip-inject: `envoy-gateway-system`, `kuadrant-system`, `kuadrant-coredns`, `gateway-system`, `skupper` (`demo/linkerd/skip-namespaces.yaml` + `up.sh`); inject only `emojivoto`
- Pins: Linkerd **edge-26.6.3**, Skupper **2.2.1**, EG **1.7.0**, Kuadrant **1.5.2**
- Critical path wow: RateLimit + CoreDNS failover + mesh + Kind↔Podman VAN — must not flake `make up`
- Host RAM ~61 Gi → headroom exists, but **talk time** and **install flake** matter more than raw RAM

#### Product UI inventory

| Candidate | Useful for talk? | Feasibility (Kind+Podman) | Footprint | Host exposure | Auth (live talk) | Mesh / conflicts |
|-----------|------------------|---------------------------|-----------|---------------|------------------|------------------|
| **emojivoto web** | **High** — audience sees the app | Already installed; west has full app; east voting-only (no web) | None | Prefer browser → `http://emojivoto.demo.local:8080/` after hosts entry (not raw `127.0.0.1` without Host) | None | Already meshed; behind EG |
| **Linkerd Viz** | **High** — golden metrics / topology for E-W | `linkerd viz install` matching **edge-26.6.3**; **west-only** | Prometheus + web (~0.5–2+ Gi depending on traffic); docs warn significant resources | **`linkerd viz dashboard --port <free>`** (default ~50750) — avoid CCM | None on localhost PF | Own `linkerd-viz` NS; do not inject N-S/Skupper |
| **Skupper Network Observer 2.2.1** | **High** — topology of 3-site VAN | Helm `oci://quay.io/skupper/helm/network-observer` **2.2.1** into **`skupper` on west** | Observer + embedded Prometheus (chart examples ~0.5–4 Gi limits) | Port-forward `svc/... 8443:443` — **do not** LB-map (collides with CCM story) | Basic auth secret `skupper-network-observer-users` — pre-stage password | `skupper` already inject=disabled |
| **Kuadrant / Limitador / Authorino** | Low for 30-min | No first-class product UI; Grafana via separate observability stack + ServiceMonitors | High (Prometheus/Grafana/operator); demo already strips ServiceMonitors when CRDs absent | :3000 PF if ever installed | Default grafana admin | Skip-inject already; conflicts with lean path |
| **Envoy admin / egctl** | Low | Admin ~9901 low-level; poor stage UX | Small | Extra PF | Usually open locally | Gateway NS skip-inject |
| **Kiali** | N/A | Istio-centric; not in stack | High | — | — | Out of scope |
| **Kubernetes Dashboard** | Noise | Easy but dilutes story | Medium | — | Token hassle | Out of scope |

### Affected Areas

- `README.md` — 30-min runbook “Access” / browser steps; hosts-file note
- `Makefile` — optional `demo-ui-*` / `ui-up` targets (must stay out of default `up` critical path)
- `demo/VERSIONS.md` — pins for `linkerd-viz` / `network-observer` if installed
- `demo/scripts/up.sh` / `down.sh` — only if optional UI install hooks; prefer separate scripts
- `demo/linkerd/` — viz install notes; skip-inject unchanged for N-S/Skupper
- `demo/skupper/` — network-observer Helm values / README
- `openspec/specs/*` — new capability delta (e.g. `talk-ui-surface`) or ADDED requirements on existing domains
- **Not affected:** Kind allowlist, CCM Option C Skupper ports **45671/55671**, Gateway **8080/8081**, `legacy-emoji` **18080**

### Approaches

1. **Docs/runbook only (browser + hosts)** — Document `/etc/hosts` → `emojivoto.demo.local`, open browser for app UI; keep mesh/Skupper/Kuadrant as CLI.
   - Pros: Zero install risk; unblocks “graphical app” immediately; no port/RAM conflicts
   - Cons: No mesh/VAN dashboards; still CLI-heavy for product story
   - Effort: **Low**

2. **Minimal opt-in UI surface (recommended)** — Phase A: browser + hosts helpers. Phase B: Linkerd Viz **west-only**, opt-in (`make ui-linkerd` / env flag), port-forward helper on free port. Phase C (stretch): Skupper network-observer **west `skupper` NS**, opt-in, PF :8443 + printed basic-auth. Default `make up` unchanged.
   - Pros: Real graphical wow for mesh + VAN; critical path protected; ports avoid CCM reserved set; matches product versions already pinned
   - Cons: Extra rehearsal; dual Prometheus if both B+C; auth password choreography for Skupper; west-only means east mesh not shown in Viz (acceptable)
   - Effort: **Medium** (A+B), **Medium–High** with C

3. **Full observability kitchen-sink** — Viz both clusters + network-observer + Kuadrant Grafana/Prometheus operator + optional Envoy admin.
   - Pros: Maximum screenshots
   - Cons: Derails 30-min path; RAM/CPU + CCM/port chaos; ServiceMonitor/CRD coupling; auth/token noise; violates lean design that rejected Istio for footprint
   - Effort: **High** — **rejected**

| Approach | Pros | Cons | Complexity |
|----------|------|------|------------|
| Docs/runbook only | Safe, fast | Weak product UI story | Low |
| Opt-in minimal (app + Viz ± Skupper console) | Best talk ROI / risk balance | Optional install maintenance | Medium |
| Full observability | Max dashboards | Breaks talk budget / lean stack | High |

### Recommendation

**Phased GO** under change name **`demo-product-uis`** — not “docs-only forever,” and not “install everything in `make up`.”

1. **Must (Phase A — Low):** Browser-enable **emojivoto** — `/etc/hosts` (or documented equivalent) for `emojivoto.demo.local` → `127.0.0.1`, open `http://emojivoto.demo.local:8080/` (west) / `:8081` (east Gateway shell only). Add `make demo-ui-app` (print URL + hosts hint; optional `xdg-open`). This closes the gap that access today is curl+Host only.
2. **Should (Phase B — Medium):** Optional **Linkerd Viz** on **kind-west only**, pin to **edge-26.6.3**, access via `linkerd viz dashboard --port 50750` (or next free). **Never** default-on in `make up`. Tear down via `make ui-down` / `down` extension that is allowlist-safe.
3. **Could (Phase C — Stretch):** Optional **Skupper network-observer 2.2.1** on west `skupper` NS; PF HTTPS :8443; pre-cache basic-auth password in runbook (secret, not committed). Skip if rehearsal shows latency/RAM pressure with Viz.
4. **No-go install:** Kuadrant Grafana stack, Envoy admin as talk surface, Kiali, Kubernetes Dashboard. Mention in docs as “metrics/CRDs only.”

**Rough capability deltas (for propose/spec):**

| Capability | Delta |
|------------|-------|
| `talk-ui-surface` (new) or extend `failover-demo` / README capability | ADDED: browser access for emojivoto; MAY Linkerd Viz west; MAY Skupper network console; MUST NOT block `make up` smoke/failover |
| `east-west-linkerd` | MAY document viz install + skip-inject unchanged |
| `skupper-van` | MAY document network-observer 2.2.1 opt-in |
| `north-south-kuadrant` | Clarify NO product UI; RateLimit remains CLI/HTTP |

**Verdict:** Worth pursuing as a **small follow-on change**. If talk date is imminent with zero rehearsal budget, ship **Phase A docs only** first and defer B/C.

### Risks

- **Browser Host mismatch:** Opening `http://127.0.0.1:8080/` without Host/`hosts` fails Gateway hostname match — easy live-talk footgun
- **Port collisions:** Must reserve UI ports outside **8080/8081/18080/18081/45671/55671**
- **CCM / LB temptation:** Publishing Viz or Observer as LoadBalancer under rootless Podman risks host-port fights with Gateway/Skupper — prefer port-forward only
- **Dual Prometheus:** Viz + network-observer both ship metrics stacks — prefer west-only and make Observer stretch
- **`make up` regression:** Any UI install in critical path threatens RateLimit/failover/Skupper Option C — keep opt-in
- **Auth friction:** Skupper basic auth mid-talk; Linkerd Viz is open on localhost (demo laptop trust model)
- **East asymmetry:** East has no emojivoto web; Viz on west only understates east mesh (accept or document)
- **Version skew:** Viz must track Linkerd **edge-26.6.3**; Observer must track Skupper **2.2.1**

### Ready for Proposal

**Yes** — propose change `demo-product-uis` with Phase A required, Phase B default-included in proposal scope, Phase C explicitly stretch/MAY. Orchestrator should confirm with user: full phased change vs Phase-A-only docs if calendar is tight.
