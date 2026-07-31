# Proposal: Multicluster Connectivity Demo

## Intent

Laptop-reproducible KCD BA 2026 demo: N-S (Kuadrant), E-W (Linkerd), Skupper Kind↔Kind↔Podman; idempotent lifecycle + scripted failover. No cloud DNS.

## Locked assumptions

- New single-node Kind: `kind-west`, `kind-east` — never reuse `kind-cluster`
- Topology: 2 Kind + 1 Podman (`podman-edge`)
- Stack: EG + Kuadrant + Linkerd + Skupper; DNS via Kuadrant CoreDNS
- Idempotent `make up` / `make down`
- CFP abstract deferred
- Host: inotify 512/1024; `skupper` + `linkerd` CLIs; Kind Podman provider

## Scope

### In Scope

- Idempotent Kind + Podman lifecycle
- EG + Kuadrant + CoreDNS HA
- Linkerd on both Kind sites
- Skupper Kind↔Kind↔Podman
- Failover script + runbook
- Minimal demo workloads

### Out of Scope

- CFP/slides; cloud DNS; 3rd Kind; Istio (fallback only); unrelated clusters

## Capabilities

### New Capabilities

- `kind-podman-lifecycle`: Idempotent Kind + Podman create/destroy; `make up`/`down`
- `north-south-kuadrant`: EG + Kuadrant Auth/RateLimit/DNS + CoreDNS HA
- `east-west-linkerd`: Linkerd E-W on both Kind sites
- `skupper-van`: Skupper Kind↔Kind↔Podman
- `failover-demo`: Scripted DNS/health failover + waits

### Modified Capabilities

- None

## Approach

`demo/` manifests + Makefile. `make up` checks prereqs, creates sites, installs EG→Kuadrant→Linkerd→Skupper→apps. `make down` destroys demo-only resources. Failover probes CoreDNS HA.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `demo/` | New | Configs, manifests, scripts |
| `Makefile` | New | `up`/`down`/smoke/failover |
| `README.md` | New | Prereqs + runbook |
| Host CLIs/sysctl | Ops | skupper, linkerd; inotify |
| Demo sites | New | kind-west/east, podman-edge |
| `kind-cluster` | Untouched | Non-goal |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| inotify=128 | High | Require 512/1024 before up |
| EG+Linkerd clash | Med | Inject/skip; pin versions |
| Kind+Podman quirks | Med | Single-node; early smoke |
| Failover lag | Med | Scripted waits |
| Missing CLIs | High | Fail-fast prereq check |

## Rollback Plan

1. `make down` — delete demo Kind + Podman only; leave `kind-cluster`.
2. Remove demo kubecontexts/secrets.
3. Revert optional inotify sysctl if raised for this demo.
4. Do not force-remove host CLIs.

## Dependencies

Podman, Kind (Podman provider), kubectl, helm, skupper, linkerd; pin versions; rootless Podman socket.

## Success Criteria

- [ ] `make up` brings full stack from clean prereqs
- [ ] `make down` cleans demo only; `kind-cluster` untouched
- [ ] Re-up after down is idempotent
- [ ] Live path: N-S, E-W, Skupper→Podman, failover
- [ ] Runbook covers prereqs, topology, rollback

## Proposal question round

1. Talk length — 30 or 45 min?
2. Live AuthPolicy in v1, or RateLimit + DNS first?
3. Demo app/brand name?
