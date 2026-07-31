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
