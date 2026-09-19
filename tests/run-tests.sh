#!/usr/bin/env bash
# run-tests.sh - master test runner for the agent tree.
#
# Runs, in order:
#   1. validate-agent.sh          - static integrity of the agent tree (CI-friendly)
#   2. test-output-schemas.py     - schema <-> fixture <-> doc-example contract tests
#   3. test-docs-validator.sh     - derived docs validator + static shape drift guard
#   4. test-conformance-register.py - machine-checked docs divergence register
#   5. test-agent-hardening.py    - permission matrix + corrected runtime claims
#   6. test-session-tool.py       - session plugin tool + slash command wiring
#   7. test-steer-inbox.py        - steering inbox plugin + wiring
#   8. test-session-export.py     - session export plugin + wiring
#
# Exit 0 = all pass, 1 = any failure.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PASS=1

run() {
  local name="$1"; shift
  echo ""
  echo "==================== $name ===================="
  if "$@"; then
    echo "  $name: PASS"
  else
    echo "  $name: FAIL" >&2
    PASS=0
  fi
}

run "validate-agent.sh"    bash "${ROOT}/scripts/validate-agent.sh"
run "output-schemas"       python3 "${ROOT}/tests/test-output-schemas.py"
run "docs-validator"       bash "${ROOT}/tests/test-docs-validator.sh"
run "conformance-register" python3 "${ROOT}/tests/test-conformance-register.py"
run "agent-hardening"      python3 "${ROOT}/tests/test-agent-hardening.py"
run "session-tool"         python3 "${ROOT}/tests/test-session-tool.py"
run "steer-inbox"        python3 "${ROOT}/tests/test-steer-inbox.py"
run "session-export"     python3 "${ROOT}/tests/test-session-export.py"

echo ""
if [ "${PASS}" -eq 1 ]; then
  echo "ALL TESTS PASS"
  exit 0
fi
echo "SOME TESTS FAILED" >&2
exit 1
