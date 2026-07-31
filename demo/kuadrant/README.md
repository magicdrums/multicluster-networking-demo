# Kuadrant (north-south)

Critical path for this demo: **RateLimitPolicy** (429 wow) + **CoreDNS** / **DNSPolicy** (`emojivoto.demo.local`).

## DNS HA (west primary / east secondary)

| Site | DNSPolicy | Weight / geo |
|------|-----------|--------------|
| `kind-west` | `dnspolicy.yaml` | weight **100**, `defaultGeo: true` |
| `kind-east` | `dnspolicy-east.yaml` | weight **50**, `defaultGeo: false` |

Each Kind site runs its **own** Kuadrant CoreDNS (`kuadrant-coredns`). Talk failover (`make failover`) therefore:

1. Scales the west Envoy proxy Deployment in `envoy-gateway-system` → 0
2. **Deletes** the west DNSPolicy (withdraw primary A from west CoreDNS)
3. Asserts east CoreDNS still answers with the east Gateway IP

Do **not** patch `loadBalancing.weight` to `0` — `coredns-kuadrant` can panic (`Intn(0)`).

Gateway listeners: west **`:8080`**, east **`:8081`** (CCM host port-mapping under rootless Podman).

## AuthPolicy (MAY) — deferred

`AuthPolicy` / Authorino API-key is optional talk bonus only. It is **not** applied by default so the 30-minute path stays RateLimit + DNS. Authorino still installs via the `Kuadrant` CR for later; do not block smoke on Auth.

To add later: create an API-key `AuthPolicy` targeting Gateway `demo` in `gateway-system` and document the header in the runbook.

## Pins

See `demo/VERSIONS.md` (N-S section). Kind node image stays at `kindest/node:v1.35.5@sha256:ce977ae6d65918d0b58a5f8b5e940429c2ce42fa3a5619ec2bbc60b949c0ac95` for Linkerd compatibility.
