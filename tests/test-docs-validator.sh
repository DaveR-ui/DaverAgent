#!/usr/bin/env bash
# test-docs-validator.sh - behavioral tests for the derived docs validator
# (templates/docs-validate.js) plus a static drift guard on the canonical docs
# shape. The former PowerShell scaffolder is retired, so each canonical string
# is now asserted against the live artifact that genuinely owns it. Node is
# required for the behavioral part; if node is absent the behavioral tests SKIP
# (exit 0) and only the static guard runs.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VALIDATOR="${ROOT}/templates/docs-validate.js"
FIX="${ROOT}/tests/fixtures/docs-corpus"
FAIL=0

echo "== static drift guard: canonical docs shape survives in the live artifacts =="
# The retired generator's internal identifiers (Build-TagIndex, Build-Index,
# repository_structure) have no surviving home and were dropped rather than
# asserted vacuously. The two index builders survive in the validator as
# renderIndexRegion / renderTagsRegion.
guard() { # <file> <literal>
  if grep -qF -- "$2" "$1"; then
    echo "  [ok] $(basename "$1") contains: $2"
  else
    echo "  [FAIL] $(basename "$1") missing: $2"
    FAIL=1
  fi
}

# The installer protocol was retired 2026-09-18; `documenter` now owns the
# canonical docs shape and names the context hub.
guard "${ROOT}/agents/documenter.md" "context-index.md"
# The validator owns both generated regions (index + tags) and their markers.
guard "${VALIDATOR}" "renderIndexRegion"
guard "${VALIDATOR}" "renderTagsRegion"
guard "${VALIDATOR}" "BEGIN GENERATED:"
# The valid corpus carries the literal canonical shapes.
guard "${ROOT}/tests/fixtures/docs-corpus/valid/project.md" "| Slice | Description | Keywords | Entry points | Primary agents |"
guard "${ROOT}/tests/fixtures/docs-corpus/valid/tag-index.md" "BEGIN GENERATED: tags"
guard "${ROOT}/tests/fixtures/docs-corpus/valid/index.md" "BEGIN GENERATED: index"

# Negative guard: the obsolete hand-rolled tag-index heading must not return.
# The validator emits "## Generated index"; the old "## Generated tag index"
# literal is gone (the validator is the live owner of the generated heading).
if grep -qF -- "## Generated tag index" "${VALIDATOR}"; then
  echo "  [FAIL] docs-validate.js still contains obsolete literal: ## Generated tag index"
  FAIL=1
else
  echo "  [ok] docs-validate.js omits obsolete literal: ## Generated tag index"
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
