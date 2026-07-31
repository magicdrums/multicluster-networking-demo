# talk-ui-surface Specification

## Purpose

Opt-in app / Linkerd Viz / Skupper observer UIs without blocking lean `make up` or reserved CCM/Gateway ports.

## Requirements

### Requirement: Phase A app browser access and validation

MUST document `/etc/hosts` `emojivoto.demo.local` → `127.0.0.1`. Validation (`make ui-app` / `ui-app-check`) MUST print west `http://emojivoto.demo.local:8080/` and MAY print east `:8081/`; MUST HTTP-probe via hostname; MUST NOT document bare `127.0.0.1` without Host. No new ingress. After `up`, expect 200/429.

#### Scenario: West URL printed and reachable

- GIVEN `make up` done and hosts maps `emojivoto.demo.local`
- WHEN Phase A validation runs
- THEN helper prints `http://emojivoto.demo.local:8080/`
- AND hostname HTTP check returns 200 or 429

#### Scenario: Bare IP without Host banned

- GIVEN Phase A docs or validation output
- WHEN following documented app access
- THEN path uses `emojivoto.demo.local`
- AND MUST NOT prescribe bare `http://127.0.0.1:8080/` without Host

### Requirement: Phase B Linkerd Viz opt-in and validation

SHOULD provide west-only Viz @ Linkerd **edge-26.6.3** via `make ui-linkerd`; PF preferred `http://127.0.0.1:50750/` (printed free-port URL is contract). MUST print final URL; MUST confirm reachability (`viz check` or HTTP). MUST NOT use CCM LB, east Viz, or default `make up`. Bundled Prom MAY.

#### Scenario: Viz URL printed and reachable

- GIVEN `make up` done; operator opts into B
- WHEN `make ui-linkerd` / check completes
- THEN helper prints final Viz URL (default `:50750` or free port)
- AND Viz is reachable there

#### Scenario: Viz out of make up and CCM

- GIVEN default `make up` without UI targets
- WHEN inspecting bring-up
- THEN Viz is not installed/PF'd by `up`
- AND not exposed via CCM LB mapping

### Requirement: Phase C Skupper observer opt-in and validation

MAY install network-observer **2.2.1**, prefer **podman-edge**, fallback west `skupper` NS. HTTPS PF preferred `https://127.0.0.1:8443/` (printed URL is contract). `make ui-skupper` / check MUST print HTTPS URL + basic-auth once; MUST NOT commit creds; MUST confirm reachability. Second Prom MAY with RAM note.

#### Scenario: Observer URL and creds printed once

- GIVEN `make up` done; operator opts into C
- WHEN `make ui-skupper` / check completes
- THEN helper prints HTTPS URL (default `:8443` or free port) and basic-auth once
- AND observer reachable with those creds

#### Scenario: podman-edge preferred, west fallback

- GIVEN Phase C requested and preferred site blocked
- WHEN install proceeds
- THEN MAY use west `skupper` NS
- AND skip-inject / VAN critical path stay intact

### Requirement: Reserved ports and teardown

UI helpers MUST avoid ports **8080, 8081, 18080, 18081, 45671, 55671**. `make ui-down` MUST tear down B/C. A is docs/hosts only. Validation MUST be post-`up` opt-in, NEVER inside `make up`. `kind-cluster` untouched.

#### Scenario: ui-down clears B and C

- GIVEN Viz and/or observer started
- WHEN `make ui-down` runs
- THEN B/C PF/installs stop
- AND Gateway/Skupper CCM ports unchanged

#### Scenario: UI validation never inside make up

- GIVEN default `make up`
- WHEN bring-up finishes
- THEN A/B/C validation did not run as part of `up`
- AND RateLimit, failover, Option C remain available
