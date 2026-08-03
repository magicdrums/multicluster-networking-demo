# Delta for skupper-van

## MODIFIED Requirements

### Requirement: Optional network-observer for VAN visualization

MAY install network-observer **2.2.1** (prefer **podman-edge**; west fallback). Access MUST be HTTPS PF + generated basic-auth (never committed). Opt-in via Phase C of `make ui`; tear down via `make ui-down`; MUST NOT be in default `make up`. VAN MUST work without observer.
(Previously: Opt-in via `make ui-skupper`.)

#### Scenario: Observer opt-in with printed HTTPS access
- GIVEN three-site VAN after `up`
- WHEN `make ui` runs Phase C
- THEN prints HTTPS URL + basic-auth once; reachable without CCM LB

#### Scenario: VAN works without observer
- GIVEN three-site VAN linked
- WHEN Phase C skipped
- THEN VAN/`make down` still work without `ui-down`
