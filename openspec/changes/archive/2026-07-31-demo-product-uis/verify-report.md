```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:f179f6cb14702e6a33d1b9bed39f4bc35221e05471d8a27c1c149333387f45a9
verdict: pass_with_warnings
blockers: 0
critical_findings: 0
requirements: 9/9
scenarios: 16/16
test_command: make test-ui-foundation && make test-ui-linkerd && make test-ui-skupper
test_exit_code: 0
test_output_hash: sha256:cfc64c9e86048c7345e3025fc57833cd12ea27d045ec2cec1d089c444e6ec0f6
build_command: bash -n demo/scripts/ui-*.sh demo/scripts/test-ui-*.sh && make -n ui-app ui-app-check ui-linkerd ui-linkerd-check ui-skupper ui-skupper-check ui-down
build_exit_code: 0
build_output_hash: sha256:70431c561c33c94dc31e17ce8e4a45df0a3b517ba6d21f46d27915957b19e640
```

## Verification Report

**Change**: demo-product-uis
**Version**: N/A
**Mode**: Standard

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | 25 |
| Tasks complete | 25 |
| Tasks incomplete | 0 |

### Build & Tests Execution
**Build**: ✅ Passed
```text
bash -n on ui-*.sh + test-ui-*.sh (11 files OK); make -n ui-* dry-runs OK
exit 0
```

**Tests**: ✅ 97 passed / ❌ 0 failed / ⚠️ 0 skipped
```text
make test-ui-foundation → 32 passed, 0 failed (exit 0)
make test-ui-linkerd → 25 passed, 0 failed (exit 0)
make test-ui-skupper → 40 passed, 0 failed (exit 0)
combined offline 97/97
```

**Live checks** (clusters up; B/C restored after offline suite cleared them via ui-down):
```text
make ui-app-check → ACCESS_URL=http://emojivoto.demo.local:8080/ HTTP 200 (exit 0)
make ui-linkerd / ui-linkerd-check → ACCESS_URL=http://127.0.0.1:50750/ HTTP 200 (exit 0)
make ui-skupper / ui-skupper-check → prefer podman-edge blocked → SITE=kind-west; ACCESS_URL=https://127.0.0.1:8443/ + basic-auth once; HTTP 200 (exit 0)
CCM reserved ports 8080/8081/18080/45671/55671 still listening after UI restore
```

**Coverage**: ➖ Not available

### Spec Compliance Matrix
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Phase A app browser + validation | West URL printed and reachable | test-ui-foundation ACCESS_URL + live ui-app-check | ✅ COMPLIANT |
| Phase A app browser + validation | Bare IP without Host banned | test-ui-foundation lacks bare-IP ACCESS_URL | ✅ COMPLIANT |
| Phase B Viz opt-in + validation | Viz URL printed and reachable | test-ui-linkerd URL contract + live ui-linkerd-check | ✅ COMPLIANT |
| Phase B Viz opt-in + validation | Viz out of make up and CCM | suites: up has no ui-*; no CCM LB wiring | ✅ COMPLIANT |
| Phase C observer opt-in + validation | Observer URL and creds printed once | live ui-skupper auth once + ui-skupper-check; values lack password | ✅ COMPLIANT |
| Phase C observer opt-in + validation | podman-edge preferred, west fallback | live fallback log + SITE=kind-west; README asserts | ✅ COMPLIANT |
| Reserved ports and teardown | ui-down clears B and C | test-ui-skupper pidfile/uninstall/CCM RED | ✅ COMPLIANT |
| Reserved ports and teardown | UI validation never inside make up | all suites: Makefile up has no ui-* | ✅ COMPLIANT |
| Runbook documents browser Host access | Runbook lists hosts and app URL | test-ui-foundation README hosts + ACCESS_URL greps | ✅ COMPLIANT |
| Product UI stays off the critical path | Critical path succeeds without UI targets | up has no ui-* (all suites) + README critical-path | ✅ COMPLIANT |
| Optional Linkerd Viz on west only | West Viz does not change skip-inject | test-ui-linkerd skip-inject + skip-namespaces asserts | ✅ COMPLIANT |
| Optional Linkerd Viz on west only | East Viz not required | test-ui-linkerd refuses east | ✅ COMPLIANT |
| Optional network-observer for VAN | Observer opt-in with printed HTTPS | live ui-skupper/check HTTPS + auth | ✅ COMPLIANT |
| Optional network-observer for VAN | VAN works without observer | test-ui-skupper: demo-skupper/check-skupper/README no observer dep | ✅ COMPLIANT |
| No Kuadrant product UI on talk path | RateLimit stays HTTP without product UI | test-ui-foundation: README bans Grafana/Kiali; demo-ratelimit + 429 | ✅ COMPLIANT |
| No Kuadrant product UI on talk path | Failover stays DNS/HTTP without product UI | test-ui-foundation: make failover + dig/CoreDNS asserts | ✅ COMPLIANT |

**Compliance summary**: 16/16 scenarios compliant

### Correctness (Static Evidence)
| Requirement | Status | Notes |
|------------|--------|-------|
| Phase A | ✅ Implemented | hosts + ACCESS_URL + hostname probe (live 200) |
| Phase B | ✅ Implemented | west-only Viz edge-26.6.3; PF 50750 (live 200) |
| Phase C | ✅ Implemented | observer 2.2.1; west fallback; HTTPS PF 8443 (live 200) |
| Reserved ports / ui-down | ✅ Implemented | denylist + pidfiles + uninstall |
| Failover runbook | ✅ Implemented | README hosts/ACCESS_URL grepped in suite |
| Critical path | ✅ Implemented | ui-* not in up |
| East-west Viz | ✅ Implemented | east refuse + skip-inject/skip-namespaces asserted |
| Skupper observer | ✅ Implemented | HTTPS live OK; VAN-without-C asserted offline |
| No Kuadrant UI | ✅ Implemented | RateLimit/failover CLI path greps in suite |

### Coherence (Design)
| Decision | Followed? | Notes |
|----------|-----------|-------|
| UI separate from up | ✅ Yes | Makefile + suites |
| Hosts hostname app access | ✅ Yes | live 200 |
| West-only Viz PF 50750 | ✅ Yes | live 200 |
| Observer prefer podman-edge → west | ✅ Yes | live SITE=kind-west |
| HTTPS PF + auth in .run | ✅ Yes | live preferred :8443 |
| ui-down for B/C | ✅ Yes | offline RED |
| Never kind-cluster | ✅ Yes | allowlist refusal tests |

### Issues Found
**CRITICAL**: None
**WARNING**:
- Linkerd viz check reports proxies not up-to-date warning (‼) while overall status remains √
- Offline test-ui-skupper executes real ui-down against pidfiles and cleared live PF/auth during verify; B/C were restored afterward for live evidence
**SUGGESTION**:
- Isolate skupper suite ui-down RED to a temp RUN_DIR so offline tests do not disturb live PF

### Verdict
PASS WITH WARNINGS
16/16 scenarios COMPLIANT; offline 97/97 and live A/B/C HTTP 200. Non-blocking Viz proxy version warning and offline ui-down side-effect remain.
