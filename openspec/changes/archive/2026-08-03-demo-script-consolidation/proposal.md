# Proposal: Demo Script Consolidation

## Intent

Cut operator cognitive load: lean lifecycle plus one Talk UI entry. `make up` stays UI-free; `make ui` runs A→B→C start+validate with ACCESS_URLs; internals → `demo/scripts/lib/`.

## Scope

### In Scope
- Public `make ui` = phases A→B→C (start + validate + ACCESS_URLs); keep `ui-down`
- Merge start/check into one dispatcher (`ui.sh` or equiv.); hard-cut old UI Make/script names
- Relocate CCM/SAN/redeem/`common.sh` → `demo/scripts/lib/`; fix callers
- README/help: `up` then optional `ui`; prereq remains one gate (`up` already calls it)
- Update offline `test-ui-*` + MODIFIED spec deltas in the same change

### Out of Scope
- UIs inside default `make up`; any `make talk-up` / mega-up
- Critical-path logic changes (RateLimit/mesh/VAN/failover) beyond lib path fixes
- Offline tests merged into runtime; alias/deprecation period

## Capabilities

### New Capabilities
- None

### Modified Capabilities
- `talk-ui-surface`: Primary entry `make ui` (A→B→C); drop per-phase Make names; keep post-`up` opt-in, ports, `ui-down`, never-in-`up`
- `skupper-van`: Retarget observer access from `make ui-skupper` to `make ui` Phase C

## Approach

Exploration **#2** + user locks: lean `up`; one public `ui`; `lib/` declutter; hard cut (no aliases). Per-phase helpers may stay private, not Make-primary.

**Public Make after:** `prereq-check` · `up` · `smoke` · `ui` · `ui-down` · `down` · `demo-*`/`failover`. **Gone:** `ui-app`, `ui-*-check`, `ui-linkerd`, `ui-skupper`, `talk-up`.

## Affected Areas

| Area | Impact | Description |
|------|--------|-------------|
| `Makefile`, `README.md` | Modified/Removed | New `ui`; drop old UI targets/docs |
| `demo/scripts/ui*.sh` | Modified/Removed | Dispatcher; hard-cut names |
| `demo/scripts/lib/` | New | Internals relocation |
| `up.sh`/`down.sh`, `test-ui-*` | Modified | Paths + assertions |
| Specs `talk-ui-surface`, `skupper-van` | Modified | Delta requirements |

Allowlist sites only; never `kind-cluster`.

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Hard-cut breaks old names | Med | Ship renames + docs/tests/specs together |
| lib/ breaks sources/greps | Med | Update all callers; keep offline green |
| Mid-`ui` partial failure | Med | Define fail-fast vs continue in sdd-spec |
| PR >400 lines | High | `ask-on-risk`; chain UI / lib / docs+tests |

## Rollback Plan

Revert commits restoring prior Makefile, `ui-*.sh`, helper paths, specs, and tests. No cluster migration.

## Dependencies

Explore locks + user decisions; change-folder `exploration.md`.

## Success Criteria

- [ ] Path: `make up` → optional `make ui` → `make down` (no `talk-up`)
- [ ] `make ui` does A→B→C + ACCESS_URLs; `up` UI-free
- [ ] Old UI names removed; specs/README/offline tests green
- [ ] `lib/` declutter; single prereq gate

## Locked decisions (user)

1. One public `make ui` (all phases)  
2. No `make talk-up`  
3. Internals → `demo/scripts/lib/`  
4. Hard cut — no deprecation aliases  
