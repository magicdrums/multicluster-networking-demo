# skupper-van Specification

## Purpose

Skupper virtual application network linking `kind-west`, `kind-east`, and `podman-edge`, exposing selected emojivoto-related or worker services across sites as needed for the talk story.

## Requirements

### Requirement: Three Skupper sites

After `make up`, Skupper sites MUST exist on `kind-west`, `kind-east`, and `podman-edge`, and MUST be linked into one VAN.

#### Scenario: Sites linked after bring-up

- GIVEN `make up` completed successfully
- WHEN an operator inspects Skupper site/link status across the three sites
- THEN all three sites MUST be present
- AND links MUST show connected/ready state for the demo VAN

### Requirement: Selected cross-site service exposure

The system MUST expose only the services required for the demo narrative (selected emojivoto or worker endpoints), not the entire cluster. Skupper MAY connect Kind↔Kind and Kind↔Podman paths as needed for the story.

#### Scenario: Consume a service from another site

- GIVEN a selected service is exposed on one Skupper site
- WHEN a consumer on a different linked site calls that service via the VAN
- THEN the call MUST succeed
- AND services not selected for exposure MUST NOT be published on the VAN

#### Scenario: Podman edge participates

- GIVEN `podman-edge` runs a Skupper site with a demo worker/backend
- WHEN a Kind-site consumer calls the exposed Podman-side service (or vice versa per script)
- THEN cross-boundary traffic MUST succeed without cloud networking

### Requirement: Teardown removes Skupper demo state

`make down` MUST remove Skupper demo sites/links associated with the three demo sites so a later `make up` can recreate a clean VAN.

#### Scenario: Down clears VAN for re-up

- GIVEN a working three-site VAN
- WHEN the operator runs `make down` then `make up`
- THEN a new VAN MUST form without leftover conflicting Skupper state from the prior run

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
