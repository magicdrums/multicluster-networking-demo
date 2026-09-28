# Speaker cards — KCD BA (stage cues only)

Full script: [`scripts.md`](scripts.md). Sites: `kind-west` / `kind-east` / `podman-edge` — **nunca** `kind-cluster`.  
**Corte overrun:** (1) UI vivo (2) Option-C backup (3) acortar takeaways · demo stuck ≤~2 min → abandonar.

---

## Card A — Francisco (≤1 screen)

**Rol:** framing · N-S (EG + Kuadrant) · CoreDNS failover · cierre  
**Reloj:** 0–5 open · **16–25 live** · 25–30 close

| When | Cue |
|------|-----|
| Pre | Confirmar `up`+`smoke`; ACCESS_URLs si hay `ui` |
| Slide 3 | Problema: sitios / RateLimit / failover (sin pitch propietario) |
| Handoff ←B | Tras slide 8: “Pasamos al borde N-S.” |
| Slide 9 | `make demo-ratelimit` → **HTTP 429** · UI A opc. `:8080` + Host |
| Slide 10 | `make failover` live · flake ~2m → video **fuera de git** / takeaways |
| Slide 11–12 | CTA `up`→`smoke`→optional `ui`→`down` · Q&A con B |

**No en cámara:** `demo/.run/` secrets · PPTX/video en git · YAML ad-hoc (usar Make)

---

## Card B — Sergio (≤1 screen)

**Rol:** topología · Skupper · Linkerd E-W · Viz/observer  
**Reloj:** 0–5 open · **5–16 live** · 25–30 close

| When | Cue |
|------|-----|
| Pre | Diagrama listo; nunca mencionar operar `kind-cluster` |
| Slide 4–6 | Agenda 4 batallas · topo west/east/edge · puente a live |
| Slide 7 | `make demo-skupper` · UI C opc. observer `:8443` |
| Slide 8 | `make demo-mesh` · UI B Viz `:50750` |
| Handoff →A | Cerrar 8: “Pasamos al borde N-S.” |
| Late | Skip UI primero; critical path Make sigue válido |

**UI order si se muestra:** A `:8080` → B Viz `:50750` → C observer `:8443` (pre-warm `make ui`)
