#!/usr/bin/env bash
# test-validate-agent.sh - runs the agent tree validator and asserts it passes.
# Exit 0 on PASS, 1 on FAIL. Warnings are allowed; errors fail the test.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"${ROOT}/scripts/validate-agent.sh"
status=$?

if [ ${status} -eq 0 ]; then
  echo "test-validate-agent: PASS"
  exit 0
fi
echo "test-validate-agent: FAIL (validator exited ${status})" >&2
exit 1
