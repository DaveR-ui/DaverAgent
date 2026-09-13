#!/usr/bin/env python3
"""Static invariants for the agent-system hardening pass.

Checks the permission matrix and the corrected runtime claims:

  1. `opencode.json` keeps `subagent_depth: 4` and declares no `lsp` block.
  2. Permission matrix (F2/F3/F4 + the `permission.task` catch-all model):
     - read-only agents deny `bash`
     - `delivery` denies `websearch`
     - `documenter` has a path-scoped `edit` grant
     - `architect`/`tester` deny `edit`
     - every agent declaring a `task:` map starts it with `"*": deny`
  3. No fabricated runtime claims remain under `agents/` or `protocols/`
     (`ChildInfo {`, `Subagent.Completed`, `Subagent.Interrupted`, `EventV2`).

Dependency-free (stdlib only). Exit 0 = pass, 1 = failures.
Run:  python3 tests/test-agent-hardening.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
AGENTS = ROOT / "agents"
PROTOCOLS = ROOT / "protocols"

failures = 0


def check(ok: bool, label: str) -> None:
    global failures
    if ok:
        print(f"  [ok] {label}")
    else:
        print(f"  [FAIL] {label}")
        failures += 1


def frontmatter(path: Path) -> str:
    text = path.read_text(encoding="utf-8")
    parts = text.split("---", 2)
    return parts[1] if len(parts) >= 3 else ""


def indented_block(fm: str, key: str, indent: int) -> list[str]:
    """Return the stripped lines of the mapping nested under `key:`."""
    lines = fm.splitlines()
    pattern = re.compile(rf"^ {{{indent}}}{re.escape(key)}:\s*$")
    for i, line in enumerate(lines):
        if pattern.match(line):
            entries: list[str] = []
            for child in lines[i + 1 :]:
                if child.strip() == "":
                    continue
                current = len(child) - len(child.lstrip())
                if current <= indent:
                    break
                entries.append(child.strip())
            return entries
    return []


def task_map(path: Path) -> list[str] | None:
    entries = indented_block(frontmatter(path), "task", 2)
    return entries or None


def has_scalar(fm: str, key: str, value: str) -> bool:
    return bool(re.search(rf"^ {{{2}}}{re.escape(key)}: {re.escape(value)}\s*$", fm, re.M))


def global_lsp_keys(node, found: list[str]) -> None:
    if isinstance(node, dict):
        for key, value in node.items():
            if key == "lsp":
                found.append(key)
            global_lsp_keys(value, found)
    elif isinstance(node, list):
        for item in node:
            global_lsp_keys(item, found)


def main() -> int:
    print("== opencode.json invariants ==")
    config = json.loads((ROOT / "opencode.json").read_text(encoding="utf-8"))
    check(config.get("subagent_depth") == 4, "subagent_depth stays 4")
    lsp_keys: list[str] = []
    global_lsp_keys(config, lsp_keys)
    check(not lsp_keys, "no `lsp` key anywhere in opencode.json")
    check(
        config.get("permission", {}).get("session_send") == "ask",
        "global `session_send: ask` makes the send gate fire",
    )

    print("== permission matrix ==")
    doc_fm = frontmatter(AGENTS / "documenter.md")
    doc_edit = indented_block(doc_fm, "edit", 2)
    joined_doc_edit = " | ".join(doc_edit)
    check('"**/*.md": allow' in joined_doc_edit, "documenter allows repo-wide `**/*.md`")
    for deny in (
        '"*": deny',
        '"agents/**": deny',
        '"protocols/**": deny',
        '"workflows/**": deny',
        '"opencode.json": deny',
        '"AGENTS.md": deny',
    ):
        check(deny in joined_doc_edit, f"documenter edit blocks {deny}")

    delivery_edit = " | ".join(indented_block(frontmatter(AGENTS / "delivery.md"), "edit", 2))
    check('"*": deny' in delivery_edit, "delivery edit is path-scoped (`*: deny`)")
    for allow in (
        '"agents/**": allow',
        '"protocols/**": allow',
        '"workflows/**": allow',
        '"opencode.json": allow',
    ):
        check(allow in delivery_edit, f"delivery edit allows {allow}")

    for name in ("explorer", "reviewer"):
        fm = frontmatter(AGENTS / f"{name}.md")
        check(has_scalar(fm, "edit", "deny"), f"{name} denies edit")
        check(has_scalar(fm, "bash", "deny"), f"{name} denies bash (read-only enforced)")

    check(
        has_scalar(frontmatter(AGENTS / "delivery.md"), "webfetch", "deny"),
        "delivery denies webfetch",
    )
    check(
        has_scalar(frontmatter(AGENTS / "delivery.md"), "websearch", "deny"),
        "delivery denies websearch",
    )

    for name in ("architect", "tester"):
        check(
            has_scalar(frontmatter(AGENTS / f"{name}.md"), "edit", "deny"),
            f"{name} denies edit (consistent with its stated body)",
        )

    orch_edit = " | ".join(indented_block(frontmatter(AGENTS / "orchestrator.md"), "edit", 2))
    check('"*": allow' in orch_edit, "orchestrator edit is explicit (`*: allow`)")
    for guarded in ('"agents/**": ask', '"protocols/**": ask', '"workflows/**": ask', '"opencode.json": ask'):
        check(guarded in orch_edit, f"orchestrator edit guards global config with {guarded}")

    print("== permission.task catch-all model ==")
    for path in sorted(AGENTS.glob("*.md")):
        entries = task_map(path)
        if entries is None:
            continue
        check(
            entries[0] == '"*": deny',
            f"{path.name} task map opens with `\"*\": deny` as its FIRST entry",
        )

    print("== delivery/orchestrator fan-out preserved ==")
    delivery_entries = task_map(AGENTS / "delivery.md") or []
    for target in (
        "interpreter", "orchestrator", "coder", "tester", "reviewer", "architect",
        "explorer", "project-context", "external-scout", "analista", "documenter",
    ):
        check(f"{target}: allow" in delivery_entries, f"delivery still allows {target}")
    orch_entries = task_map(AGENTS / "orchestrator.md") or []
    for target in (
        "coder", "tester", "reviewer", "architect", "explorer",
        "project-context", "external-scout", "analista", "documenter",
    ):
        check(f"{target}: allow" in orch_entries, f"orchestrator still allows {target}")

    print("== every agent is reachable from delivery ==")
    delivery_targets = {
        entry.split(":")[0]
        for entry in (task_map(AGENTS / "delivery.md") or [])
        if entry.endswith(": allow")
    }
    for path in sorted(AGENTS.glob("*.md")):
        if path.stem == "delivery":
            continue
        check(path.stem in delivery_targets, f"delivery allow-list reaches {path.stem}")

    print("== no fabricated runtime claims ==")
    forbidden = ("ChildInfo {", "Subagent.Completed", "Subagent.Interrupted", "EventV2")
    offenders: list[str] = []
    for base in (AGENTS, PROTOCOLS):
        for path in sorted(base.rglob("*.md")):
            text = path.read_text(encoding="utf-8")
            for needle in forbidden:
                if needle in text:
                    offenders.append(f"{path.relative_to(ROOT)}: {needle}")
    check(not offenders, "no ChildInfo/Subagent.*/EventV2 claims under agents/ or protocols/")
    for offender in offenders:
        print(f"         - {offender}")

    print()
    if failures:
        print(f"FAIL: {failures} failure(s)")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
