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
