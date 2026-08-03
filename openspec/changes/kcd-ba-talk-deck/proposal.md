# Proposal: KCD BA Talk Deck

## Intent

30-min dual-speaker KCD Argentina 2026 packaging for the laptop demo on `main` (EG+Kuadrant+Linkerd+Skupper+CoreDNS): 12 slides, Spanish scripts, hybrid ES/EN, live UI+failover cues, Gemini prompts — no PPTX/video or proprietary workshop content in git.

## Scope

### In Scope
- 12-slide plan (owners, timing, ES/EN); Spanish points + Make cues
- Live UI A→B→C; failover live + backup video **outside git**
- English Gemini prompts (explore); optional README pointer

### Out of Scope
- Binaries/secrets/proprietary paths; stack redesign; Authorino; `kind-cluster`; committed QR/bios

## Capabilities

### New Capabilities
- `kcd-talk-deck`: slides, speakers, scripts, wording, live/UI/failover cues, Gemini prompts, source policy

### Modified Capabilities
- None

## Approach

Approach 1: 12 slides + demo-forward; warm stack (`prereq-check`→`up`→`smoke`→`ui`); Prefer Make.

| Role | Name | Owns |
|------|------|------|
| A | Francisco Meneses | Framing, EG+Kuadrant N-S, CoreDNS failover, close |
| B | Sergio Canales | Topology, Skupper Kind↔Podman, Linkerd E-W, Viz/observer |

Swap OK if documented. **Language:** Spanish body; English for RateLimit, failover, mesh, Gateway, N-S/E-W, ACCESS_URL, LoadBalancer, port-forward. Gemini=EN.

**Timing:** 0–5 open A→B; 5–9 topo B; 9–16 Skupper+mesh+UI B/C (B); 16–25 429+failover+UI A (A); 25–30 close A+B.

**Slides 1–12 (ES title / owner / cue):** (1) Conectividad multicluster A+B; (2) Quiénes somos A+B; (3) Problema A; (4) Agenda B — never `kind-cluster`; (5) Topología B; (6) Historia B; (7) Skupper B — `demo-skupper`+`:8443`; (8) East–west Linkerd B — `demo-mesh`+Viz `:50750`; (9) North–south EG+Kuadrant A — `demo-ratelimit`/`:8080`→429; (10) Failover CoreDNS A — `failover` live, video if flake; (11) Qué se llevan A — `up`→`smoke`→`ui`→`down`; (12) Gracias A+B. Cut first: Option-C backup slide.

**Live:** Pre-warm+`make ui`. B: Skupper→observer→mesh→Viz. A: 429→`failover`. If flake: video; if late: skip UI; never fight >~2m; never touch `kind-cluster`.

## Affected Areas

`openspec/changes/kcd-ba-talk-deck/` (new); `README.md` (optional); `demo/` cue-only; demo specs unchanged.

## Risks

Failover flake (M→video); UI cert stall (M→skip); overrun (M→cut UI/backup slide); proprietary creep (L→OSS-only).

## Rollback Plan

Revert change artifacts (no stack impact). Stage: video backup; skip UI; Keep Make demos; never mutate `kind-cluster`. Video outside git.

## Dependencies

Healthy `make smoke`; offline visuals + failover video outside git.

## Success Criteria

- [ ] 12 slides + Francisco=A / Sergio=B + hybrid ES/EN
- [ ] Specs: UI A→B→C + failover live + video contingency
- [ ] No PPTX/video/secrets/proprietary in git
- [ ] Rehearsal: 429+mesh+Skupper; failover live or video on time
- [ ] CTA: `up`→`smoke`→optional `ui`→`down`

## Open questions

None.

## Next

`sdd-spec` (`kcd-talk-deck`); parallel-ok `sdd-design`. Delivery: **ask-on-risk**.
