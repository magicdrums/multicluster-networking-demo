# Skupper VAN (kind-west ↔ kind-east ↔ podman-edge)

Pinned CLI/controller: **2.2.1** (see `demo/VERSIONS.md`).

## Surface

| Path | Pattern |
|------|---------|
| voting west↔east | `AttachedConnector` in `emojivoto` + `AttachedConnectorBinding` in `skupper`; Listener host `voting-van`; routing key `voting` |
| Kind ↔ Podman | Podman Connector `legacy-emoji` → Kind Listener `legacy-emoji` (routing key `legacy-emoji`) |

Kind sites live in namespace `skupper` (mesh inject disabled). Podman site namespace: `podman-edge`.

Consumers reach VAN services as `voting-van.skupper:8080` and `legacy-emoji.skupper:8080` (mesh-local `voting-svc` unchanged).

## Install order (`make up`)

1. Cluster-scoped controller (`skupper-cluster-scope.yaml` **2.2.1**) on each Kind site
2. Apply `namespace.yaml` + Site CRs (`sites/`)
3. Start `legacy-emoji` + Podman site (`system apply` + `system start`)
4. Apply Connectors / Listeners / AttachedConnector*
5. Link: west issues token; east + podman-edge redeem (Option C for Podman)

Links are procedural (token issue/redeem) — credentials are runtime-generated under `demo/skupper/.tokens/` (**gitignored**; never commit `*.token` / `*.bak`).

`make up` **fails** if token issue, east redeem, or `redeem-podman-skupper.sh` fails — a successful bring-up implies the three-site VAN is linked.

## Kind LoadBalancer (first-class)

`linkAccess: default` needs a LoadBalancer IP. This demo uses **`cloud-provider-kind`** (official Kind path — **not MetalLB**):

- `make prereq-check` requires `cloud-provider-kind` on `PATH`
- `make up` starts `cloud-provider-kind --enable-lb-port-mapping` (Podman) if not already running; pidfile under `demo/.run/`
- After each Kind create, clears `node.kubernetes.io/exclude-from-external-load-balancers`
- `up.sh` **waits** for site Ready (default 90s) before continuing; if still not Ready, prints LB hints (not “ignore LB” as the only story)
- `make down` stops CCM only when the demo owns the pidfile marker

See `demo/VERSIONS.md` for install pins. Offline checks validate manifests only.

## Rootless Podman notes

- **Gateway ports**: west host-maps **`:8080`**; east uses **`:8081`** so CCM `--enable-lb-port-mapping` does not collide on rootless Podman.
  ```bash
  curl -sS -H 'Host: emojivoto.demo.local' http://127.0.0.1:8080/
  curl -sS -H 'Host: emojivoto.demo.local' http://127.0.0.1:8081/
  ```
- **CoreDNS** uses ClusterIP (not LoadBalancer on `:53`).
- **CCM resync**: after each new Kind create, demo-owned `cloud-provider-kind` is restarted so the site is adopted (and `KIND_EXPERIMENTAL_PROVIDER=podman` is always set).
- **Podman edge → Kind VAN (Option C)**: grant/router EXTERNAL-IPs are `10.89.0.x` (Kind netns); the host-networked Skupper router cannot route there. With `cloud-provider-kind --enable-lb-port-mapping`, router ports are on host `*:45671` / `*:55671`. The redeem helper:
  1. Keeps `skupper-site-server` SANs including `127.0.0.1` / `localhost` (`ensure-skupper-localhost-san.sh`)
  2. Redeems the grant from a container on network `kind` (grant URL is still `10.89.0.x`)
  3. Rewrites Link endpoints to `127.0.0.1` and reloads `podman-edge`
  ```bash
  ./demo/scripts/lib/redeem-podman-skupper.sh
  ```
  Live hybrid check (from Kind):
  ```bash
  kubectl --context kind-kind-west -n skupper run -i --rm --restart=Never curl-legacy \
    --image=curlimages/curl --command -- curl -sS http://legacy-emoji.skupper:8080/
  ```
  Host publish for the connector remains `curl http://127.0.0.1:18080/`. Kind↔Kind voting stays the mesh wow.

## Optional Network Observer (Phase C — talk UI)

**Not** part of `make up`. VAN critical path works without it. Opt-in only.

| Item | Contract |
|------|----------|
| Pin | Helm chart `oci://quay.io/skupper/helm/network-observer` **2.2.1** (see `demo/VERSIONS.md`) |
| Site preference | Prefer **podman-edge**; Podman cannot host the Helm chart → print fallback and install on **kind-west** `skupper` (`SITE=kind-west`) |
| Entry | Phase C of `make ui` (fail-fast A→B→C) |
| Access URL | Prefer `https://127.0.0.1:8443/` — helper prints `ACCESS_URL=…` (printed free port is the run contract) |
| Auth | Chart auto-creates basic-auth (user `skupper` + random password). Printed **once** as `BASIC_AUTH_USER=` / `BASIC_AUTH_PASSWORD=` and saved under `demo/.run/ui-skupper-basic-auth` (**gitignored** — never commit) |
| Exposure | Localhost HTTPS port-forward only — **never** CCM LoadBalancer |
| Metrics / RAM | Bundled Prometheus is a **second** Prom next to Linkerd Viz — expect extra RAM on the talk laptop |
| Tear down | `make ui-down` stops PF and `helm uninstall`s the release |

```bash
make ui
# === Talk UI (phase C — Skupper network-observer) ===
# ACCESS_URL=https://127.0.0.1:8443/
# BASIC_AUTH_USER=skupper
# BASIC_AUTH_PASSWORD=<printed-once>
```

Values live in `demo/skupper/network-observer/values.yaml` (no password in git).

