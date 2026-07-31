# Delta for east-west-linkerd

## ADDED Requirements

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
