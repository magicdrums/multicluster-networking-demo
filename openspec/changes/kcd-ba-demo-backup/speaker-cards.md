# Speaker cards — con clips de backup

Conductor completo: [`talk-conductor.md`](./talk-conductor.md) · Comandos: [`stage-commands.md`](./stage-commands.md)  
Media: `/home/fmeneses/Videos/kcd-ba-demo-backup/` · **nunca** `kind-cluster`  
**Stuck ≤~2 min:** abandonar live → play clip del slide → seguir

---

## Card A — Francisco

**Rol:** framing · N-S · failover · cierre · clips **03 / 04 / (05)**  
**Reloj:** 0–5 · **16–25** · 25–30

| When | Live | Si falla → play |
|------|------|-----------------|
| Slide 3 | Problema (sin media) | — |
| ← handoff B | Tras slide 8: “Pasamos al borde N-S.” | — |
| **Slide 9** | `make demo-ratelimit` → **429** | `kcd-ba-03-ratelimit-429.cast` |
| Slide 9 opc. | App `:8080` + Host | `kcd-ba-05-ui-a.webm` |
| **Slide 10** | `make failover` | `kcd-ba-04-failover.cast` |
| 11–12 | CTA + Q&A | Mencionar wows = clips 01–04 |

**No en cámara:** `demo/.run/` · secrets · video en git

---

## Card B — Sergio

**Rol:** topo · Skupper · mesh · clips **01 / 02 / (07) / (06)**  
**Reloj:** 0–5 · **5–16** · 25–30

| When | Live | Si falla → play |
|------|------|-----------------|
| 4–6 | Agenda / topo / puente | — |
| **Slide 7** | `make demo-skupper` (+ curl `:18080`) | `kcd-ba-01-skupper.cast` |
| Slide 7 opc. | Observer `:8443` | `kcd-ba-07-ui-c.webm` |
| **Slide 8** | `make demo-mesh` | `kcd-ba-02-mesh.cast` |
| Slide 8 opc. | Viz `:50750` | `kcd-ba-06-ui-b.webm` |
| → handoff A | “Pasamos al borde N-S.” | — |

**Orden UI si se muestra:** preferir live tras el Make del mismo acto; backup webm solo si UI no abre.
