# failover-demo Specification

## Purpose

Scripted CoreDNS/health failover and talk runbook paced for a **30-minute** talk: minimal live typing, explicit waits, RateLimit + DNS HA as primary wow.

## Requirements

### Requirement: Thirty-minute critical path

The critical live demo path MUST fit a 30-minute talk, covering N-S RateLimit, E-W meshed emojivoto, Skupper cross-site, and DNS/health failover. The path MUST prefer scripted commands and waits over live typing. AuthPolicy MAY appear only as a time-boxed bonus after the critical path.

#### Scenario: Critical path is scripted

- GIVEN the demo stack is already up before or at talk start
- WHEN the speaker runs the documented critical-path scripts
- THEN RateLimit, meshed E-W, Skupper, and failover MUST be demonstrable without manual YAML editing
- AND optional AuthPolicy MUST NOT be required to declare the demo successful

### Requirement: Scripted DNS/health failover with waits

The system MUST provide a failover script (or Make target) that triggers primary/secondary DNS or health failover, waits for reconcile, and verifies traffic or DNS answers move to the healthy site. The script MUST account for non-instant CoreDNS/group reconcile lag.

#### Scenario: Kill primary, observe failover

- GIVEN DNS HA is configured with primary and secondary roles across Kind sites
- WHEN the failover script disables or makes the primary unhealthy
- THEN after the scripted wait the demo hostname MUST resolve or route to the healthy secondary
- AND the script MUST exit non-zero if failover does not complete within the documented timeout

#### Scenario: Failover lag is handled

- GIVEN CoreDNS/group failover is reconcile-driven
- WHEN the failover script runs
- THEN it MUST wait/probe rather than assume instant cutover
- AND the runbook MUST state expected wait bounds for the speaker

### Requirement: Runbook documents talk flow and rollback

A runbook MUST document prerequisites, topology (`kind-west`, `kind-east`, `podman-edge`), critical-path order, scripted waits, optional Auth bonus, and rollback via `make down` leaving `kind-cluster` untouched.

#### Scenario: Operator recovers with documented rollback

- GIVEN the demo environment is partially broken mid-talk
- WHEN the operator follows the runbook rollback
- THEN `make down` MUST clean demo-only resources
- AND `kind-cluster` MUST remain untouched
