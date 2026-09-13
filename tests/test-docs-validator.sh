#!/usr/bin/env bash
# test-docs-validator.sh - behavioral tests for the derived docs validator
# (templates/docs-validate.js) plus a static drift guard on the PowerShell
# scaffolder. Node is required for the behavioral part; if node is absent the
# behavioral tests SKIP (exit 0) and only the static guard runs.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="${ROOT}/templates/docs-validate.js"
FIX="${ROOT}/tests/fixtures/docs-corpus"
FAIL=0

echo "== static drift guard: scaffolder emits the canonical structure =="
for s in \
  "| Slice | Description | Keywords | Entry points | Primary agents |" \
  "repository_structure" \
  "context-index.md" \
  "Build-TagIndex" \
  "BEGIN GENERATED: tags" \
  "Build-Index" \
  "BEGIN GENERATED: index"; do
  if grep -qF -- "$s" "${ROOT}/scripts/install-agent.ps1"; then
    echo "  [ok] install-agent.ps1 contains: $s"
  else
    echo "  [FAIL] install-agent.ps1 missing: $s"
    FAIL=1
  fi
done

# Negative guard: the parity fix replaced the hand-rolled tag-index heading
# with the validator's generated region, so the obsolete literal must be gone.
if grep -qF -- "## Generated tag index" "${ROOT}/scripts/install-agent.ps1"; then
  echo "  [FAIL] install-agent.ps1 still contains obsolete literal: ## Generated tag index"
  FAIL=1
else
  echo "  [ok] install-agent.ps1 omits obsolete literal: ## Generated tag index"
fi

if ! command -v node >/dev/null 2>&1; then
  echo ""
  echo "SKIP: node not found - behavioral docs-validator tests skipped"
  exit "$FAIL"
fi

echo ""
echo "== valid corpus passes (exit 0) =="
if node "$VALIDATOR" --root "$FIX/valid" >/tmp/docs-valid.out 2>&1; then
  echo "  [ok] exit 0"
else
  echo "  [FAIL] expected exit 0"
  sed 's/^/    /' /tmp/docs-valid.out
  FAIL=1
fi

echo ""
echo "== invalid corpus fails (exit 1) and reports the expected checks =="
if node "$VALIDATOR" --root "$FIX/invalid" >/tmp/docs-invalid.out 2>&1; then
  echo "  [FAIL] expected exit 1"
  FAIL=1
else
  echo "  [ok] exit 1"
fi
for check in metadata-outside-contract non-kebab-case-name dangling-link duplicate-ids secret-in-prose stale-generated-index dangling-related-target missing-from-entry orphan-note no-h1; do
  if grep -q "$check" /tmp/docs-invalid.out; then
    echo "  [ok] reported $check"
  else
    echo "  [FAIL] missing $check"
    FAIL=1
  fi
done

echo ""
echo "== --write regenerates the tags region, write-if-diff =="
WRITE_DIR="$(mktemp -d)"
cp -r "$FIX/valid/." "$WRITE_DIR/"
node "$VALIDATOR" --root "$WRITE_DIR" --write >/dev/null 2>&1
if grep -q "## architecture" "$WRITE_DIR/tag-index.md"; then
  echo "  [ok] tags region regenerated"
else
  echo "  [FAIL] tags region not regenerated"
  FAIL=1
fi
before="$(cat "$WRITE_DIR/tag-index.md")"
node "$VALIDATOR" --root "$WRITE_DIR" --write >/dev/null 2>&1
after="$(cat "$WRITE_DIR/tag-index.md")"
if [ "$before" = "$after" ]; then
  echo "  [ok] second --write is a no-op (write-if-diff)"
else
  echo "  [FAIL] --write is not idempotent"
  FAIL=1
fi
rm -rf "$WRITE_DIR"

echo ""
echo "== --write regenerates the index region, write-if-diff =="
WRITE_DIR="$(mktemp -d)"
cp -r "$FIX/valid/." "$WRITE_DIR/"
node "$VALIDATOR" --root "$WRITE_DIR" --write >/dev/null 2>&1
if grep -q "### Tree" "$WRITE_DIR/index.md"; then
  echo "  [ok] index region regenerated"
else
  echo "  [FAIL] index region not regenerated"
  FAIL=1
fi
before="$(cat "$WRITE_DIR/index.md")"
node "$VALIDATOR" --root "$WRITE_DIR" --write >/dev/null 2>&1
after="$(cat "$WRITE_DIR/index.md")"
if [ "$before" = "$after" ]; then
  echo "  [ok] second --write is a no-op (write-if-diff)"
else
  echo "  [FAIL] --write is not idempotent"
  FAIL=1
fi
rm -rf "$WRITE_DIR"

if [ "$FAIL" -eq 0 ]; then
  echo ""
  echo "docs-validator: PASS"
  exit 0
fi
echo ""
echo "docs-validator: FAIL" >&2
exit 1
