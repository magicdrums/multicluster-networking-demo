# Gemini prompts: KCD BA Talk Deck

English image-generation prompts for slides 1–12. Widescreen **16:9**, community / KCD Argentina aesthetic.  
Derived from this repo’s talk narrative (README + `demo/`). **No proprietary workshop copy, vendor logos as hero branding, or commercial packaging.**

## Global style (prepend or keep in mind for every prompt)

Widescreen 16:9 presentation slide mockup, clean community conference aesthetic (KCD Argentina), high-contrast readable typography, no commercial vendor logos or corporate product packaging, no trademarked vendor wordmarks as hero branding, open-source / CNCF-adjacent iconography OK as generic geometric marks, avoid purple-on-white AI cliché, prefer deep teal + warm sand + charcoal, subtle abstract network mesh background, generous margins, one focal diagram or title group.

---

### Slide 1 — Title

16:9 title slide for KCD Argentina 2026. Huge event wordmark “KCD Argentina”, subtitle “Conectividad multicluster en 30 minutos”, small abstract map of three glowing nodes labeled west / east / edge, two silhouettes of speakers as abstract shapes not photos, dark teal gradient atmosphere, no logos of commercial vendors.

### Slide 2 — Who we are

16:9 slide with two equal portrait placeholders (geometric avatars), labels “Francisco — Speaker A” and “Sergio — Speaker B”, thin dividing line, icons suggesting gateway policy vs network topology, community meetup vibe, sand and charcoal palette.

### Slide 3 — Problem

16:9 conceptual slide: three isolated islands (Kubernetes hex, Kubernetes hex, small server/edge box) with broken dashed lines between them, frustrated traffic arrows bouncing back, headline space for “Muchos sitios, poca confianza”, minimal text, dramatic lighting.

### Slide 4 — Agenda

16:9 agenda slide with four numbered horizontal stages as a journey path: Interconectar → Mesh E-W → Políticas N-S → Failover, each with a simple icon (link, shield mesh, gate, heartbeat), clock hint “30 min”, clean and sparse.

### Slide 5 — Topology

16:9 architecture diagram: left client browser, center hub cluster “kind-west” with gateway diamond and mesh dots, right “kind-east”, bottom “podman-edge” with tiny emoji service, Skupper curves linking all three, CoreDNS arrows west to east, labeled clearly, whiteboard-meets-infographic style.

### Slide 6 — Story bridge

16:9 before/after split: left side gray disconnected clusters, right side colorful linked fabric, arrow “VAN + mesh + policy”, cinematic but not sci-fi, no product logos.

### Slide 7 — Skupper

16:9 demo slide focused on Kind-to-Podman link: two clusters and one Podman node connected by a bright virtual application network ribbon, callout “legacy-emoji”, terminal window silhouette with green success text blurred, community tone.

### Slide 8 — Linkerd

16:9 east-west mesh slide: emojivoto-style microservices (web, voting, emoji) as friendly nodes with mTLS lock icons on edges inside kind-west, faint Viz dashboard mock without readable proprietary UI chrome, title area for “East–west con Linkerd”.

### Slide 9 — RateLimit

16:9 north-south policy slide: big gateway icon in front of cluster, traffic bars hitting a shield labeled RateLimit, one request stamped huge “HTTP 429”, Envoy-like proxy glyph as generic, Kuadrant as plain text label only if needed, bold and playful.

### Slide 10 — Failover

16:9 resilience slide: west gateway node dimmed/offline, east gateway glowing, DNS records animating toward east IP, dig output aesthetic in a monospace panel, heartbeat line recovering, title “Failover CoreDNS”.

### Slide 11 — Takeaways

16:9 checklist slide with four large checkmarks: 429, failover, mesh, Skupper Kind↔Podman, plus a small code-block graphic showing make up / make smoke / make ui / make down, repo silhouette, inviting and clear.

### Slide 12 — Thanks

16:9 closing slide: large “Gracias”, empty QR code placeholder square, subtle confetti of network nodes, KCD Argentina footer line, space for GitHub URL, warm sand background with teal accents.
