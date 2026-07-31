## Exploration: multicluster-connectivity-demo

### Current State

Greenfield KCD Buenos Aires 2026 talk+demo repo (`kcd-argentina2026`). No application code, manifests, or demo scripts yet — only SDD scaffolding (`openspec/`, `.atl/`). Purpose is a **laptop-reproducible** multicluster connectivity demo covering:

1. **North-South** — Kuadrant Gateway API policies (Auth / RateLimit / DNS+health)
2. **East-West** — service mesh (Istio vs Linkerd — decide here)
3. **Inter-cluster + outside cluster** — Skupper VAN linking Kind clusters **and** a Podman site

**Host (measured 2026-07-30, re-checked during explore):**

| Fact | Value |
|------|-------|
| OS | Fedora 44 Workstation, amd64 ThinkPad P16v Gen1 |
| CPU / RAM | 16 CPUs; 61 Gi total; ~48 Gi available; Swap 8 Gi unused |
| Disk `/home` | 952G, ~785G free |
| Podman | 5.8.4 (rootless socket `/run/user/28164/podman/podman.sock`) |
| Kind | v0.32.0 — **auto-enables experimental Podman provider** |
| kubectl / helm | v1.36.2 / present |
| Missing CLIs | `skupper`, `istioctl`, `linkerd` |
| Existing Kind | `kind-cluster` (1 control-plane, **Exited** 7d) — unrelated; do not reuse |
| inotify | `fs.inotify.max_user_instances=128` (**multi-Kind risk**) |

**Docs-backed feasibility anchors:**

- Kuadrant documents **Istio** and **Envoy Gateway** as Gateway API providers for Auth/RateLimit; getting-started often installs Istio.
- Kuadrant **CoreDNS provider** + `CLUSTER_COUNT=3 ./hack/multicluster.sh local-setup` enables local Kind multicluster DNS/failover **without cloud credentials** ([CoreDNS guide](https://docs.kuadrant.io/latest/kuadrant-operator/doc/user-guides/dns/core-dns/)).
- Skupper v2 supports Kubernetes + Podman sites; official podman example exists.

### Affected Areas

- `openspec/changes/multicluster-connectivity-demo/` — change artifacts (this exploration → proposal/design/tasks)
- `openspec/config.yaml` — context already anticipates Kuadrant / mesh TBD / Skupper / Kind+Podman
- *(future)* `demo/` or equivalent — Kind configs, Kuadrant/Envoy Gateway/Linkerd/Skupper manifests, shell scripts (not created yet)
- *(future)* docs / README — talk runbook; CFP abstract only **after** feasibility proven (this explore)
- Host sysctl / CLI installs — operational prerequisites, not repo code
- Do **not** mutate existing `kind-cluster`

### Approaches

1. **Envoy Gateway + Kuadrant (N-S) + Linkerd (E-W) + Skupper (VAN)** — Split planes: Gateway API policies on Envoy Gateway; lightweight mesh for E-W; Skupper for Kind↔Kind↔Podman.
   - Pros: Lowest resource cost of viable full stacks (Linkerd CP ~200–300 Mi/cluster; proxy ~10–30 Mi/pod vs Istio CP ~1–2 Gi + Envoy sidecar ~50+ Mi/pod — approximate industry figures); clear talk narrative (policies vs mesh vs VAN); Kuadrant officially supports Envoy Gateway; fits dual-Kind + Podman headroom with margin for browser/IDE.
   - Cons: Two control planes to explain (EG + Linkerd); more install/wiring than “Istio does gateway+mesh”; some Kuadrant guides/samples still Istio-first; must validate EG+Kuadrant+Linkerd coexistence (no sidecar clash on gateway pods).
   - Effort: Medium–High (integration glue), Low–Medium (runtime cost)

2. **Istio (gateway + mesh) + Kuadrant + Skupper** — Single mesh/gateway stack for N-S and E-W; Kuadrant attaches to Istio Gateway API; Skupper for inter-cluster/Podman.
   - Pros: Matches Kuadrant getting-started path; one vendor story for gateway+mesh; fewer moving parts for install scripts; Ambient option exists but still heavier/more complex than Linkerd for a small demo.
   - Cons: Highest RAM/CPU of the compared options on **two** Kind clusters (≈+2–4 Gi control plane alone vs Linkerd, plus heavier sidecars); less “planes of connectivity” contrast for the talk; Ambient L7 waypoints add complexity without beating Linkerd for laptop demos.
   - Effort: Medium (docs-aligned), High (resource pressure / talk pacing if 3 Kind)

3. **Istio gateway-only + no E-W mesh + Skupper** — Drop in-cluster mesh; use Skupper for cross-site only.
   - Pros: Smaller footprint; Skupper story stays strong.
   - Cons: **Fails** the E-W plane requirement; weakens HA/failover story inside a cluster.
   - Effort: Low — rejected for goals

4. **Three Kind clusters (Kuadrant CoreDNS reference) + Istio everywhere + Skupper + Podman** — Mirror `CLUSTER_COUNT=3` local-setup fully.
   - Pros: Closest to official DNS primary/secondary docs; richest failover demo.
   - Cons: Highest complexity and inotify/Kind load; unnecessary if 2 Kind + CoreDNS primary/secondary roles still show failover; talk time risk.
   - Effort: High — stretch path only

#### Resource comparison (approximate industry figures, not local measurements)

| Stack | Control plane (per K8s site) | Data plane (per app pod) | Dual-Kind relative cost |
|-------|------------------------------|--------------------------|-------------------------|
| Linkerd | ~200–300 Mi | ~10–30 Mi | Baseline (lean) |
| Istio sidecar | ~1–2 Gi | ~50+ Mi | Roughly **3–5×** heavier CP + heavier proxies |
| Istio Ambient | Lighter L4 (ztunnel); L7 waypoints add cost/complexity | Mixed | Still heavier/more complex than Linkerd for this demo |

#### DNS / HA local path

| Option | Cloud credentials? | Local Kind feasibility | Notes |
|--------|--------------------|------------------------|-------|
| **Kuadrant CoreDNS provider** | **No** | **Yes** — documented Kind path | Authoritative CoreDNS + DNSPolicy; failover via groups / health; dig against CoreDNS Service IP |
| Route53 (or other cloud DNS) | Yes (AWS etc.) | Poor for “fully laptop” | Better for production story; optional stretch if credentials appear later |

**Recommendation for DNS:** CoreDNS provider only for the laptop demo. Skip Route53 unless a separate “cloud parity” appendix is desired later.

### Recommendation

**Adopt Approach 1: Envoy Gateway + Kuadrant (N-S) + Linkerd (E-W) + Skupper (Kind↔Kind↔Podman), with Kuadrant CoreDNS for local DNS/HA.**

**Why:** On this host, RAM/CPU/disk are ample (~48 Gi available), but the binding constraint is **demo reliability and talk clarity under multi-Kind load**, not raw capacity. Linkerd keeps E-W affordable across **two** Kind clusters while Envoy Gateway remains a first-class Kuadrant provider — avoiding Istio’s ~1–2 Gi/cluster control-plane tax and heavier sidecars. Skupper uniquely covers the Podman “outside cluster” site. CoreDNS removes cloud-credential blockers for failover/HA.

Reject full-Istio as default (Approach 2) unless proposal phase discovers a hard Kuadrant+Envoy Gateway gap for Auth/RateLimit/DNS that only Istio closes — then fall back to Istio with Ambient evaluated only as a secondary option.

#### Topology recommendation (talk-default)

| Site | Role | Runs |
|------|------|------|
| **kind-west** (new) | Primary edge + DNS primary | Envoy Gateway, Kuadrant (Authorino/Limitador/DNS operator), CoreDNS (kuadrant plugin), Linkerd, Skupper site, frontend/demo apps |
| **kind-east** (new) | Secondary / failover peer | Envoy Gateway (or shared pattern), Kuadrant DNS secondary/delegating role as needed, Linkerd, Skupper site, backend/demo apps |
| **podman-edge** | Outside-cluster site | Skupper Podman site + one backend/worker container |
| **kind-cluster** (existing) | Unrelated | Leave stopped / untouched |

**Cluster count:** **2 Kind + 1 Podman** for the talk. Document optional **3rd Kind** only if full Kuadrant primary/primary/secondary DNS guide must be mirrored live.

**Kind sizing:** Prefer **1 control-plane node per cluster** (no workers) to save RAM; pin Kind config (`kubeadm` patches / resource requests) in repo scripts. Expect **~1.5–3+ Gi baseline per Kind node** before add-ons (industry-typical).

#### Expected memory envelope (approximate)

| Component | kind-west | kind-east | Podman site | Subtotal |
|-----------|-----------|-----------|-------------|----------|
| Kind node baseline | 2.0–3.0 Gi | 2.0–3.0 Gi | — | 4.0–6.0 Gi |
| Envoy Gateway + Kuadrant stack | 1.5–2.5 Gi | 1.0–2.0 Gi | — | 2.5–4.5 Gi |
| Linkerd CP + few proxies | 0.4–0.8 Gi | 0.4–0.8 Gi | — | 0.8–1.6 Gi |
| Skupper router | 0.2–0.4 Gi | 0.2–0.4 Gi | 0.2–0.4 Gi | 0.6–1.2 Gi |
| Demo apps / CoreDNS | 0.4–0.8 Gi | 0.3–0.6 Gi | 0.2–0.3 Gi | 0.9–1.7 Gi |
| **Lean stack total** | | | | **~9–15 Gi** |
| Istio alternative delta | +~1–2 Gi CP + heavier proxies/cluster | same | — | **~12–20 Gi** |

Host has ~48 Gi available → **lean stack fits with comfortable margin** even with IDE/browser; raise inotify before creating second Kind cluster.

#### Host prerequisites (must before apply)

1. Raise `fs.inotify.max_user_instances` to **512 or 1024** (persist via sysctl.d) — **128 is insufficient for multi-Kind**.
2. Install missing CLIs: `skupper`, `linkerd` (and skip `istioctl` unless falling back to Approach 2).
3. Use dedicated Kind cluster names; do not reuse `kind-cluster`.
4. Rely on Kind’s experimental Podman provider (already auto-enabled on this host); document `KIND_EXPERIMENTAL_PROVIDER=podman` for reproducibility.
5. Prefer rootless Podman as user `fmeneses` (verified socket).

### Risks

- **inotify=128** — multi-Kind create/watch failures until raised to 512/1024.
- **Missing CLIs** — install `skupper` + `linkerd` before apply; version-pin in docs.
- **Kind+Podman experimental** — occasional networking/port-map quirks; keep clusters single-node; smoke-test early.
- **EG + Linkerd coexistence** — ensure gateway pods are correctly injected/skipped; validate Kuadrant policy attachment on Envoy Gateway in chosen versions.
- **Kuadrant Kind kubeconfig secrets** — official multicluster helper notes Kind kubeconfigs can be invalid without `./hack/multicluster.sh create-cluster-secret` workaround — bake into demo scripts.
- **DNS failover timing** — CoreDNS/group failover is reconcile-driven (not instant); script waits/probes for talk.
- **3-cluster temptation** — RAM allows it; talk time and inotify risk argue against defaulting to 3.
- **Existing Exited `kind-cluster`** — leftover containers may confuse `podman ps`; leave alone or delete only with explicit intent.
- **No project tests yet** — Strict TDD disabled; verification will be scripted smoke demos, not a unit suite.
- **CFP abstract** — deferred until proposal/design lock; do not write yet.

### Ready for Proposal

**Yes** — local demo is feasible on this host with clear constraints: raise inotify, install `skupper`/`linkerd`, use **2 new Kind clusters + 1 Podman site**, prefer **Envoy Gateway + Kuadrant + Linkerd + Skupper** with **CoreDNS** (no cloud DNS), leave `kind-cluster` untouched. Orchestrator should proceed to **sdd-propose** (not CFP writing). Ready = No only if a later spike proves Envoy Gateway incompatible with required Kuadrant DNS/Auth/RateLimit combo — then switch to Approach 2 (Istio) still within host RAM budget.
