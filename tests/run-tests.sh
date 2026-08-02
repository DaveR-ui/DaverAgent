#!/usr/bin/env bash
# run-tests.sh - master test runner for the agent tree.
#
# Runs, in order:
#   1. validate-agent.sh          - static integrity of the agent tree (CI-friendly)
#   2. test-output-schemas.py     - schema <-> fixture <-> doc-example contract tests
#   3. plugin typecheck           - tsc --noEmit on plugins/prompt-fetcher
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

if command -v bun >/dev/null 2>&1; then
  run "plugin typecheck" bash -c "cd '${ROOT}/plugins/prompt-fetcher' && bun run typecheck"
else
  echo ""
  echo "  [skip] plugin typecheck (bun not installed)"
fi

echo ""
if [ "${PASS}" -eq 1 ]; then
  echo "ALL TESTS PASS"
  exit 0
fi
echo "SOME TESTS FAILED" >&2
exit 1
