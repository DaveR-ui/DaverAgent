#!/usr/bin/env python3
"""Structural tests for the session-export capability.

Verifies the session-export plugin exists, is safe by construction, honors its
configuration, and is wired into the test runner:

  1. `plugins/session-export.js` — publishes the opencode session list + status
     map to a JSON file. It must export a `server` plugin, read the local SDK
     (`session.list` / `session.status`), use async fs only, write atomically,
     and never throw upward.
  2. `tests/run-tests.sh` — the new test is wired into the master runner.

Dependency-free (stdlib only). Exit 0 = pass, 1 = failures.
Run:  python3 tests/test-session-export.py
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PLUGIN = ROOT / "plugins" / "session-export.js"
BEHAVIOR = ROOT / "tests" / "session-export.behavior.mjs"
RUN_TESTS = ROOT / "tests" / "run-tests.sh"

failures = 0


def check(ok: bool, label: str) -> None:
    global failures
    if ok:
        print(f"  [ok] {label}")
    else:
        print(f"  [FAIL] {label}")
        failures += 1


def main() -> int:
    print("== session export plugin ==")
    check(PLUGIN.is_file(), "plugins/session-export.js exists")
    source = PLUGIN.read_text(encoding="utf-8") if PLUGIN.is_file() else ""

    check("export const server" in source, "plugin exports `server`")

    print("== sdk calls ==")
    check("session.list" in source, "references `session.list`")
    check("session.status" in source, "references `session.status`")

    print("== safety ==")
    check("catch" in source, "uses try/catch (never throws upward)")
    check("node:fs" in source, "imports node:fs")
    check("promises" in source, "uses async fs (`promises`)")
    check(
        re.search(r"\b\w+Sync\s*\(", source) is None,
        "no sync fs calls in the hook path",
    )

    print("== configuration ==")
    check(
        "OPENCODE_SESSION_EXPORT" in source,
        "honors the OPENCODE_SESSION_EXPORT override",
    )
    check(
        "OPENCODE_SESSION_EXPORT_DISABLE" in source,
        "honors the OPENCODE_SESSION_EXPORT_DISABLE kill switch",
    )

    print("== format contract ==")
    for field in ("updatedAt", "sessions", "parentID", "status", "updated"):
        check(field in source, f"references the `{field}` field")
    check(
        "idle" in source and "busy" in source and "retry" in source,
        "references the `idle` / `busy` / `retry` status values",
    )
    check("rename" in source, "writes atomically via fs.rename")

    print("== hooks ==")
    check("event:" in source, "registers the `event` hook")
    check('"chat.message"' in source, "registers the `chat.message` hook")
    check(
        '"tool.execute.after"' in source,
        "registers the `tool.execute.after` hook",
    )

    print("== behavioral test ==")
    check(BEHAVIOR.is_file(), "tests/session-export.behavior.mjs exists")

    node = shutil.which("node")
    if node:
        with tempfile.NamedTemporaryFile("w", suffix=".mjs", delete=False) as handle:
            handle.write(source)
            tmp = handle.name
        try:
            proc = subprocess.run([node, "--check", tmp], capture_output=True, text=True)
            check(proc.returncode == 0, "plugins/session-export.js parses under `node --check`")
            if proc.returncode != 0:
                print(proc.stderr.strip())
        finally:
            os.unlink(tmp)

        proc = subprocess.run(
            [node, str(BEHAVIOR)], capture_output=True, text=True, timeout=30
        )
        check(proc.returncode == 0, "behavioral test passes")
        if proc.returncode != 0:
            print(proc.stdout.strip())
            print(proc.stderr.strip())
    else:
        print("  [skip] node not found — JS checks skipped")

    print("== harness wiring ==")
    runner = RUN_TESTS.read_text(encoding="utf-8") if RUN_TESTS.is_file() else ""
    check("test-session-export.py" in runner, "run-tests.sh runs test-session-export.py")

    print()
    if failures:
        print(f"FAIL: {failures} failure(s)")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
