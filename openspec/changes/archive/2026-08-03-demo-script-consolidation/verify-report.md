```yaml
schema: gentle-ai.verify-result/v1
evidence_revision: sha256:9010ad710bb97ced55ae109367dc16c0b108a9333cb85a9d584b1d74256db55d
verdict: pass_with_warnings
blockers: 0
critical_findings: 0
requirements: 7/7
scenarios: 16/16
test_command: make test-allowlist && make test-ui-foundation && make test-ui-linkerd && make test-ui-skupper
test_exit_code: 0
test_output_hash: sha256:9dceb7ca427a5a51090e05fc7fe3f7f90e7222fa4297fe675446f0feda405b2e
build_command: make help && make -n ui && make -n ui-down && bash -n demo/scripts/ui.sh demo/scripts/ui/_phase_a.sh demo/scripts/ui/_phase_b.sh demo/scripts/ui/_phase_c.sh demo/scripts/ui-down.sh demo/scripts/ui-common.sh
build_exit_code: 0
build_output_hash: sha256:e075c53d1aa9c8c47f129d299000da8f9cb0b619128886a6075ebca6f0e6f0d9
```

## Verification Report

**Change**: demo-script-consolidation
**Version**: N/A (delta change; promoted specs present)
**Mode**: Standard
**Branch tip**: `demo-script-consolidation-pr3-readme` @ `b004371`
**Persistence**: hybrid

### Completeness
| Metric | Value |
|--------|-------|
| Tasks total | 16 |
| Tasks complete | 16 |
| Tasks incomplete | 0 |

### Build & Tests Execution
**Build**: ✅ Passed
```text
make help && make -n ui && make -n ui-down && bash -n …ui*.sh
exit 0
hash sha256:e075c53d1aa9c8c47f129d299000da8f9cb0b619128886a6075ebca6f0e6f0d9
help lists ui/ui-down; omits ui-app*/ui-linkerd*/ui-skupper*/talk-up
bash -n: OK
```

**Tests**: ✅ 124 passed / ❌ 0 failed / ⚠️ 0 skipped (offline canonical)
```text
make test-allowlist && make test-ui-foundation && make test-ui-linkerd && make test-ui-skupper
exit 0
hash sha256:9dceb7ca427a5a51090e05fc7fe3f7f90e7222fa4297fe675446f0feda405b2e
Allowlist: 5/5
UI foundation: 50/50
UI linkerd: 27/27
UI skupper: 42/42
```

**Live harness** (Kind stack already up; exercised):
```text
make smoke → exit 0 (Gateway 200, RateLimit 429, Linkerd, Skupper VAN, CoreDNS)
make ui → exit 0
  Phase A ACCESS_URL=http://emojivoto.demo.local:8080/ (probe 200)
  Phase B ACCESS_URL=http://127.0.0.1:50750/ (probe 200)
  Phase C ACCESS_URL=https://127.0.0.1:8443/ + BASIC_AUTH once (probe 200)
  Phase C preferred podman-edge then fell back to kind-west (observed)
make ui-down → exit 0 (Viz PF stopped + uninstall; observer helm uninstall; CCM 8080/8081 untouched; A still 200)
```

**Coverage**: ➖ Not available (shell Make suites; no coverage threshold)

### Spec Compliance Matrix
| Requirement | Scenario | Test | Result |
|-------------|----------|------|--------|
| Public Make UI entry and fail-fast | make ui runs A then B then C | `test-ui-foundation` A→B→C + live `make ui` | ✅ COMPLIANT |
| Public Make UI entry and fail-fast | Mid-ui fail-fast | `test-ui-foundation` fail-fast B skips C | ✅ COMPLIANT |
| Public Make UI entry and fail-fast | Hard cut of old UI Make names | `test-ui-foundation` hard-cut + `make -n` | ✅ COMPLIANT |
| Public Make help versus lib internals | Help lists ui not per-phase | `test-ui-foundation` help asserts + `make help` | ✅ COMPLIANT |
| Public Make help versus lib internals | Internals under lib | `test-ui-foundation` lib/common.sh + tree | ✅ COMPLIANT |
| Public Make help versus lib internals | Offline UI suites without Kind | three `test-ui-*` exit 0 | ✅ COMPLIANT |
| Phase A app browser access | West URL printed and reachable | live Phase A ACCESS_URL + HTTP 200 | ✅ COMPLIANT |
| Phase A app browser access | Bare IP without Host banned | `test-ui-foundation` bare-IP ban + README | ✅ COMPLIANT |
| Phase B Linkerd Viz | Viz URL printed and reachable | live Phase B ACCESS_URL + HTTP 200 | ✅ COMPLIANT |
| Phase B Linkerd Viz | Viz out of make up and CCM | `test-ui-linkerd` up.sh/CCM asserts | ✅ COMPLIANT |
| Phase C Skupper observer | Observer URL and creds printed once | live Phase C HTTPS + basic-auth once | ✅ COMPLIANT |
| Phase C Skupper observer | podman-edge preferred, west fallback | live prefer→fallback log | ✅ COMPLIANT |
| Reserved ports and teardown | ui-down clears B and C | live `make ui-down` + offline ui-down asserts | ✅ COMPLIANT |
| Reserved ports and teardown | UI validation never inside make up | `test-ui-*` Makefile up no ui deps | ✅ COMPLIANT |
| Optional network-observer (skupper-van) | Observer opt-in with printed HTTPS access | live Phase C HTTPS PF (no CCM LB) | ✅ COMPLIANT |
| Optional network-observer (skupper-van) | VAN works without observer | `test-ui-skupper` + live `make smoke` VAN | ✅ COMPLIANT |

**Compliance summary**: 16/16 scenarios compliant

### Correctness (Static Evidence)
| Requirement | Status | Notes |
|------------|--------|-------|
| Public `make ui` only | ✅ Implemented | `Makefile` → `demo/scripts/ui.sh`; A→B→C fail-fast |
| No talk-up | ✅ Implemented | target gone; help omits |
| Internals under `demo/scripts/lib/` | ✅ Implemented | common/CCM/SAN/redeem present; callers retargeted |
| Hard cut old UI names | ✅ Implemented | Make targets + scripts removed |
| `make up` UI-free | ✅ Implemented | no ui deps; up.sh has no UI refs |
| Offline suites green | ✅ Implemented | allowlist + three test-ui-* |
| Specs promoted | ✅ Implemented | `openspec/specs/talk-ui-surface`, `skupper-van` |

### Coherence (Design)
| Decision | Followed? | Notes |
|----------|-----------|-------|
| One public `make ui` | ✅ Yes | help + Makefile |
| `up` then optional `ui` | ✅ Yes | README + live path |
| `ui.sh` dispatcher + `_phase_*` | ✅ Yes | `demo/scripts/ui/_phase_{a,b,c}.sh` |
| Fail-fast mid-ui | ✅ Yes | offline + set -e |
| Internals in `lib/` | ✅ Yes | |
| Hard cut, no aliases | ✅ Yes | |
| Keep three offline suites | ✅ Yes | |
| Single prereq gate | ✅ Yes | `prereq-check` still listed; up calls it |

### Issues Found
**CRITICAL**: None

**WARNING (resolved before archive)**:
- Live `make ui-down` initially reported `no pidfile (ui-skupper-observer)` with a brief orphan on `:8443`. Fixed by `demo_ui_record_pf` (pid+port + `disown`) and `demo_ui_stop_pf` port fallback in `ui-common.sh`. Re-verified live: Phase C writes `ui-skupper-observer.pid`/`.port`; `ui-down` stops PF by pid; no leftover `:8443` listener. Offline `test-ui-skupper` 46/46.

**SUGGESTION**:
- Linkerd CLI/control-plane “not latest edge” warnings (`26.6.3` vs `26.7.2`) during smoke/ui are pin-noise only; keep pin per VERSIONS.md unless intentionally bumping.

### Verdict
PASS WITH WARNINGS
16/16 scenarios compliant; offline suites green; live `make ui`/`ui-down` exercised on existing Kind stack with three ACCESS_URLs; leftover gap is observer PF pidfile hygiene on teardown.
