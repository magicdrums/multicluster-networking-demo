# talk-ui-surface Specification

## Purpose

Opt-in app / Linkerd Viz / Skupper observer UIs without blocking lean `make up` or reserved CCM/Gateway ports.

## Requirements

### Requirement: Public Make UI entry and fail-fast

Public UI entry MUST be `make ui` only: A→B→C start+validate + ACCESS_URL each. MUST NOT alias removed UI Make names (`ui-app*`, `ui-linkerd*`, `ui-skupper*`, `talk-up`). Mid-failure MUST fail-fast (non-zero; MUST NOT start later phases); earlier phases MAY remain until `ui-down`/`down`. Path: `make up` then optional `make ui`.

#### Scenario: make ui runs A then B then C

- GIVEN `make up` done
- WHEN `make ui` succeeds
- THEN A–C each start+validate and print ACCESS_URL

#### Scenario: Mid-ui fail-fast

- GIVEN A ok and B fails
- WHEN failure detected
- THEN non-zero exit; Phase C MUST NOT start

#### Scenario: Hard cut of old UI Make names

- GIVEN consolidated Makefile
- WHEN removed UI target invoked
- THEN no alias success; help MUST NOT list it

### Requirement: Public Make help versus lib internals

`make help` MUST list `prereq-check`, `up`, `smoke`, `ui`, `ui-down`, `down`, plus demo/failover/test targets. Internals MUST live under `demo/scripts/lib/` (not primary help). Single prereq gate MUST remain. Offline `test-ui-*` MUST stay green without Kind and assert new surface/`lib/`.

#### Scenario: Help lists ui not per-phase

- GIVEN Makefile help
- WHEN `make help` runs
- THEN lists `ui`/`ui-down`; omits removed per-phase UI names

#### Scenario: Internals under lib

- GIVEN relocated helpers
- WHEN inspecting `demo/scripts/`
- THEN internals under `lib/`; callers still work

#### Scenario: Offline UI suites without Kind

- GIVEN no Kind
- WHEN `test-ui-*` run
- THEN exit 0 on new surface/`lib/` contracts

### Requirement: Phase A app browser access and validation

MUST document hosts `emojivoto.demo.local`→`127.0.0.1`. Phase A via `make ui` MUST print west `http://emojivoto.demo.local:8080/` (MAY east `:8081/`); MUST HTTP-probe via hostname; MUST NOT document bare IP without Host. After `up`, expect 200/429.

#### Scenario: West URL printed and reachable

- GIVEN `make up` done and hosts mapped
- WHEN Phase A via `make ui`
- THEN prints west ACCESS_URL; hostname check 200 or 429

#### Scenario: Bare IP without Host banned

- GIVEN Phase A docs/output
- WHEN following app access
- THEN uses hostname; MUST NOT prescribe bare IP without Host

### Requirement: Phase B Linkerd Viz opt-in and validation

SHOULD provide west-only Viz @ Linkerd **edge-26.6.3** as Phase B of `make ui`; PF preferred `:50750` (printed URL is contract). MUST print URL and confirm reachability. MUST NOT use CCM LB, east Viz, or default `make up`.

#### Scenario: Viz URL printed and reachable

- GIVEN `make up` done; Phase B
- WHEN Phase B completes
- THEN prints Viz URL; Viz reachable

#### Scenario: Viz out of make up and CCM

- GIVEN default `make up` without `make ui`
- WHEN inspecting bring-up
- THEN Viz not installed/PF'd by `up` nor via CCM LB

### Requirement: Phase C Skupper observer opt-in and validation

MAY install network-observer **2.2.1** (prefer **podman-edge**; west fallback). HTTPS PF preferred `:8443`. Phase C of `make ui` MUST print HTTPS URL + basic-auth once; MUST NOT commit creds; MUST confirm reachability.

#### Scenario: Observer URL and creds printed once

- GIVEN `make up` done; Phase C
- WHEN Phase C completes
- THEN prints HTTPS URL + basic-auth once; observer reachable

#### Scenario: podman-edge preferred, west fallback

- GIVEN Phase C and preferred site blocked
- WHEN install proceeds
- THEN MAY use west `skupper` NS; VAN/skip-inject intact

### Requirement: Reserved ports and teardown

UI helpers MUST avoid **8080, 8081, 18080, 18081, 45671, 55671**. `make ui-down` MUST tear down B/C. UI MUST be post-`up` opt-in via `make ui`, NEVER inside `make up`. `kind-cluster` untouched.

#### Scenario: ui-down clears B and C

- GIVEN Viz and/or observer started
- WHEN `make ui-down` runs
- THEN B/C stop; Gateway/Skupper CCM ports unchanged

#### Scenario: UI validation never inside make up

- GIVEN default `make up`
- WHEN bring-up finishes
- THEN A/B/C validation did not run; RateLimit/failover/Option C remain
