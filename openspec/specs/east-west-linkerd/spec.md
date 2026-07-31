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

### Requirement: Optional Linkerd Viz on west only

MAY install Viz on **kind-west only**, aligned with **edge-26.6.3**, via opt-in UI helpers. Skip-inject (`envoy-gateway-system`, `kuadrant-system`, `kuadrant-coredns`, `gateway-system`, `skupper`) MUST stay unchanged. Viz MUST NOT be required for E-W success. East Viz MUST NOT be required.

#### Scenario: West Viz does not change skip-inject

- GIVEN Linkerd healthy on both Kind sites after `up`
- WHEN Viz optionally enabled on kind-west
- THEN skip-inject unchanged
- AND meshed emojivoto E-W still succeeds

#### Scenario: East Viz not required

- GIVEN Phase B helpers available
- WHEN Viz enabled for the talk
- THEN install targets kind-west only by default
- AND no east Viz MUST NOT fail mesh criteria
