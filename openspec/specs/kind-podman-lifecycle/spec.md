# kind-podman-lifecycle Specification

## Purpose

Idempotent create/destroy of demo sites `kind-west`, `kind-east`, and `podman-edge` via `make up` / `make down`, without touching unrelated clusters.

## Requirements

### Requirement: Prerequisite gate before bring-up

The system MUST fail fast if required host prerequisites are unmet: `fs.inotify.max_user_instances` below 512, or missing `podman`, `kind`, `kubectl`, `helm`, `skupper`, or `linkerd` CLIs. The system SHOULD document pinned CLI versions.

#### Scenario: Missing CLI blocks up

- GIVEN the host lacks the `skupper` CLI
- WHEN the operator runs `make up`
- THEN bring-up MUST abort before creating any demo site
- AND the failure message MUST name the missing prerequisite

#### Scenario: Low inotify blocks multi-Kind

- GIVEN `fs.inotify.max_user_instances` is 128
- WHEN the operator runs `make up`
- THEN bring-up MUST abort before creating the second Kind cluster
- AND the message MUST require raising inotify to at least 512

### Requirement: Dedicated demo sites only

The system MUST create exactly the demo sites `kind-west`, `kind-east` (single-node Kind each), and `podman-edge`. The system MUST NOT create, reuse, start, stop, or delete the existing cluster `kind-cluster`.

#### Scenario: Fresh bring-up creates three demo sites

- GIVEN prerequisites are met and demo sites do not exist
- WHEN the operator runs `make up`
- THEN `kind-west`, `kind-east`, and `podman-edge` MUST exist and be reachable
- AND `kind-cluster` MUST remain unchanged

#### Scenario: Existing unrelated Kind is left alone

- GIVEN `kind-cluster` exists in any state
- WHEN the operator runs `make up` or `make down`
- THEN `kind-cluster` MUST NOT be modified

### Requirement: Idempotent up and scoped down

`make up` MUST be safe to re-run when demo sites already exist (reconcile to desired state, not fail as duplicate). `make down` MUST destroy only demo Kind clusters and the Podman edge site, and MUST remove demo kubecontexts/secrets associated with those sites.

#### Scenario: Re-up after successful up

- GIVEN a completed successful `make up`
- WHEN the operator runs `make up` again
- THEN the command MUST succeed without recreating sites from scratch unnecessarily
- AND demo sites MUST remain healthy

#### Scenario: Down leaves unrelated resources

- GIVEN demo sites and `kind-cluster` both exist
- WHEN the operator runs `make down`
- THEN demo Kind clusters and `podman-edge` MUST be removed
- AND `kind-cluster` MUST still exist unchanged
