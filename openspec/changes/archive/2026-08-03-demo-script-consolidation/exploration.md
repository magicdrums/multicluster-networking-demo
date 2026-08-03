## Exploration: demo-script-consolidation

**Change name (proposed):** `demo-script-consolidation`  
**Intent:** Reduce cognitive load for public users of varying skill by consolidating operator-facing demo scripts/Make targets, while preserving talk rehearsal flexibility and locked critical-path contracts.  
**Baseline:** `main` with full EG/Kuadrant/Linkerd/Skupper demo + opt-in talk UIs (archived `multicluster-connectivity-demo`, `demo-product-uis`).  
**Audience:** Public share — simplicity of bring-up first; speaker rehearsal second.  
**CodeGraph note:** `.codegraph/` present but shell/Make not usefully returned; inventory via filesystem + README/specs.

### Current State

#### Inventory counts

| Surface | Count | Notes |
|---------|------:|-------|
| Scripts under `demo/scripts/` | **24** | ~3.8k LOC total |
| Make `.PHONY` / help targets | **~22** (+ aliases `demo-smoke`/`demo-failover`) | Thin wrappers → one script each |
| Opt-in UI start/check scripts | **6** (+ `ui-common.sh`, `ui-down.sh`) | A/B/C × (start, check) |
| Offline test suites | **4** | `test-allowlist`, `test-ui-{foundation,linkerd,skupper}` |
| Internal helpers (not in Make help as first-class) | **4** | `cloud-provider-kind.sh` (sourced), `ensure-skupper-localhost-san.sh`, `redeem-podman-skupper.sh`, `common.sh` |

#### How composition works today

```text
Public path (README 30-min):
  make prereq-check → make up → make smoke → [demo-* / failover] → make down

up.sh already calls prereq-check.sh (cohesive gate exists; Make target is redundant but useful alone).

Talk UI path (opt-in, NEVER dependency of up — talk-ui-surface):
  make ui-app / ui-app-check
  make ui-linkerd && make ui-linkerd-check
  make ui-skupper && make ui-skupper-check
  make ui-down   (also best-effort from down.sh)
```

| Role | Scripts / targets | Newcomer load |
|------|-------------------|---------------|
| Lifecycle | `up.sh`, `down.sh` | Clear — keep |
| Host gate | `prereq-check.sh` (also invoked by `up`) | Clear — already single gate |
| Wow / probes | `smoke`, `failover`, `demo-ratelimit`, `demo-mesh`→`check-east-west`, `demo-skupper`→`check-skupper` | Moderate — naming split (`demo-*` vs `check-*`) |
| Talk UI | 6 start/check + down | **High** — start vs check doubles surface |
| Internals | CCM / SAN / redeem | High if user browses `demo/scripts/` directory |
| Offline tests | `test-*` | Fine for maintainers; should stay out of happy-path docs |

#### Overlap / thin wrappers

- **Makefile** is almost entirely 1:1 façade over scripts (good pattern).
- **`ui-app.sh` vs `ui-app-check.sh`:** A-start only prints URL/hosts; check prints same ACCESS_URL + probes — near-duplicate for public users.
- **B/C start vs check:** Start does install+PF; check validates — real split, but operators always want both.
- **`demo-mesh` / `demo-skupper`:** Rename wrappers over `check-*.sh` (file names diverge from Make).
- **`demo-smoke` / `demo-failover`:** Pure aliases.
- **Prereq:** Already cohesive; gap is discoverability/docs, not missing CLIs/inotify checks.

#### Locked contracts (must not break)

- Allowlist only: `kind-west`, `kind-east`, `podman-edge` — **never** `kind-cluster`
- Default `make up` critical path: RateLimit / mesh / Skupper VAN / failover remain available; **UI validation NEVER inside `up`**
- ACCESS_URL printing + hostname app URL (`emojivoto.demo.local`); reserved ports 8080/8081/18080/18081/45671/55671
- Offline suites stay green without Kind
- Spec names `make ui-app` / `ui-linkerd` / `ui-skupper` (+ checks) — deltas may rename if aliases preserved or specs MODIFIED

### Affected Areas

- `Makefile` — primary public façade; help text / happy-path targets
- `README.md` — 30-min runbook + Talk UIs section (progressive disclosure)
- `demo/scripts/ui-*.sh` — consolidation of start+check; optional `ui.sh` dispatcher
- `demo/scripts/test-ui-*.sh` — hardcoded paths/target names
- `openspec/specs/talk-ui-surface/spec.md` — ADDED/MODIFIED if Make names change
- Possibly `demo/scripts/{check-east-west,check-skupper,prereq-check}.sh` — naming only
- **Avoid changing** core logic of `up.sh` / `failover.sh` / Skupper Option C helpers unless purely relocation
- **Out of scope for merge:** `cloud-provider-kind.sh`, `redeem-podman-skupper.sh`, `ensure-skupper-localhost-san.sh` (internals)

### Approaches

1. **Docs + Make façade only** — Add composed targets (`make ui`, `make talk-ui`, clearer help sections); keep all 24 scripts; rewrite README quick path to 4–5 Make commands.
   - Pros: Lowest risk; offline tests untouched; preserves every rehearsal target
   - Cons: Directory still noisy; start/check duplication remains in `ls demo/scripts`
   - Effort: **Low**

2. **Operator façade + UI start/validate merge (recommended)** — Keep lifecycle/`up` lean. Merge each phase’s start+check into one script (or one `ui.sh` with `PHASE=a|b|c|all`), Make aliases for old names. Optional `make talk-ui` / `make ui` runs A→B→C with ACCESS_URLs. Relocate internals to `demo/scripts/lib/` (or `internal/`) so public directory lists only operator scripts. Do **not** fold UIs into default `up`; optional separate `make talk-up` = `up` then `ui` only if explicitly named.
   - Pros: Matches user intent (fewer UI scripts, one cohesive UI action); keeps talk flexibility via PHASE/aliases; prereq already single gate; public path stays simple; offline tests updateable
   - Cons: Spec + test churn for renamed paths; need careful alias period
   - Effort: **Medium**

3. **Mega bring-up (fold everything into one script / `up` includes UIs)** — Single script installs stack + all UIs by default.
   - Pros: One command for “everything”
   - Cons: Violates `talk-ui-surface` (UI never inside default `up`); longer/fail-prone critical path; hurts lean public bring-up and rehearsal isolation
   - Effort: **High** — **reject as default**; only acceptable as explicitly named opt-in composition (`make talk-up`), never as silent `up` behavior

| Approach | Pros | Cons | Complexity |
|----------|------|------|------------|
| Docs + Make façade | Safe, fast | Scripts folder still busy | Low |
| Façade + UI merge + lib/ | Best public clarity / flexibility | Test/spec rename churn | Medium |
| Mega `up` with UIs | One command | Breaks opt-in / lean contracts | High — reject default |

### Recommendation

**GO** with change name **`demo-script-consolidation`**, approach **#2**:

**Public happy path (document first):**
1. `make prereq-check` (or document that `make up` already runs it)
2. `make up`
3. `make smoke`
4. Optional: `make ui` / `make talk-ui` (A+B+C start+validate)
5. `make down`

**Consolidation shape:**
- **UI:** One operator entry — prefer `demo/scripts/ui.sh` subcommands or `make ui PHASE=all|a|b|c` that start **and** validate, printing ACCESS_URL. Keep `ui-down`. Preserve thin Make aliases (`ui-app`, `ui-linkerd`, …) during transition so talk muscle memory and offline suites can migrate.
- **Everything-at-once:** Offer **explicit** `make talk-up` (= `up` + `ui`) for speakers who want it; **never** change default `up` semantics.
- **Prereq:** Keep single `prereq-check.sh`; improve help/docs (“doctor” naming optional). No second competing gate.
- **Internals:** Move CCM/SAN/redeem (+ maybe `common.sh`) under `demo/scripts/lib/` so newcomers see ~10 operator scripts, not 24 peers.
- **Offline tests / demo-\* probes:** Keep; update path assertions; do not merge test suites into runtime scripts.
- **Naming cleanup (optional same change):** Align `check-east-west.sh` → invoked only as `demo-mesh` story, or rename files to match Make.

**Why not #1 alone:** User explicitly wants fewer scripts / single UI start+validate — façade-only leaves the confusing start/check split.

**Why not #3 as default:** Conflicts with promoted `talk-ui-surface` and prior design lock that UIs must not block lean `make up`.

### Risks

- Renaming `ui-*-check` breaks offline suites and README/spec text unless aliases + MODIFIED deltas land together
- Merging start+check hides “print URL only” (Phase A) — mitigate with `UI_CHECK=0` or `make ui-app` alias = print-only if needed
- Relocating internals can break `up.sh`/`down.sh` source paths and Skupper offline greps
- `make talk-up` may be mistaken for required path — README must lead with lean `up` then optional UIs
- Review size likely >400 lines if lib/ move + test updates → expect chained PRs (`ask-on-risk`)

### Open questions for the user

1. Prefer **one** `make ui` (all phases) as the public UI story, or keep **per-phase** as primary with an optional `all`?
2. Should speakers get an explicit **`make talk-up`** (up+UIs), or is “up then ui” enough?
3. OK to **relocate** internal helpers to `demo/scripts/lib/` (dir declutter), or only merge UI start/check?
4. Keep deprecated Make aliases (`ui-app-check`, etc.) for one release, or hard cut with spec MODIFIED?

### Ready for Proposal

**Yes** — orchestrator should confirm change name `demo-script-consolidation` and the open questions above, then run **sdd-propose**. Scope proposal around approach #2; explicitly reject folding UIs into default `make up`.
