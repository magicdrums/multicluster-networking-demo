# Exploration: kcd-ba-talk-deck

**Change:** `kcd-ba-talk-deck`  
**Project:** kcd-argentina2026  
**Mode:** hybrid (openspec + Engram)  
**Artifact language:** English structure; **Spanish speaker scripts**; **English Gemini image prompts** (better image-gen quality)  
**Source rule:** Talk narrative is derived only from this repo’s README + `demo/` stack on `main`. Proprietary workshop decks and marketing copy stay **outside git**. Only original KCD/community prompts and scripts live under `openspec/`.

---

## Problem / Goal

Prepare a **30-minute, dual-speaker** KCD Buenos Aires / Argentina 2026 talk deck that frames and drives the existing **laptop multicluster connectivity demo** already on `main`:

| Fact | Value |
|------|-------|
| Sites | `kind-west`, `kind-east`, `podman-edge` (never touch `kind-cluster`) |
| Stack | Envoy Gateway + Kuadrant + Linkerd + Skupper + CoreDNS |
| Wow moments | RateLimit HTTP **429**, CoreDNS HA failover, meshed emojivoto, Skupper Kind↔Podman |
| Public path | `make up` → `make smoke` → optional `make ui` (A→B→C) → `make down` |
| ACCESS_URLs | `emojivoto.demo.local:8080` / `:8081`, Viz `:50750`, observer `:8443` |

Deliverables for later phases: slide list, timing, Speaker A/B ownership, Spanish talking points with demo cues, and Gemini prompts to generate each 16:9 visual — **not** a binary PPTX in git.

---

## Current State

Demo is **implemented and documented**. Public operator path is lean:

1. `make up` — stack only (UI-free, idempotent)
2. `make smoke` — 200/429, mesh, Skupper, dig
3. Optional `make ui` — app → Linkerd Viz → Skupper observer (fail-fast A→B→C)
4. Live critical path Make targets: `demo-ratelimit`, `demo-mesh`, `demo-skupper`, `failover`
5. `make down` — best-effort `ui-down`, then demo sites only

Talk UI surfaces (optional, not required for critical-path success):

| Phase | Surface | Typical URL |
|-------|---------|-------------|
| A | Emojivoto (west Gateway) | `http://emojivoto.demo.local:8080/` |
| A | East Gateway (optional) | `http://emojivoto.demo.local:8081/` |
| B | Linkerd Viz (west) | `http://127.0.0.1:50750/` |
| C | Skupper network-observer | `https://127.0.0.1:8443/` |

Topology (from README):

```
Client → EG (west) → web (meshed) → voting → emoji
              │            │            │
         RateLimit      Linkerd      Skupper
              │                         ├─ voting (east)
         CoreDNS west→east              └─ legacy-emoji (podman-edge)
```

Archived SDD changes already fixed the demo story (`multicluster-connectivity-demo`, `demo-product-uis`, `demo-script-consolidation`). This change is **talk packaging only** — no stack redesign.

### Affected Areas

- `openspec/changes/kcd-ba-talk-deck/` — exploration → proposal → (optional) talk-script artifacts
- `README.md` — reference for runbook / ACCESS_URLs (read-only unless propose adds a short “Talk deck” pointer)
- `demo/` — live demo cues only; **no** PPTX binaries, no secrets (e.g. `demo/.run/ui-skupper-basic-auth` stays gitignored)
- Out of scope for apply: copying proprietary workshop decks, vendor marketing copy, or external catalog item IDs into the repo

---

## Approaches

| # | Approach | Pros | Cons | Effort |
|---|----------|------|------|--------|
| 1 | **~12 slides + demo-forward** (recommended) — Narrative slides bookend a rehearsed live critical path; UI optional | Fits 30 min; matches README runbook; two speakers can trade demo vs story; low slide clutter | Requires cold-start rehearsal; live risk if stack flaky | Medium |
| 2 | **Dense ~16 slides, light live** — More theory diagrams; short CLI clips | Safer if Wi-Fi/laptop fails | Feels workshop-like; underuses the wow path; dual-speaker energy drops | Medium |
| 3 | **~8–10 slides, demo-maximal** — Minimal deck; almost all time in terminal/UI | Highest “wow” density | Hard for audience without mesh experience; weak takeaways slide; timing brittle | Low–Medium |
| 4 | **Pre-recorded video + thin deck** | Zero live risk | Less KCD energy; less Q&A flexibility | Medium |

### Comparison notes

- Compressing a longer “module arc” (framing → interconnect → E-W → N-S → wrap) into **12 slides** keeps one idea per slide and leaves **~15–18 minutes** for live demos.
- Demo-heavy beats slide-heavy for this repo: the product *is* the laptop stack.
- Pre-record is a **backup**, not the primary plan.

---

## Recommendation

**Approach 1: ~12 original slides + demo-forward dual-speaker talk.**

### Timing budget (30 minutes)

| Block | Minutes | Owner bias | Content |
|-------|---------|------------|---------|
| Open + problem + agenda | 0:00–5:00 | A then B | Title, who, challenges, agenda |
| Topology + story setup | 5:00–9:00 | B | Three sites; disconnected → connected narrative |
| Live: interconnect + mesh | 9:00–16:00 | B (A support) | Skupper Kind↔Podman; Linkerd / emojivoto; optional Viz |
| Live: N-S policy + failover | 16:00–25:00 | A (B support) | RateLimit 429; CoreDNS failover; optional app browser |
| Takeaways + thank you + Q&A buffer | 25:00–30:00 | A + B | Repo link, what to try at home, questions |

**Speaker split (placeholders until names known):**

- **Speaker A** — Framing, north-south (Envoy Gateway + Kuadrant), CoreDNS failover, close
- **Speaker B** — Topology, Skupper VAN / edge, Linkerd east-west, optional UI phases B/C

**Pre-talk (not on stage clock):** `make prereq-check` → `make up` → `make smoke` → optional `make ui` (hosts entry once). Prefer stack **already warm** before the room fills.

**Language choice stated here:** Slide *titles* in Spanish by default (KCD Argentina); Gemini prompts in English; talking points in conversational Spanish.

---

## Proposed slide list (12)

| # | Title (ES) | Purpose | Owner | ~Time on slide |
|---|------------|---------|-------|----------------|
| 1 | KCD Argentina 2026 — Conectividad multicluster | Title / brand / event | A+B | 1:00 |
| 2 | Quiénes somos | Two presenters, roles | A+B | 1:00 |
| 3 | El problema: muchos sitios, poca confianza | Audience pain: hybrid, edge, policy gaps | A | 2:00 |
| 4 | Agenda (30 min) | Promise: interconnect → mesh → policy → failover | B | 1:00 |
| 5 | Topología del demo | `kind-west` / `kind-east` / `podman-edge` | B | 2:00 |
| 6 | Historia: de desconectado a conectado | Narrative bridge into live demo | B | 1:30 |
| 7 | Interconectar entornos con Skupper | Kind↔Podman VAN; cue `make demo-skupper` | B | 3:00 (incl. live) |
| 8 | East–west con Linkerd | Meshed emojivoto; cue `make demo-mesh` (+ Viz opcional) | B | 3:00 (incl. live) |
| 9 | North–south con Envoy Gateway + Kuadrant | RateLimit 429; cue `make demo-ratelimit` | A | 3:30 (incl. live) |
| 10 | Failover con CoreDNS | Kill primary west → east still answers; cue `make failover` | A | 3:30 (incl. live) |
| 11 | Qué se llevan | Public path + wow list + repo | A | 1:30 |
| 12 | Gracias + preguntas | Contact / QR / Q&A | A+B | 2:00+ |

Optional stretch (cut first if over time): deep-dive diagram of Skupper Option C loopback redeem — keep as **backup slide**, not in the 12.

---

## Speaking scripts / talking points (Spanish)

Demo cues use Make targets from README. Prefer Make over typing YAML on stage.

### Slide 1 — Título
- Bienvenida a KCD Argentina / Buenos Aires 2026.
- Promesa en una frase: “Vamos a conectar tres sitios en una laptop y mostrar políticas, mesh y failover en vivo.”
- Mencionar stack open-source por nombre: Envoy Gateway, Kuadrant, Linkerd, Skupper, CoreDNS.
- Cue: no demo aún; confirmar que el stack ya está en `make up` + `smoke` OK (off-mic).

### Slide 2 — Quiénes somos
- Speaker A / Speaker B se presentan (nombres TBD).
- Rol claro: A = políticas N-S + resiliencia DNS; B = topología + Skupper + mesh.
- Una línea cada uno sobre por qué les importa la conectividad multicluster / edge.

### Slide 3 — El problema
- Realidad: apps repartidas en clusters y fuera de cluster (edge/legacy).
- Dolores: “¿cómo enlazo sin VPN eterna?”, “¿quién aplica rate limit en el borde?”, “¿qué pasa si cae el sitio primario?”.
- No vender productos propietarios; enmarcar como problema de **planos de conectividad**.

### Slide 4 — Agenda
- Cuatro batallas: interconectar → controlar E-W → gobernar N-S → sobrevivir al failover.
- Aclarar: demo en laptop, sitios `kind-west`, `kind-east`, `podman-edge`.
- Decir en voz alta que **nunca** tocamos un cluster ajeno (`kind-cluster`).

### Slide 5 — Topología
- West = hub (Gateway, Kuadrant, Linkerd, emojivoto completo, Skupper hub).
- East = réplica voting + spoke Skupper + Gateway.
- Podman-edge = sitio Skupper + `legacy-emoji` HTTP JSON.
- Señalar el dibujo: cliente → EG west → servicios mesh → Skupper a east/edge.

### Slide 6 — Historia
- Empezamos “desconectados”: tres islas.
- Objetivo: un servicio híbrido y políticas consistentes sin reescribir la app.
- Transición: “Ahora lo vemos en vivo — primero el cableado entre sitios.”

### Slide 7 — Skupper (live)
- Explicar VAN: enlazar Kind con Podman (fuera de Kubernetes).
- Cue: `make demo-skupper` (y/o `curl http://127.0.0.1:18080/` para legacy-emoji).
- Opcional UI: si `make ui` ya corrió, abrir observer `ACCESS_URL` ~`:8443` (aceptar cert self-signed; basic-auth en `demo/.run/` — no mostrar secretos en cámara).
- Frase de cierre: “Misma app lógica, un hop que cruza el borde.”

### Slide 8 — Linkerd (live)
- E-W: mTLS / identidad entre microservicios emojivoto en west (y narrativa de mesh).
- Cue: `make demo-mesh`.
- Opcional: Linkerd Viz `http://127.0.0.1:50750/` (fase B de `make ui`).
- Contraste: mesh **dentro** del cluster vs Skupper **entre** sitios.

### Slide 9 — Envoy Gateway + Kuadrant (live)
- N-S: el cliente entra por Gateway; la política vive en Kuadrant (RateLimit).
- Cue principal: `make demo-ratelimit` → al menos un **HTTP 429**.
- Alternativa visual: browser `http://emojivoto.demo.local:8080/` — clicks rápidos en lista/leaderboard → 429 (3 req / 10s).
- Recordar Host header / hostname; no usar bare `127.0.0.1:8080` sin Host.

### Slide 10 — Failover CoreDNS (live)
- Historia: si el primario west duele, el DNS/HA debe seguir sirviendo east.
- Cue: `make failover` — escala dataplane west Envoy a 0, borra DNSPolicy west; dig dual-site; espera hasta ~120s; restaura al salir.
- Advertencia de operador (una frase): no poner `weight: 0` (pánico conocido en CoreDNS provider) — el script ya hace el camino seguro.
- Si timeout: ser honestos, mostrar que el smoke previo pasó, y pasar a takeaways (no pelear 5 min).

### Slide 11 — Qué se llevan
- Camino público: `make up` → `make smoke` → opcional `make ui` → `make down`.
- Cuatro wows: 429, failover, mesh, Skupper Kind↔Podman.
- Repo GitHub del demo; invitar a clonar y romper cosas en casa.

### Slide 12 — Gracias
- Agradecer KCD / comunidad.
- Q&A; ofrecer quedarse para ver UI si no entró en el bloque live.
- Contactos TBD.

---

## Gemini prompts per slide (English, 16:9)

**Global style for all prompts:** Widescreen 16:9 presentation slide mockup, clean community conference aesthetic (KCD Argentina), high contrast readable typography, no commercial vendor logos or corporate product packaging, no trademarked vendor wordmarks as hero branding, open-source / CNCF-adjacent iconography ok as generic geometric marks, avoid purple-on-white AI cliché, prefer deep teal + warm sand + charcoal, subtle abstract network mesh background, generous margins, one focal diagram or title group.

1. **Title:** “16:9 title slide for KCD Argentina 2026. Huge event wordmark ‘KCD Argentina’, subtitle ‘Conectividad multicluster en 30 minutos’, small abstract map of three glowing nodes labeled west / east / edge, two silhouettes of speakers as abstract shapes not photos, dark teal gradient atmosphere, no logos of commercial vendors.”

2. **Who we are:** “16:9 slide with two equal portrait placeholders (geometric avatars), labels ‘Speaker A’ and ‘Speaker B’, thin dividing line, icons suggesting gateway policy vs network topology, bilingual empty name fields, community meetup vibe, sand and charcoal palette.”

3. **Problem:** “16:9 conceptual slide: three isolated islands (Kubernetes hex, Kubernetes hex, small server/edge box) with broken dashed lines between them, frustrated traffic arrows bouncing back, headline space for ‘Muchos sitios, poca confianza’, minimal text, dramatic lighting.”

4. **Agenda:** “16:9 agenda slide with four numbered horizontal stages as a journey path: Interconectar → Mesh E-W → Políticas N-S → Failover, each with a simple icon (link, shield mesh, gate, heartbeat), clock hint ‘30 min’, clean and sparse.”

5. **Topology:** “16:9 architecture diagram: left client browser, center hub cluster ‘kind-west’ with gateway diamond and mesh dots, right ‘kind-east’, bottom ‘podman-edge’ with tiny emoji service, Skupper curves linking all three, CoreDNS arrows west to east, labeled clearly, whiteboard-meets-infographic style.”

6. **Story bridge:** “16:9 before/after split: left side gray disconnected clusters, right side colorful linked fabric, arrow ‘VAN + mesh + policy’, cinematic but not sci-fi, no product logos.”

7. **Skupper:** “16:9 demo slide focused on Kind-to-Podman link: two clusters and one Podman node connected by a bright virtual application network ribbon, callout ‘legacy-emoji’, terminal window silhouette with green success text blurred, community tone.”

8. **Linkerd:** “16:9 east-west mesh slide: emojivoto-style microservices (web, voting, emoji) as friendly nodes with mTLS lock icons on edges inside kind-west, faint Viz dashboard mock without readable proprietary UI chrome, title area for ‘East–west con Linkerd’.”

9. **RateLimit:** “16:9 north-south policy slide: big gateway icon in front of cluster, traffic bars hitting a shield labeled RateLimit, one request stamped huge ‘HTTP 429’, Envoy-like proxy glyph as generic, Kuadrant mentioned only as plain text label if needed, bold and playful.”

10. **Failover:** “16:9 resilience slide: west gateway node dimmed/offline, east gateway glowing, DNS records animating toward east IP, dig output aesthetic in a monospace panel, heartbeat line recovering, title ‘Failover CoreDNS’.”

11. **Takeaways:** “16:9 checklist slide with four large checkmarks: 429, failover, mesh, Skupper Kind↔Podman, plus a small code-block graphic showing make up / make smoke / make ui / make down, repo silhouette, inviting and clear.”

12. **Thanks:** “16:9 closing slide: large ‘Gracias’, empty QR code placeholder square, subtle confetti of network nodes, KCD Argentina footer line, space for GitHub URL, warm sand background with teal accents.”

---

## Source materials policy (explicit)

- **In git / openspec / Engram:** original slide outlines, Spanish scripts, English Gemini prompts, timing, speaker ownership, demo cues tied to this repo.
- **Outside git:** any local proprietary workshop PPTX or corporate marketing decks used only as private narrative inspiration by presenters — **do not quote paths, slide text, catalog links, presenter names from those decks, sample app stories from those decks, or product marketing copy** into repo artifacts.
- **Do not** commit binary PPTX, screenshots that embed proprietary workshop branding, or secrets from `demo/.run/`.

---

## Open questions — RESOLVED (propose)

1. **Speakers:** Francisco Meneses = A (N-S, failover, close); Sergio Canales = B (topology, Skupper, Linkerd, Viz/observer). Swap OK if documented.
2. **Language:** Spanish titles/body; English for awkward tech terms (hybrid ES+EN).
3. **Live UI:** YES — include `make ui` A→B→C on stage (skip if over time).
4. **Failover:** LIVE primary + backup video outside git (do not commit binaries).
5. **CTA:** GitHub URL; QR placeholder later, not committed unless asked.
6. **Next artifact:** `sdd-spec` for `kcd-talk-deck` (talk-script requirements); design/tasks after.

---

## Risks

- **Live demo flakiness** (Skupper Option C, failover 120s timeout) can blow the timing budget — mitigated by video backup.
- **UI basic-auth / cert warnings** on observer can stall the room if not rehearsed — skip UI if late.
- **Dual-speaker handoffs** — names/roles now locked in proposal.
- **Scope creep** into proprietary workshop content would violate the source policy — keep artifacts original.
- **Auth bonus (Authorino)** is optional and should stay out of the 30-min critical path.

---

## Ready for Proposal

**Done.** See `proposal.md`. Speakers, language, UI, and failover contingency locked.

**Suggested next SDD step:** `sdd-spec` (parallel-ok with `sdd-design`)
