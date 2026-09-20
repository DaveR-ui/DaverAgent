#!/usr/bin/env bash
# run-tests.sh - master test runner for the agent tree.
#
# Runs, in order:
#   1. validate-agent.sh          - static integrity of the agent tree (CI-friendly)
#   2. test-output-schemas.py     - schema <-> fixture <-> doc-example contract tests
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

echo ""
if [ "${PASS}" -eq 1 ]; then
  echo "ALL TESTS PASS"
  exit 0
fi
echo "SOME TESTS FAILED" >&2
exit 1
