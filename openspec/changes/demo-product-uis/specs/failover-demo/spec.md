# Delta for failover-demo

## ADDED Requirements

### Requirement: Runbook documents browser Host access

Runbook MUST document `/etc/hosts` for `emojivoto.demo.local` → `127.0.0.1` and Phase A URLs (`http://emojivoto.demo.local:8080/`, optional east `:8081/`). Graphical UI MUST stay outside critical-path success.

#### Scenario: Runbook lists hosts and app URL

- GIVEN operator opens talk runbook
- WHEN following app-access guidance
- THEN runbook shows hosts mapping and Phase A URL(s)
- AND MUST NOT require Viz/observer for critical-path success

### Requirement: Product UI stays off the critical path

Optional UI (app helpers, Viz, observer) MUST NOT block the 30-minute critical path. Success remains RateLimit, meshed E-W, Skupper, failover without UI targets.

#### Scenario: Critical path succeeds without UI targets

- GIVEN `make up` done; UI targets not run
- WHEN critical-path scripts run
- THEN RateLimit, mesh, Skupper, failover are demonstrable
- AND missing Viz/observer MUST NOT fail the talk path
