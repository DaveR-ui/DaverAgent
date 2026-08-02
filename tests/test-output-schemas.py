#!/usr/bin/env python3
"""Behavioral contract tests for the agent output schemas.

Four kinds of assertions:

1. Every fixture in tests/fixtures/outputs/<name>.json must VALIDATE against
   agents/subagents/<name>.json (the happy path).
2. Every fixture in tests/fixtures/outputs/invalid/<name>.json must FAIL
   validation (proves strict rejection actually works — catches schemas that
   were accidentally weakened).
3. Every golden routing packet in tests/fixtures/prompts/*.json must VALIDATE
   against agents/subagents/interpreter.schema.json (pins the Step 0 contract,
   including both the skip-question default and the clarification path).
4. Every JSON code block inside agents/subagents/*.md that parses must VALIDATE
   against the agent's declared output_schema (keeps the documented examples in
   sync with the schemas — the bridge contract from subagent-spec-template.md).

Exit code 0 = pass, 1 = any failure. Dependency-free (stdlib only).

Run:  python3 tests/test-output-schemas.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from schema_check import validate  # noqa: E402

ROOT = Path(__file__).resolve().parent.parent
AGENTS_DIR = ROOT / "agents" / "subagents"
FIXTURES_DIR = ROOT / "tests" / "fixtures" / "outputs"
PROMPTS_DIR = ROOT / "tests" / "fixtures" / "prompts"

failures: list[str] = []


def check(ok: bool, message: str) -> None:
    status = "ok" if ok else "FAIL"
    print(f"  [{status}] {message}")
    if not ok:
        failures.append(message)


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        check(False, f"{path.relative_to(ROOT)} is not valid JSON: {exc}")
        return None


def frontmatter_output_schema(md_path: Path) -> str | None:
    """Return the output_schema path from the frontmatter of an agent .md."""
    text = md_path.read_text(encoding="utf-8")
    match = re.search(r"^---\n(.*?)\n---", text, re.MULTILINE | re.DOTALL)
    if not match:
        return None
    for line in match.group(1).splitlines():
        if line.startswith("output_schema:"):
            return line.split(":", 1)[1].strip()
    return None


print("== [1/4] valid output fixtures validate ==")
schema_files = sorted(AGENTS_DIR.glob("*.schema.json"))
for schema_path in schema_files:
    schema = load_json(schema_path)
    if schema is None:
        continue
    fixture = FIXTURES_DIR / schema_path.name
    if not fixture.exists():
        check(False, f"no valid fixture for {schema_path.name} (expected {fixture.name})")
        continue
    data = load_json(fixture)
    if data is None:
        continue
    errors = validate(data, schema)
    check(not errors, f"{fixture.name} validates" + (f" [{'; '.join(errors)}]" if errors else ""))

print("== [2/4] invalid fixtures are rejected ==")
invalid_dir = FIXTURES_DIR / "invalid"
for schema_path in schema_files:
    schema = load_json(schema_path)
    if schema is None:
        continue
    fixture = invalid_dir / schema_path.name
    if not fixture.exists():
        check(False, f"no invalid fixture for {schema_path.name} (expected {fixture.name})")
        continue
    data = load_json(fixture)
    if data is None:
        continue
    errors = validate(data, schema)
    check(bool(errors), f"{fixture.name} rejected" + ("" if errors else " (VALIDATED — schema too weak)"))

print("== [3/4] golden routing packets validate against interpreter schema ==")
interp_schema = load_json(AGENTS_DIR / "interpreter.schema.json")
for packet_path in sorted(PROMPTS_DIR.glob("*.json")):
    wrapper = load_json(packet_path)
    if wrapper is None:
        continue
    if "packet" not in wrapper:
        check(False, f"{packet_path.name} missing 'packet' wrapper field")
        continue
    errors = validate(wrapper["packet"], interp_schema)
    check(not errors, f"{packet_path.name} packet validates" + (f" [{'; '.join(errors)}]" if errors else ""))

print("== [4/4] documented JSON examples match their schema ==")
for md_path in sorted(AGENTS_DIR.glob("*.md")):
    schema_ref = frontmatter_output_schema(md_path)
    if schema_ref is None:
        continue
    schema_path = (md_path.parent / schema_ref).resolve()
    if not schema_path.exists():
        check(False, f"{md_path.name} declares output_schema {schema_ref} but it does not exist")
        continue
    schema = load_json(schema_path)
    if schema is None:
        continue
    text = md_path.read_text(encoding="utf-8")
    blocks = re.findall(r"```json\n(.*?)```", text, re.DOTALL)
    for index, block in enumerate(blocks):
        try:
            data = json.loads(block)
        except json.JSONDecodeError:
            continue  # partial snippet with "..." — not a full example, skip
        errors = validate(data, schema)
        check(
            not errors,
            f"{md_path.name} example {index + 1} validates"
            + (f" [{'; '.join(errors)}]" if errors else ""),
        )

print()
if failures:
    print(f"FAIL: {len(failures)} failure(s)")
    for failure in failures:
        print(f"  - {failure}")
    sys.exit(1)
print("PASS")
sys.exit(0)
