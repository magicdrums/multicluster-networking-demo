# kcd-talk-deck Specification

## Purpose

30-min dual-speaker KCD Argentina 2026 packaging for the laptop demo on `main`. MUST NOT redesign or weaken demo-stack specs.

## Requirements

### Requirement: Twelve-slide dual-speaker plan

Packaging MUST define exactly 12 primary slides with Spanish titles, owner (A/B/A+B), and timing. Speaker A MUST be Francisco Meneses (framing, N-S EG+Kuadrant, CoreDNS failover, close). Speaker B MUST be Sergio Canales (topology, Skupper, Linkerd E-W, Viz/observer). Swap MAY if documented. Sites MUST be `kind-west`/`kind-east`/`podman-edge`; MUST NOT operate `kind-cluster`. Option-C backup MAY sit outside the 12; MUST cut first on overrun.

#### Scenario: Locked 12-slide ownership

- GIVEN packaged talk artifacts
- WHEN reviewing the primary deck plan
- THEN 12 slides list ES titles, A=Francisco / B=Sergio (or documented swap), and timing

#### Scenario: kind-cluster excluded

- GIVEN agenda or live cues
- WHEN speakers reference demo sites
- THEN only west/east/podman-edge appear; `kind-cluster` MUST NOT be operated

### Requirement: Hybrid Spanish body and English tech terms

Titles and speaking body MUST be Spanish. RateLimit, failover, mesh, Gateway, N-S, E-W, ACCESS_URL, LoadBalancer, port-forward MUST stay English. Gemini prompts MUST be English. Scripts MUST prefer Make over ad-hoc YAML on stage.

#### Scenario: Hybrid wording check

- GIVEN titles and talking points
- WHEN inspecting language mix
- THEN body/titles are Spanish and listed tech terms stay English

#### Scenario: Gemini prompts English

- GIVEN prompts for slides 1–12
- WHEN reviewed
- THEN each is English and 16:9 community-oriented

### Requirement: Live demo cues and optional UI A→B→C

Live blocks MUST cue `demo-skupper` (B), `demo-mesh` (B), `demo-ratelimit`→HTTP 429 (A), `failover` (A). Pre-talk SHOULD warm `prereq-check`→`up`→`smoke`→optional `ui`. On-stage UI MUST follow `make ui` A→B→C (app → Viz `:50750` → observer `:8443`) without changing `talk-ui-surface`. On stall/lateness SHOULD skip UI; MUST NOT fight >~2 minutes.

#### Scenario: Critical-path Make cues present

- GIVEN slides 7–10 packaging
- WHEN live cues are listed
- THEN cues map to named Make targets and owners for Skupper, mesh, ratelimit→429, failover

#### Scenario: UI skip on overrun

- GIVEN clock pressure or UI stall
- WHEN continuing
- THEN UI MAY be skipped; Make critical path remains valid

### Requirement: Failover live primary with offline video backup

Failover MUST be live via `make failover`. Backup video MUST exist for flakes and MUST stay outside git. After ~2m failure/timeout MUST stop, acknowledge prior smoke, and advance (video and/or takeaways).

#### Scenario: Live-first failover

- GIVEN slide 10 and warm stack
- WHEN failover is demonstrated
- THEN primary path is live `make failover`

#### Scenario: Video contingency outside git

- GIVEN live failover flakes
- WHEN falling back
- THEN backup video is used outside the repo; no video binary is committed

### Requirement: Source and binary policy

Artifacts MUST be original outlines, Spanish scripts, English Gemini prompts, timing, ownership, repo-tied cues. MUST NOT include proprietary workshop PPTX/marketing/paths/catalog IDs. MUST NOT commit PPTX/video binaries or secrets (incl. `demo/.run/`). QR/bios MUST NOT be committed unless later requested.

#### Scenario: No proprietary or binary creep

- GIVEN a proposed talk-packaging commit
- WHEN reviewing staged files
- THEN no PPTX/video binaries, `demo/.run/` secrets, or proprietary workshop text/paths

#### Scenario: Original narrative only

- GIVEN scripts and prompts
- WHEN checking provenance
- THEN content derives from this repo’s README/`demo/` story

### Requirement: Timing budget and packaging success criteria

Packaging MUST target 30 min: 0–5 open (A→B); 5–9 topo (B); 9–16 Skupper+mesh+UI B/C (B); 16–25 429+failover+UI A (A); 25–30 close (A+B). Success MUST cover requirements above, rehearsal of 429+mesh+Skupper and failover live or video on time, and CTA `up`→`smoke`→optional `ui`→`down`. Demo-stack specs MUST remain unmodified.

#### Scenario: Timing blocks documented

- GIVEN talk packaging
- WHEN checking the 30-min plan
- THEN the five timing blocks and owners match

#### Scenario: CTA and non-interference

- GIVEN takeaways and existing demo specs
- WHEN this change is applied
- THEN CTA lists `up`→`smoke`→optional `ui`→`down`; demo-stack specs stay unchanged
