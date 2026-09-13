#!/usr/bin/env python3
"""Structural tests for the session capability (Decision 4).

Verifies the two halves of the session capability exist and are wired:

  1. `plugins/session-tool.js` — the agent-callable tool. It must export a
     `server` plugin on `@opencode-ai/plugin`, expose the eight ops
     (`children|tree|parent|messages|status|todo|diff|send`), and gate `send`
     behind `ctx.ask` with an `orchestrator|delivery` allow-list.
  2. `commands/session.md` — the human-facing slash command. It must carry
     frontmatter and reference the `session` tool.
  3. Both new tests are wired into `tests/run-tests.sh`.

Dependency-free (stdlib only). Exit 0 = pass, 1 = failures.
Run:  python3 tests/test-session-tool.py
"""
from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLUGIN = ROOT / "plugins" / "session-tool.js"
COMMAND = ROOT / "commands" / "session.md"
RUN_TESTS = ROOT / "tests" / "run-tests.sh"

OPS = ["children", "tree", "parent", "messages", "status", "todo", "diff", "send"]

failures = 0


def check(ok: bool, label: str) -> None:
    global failures
    if ok:
        print(f"  [ok] {label}")
    else:
        print(f"  [FAIL] {label}")
        failures += 1


def main() -> int:
    print("== plugin tool ==")
    check(PLUGIN.is_file(), "plugins/session-tool.js exists")
    source = PLUGIN.read_text(encoding="utf-8") if PLUGIN.is_file() else ""

    check('from "@opencode-ai/plugin"' in source, "plugin imports @opencode-ai/plugin")
    check("export const server" in source, "plugin exports `server`")
    for op in OPS:
        check(f'"{op}"' in source, f"declares op `{op}`")

    check("SEND_AGENTS" in source and "orchestrator" in source and "delivery" in source,
          "send is allow-listed to orchestrator|delivery")
    check("ask(" in source and '"session_send"' in source,
          "send is gated behind ctx.ask(permission: session_send)")

    node = shutil.which("node")
    if node:
        with tempfile.NamedTemporaryFile("w", suffix=".mjs", delete=False) as handle:
            handle.write(source)
            tmp = handle.name
        try:
            proc = subprocess.run([node, "--check", tmp], capture_output=True, text=True)
            check(proc.returncode == 0, "plugins/session-tool.js parses under `node --check`")
            if proc.returncode != 0:
                print(proc.stderr.strip())
        finally:
            os.unlink(tmp)
    else:
        print("  [skip] node not found — JS syntax check skipped")

    print("== slash command ==")
    check(COMMAND.is_file(), "commands/session.md exists")
    command = COMMAND.read_text(encoding="utf-8") if COMMAND.is_file() else ""
    check(command.startswith("---"), "command carries YAML frontmatter")
    check("agent: orchestrator" in command, "command targets the orchestrator agent")
    check("`session` tool" in command, "command references the `session` tool")

    print("== harness wiring ==")
    runner = RUN_TESTS.read_text(encoding="utf-8") if RUN_TESTS.is_file() else ""
    check("test-session-tool.py" in runner, "run-tests.sh runs test-session-tool.py")
    check("test-agent-hardening.py" in runner, "run-tests.sh runs test-agent-hardening.py")

    print()
    if failures:
        print(f"FAIL: {failures} failure(s)")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
