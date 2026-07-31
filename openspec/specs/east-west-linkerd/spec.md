# east-west-linkerd Specification

## Purpose

Linkerd service mesh on both Kind sites for in-cluster east-west traffic over the emojivoto multi-service voting app.

## Requirements

### Requirement: Linkerd on both Kind sites

`kind-west` and `kind-east` MUST each run a healthy Linkerd control plane after `make up`. Istio MUST NOT be required on the critical path (fallback only if EG+Kuadrant+Linkerd proves incompatible — out of default scope).

#### Scenario: Linkerd ready on west and east

- GIVEN `make up` completed successfully
- WHEN an operator checks Linkerd health on `kind-west` and `kind-east`
- THEN both control planes MUST report ready
- AND mesh proxies MUST be injectable for demo namespaces

### Requirement: Emojivoto is the demo application

The demo application MUST be emojivoto (official Linkerd sample multi-service voting app). Emojivoto services used in the E-W story MUST run in the mesh on Kind sites.

#### Scenario: Meshed emojivoto serves votes path

- GIVEN emojivoto is deployed and meshed on a Kind site
- WHEN a request traverses emoji / voting / web services in-cluster
- THEN traffic MUST flow between meshed services
- AND Linkerd MUST be able to show live E-W connectivity for the talk

### Requirement: Gateway and mesh coexistence

Envoy Gateway (and Kuadrant control-plane pods as needed) MUST coexist with Linkerd without breaking N-S or E-W critical paths (correct inject/skip behavior).

#### Scenario: N-S and E-W both work after full up

- GIVEN EG, Kuadrant, Linkerd, and emojivoto are installed
- WHEN the operator exercises Gateway ingress and an in-cluster meshed call
- THEN both paths MUST succeed
- AND Gateway pods MUST NOT be broken by incorrect mesh injection
