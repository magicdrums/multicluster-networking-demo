# Linkerd (east-west)

Pinned CLI: **edge-26.6.3** (see `demo/VERSIONS.md`).

## Install (via `make up`)

1. Fresh site: `linkerd install --crds` then `linkerd install -f values.yaml`
2. Idempotent **re-up**: if ConfigMap `linkerd-config` already exists, `up.sh` runs `linkerd upgrade` instead (plain `install` refuses and breaks `kubectl apply`)
3. Skip-inject on EG / Kuadrant / CoreDNS / `gateway-system` / `skupper`
4. Inject `emojivoto` namespace; deploy west full app / east voting replica

## Coexistence

| Namespace | Mesh |
|-----------|------|
| `envoy-gateway-system` | skip |
| `kuadrant-system` | skip |
| `kuadrant-coredns` | skip |
| `gateway-system` | skip |
| `emojivoto` | inject |

Do not inject Gateway or Kuadrant control-plane pods.

## Optional Linkerd Viz (Phase B — talk UI)

**Not** part of `make up`. Opt-in only on **kind-west** (full mesh). East Viz is not required.

| Item | Contract |
|------|----------|
| Pin | **edge-26.6.3** (same CLI as control plane — see `demo/VERSIONS.md`) |
| Entry | `make ui` runs **A→B→C** (app + Viz + observer); this section describes **Phase B** only |
| Access URL | Prefer `http://127.0.0.1:50750/` — helper prints `ACCESS_URL=…` (printed free port is the run contract) |
| Exposure | Localhost port-forward only — **never** CCM LoadBalancer |
| Metrics | Bundled Prometheus OK |
| Skip-inject | Unchanged — Viz must not alter N-S / Skupper inject policy |
| Tear down | `make ui-down` (stops dashboard PF and uninstalls Viz) |

```bash
make ui
# make ui always starts app (A), then Viz (B), then observer (C) — fail-fast
# === Talk UI (phase B — Linkerd Viz) ===
# ACCESS_URL=http://127.0.0.1:50750/
```
