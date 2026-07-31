# Delta for north-south-kuadrant

## ADDED Requirements

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
