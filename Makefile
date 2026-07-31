# Multicluster connectivity demo — lifecycle + N-S + E-W + Skupper + failover (PR1–PR5).
# Allowlist: kind-west, kind-east, podman-edge. Never kind-cluster.
# LoadBalancer: cloud-provider-kind (NOT MetalLB) — see demo/VERSIONS.md.
# Talk UI (opt-in): ui-app / ui-linkerd / ui-skupper — NEVER dependencies of up.

ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SCRIPTS := $(ROOT)/demo/scripts

.PHONY: help up down test-allowlist test-ui-foundation test-ui-linkerd prereq-check \
	smoke failover \
	demo-ratelimit demo-mesh demo-skupper demo-smoke demo-failover \
	ui-app ui-app-check ui-linkerd ui-linkerd-check \
	ui-skupper ui-skupper-check ui-down

help:
	@printf '%s\n' \
	  'Targets:' \
	  '  make up             Bring up demo sites + EG/Kuadrant + Linkerd + Skupper + apps' \
	  '  make down           Tear down demo sites only (never kind-cluster); stop demo-owned CCM' \
	  '  make prereq-check   Fail-fast host prerequisite gate (incl. cloud-provider-kind)' \
	  '  make test-allowlist Allowlist refusal suite' \
	  '  make test-ui-foundation  UI foundation + Phase A contract suite (offline)' \
	  '  make test-ui-linkerd     UI Phase B Viz contract suite (offline)' \
	  '  make smoke          End-to-end smoke (200/429, mesh, Skupper, dig) — offline if no Kind' \
	  '  make failover       Hurt west primary; wait CoreDNS→east; timeout≠0' \
	  '  make demo-ratelimit Burst Gateway traffic; expect HTTP 429 (N-S wow)' \
	  '  make demo-mesh      Linkerd/emojivoto check (live or offline manifests)' \
	  '  make demo-skupper   Skupper/legacy-emoji check (live or offline manifests)' \
	  '  make demo-smoke     Alias of make smoke' \
	  '  make demo-failover  Alias of make failover' \
	  '  make ui-app         Phase A: hosts hint + ACCESS_URL (opt-in; not part of up)' \
	  '  make ui-app-check   Phase A: hostname curl 200/429 + print ACCESS_URL' \
	  '  make ui-linkerd     Phase B: Linkerd Viz west-only (PF prefer :50750)' \
	  '  make ui-linkerd-check  Phase B: viz check + HTTP; print ACCESS_URL' \
	  '  make ui-skupper     Phase C stub: Skupper observer (PR3)' \
	  '  make ui-skupper-check  Phase C stub check (PR3)' \
	  '  make ui-down        Tear down B/C UI only (A=docs reminder)' \
	  'Optional: CLUSTER=<allowlisted-name> scopes up/down/demo-ratelimit/ui-*'

up:
	@$(SCRIPTS)/up.sh

down:
	@$(SCRIPTS)/down.sh

prereq-check:
	@$(SCRIPTS)/prereq-check.sh

test-allowlist:
	@$(SCRIPTS)/test-allowlist.sh

test-ui-foundation:
	@$(SCRIPTS)/test-ui-foundation.sh

test-ui-linkerd:
	@$(SCRIPTS)/test-ui-linkerd.sh

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

# --- Opt-in talk UI (never deps of up) ---
ui-app:
	@$(SCRIPTS)/ui-app.sh

ui-app-check:
	@$(SCRIPTS)/ui-app-check.sh

ui-linkerd:
	@$(SCRIPTS)/ui-linkerd.sh

ui-linkerd-check:
	@$(SCRIPTS)/ui-linkerd-check.sh

ui-skupper:
	@$(SCRIPTS)/ui-skupper.sh

ui-skupper-check:
	@$(SCRIPTS)/ui-skupper-check.sh

ui-down:
	@$(SCRIPTS)/ui-down.sh
