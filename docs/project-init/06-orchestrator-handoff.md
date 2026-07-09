# 06 — Orchestrator Handoff

> Experiential annotations on structuring the orchestrator handoff and interpreting what comes back. See `.opencode/agents/orchestrator.md` (if present), `.opencode/protocols/interruption.md`, and `.opencode/docs/agent-output-protocol.md`.

---

## The Orchestrator is Ephemeral

The orchestrator gets a **fresh context per task**. It does the work, returns an agent-snapshot, and is archived. The snapshot is the ONLY thing that persists — make sure it's complete.

---

## Handoff Template (delivery → orchestrator)

| Field | Content |
|---|---|
| Task | Verbatim from the human, translated to English — do NOT paraphrase |
| Acceptance criteria | Concrete, testable, from Phase 1 |
| Project state snapshot | Project, branch, recent changes, hot files |
| Session path | `~/.config/opencode/sessions/{human}/{project}/{DDMMYYYY-keywords}/` |
| Slice info | Pre-matched slice(s) or "unmatched" |
| Ladder rung | Starting point, override signals applied, rationale |
| Constraints | Standards, SSR-safety, accessibility, etc. |
| Stop conditions | When to pause and ask the human |

---

## Agent-Snapshot (orchestrator → delivery)

| Field | Content |
|---|---|
| Status | DONE / NEEDS_HUMAN / STUCK |
| Decisions | Any rung adjustments, scope changes, deviations — with rationale |
| Files changed | List with paths |
| Agent outputs | On disk at `{session_path}/agents/{agent}-{timestamp}/` |
| Commands run | Build, test, lint — with results |
| Open questions | Anything needing human input |
| Resume instructions | How to continue if re-instantiated |

---

## Agent Output Paths

```
{session_path}/agents/
├── manifest.md                      # index of all agent outputs
├── coder-{timestamp}/
│   ├── summary.md                   # short, 5–10 lines (returned to orchestrator)
│   └── output-full.md               # detailed: diffs, logs, reasoning
├── tester-{timestamp}/
├── reviewer-{timestamp}/
└── orchestrator-{timestamp}/        # if orchestrator writes strategy files
```

- `summary.md` is the short report returned to the orchestrator — keeps context small.
- `output-full.md` is the detailed report with diffs, logs, and findings — read on demand.
- `manifest.md` indexes every agent output in the session.

---

## Parallel Subagents

The orchestrator can release multiple subagents **in parallel** where work is independent. Example: a coder implements the feature while a tester writes tests against the acceptance criteria — if the interface is agreed upfront.

---

## Strategy Files on Disk

The orchestrator may write a strategy file to disk (e.g., `agents/orchestrator/design-strategy.md`) and have coders **read it** instead of duplicating context in each coder prompt. This keeps the orchestrator's context small and avoids drift between parallel coders.

---

## Re-instantiation Triggers

| Trigger | Action |
|---|---|
| Human requests restart ("reiniciá el orquestador") | Fresh orchestrator with the same handoff |
| Context growth (`reasoning-full.md` > ~200KB) | Re-instantiate to reset context |
| Independent workstreams | Run parallel orchestrators |

Orchestrator snapshots are saved to:
`sessions/{human_id}/{project_id}/{DDMMYYYY-keywords}/orchestrator-snapshots/{uuid}.md`

---

## Gotchas

- Include the task **VERBATIM** (translated to English) in the handoff — don't paraphrase. The orchestrator needs the exact intent, not your interpretation.
- **Always include the session path** — the orchestrator needs it to write agent outputs. Without it, outputs go nowhere.
- The orchestrator's **agent-snapshot is the ONLY thing that persists** after archival. If it's incomplete, the work is lost to the next session.
- If the orchestrator reports a **pre-existing build failure**, verify it's actually pre-existing (check `git status` / `git diff`) before reporting to the human. Sometimes the orchestrator's own changes caused it.
- The orchestrator **can adjust the ladder rung** if codebase reading reveals a different reality — but any adjustment MUST be documented in the agent-snapshot under "Decisions" with rationale.
- Don't let the orchestrator's context sprawl — use strategy files on disk and targeted excerpts, not full file dumps.
- The `summary.md` is what the orchestrator reads back; the `output-full.md` is for humans and reviewers. Keep the summary short.

---

## Quick Reference

**Handoff fields**: task (verbatim), acceptance criteria, project state, session path, slice info, ladder rung, constraints, stop conditions.

**Agent-snapshot fields**: status, decisions, files changed, agent outputs, commands run, open questions, resume instructions.

**Agent output paths**: `{session_path}/agents/{agent}-{timestamp}/summary.md` + `output-full.md`; index at `agents/manifest.md`.

**Re-instantiation triggers**: human request, context >200KB, independent workstreams.

**Cross-reference**: `.opencode/agents/orchestrator.md` (if exists), `.opencode/protocols/interruption.md`, `.opencode/docs/agent-output-protocol.md`.