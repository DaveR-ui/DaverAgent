#!/usr/bin/env python3
"""Machine-checked divergence register for the derived docs validator.

Loads templates/docs-conformance.json, validates it against
templates/docs-conformance.schema.json using the dependency-free
tests/schema_check.py validator, requires a NON-EMPTY `entries` array whose ids
are unique, then runs every entry's `test` command from the repository root.
Each entry is reported PASS/FAIL; the process exits non-zero if any entry
fails. Validation failures fail the run loudly (they are never skipped).

Run:  python3 tests/test-conformance-register.py
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from schema_check import validate  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
REGISTER = ROOT / "templates" / "docs-conformance.json"
SCHEMA = ROOT / "templates" / "docs-conformance.schema.json"


def main() -> int:
    try:
        register = json.loads(REGISTER.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"FAIL: cannot load {REGISTER.relative_to(ROOT)}: {exc}")
        return 1

    try:
        schema = json.loads(SCHEMA.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"FAIL: cannot load {SCHEMA.relative_to(ROOT)}: {exc}")
        return 1

    failures = 0

    schema_errors = validate(register, schema)
    if schema_errors:
        for error in schema_errors:
            print(f"  [FAIL] register does not validate: {error}")
        failures += 1
    else:
        print(f"  [ok] {REGISTER.relative_to(ROOT)} validates against the schema")

    entries = register.get("entries") if isinstance(register, dict) else None
    if not isinstance(entries, list) or not entries:
        print("  [FAIL] register has no entries")
        failures += 1
        print()
        print(f"FAIL: {failures} failure(s)")
        return 1

    print(f"  [ok] register is non-empty ({len(entries)} entries)")

    # Unique ids: a duplicated divergence id makes the register ambiguous.
    seen_ids: set[str] = set()
    for entry in entries:
        entry_id = entry.get("id") if isinstance(entry, dict) else None
        if not isinstance(entry_id, str) or not entry_id:
            print("  [FAIL] an entry has no usable 'id'")
            failures += 1
            continue
        if entry_id in seen_ids:
            print(f"  [FAIL] duplicate entry id '{entry_id}'")
            failures += 1
            continue
        seen_ids.add(entry_id)

    for entry in entries:
        if not isinstance(entry, dict):
            continue
        entry_id = entry.get("id", "<missing-id>")
        test = entry.get("test")
        if not isinstance(test, str) or not test.strip():
            print(f"  [FAIL] {entry_id}: missing 'test' command")
            failures += 1
            continue
        completed = subprocess.run(test, shell=True, cwd=ROOT)
        if completed.returncode == 0:
            print(f"  [ok] {entry_id}")
        else:
            print(f"  [FAIL] {entry_id} (exit {completed.returncode}): {test}")
            failures += 1

    print()
    if failures:
        print(f"FAIL: {failures} failure(s)")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
