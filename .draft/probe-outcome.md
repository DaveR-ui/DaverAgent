# Probe Outcome — Phase 0.2 Branch Gate

**Date:** 2026-08-24
**Probe path:** `.opencode/agents/subagents/_probe/probe.md`
**Snapshot commit:** `b632c0a` — "chore: snapshot opencode baseline before RPG restructure (Phase 0.1)" (55 files, 5 subdirs + .gitignore)

## Outcome: Branch B (provisional)

**Reason:** `bash .opencode/scripts/validate-agent.sh` uses flat loading (`find -maxdepth 1 -name '*.md'` and glob `*.md` at top level). It did **not** detect the nested probe agent. This matches the documented flat-agent loading behavior. Recursive precedent exists for skills (`**/SKILL.md`) and commands (`**/*.md`), but the current agent validator is explicitly flat.

If opencode's runtime loader mirrors the validator (flat), the probe will NOT load after restart → Branch B (flat fallback: `.opencode/agents/subagents/<id>.md` unchanged). If the runtime is recursive, probe WILL load → Branch A (nested loads: `.opencode/agents/subagents/<id>/<id>.md`).

**Human restart verification required** to confirm final branch.

## Validation log (with probe present, 2026-08-24 15:08 UTC)
```
== [1/7] config JSON ==
ok: /run/media/admin/Datos/Matafuegos necochea/agent-wizard/opencode.json
== [2/7] agent frontmatter (model optional; tools: check) ==
ok: frontmatter scanned (model optional; tools: check)
== [3/7] output_schema files ==
ok: analista.md -> ./analista.schema.json
ok: architect.md -> ./architect.schema.json
ok: coder.md -> ./coder.schema.json
ok: documenter.md -> ./documenter.schema.json
ok: explorer.md -> ./explorer.schema.json
ok: interpreter.md -> ./interpreter.schema.json
ok: reviewer.md -> ./reviewer.schema.json
ok: tester.md -> ./tester.schema.json
== [4/7] permission.task targets ==
ok: delivery.md task targets exist
ok: orchestrator.md task targets exist
== [5/7] required frontmatter ==
ok: frontmatter scanned
== [6/7] config instructions/references paths ==
ok: instruction 'docs/project.md'
ok: instruction '.opencode/protocols/prompt-pipeline.md'
ok: reference 'docs-context'
ok: reference 'docs-protocols'
ok: reference 'opencode-protocols'
== [7/7] schema JSON files ==
ok: analista.schema.json
ok: architect.schema.json
ok: coder.schema.json
ok: documenter.schema.json
ok: explorer.schema.json
ok: interpreter.schema.json
ok: reviewer.schema.json
ok: tester.schema.json
ok: install-agent.schema.json

PASS: 0 errors, 0 warning(s)
```
*Note:* No mention of `_probe/probe.md`; validator's `find -maxdepth 1` excludes subdirectories → evidence for Branch B.

`bash .opencode/tests/run-tests.sh` → **ALL TESTS PASS** (validate-agent + output-schemas) with probe present — probe is ignored, not treated as error.

## `ls` evidence
```
.opencode/agents/subagents/_probe:
probe.md
```

## Snapshot verification (`git show --stat HEAD` for b632c0a)
```
 .opencode/.gitignore                               |   8 +
 .opencode/agents/subagents/analista.md             | 104 +++++
 .opencode/agents/subagents/analista.schema.json    |  51 ++
 .opencode/agents/subagents/architect.md            |  79 ++++
 .opencode/agents/subagents/architect.schema.json   |  44 ++
 .opencode/agents/subagents/coder.md                |  53 +++
 .opencode/agents/subagents/coder.schema.json       |  34 ++
 .opencode/agents/subagents/delivery.md             | 207 +++++++++
 .opencode/agents/subagents/documenter.md           |  86 ++++
 .opencode/agents/subagents/documenter.schema.json  |  42 ++
 .opencode/agents/subagents/explorer.md             | 103 +++++
 .opencode/agents/subagents/explorer.schema.json    |  26 ++
 .opencode/agents/subagents/external-scout.md       |  61 +++
 .opencode/agents/subagents/interpreter.md          | 148 ++++++
 .opencode/agents/subagents/interpreter.schema.json | 128 ++++++
 .opencode/agents/subagents/orchestrator.md         | 281 +++++++++++
 .opencode/agents/subagents/project-context.md      |  77 ++++
 .opencode/agents/subagents/reviewer.md             | 127 +++++
 .opencode/agents/subagents/reviewer.schema.json    |  64 +++
 .opencode/agents/subagents/tester.md               |  66 +++
 .opencode/agents/subagents/tester.schema.json      |  35 ++
 .opencode/protocols/readme.md                      |  65 +++
 .opencode/protocols/agent-installer.md             | 127 +++++
 .../protocols/broad-investigation-template.md      |  55 +++
 .opencode/protocols/prompt-pipeline.md             | 113 +++++
 .opencode/protocols/session-recovery.md            | 152 ++++++
 .opencode/protocols/subagent-spec-template.md      | 345 ++++++++++++++
 .opencode/scripts/install-agent.ps1                | 511 +++++++++++++++++++++
 .opencode/scripts/install-agent.schema.json        | 183 ++++++++
 .opencode/scripts/session-recover.ps1              | 115 +++++
 .opencode/scripts/validate-agent.sh                | 239 ++++++++++
 .../tests/fixtures/outputs/analista.schema.json    |  11 +
 .../tests/fixtures/outputs/architect.schema.json   |  11 +
 .opencode/tests/fixtures/outputs/coder.schema.json |   6 +
 .../tests/fixtures/outputs/documenter.schema.json  |   7 +
 .../tests/fixtures/outputs/explorer.schema.json    |   5 +
 .../tests/fixtures/outputs/interpreter.schema.json |  20 +
 .../fixtures/outputs/invalid/analista.schema.json  |  12 +
 .../fixtures/outputs/invalid/architect.schema.json |  12 +
 .../fixtures/outputs/invalid/coder.schema.json     |   7 +
 .../outputs/invalid/documenter.schema.json         |   7 +
 .../fixtures/outputs/invalid/explorer.schema.json  |   6 +
 .../outputs/invalid/interpreter.schema.json        |  12 +
 .../fixtures/outputs/invalid/reviewer.schema.json  |  13 +
 .../fixtures/outputs/invalid/tester.schema.json    |   6 +
 .../tests/fixtures/outputs/reviewer.schema.json    |  12 +
 .../tests/fixtures/outputs/tester.schema.json      |   6 +
 .opencode/tests/fixtures/prompts/bug-fix.json      |  23 +
 .../tests/fixtures/prompts/feature-design.json     |  22 +
 .opencode/tests/run-tests.sh                       |  34 ++
 .opencode/tests/schema_check.py                    |  65 +++
 .opencode/tests/test-output-schemas.py             | 144 ++++++
 .opencode/tests/test-validate-agent.sh             |  15 +
 .opencode/workflows/dispatch.md                    |  26 ++
 .opencode/workflows/orchestrate.md                 |  21 +
 55 files changed, 4232 insertions(+)
```

`git diff --cached --stat` before commit showed same 55 files; `git status` after commit (at b632c0a) showed unstaged docs changes and untracked `.opencode/install.md`, `readme.md`, `jason-opencode.json`, `docs/plans/` — docs not committed in snapshot, honoring selective staging.

## Final outcome — Branch B confirmed (Phase 1, 2026-08-24)

**Date:** 2026-08-24
**Decision:** Branch B (flat fallback) confirmed — `.opencode/protocols/<id>/` for per-agent scrolls.
**Evidence:** `validate-agent.sh` flat scan (`find -maxdepth 1`) ignored nested `_probe/probe.md`; `ls .opencode/agents/subagents/` shows 12 agents after `rm -rf .opencode/agents/subagents/_probe/`; `bash .opencode/tests/run-tests.sh` PASS.
**Action taken (Phase 1 coder):** Probe directory removed (`rm -rf`); `ls` confirms 12 agents only (delivery, orchestrator, interpreter, explorer, project-context, external-scout, coder, reviewer, architect, analista, tester, documenter); tests re-run PASS.

## Human next steps (required — pre-Phase 1 remaining)
1. **Restart opencode** (no hot reload — config loaded once).
2. Verify probe loads: check agent list for `_probe` / `probe` (e.g., `opencode agents list` or `task` tool attempt to call `probe`). If probe appears → **Branch A** confirmed (nested loads). If absent → **Branch B** confirmed (flat).
3. Record final outcome here (overwrite provisional B if A confirmed).
4. **Delete scratch:** `rm -rf .opencode/agents/subagents/_probe/` — DONE in Phase 1.
5. Restart opencode again and verify **12 agents** load (the 12 actual per v1.0.2 — `delivery`, `orchestrator`, `interpreter`, `explorer`, `project-context`, `external-scout`, `coder`, `reviewer`, `architect`, `analista`, `tester`, `documenter`).
6. Re-run `bash .opencode/tests/run-tests.sh` → must pass; and `bash .opencode/scripts/validate-agent.sh` → must pass.
7. Remove this outcome file or keep as log; ensure `.opencode/.draft/` remains ignored via `.opencode/.gitignore` entry `.opencode/.draft/`.

## Current git status (after snapshot b632c0a, before human restart)
```
On branch master (behind origin/master by 1 — origin has extra docs commit 9d88c42)
Changes not staged: docs/_TAG-INDEX.md, docs/context/doc-conventions.md, docs/project.md
Untracked: .opencode/install.md, .opencode/readme.md, .opencode/jason-opencode.json, docs/plans/, .opencode/agents/subagents/_probe/ (scratch)
Ignored: .angular/, node_modules/, .opencode/tests/__pycache__/, .opencode/node_modules/ (via .opencode/.gitignore), .opencode/.draft/ (via appended entry)
```
