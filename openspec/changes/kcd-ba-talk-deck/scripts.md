# Scripts: KCD BA Talk Deck

**Talk:** KCD Argentina 2026 — conectividad multicluster (30 min)  
**Speakers:** A = Francisco Meneses · B = Sergio Canales (swap OK if documented)  
**Sites:** `kind-west` / `kind-east` / `podman-edge` — **nunca** operar `kind-cluster`  
**Wording:** títulos y cuerpo en español; términos técnicos en inglés (RateLimit, failover, mesh, Gateway, N-S, E-W, ACCESS_URL, LoadBalancer, port-forward)  
**Stage rule:** preferir Make sobre YAML ad-hoc

---

## Commit / binary policy (MUST)

Artifacts de este change son outlines, guiones ES, prompts EN, timing y cues del repo.

**MUST NOT** commit:

- Binarios PPTX / Keynote / video (failover backup incluido)
- Secretos (`demo/.run/`, basic-auth, tokens)
- QR / bios (salvo pedido explícito posterior)
- Texto, paths, catalog IDs o marketing de workshops propietarios (RH u otros)

Narrativa = README + `demo/` de este repo únicamente.

---

## Timing budget (30 min)

| Clock | Owner | Block |
|-------|-------|-------|
| 0–5 | A→B | Apertura, problema, agenda |
| 5–9 | B | Topología + historia |
| 9–16 | B | Skupper + mesh + UI B/C opcional |
| 16–25 | A | RateLimit 429 + failover + UI A opcional |
| 25–30 | A+B | Takeaways + gracias + Q&A |

**Corte si hay overrun (orden):** (1) UI en vivo, (2) slide backup Option-C (fuera de las 12), (3) acortar takeaways — **no** pelear un demo >~2 min.

---

## Slide plan (1–12)

| # | Título (ES) | Owner | ~Min | Make / UI cue |
|---|-------------|-------|------|---------------|
| 1 | KCD Argentina 2026 — Conectividad multicluster | A+B | 1:00 | Pre-warm off-mic |
| 2 | Quiénes somos | A+B | 1:00 | — |
| 3 | El problema: muchos sitios, poca confianza | A | 2:00 | — |
| 4 | Agenda (30 min) | B | 1:00 | Nunca `kind-cluster` |
| 5 | Topología del demo | B | 2:00 | Diagrama |
| 6 | Historia: de desconectado a conectado | B | 1:30 | Puente a live |
| 7 | Interconectar entornos con Skupper | B | 3:00 | `demo-skupper`; UI C `:8443` opcional |
| 8 | East–west con Linkerd | B | 3:00 | `demo-mesh`; UI B Viz `:50750` opcional |
| 9 | North–south con Envoy Gateway + Kuadrant | A | 3:30 | `demo-ratelimit` → HTTP 429; UI A `:8080` opcional |
| 10 | Failover con CoreDNS | A | 3:30 | `failover` live; video fuera de git si flake |
| 11 | Qué se llevan | A | 1:30 | CTA `up`→`smoke`→optional `ui`→`down` |
| 12 | Gracias + preguntas | A+B | 2:00+ | Q&A |

Backup (fuera de las 12; cortar primero): diagrama profundo Option-C Skupper loopback.

---

## Talking points (ES)

### Slide 1 — Título · A+B · ~1:00

- Bienvenida a KCD Argentina / Buenos Aires 2026.
- Promesa: conectar tres sitios en una laptop y mostrar políticas, mesh y failover en vivo.
- Nombrar stack OSS: Envoy Gateway, Kuadrant, Linkerd, Skupper, CoreDNS.
- Off-mic: confirmar `make up` + `make smoke` OK antes de empezar.

### Slide 2 — Quiénes somos · A+B · ~1:00

- Francisco (A): framing, políticas N-S (EG + Kuadrant), CoreDNS failover, cierre.
- Sergio (B): topología, Skupper Kind↔Podman, Linkerd E-W, Viz / observer.
- Una línea cada uno sobre por qué importa la conectividad multicluster / edge.

### Slide 3 — El problema · A · ~2:00

- Apps repartidas en clusters y fuera de cluster (edge / legacy).
- Dolores: enlace sin VPN eterna; quién aplica RateLimit en el borde; qué pasa si cae el sitio primario.
- Enmarcar como planos de conectividad — no vender productos propietarios.

### Slide 4 — Agenda · B · ~1:00

- Cuatro batallas: interconectar → controlar E-W → gobernar N-S → sobrevivir al failover.
- Demo en laptop: `kind-west`, `kind-east`, `podman-edge`.
- Decir en voz alta: **nunca** tocamos `kind-cluster`.

### Slide 5 — Topología · B · ~2:00

- West = hub (Gateway, Kuadrant, Linkerd, emojivoto, Skupper hub).
- East = réplica voting + spoke Skupper + Gateway.
- Podman-edge = sitio Skupper + `legacy-emoji` HTTP JSON.
- Cliente → EG west → servicios mesh → Skupper a east / edge; CoreDNS west→east.

### Slide 6 — Historia · B · ~1:30

- Empezamos desconectados: tres islas.
- Objetivo: servicio híbrido + políticas consistentes sin reescribir la app.
- Transición: “Ahora en vivo — primero el cableado entre sitios.”

### Slide 7 — Skupper (live) · B · ~3:00

- VAN: enlazar Kind con Podman (fuera de Kubernetes).
- **Cue:** `make demo-skupper` (y/o `curl http://127.0.0.1:18080/` para legacy-emoji).
- **UI C opcional:** si `make ui` ya corrió, observer ACCESS_URL ~`https://127.0.0.1:8443/` (cert self-signed; basic-auth en `demo/.run/` — **no mostrar secretos en cámara**).
- Cierre: misma app lógica, un hop que cruza el borde.

### Slide 8 — Linkerd (live) · B · ~3:00

- E-W: mTLS / identidad entre microservicios emojivoto en west.
- **Cue:** `make demo-mesh`.
- **UI B opcional:** Linkerd Viz `http://127.0.0.1:50750/`.
- Contraste: mesh **dentro** del cluster vs Skupper **entre** sitios.
- Handoff a A: “Pasamos al borde N-S.”

### Slide 9 — Envoy Gateway + Kuadrant (live) · A · ~3:30

- N-S: cliente entra por Gateway; política RateLimit en Kuadrant.
- **Cue:** `make demo-ratelimit` → al menos un **HTTP 429**.
- **UI A opcional:** browser `http://emojivoto.demo.local:8080/` — clicks rápidos → 429 (3 req / 10s). Usar hostname / Host header; no bare `127.0.0.1:8080` sin Host.

### Slide 10 — Failover CoreDNS (live) · A · ~3:30

- Si duele el primario west, DNS/HA debe seguir sirviendo east.
- **Cue primario:** `make failover` (escala dataplane west Envoy a 0, limpia DNSPolicy west, dig dual-site, espera ≤~120s, restaura al salir).
- Operador: no poner `weight: 0` (pánico conocido); el script ya hace el camino seguro.
- Si falla / timeout ~2 min: parar, reconocer smoke previo, video backup **fuera de git** y/o avanzar a takeaways — no pelear.

### Slide 11 — Qué se llevan · A · ~1:30

- CTA público: `make up` → `make smoke` → optional `make ui` → `make down`.
- Cuatro wows: 429, failover, mesh, Skupper Kind↔Podman.
- Repo GitHub; invitar a clonar y romper cosas en casa.

### Slide 12 — Gracias · A+B · ~2:00+

- Agradecer KCD / comunidad.
- Q&A; ofrecer quedarse para UI si no entró en el bloque live.
- Contactos / QR: placeholders fuera de git salvo pedido.

---

## Live critical-path cues (slides 7–10)

| Slide | Owner | Make target | Expected signal |
|-------|-------|-------------|-----------------|
| 7 | B | `make demo-skupper` | Kind↔Podman / legacy-emoji OK |
| 8 | B | `make demo-mesh` | Mesh / emojivoto OK |
| 9 | A | `make demo-ratelimit` | ≥1 HTTP **429** |
| 10 | A | `make failover` | East sigue respondiendo (live) |

UI order if shown: `make ui` **A→B→C** (app `:8080` → Viz `:50750` → observer `:8443`). Skip UI if late or stall.

---

## Rehearsal checklist

Hacer **antes** del talk (no cuenta en el reloj de 30 min).

### Stack warm

- [ ] `make prereq-check`
- [ ] `make up`
- [ ] `make smoke` (200/429, mesh, Skupper, dig)
- [ ] Hosts entry para `emojivoto.demo.local` si hace falta
- [ ] Opcional: `make ui` — guardar ACCESS_URLs impresos (A→B→C)
- [ ] Confirmar que **no** se usa `kind-cluster`

### Critical path dry-run

- [ ] `make demo-skupper` (B)
- [ ] `make demo-mesh` (B)
- [ ] `make demo-ratelimit` → ver 429 (A)
- [ ] `make failover` live (A) — medir tiempo real
- [ ] Contingencia: video failover listo **fuera del repo** (path local conocido)
- [ ] Regla ≤2 min: si se atasca, abandonar → video / takeaways

### Timing / corte

- [ ] Cronometrar bloques 9–16 y 16–25
- [ ] Si late: **cortar UI primero**, luego Option-C backup
- [ ] Handoffs A↔B ensayados (frase de cierre de cada bloque)

### Post-rehearsal / teardown (opcional)

- [ ] `make down` (best-effort `ui-down`, solo sitios demo)

### Offline packaging check (WU2)

- [x] 12 slides + owners A=Francisco / B=Sergio; hybrid ES+EN; Make cues 7–10; CTA `up`→`smoke`→optional `ui`→`down`; no `kind-cluster` operate; demo-stack specs untouched (see `tasks.md` 3.2)
