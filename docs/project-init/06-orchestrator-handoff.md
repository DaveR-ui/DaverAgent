# 06 — Orchestrator Handoff

> Experiential annotations on structuring the orchestrator handoff and interpreting what comes back. See `.opencode/agents/orchestrator.md` and `.opencode/docs/agent-output-protocol.md` (historical).

---

## The Orchestrator is Persistent

The orchestrator is released **once per session** via the task tool with `background: true`. It maintains state across all delegations within a session. The orchestrator's **agent-snapshot** is the structured return it emits at the end of its work; the snapshot is the only thing `delivery` consumes to report back to the human.

---

## Handoff Template (delivery → orchestrator)

| Field | Content |
|---|---|
| Task | Verbatim from the human, translated to English — do NOT paraphrase |
| Acceptance criteria | Concrete, testable, from Phase 1 |
| Project state snapshot | Project, branch, recent changes, hot files |
| Session path | `~/.config/opencode/sessions/{human}/{project}/{DDMMYYYY-keywords}/` |
| Slice info | Pre-matched slice(s) or "unmatched" |
| Constraints | Standards, conventions, what NOT to touch |
| Stop conditions | When to pause and ask the human |

---

## Agent-Snapshot (orchestrator → delivery)

| Field | Content |
|---|---|
| Status | DONE / NEEDS_HUMAN / STUCK |
| Decisions | Any rung adjustments, scope changes, deviations — with rationale |
| Files changed | List with paths |
| Subagent outcomes | Citations to `event:Subagent.Completed#01H...` and `event:Subagent.Interrupted#01H...` |
| Commands run | Build, test, lint — with results |
| Open questions | Anything needing human input |
| Resume instructions | How to continue if re-instantiated |

Structured returns from subagents (e.g. `CoderOutput`, `ReviewerOutput`) are **embedded in the `Subagent.Completed` event** on the EventV2 bus. The orchestrator receives the validated JSON via the task tool return, not as a file on disk. To inspect a specific subagent's return, query the event store or call `GET /session/:id/children` for the child session.

---

## Subagent Outcomes Layout

Subagent outcomes do not live in the file tree. The runtime captures everything in the EventV2 bus (persisted in SQLite) and exposes it through `GET /session/:id/children`:

```
event:Subagent.Spawned     # child_session_id, agent_type, prompt_summary
event:Subagent.Completed   # child_session_id, status, duration_ms (+ structured JSON if output_schema)
event:Subagent.Failed      # child_session_id, error
event:Subagent.Interrupted # child_session_id, reason
```

For per-subagent details, query `GET /session/:id/children` which returns a `ChildInfo[]` array with `status`, `summary`, `agentType`, `durationMs`, and `createdAt` per child.

---

## Parallel Subagents

The orchestrator can release multiple subagents **in parallel** where work is independent. Example: a coder implements the feature while a tester writes tests against the acceptance criteria — if the interface is agreed upfront.

For same-type fan-out (one subagent type, N instances with disjoint inputs), see "Fan-out" in `.opencode/agents/orchestrator.md`. Each instance returns the same `output_schema` JSON; the orchestrator aggregates them in memory.

---

## Re-instantiation Triggers

| Trigger | Action |
|---|---|
| Human requests restart ("restart the orchestrator") | Fresh orchestrator with the same handoff |
| Context growth (orchestrator approaching the 250K context budget) | Suggest restart to the human, with a clean snapshot |
| Independent workstreams | Run parallel orchestrators |

Orchestrator snapshots are saved to:
`sessions/{human_id}/{project_id}/{DDMMYYYY-keywords}/orchestrator-snapshots/{uuid}.md`

---

## Gotchas

- Include the task **VERBATIM** (translated to English) in the handoff — don't paraphrase. The orchestrator needs the exact intent, not your interpretation.
- The orchestrator's **agent-snapshot is the primary persistent artifact** after it returns. If it's incomplete, the work is lost to the next session.
- If the orchestrator reports a **pre-existing build failure**, verify it's actually pre-existing (check `git status` / `git diff`) before reporting to the human. Sometimes the orchestrator's own changes caused it.
- The orchestrator **can adjust scope** if codebase reading reveals a different reality — but any adjustment MUST be documented in the agent-snapshot under "Decisions" with rationale.
- Don't let the orchestrator's context sprawl — keep summaries tight, use `output_schema` validation to keep returns structured, and don't inline large file dumps.
- Subagent returns that include `output_schema` validation warnings (`[output_schema validation warning: ...]`) indicate the agent returned text instead of JSON. The orchestrator should treat the warning as a sign the subagent needs clearer instructions, not as a failure.

---

## Quick Reference

**Handoff fields**: task (verbatim), acceptance criteria, project state, session path, slice info, constraints, stop conditions.

**Agent-snapshot fields**: status, decisions, files changed, subagent outcomes (with event IDs), commands run, open questions, resume instructions.

**Subagent outcomes**: EventV2 bus + `GET /session/:id/children` (not files). Structured returns via `output_schema`.

**Re-instantiation triggers**: human request, context approaching 250K, independent workstreams.

**Cross-reference**: `.opencode/agents/orchestrator.md`, `.opencode/docs/agent-output-protocol.md` (historical).
