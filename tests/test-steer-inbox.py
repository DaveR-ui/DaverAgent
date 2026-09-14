#!/usr/bin/env python3
"""Structural tests for the file-based steering inbox capability.

Verifies the steering inbox plugin exists, is safe by construction, and is
wired into the test runner:

  1. `plugins/steer-inbox.js` — the file-based steering inbox. It must export a
     `server` plugin, deliver over the v2 steer channel (`delivery: "steer"`),
     use async fs only, and carry the safe provider policy (no secrets, no
     auto-connect).
  2. `tests/run-tests.sh` — the new test is wired into the master runner.

Dependency-free (stdlib only). Exit 0 = pass, 1 = failures.
Run:  python3 tests/test-steer-inbox.py
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
PLUGIN = ROOT / "plugins" / "steer-inbox.js"
BEHAVIOR = ROOT / "tests" / "steer-inbox.behavior.mjs"
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
    print("== steering inbox plugin ==")
    check(PLUGIN.is_file(), "plugins/steer-inbox.js exists")
    source = PLUGIN.read_text(encoding="utf-8") if PLUGIN.is_file() else ""

    check("export const server" in source, "plugin exports `server`")

    print("== steer channel ==")
    check("delivery" in source, "references the `delivery` field")
    check('"steer"' in source, 'references the `"steer"` delivery value')
    check(
        "@opencode-ai/sdk/v2" in source or "/api/session/" in source,
        "references the real v2 channel (@opencode-ai/sdk/v2 or /api/session/)",
    )

    print("== safety ==")
    check("catch" in source, "uses try/catch (never throws upward)")
    check("node:fs" in source, "imports node:fs")
    check("promises" in source, "uses async fs (`promises`)")
    check(
        re.search(r"\b\w+Sync\s*\(", source) is None,
        "no sync fs calls in the hook path",
    )

    print("== provider policy ==")
    check("opencode-go" in source, "documents the opencode-go integration")
    check(
        "manual" in source.lower() or "connect" in source.lower(),
        "documents the one-time manual connect note",
    )
    check("auth.json" not in source, "does not reference auth.json")
    check("apiKey" not in source, "does not reference apiKey")

    print("== configuration ==")
    check("OPENCODE_STEER_INBOX" in source, "honors the OPENCODE_STEER_INBOX override")
    check(
        "OPENCODE_STEER_INBOX_DISABLE" in source,
        "honors the OPENCODE_STEER_INBOX_DISABLE kill switch",
    )

    print("== behavioral test ==")
    check(BEHAVIOR.is_file(), "tests/steer-inbox.behavior.mjs exists")

    node = shutil.which("node")
    if node:
        with tempfile.NamedTemporaryFile("w", suffix=".mjs", delete=False) as handle:
            handle.write(source)
            tmp = handle.name
        try:
            proc = subprocess.run([node, "--check", tmp], capture_output=True, text=True)
            check(proc.returncode == 0, "plugins/steer-inbox.js parses under `node --check`")
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
    check("test-steer-inbox.py" in runner, "run-tests.sh runs test-steer-inbox.py")

    print()
    if failures:
        print(f"FAIL: {failures} failure(s)")
        return 1
    print("PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
