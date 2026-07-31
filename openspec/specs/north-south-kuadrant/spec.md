# north-south-kuadrant Specification

## Purpose

North-south edge on Kind sites using Envoy Gateway and Kuadrant: RateLimit + CoreDNS DNS HA as the live wow; AuthPolicy optional; expose emojivoto.

## Requirements

### Requirement: EG and Kuadrant on Kind sites

After lifecycle bring-up, `kind-west` and `kind-east` MUST run Envoy Gateway and Kuadrant components needed for Gateway API policies and DNS. Cloud DNS providers MUST NOT be required.

#### Scenario: Gateway accepts external HTTP to emojivoto

- GIVEN `make up` completed successfully
- WHEN a client sends an HTTP request through the demo Gateway to emojivoto
- THEN the request MUST reach the meshed emojivoto front service
- AND no cloud DNS credentials MUST be required

### Requirement: RateLimitPolicy is primary live N-S wow

The critical demo path MUST demonstrate a live `RateLimitPolicy` producing visible throttling (e.g. HTTP 429) under scripted load. Full OIDC/Keycloak Auth MUST NOT be on the critical path.

#### Scenario: Excess requests are rate-limited

- GIVEN a RateLimitPolicy is attached to the demo Gateway route for emojivoto
- WHEN scripted requests exceed the configured limit
- THEN subsequent responses MUST include HTTP 429 (or equivalent limit signal)
- AND the demo MUST complete without interactive IdP setup

### Requirement: CoreDNS DNS HA for N-S

The system MUST provide Kuadrant CoreDNS-based DNS/health so primary/secondary site roles support HA demonstration without cloud DNS.

#### Scenario: DNS answers from CoreDNS

- GIVEN CoreDNS with the Kuadrant DNS path is running for the demo
- WHEN an operator queries the demo hostname against the CoreDNS Service
- THEN a resolvable answer for the Gateway endpoint MUST be returned

### Requirement: AuthPolicy is optional bonus only

AuthPolicy MAY be demonstrated as a lightweight API-key / Authorino bonus if talk time remains. AuthPolicy MUST NOT block the 30-minute critical path. Full OIDC/Keycloak MUST NOT be required for success criteria.

#### Scenario: Critical path succeeds without AuthPolicy

- GIVEN AuthPolicy is not applied
- WHEN the operator runs the critical N-S demo (RateLimit + DNS path)
- THEN RateLimit and DNS HA steps MUST still succeed

### Requirement: No Kuadrant product UI on the talk path

N-S demo MUST stay CLI/HTTP (Gateway, RateLimit, CoreDNS failover). MUST NOT install Kuadrant Grafana, Envoy admin UI, Kiali, or Kubernetes Dashboard as talk surfaces. Docs MAY note metrics/CRDs-only.

#### Scenario: RateLimit stays HTTP without product UI

- GIVEN `make up` done
- WHEN demonstrating N-S RateLimit
- THEN throttling shown via HTTP (e.g. 429) / CLI
- AND no banned product UI required

#### Scenario: Failover stays DNS/HTTP without product UI

- GIVEN DNS HA configured
- WHEN failover scripts run
- THEN success verified via DNS/HTTP per failover-demo
- AND missing Kuadrant UI MUST NOT fail N-S criteria
