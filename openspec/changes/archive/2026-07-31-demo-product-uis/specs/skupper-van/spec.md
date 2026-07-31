# Delta for skupper-van

## ADDED Requirements

### Requirement: Optional network-observer for VAN visualization

MAY install network-observer **2.2.1** (prefer **podman-edge**; fallback west `skupper` NS). Access MUST be HTTPS PF + generated basic-auth (never committed). Opt-in via `make ui-skupper`; tear down via `make ui-down`; MUST NOT be in default `make up`. VAN critical path MUST work without observer.

#### Scenario: Observer opt-in with printed HTTPS access

- GIVEN working three-site VAN after `up`
- WHEN `make ui-skupper` / check runs
- THEN helper prints HTTPS URL (preferred `https://127.0.0.1:8443/` or free-port) and basic-auth once
- AND observer reachable without CCM LB

#### Scenario: VAN works without observer

- GIVEN three-site VAN linked
- WHEN Phase C skipped
- THEN cross-site exposure and `make down` still satisfy skupper-van
- AND `ui-down` MUST NOT be required for VAN cleanup via `down`
