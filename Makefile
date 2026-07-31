# Multicluster connectivity demo — lifecycle + N-S + E-W + Skupper + failover (PR1–PR5).
# Allowlist: kind-west, kind-east, podman-edge. Never kind-cluster.
# LoadBalancer: cloud-provider-kind (NOT MetalLB) — see demo/VERSIONS.md.

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(ROOT)/demo/scripts

.PHONY: help up down test-allowlist prereq-check \
	smoke failover \
	demo-ratelimit demo-mesh demo-skupper demo-smoke demo-failover

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  make up             Bring up demo sites + EG/Kuadrant + Linkerd + Skupper + apps' \
	  '  make down           Tear down demo sites only (never kind-cluster); stop demo-owned CCM' \
	  '  make prereq-check   Fail-fast host prerequisite gate (incl. cloud-provider-kind)' \
	  '  make test-allowlist Allowlist refusal suite' \
	  '  make smoke          End-to-end smoke (200/429, mesh, Skupper, dig) — offline if no Kind' \
	  '  make failover       Hurt west primary; wait CoreDNS→east; timeout≠0' \
	  '  make demo-ratelimit Burst Gateway traffic; expect HTTP 429 (N-S wow)' \
	  '  make demo-mesh      Linkerd/emojivoto check (live or offline manifests)' \
	  '  make demo-skupper   Skupper/legacy-emoji check (live or offline manifests)' \
	  '  make demo-smoke     Alias of make smoke' \
	  '  make demo-failover  Alias of make failover' \
	  'Optional: CLUSTER=<allowlisted-name> scopes up/down/demo-ratelimit'

up:
	@$(SCRIPTS)/up.sh

down:
	@$(SCRIPTS)/down.sh

prereq-check:
	@$(SCRIPTS)/prereq-check.sh

test-allowlist:
	@$(SCRIPTS)/test-allowlist.sh

smoke demo-smoke:
	@$(SCRIPTS)/smoke.sh

failover demo-failover:
	@$(SCRIPTS)/failover.sh

demo-ratelimit:
	@$(SCRIPTS)/demo-ratelimit.sh

demo-mesh:
	@$(SCRIPTS)/check-east-west.sh

demo-skupper:
	@$(SCRIPTS)/check-skupper.sh
