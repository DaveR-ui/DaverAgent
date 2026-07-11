# Protocol: Session Archiver

Distillation convention. Closes a session by reading the durable `Subagent.*` and `Step.*` event stream from the EventV2 bus (persisted in SQLite) and producing a single cross-agent digest.

This protocol replaces the older file-based cycle where subagents wrote `reasoning-full.md` + `summary.md` to disk and the archiver consumed those files. The replacement is event-sourced: the runtime emits lifecycle events with stable IDs, the archiver projects them into a human-readable digest.

## When to apply

- The human asks to "archive this session", "close the session", "distill", "summarize what we did".
- The session has reached a natural close (delivery is about to return the final response to the human and no further work is queued).
- The human is about to start a new session and explicitly says to "save", "persist", or "freeze" the current state.

Do **not** apply:

- Mid-session, while a subagent is still running. Wait for the subagent's `Subagent.Completed` / `Subagent.Failed` / `Subagent.Interrupted` event before reading the stream.
- For per-agent summaries — that is the structured return from the task tool (validated against `output_schema` when defined).
- For real-time memory — this is a one-shot distillation, not a streaming log.

## Inputs

| Source | Path / accessor | Required |
|---|---|---|
| Durable event stream | EventV2 bus, persisted in SQLite (e.g. via `EventV2Bridge.Service.listByAggregate(sessionID)`) | Yes |
| Session metadata | Session row in DB (`session.id`, `session.parent_id`, `session.title`, `session.created_at`, `session.updated_at`) | Yes |
| Subagent `output_schema` results | The structured JSON returned by each `Subagent.Completed` event | Recommended (one per completed subagent) |
| Final assistant messages | Last `MessageV2` per subagent session (fallback when no `output_schema`) | Fallback |

The session root is `~/.config/opencode/sessions/{human}/{project}/{DDMMYYYY-keywords}/` by default. The delivery agent or the orchestrator passes the absolute path when invoking this protocol.

## Output

A single file: `session-digest.md` at the session root. It contains:

1. **Header** — session name, date range, human, project, subagent count, final status per subagent.
2. **Decisions** — cross-agent decisions, deduplicated and grouped by topic. Each decision cites the `Subagent.Spawned` event ID and the originating agent.
3. **Lessons learned** — cross-agent lessons, deduplicated. Each lesson cites the source event(s).
4. **Open questions** — questions left unanswered, surfaced from `output_schema` fields (e.g. `coder.open_questions`) or final assistant messages.
5. **Links** — links to each child session via `GET /session/:id/children` so the per-subagent run is reachable.
6. **Interruptions summary** — count of `Subagent.Interrupted` events, count of `Step.Failed` with `metadata.interrupted = true`, and a short list of the most consequential interrupts.

## Process

1. **Discover** — query the event store for the parent session ID. List every `Subagent.Spawned` event to enumerate child sessions.
2. **Read** — for each child session, follow the event stream: `Subagent.Spawned` → `Subagent.Completed` / `Subagent.Failed` / `Subagent.Interrupted`. Capture `duration_ms` and final status. If `output_schema` is defined, attach the structured JSON to the child record.
3. **Extract** — pull out decisions, lessons, and open questions from each child's structured return (preferred) or from the final assistant message (fallback). Tag every item with the agent name and a citation like `event:Subagent.Completed#01H...`.
4. **Deduplicate** — merge decisions and lessons that appear in multiple children. Prefer the most specific phrasing; keep all citations.
5. **Group** — organize decisions by topic (e.g. "Testing strategy", "Module boundaries", "Error handling") and lessons by severity (e.g. "Bugs to avoid", "Conventions to follow").
6. **Write** — produce `session-digest.md` at the session root.
7. **No mutation** — the event stream is append-only and durable. The archiver never modifies it.

## Output Template

```markdown
# Session Digest — {DDMMYYYY-keywords}

**Human**: {human_id}
**Project**: {project_id}
**Date range**: {started_at} → {closed_at}
**Subagents involved**: {comma-separated list of agent names}
**Subagent outcomes**: {N} completed, {M} failed, {K} interrupted

## Final Status

| Subagent | Status | Duration | Summary |
|---|---|---|---|
| coder | completed | 1234ms | Implemented 3 endpoints |
| tester | partial | 567ms | Wrote 8 tests, 2 skipped |
| reviewer | interrupted | 89ms | Cancelled mid-review |

## Decisions

### {Topic group 1}
- **{Decision}** — cited from `event:Subagent.Completed#01H...` (also `event:Subagent.Completed#01H...`).

### {Topic group 2}
- **{Decision}** — cited from `event:Subagent.Completed#01H...`.

## Lessons learned

### Bugs to avoid
- **{Lesson}** — cited from `event:Subagent.Completed#01H...`.

### Conventions to follow
- **{Lesson}** — cited from `event:Subagent.Completed#01H...`.

## Open questions

- {question 1} — from `event:Subagent.Completed#01H...`.
- {question 2} — from `event:Subagent.Completed#01H...`.

## Interruptions summary

- Total `Subagent.Interrupted`: {N}
- Total `Step.Failed` with `metadata.interrupted = true`: {N}
- Most consequential interrupts:
  - {ISO-8601 timestamp}: {one-line summary of the interrupt and how it was handled}

## Per-subagent runs

- coder — child session `{id}`, structured return at `event:Subagent.Completed#01H...`
- tester — child session `{id}`, structured return at `event:Subagent.Completed#01H...`
- reviewer — child session `{id}`, interrupted at `event:Subagent.Interrupted#01H...`
- {etc.}
```

## Event source: EventV2 bus

The archiver reads the durable event bus. The relevant event types are:

- `Subagent.Spawned { parent_session_id, child_session_id, agent_type, prompt_summary }`
- `Subagent.Completed { child_session_id, status, duration_ms }`
- `Subagent.Failed { child_session_id, error }`
- `Subagent.Interrupted { child_session_id, reason }`
- `Step.Failed { session_id, error, metadata: { interrupted: true } }`

Schema definitions live in `packages/schema/src/session-event.ts` (namespace `Subagent`, lines ~434-526). Persistence is handled by `EventV2Bridge.Service` in `packages/core/src/event.ts`.

## Implementation phases

This protocol describes the **final** event-sourced shape. Two intermediate phases apply:

1. **Phase 1 (current)**: archiver reads the EventV2 bus but accepts fallback to the old `summary.md` path if a child has no `Subagent.Completed` event. The old files are produced only as a transitional measure by agents that have not yet been updated to return structured JSON.
2. **Phase 2 (after orchestrator stability is verified)**: archiver reads **only** the EventV2 bus. All old `summary.md` / `output-full.md` / `manifest.md` references are removed. `GET /session/:id/children` with `ChildInfo` becomes the single source of truth for subagent outcomes.

Do not skip Phase 1. The archiver must be testable end-to-end against the event stream before any agent stops writing the fallback files.

## Rules

- Always run after all subagents have returned. Never archive while a subagent is still running.
- Never edit the event stream — it is append-only and durable.
- Never read or write `summary.md` / `output-full.md` / `manifest.md` / `traffic-light.md` / `interruption-log.md` / `reasoning-full.md` — those files no longer exist in the protocol.
- All output in ENGLISH.
- If no events exist for the session, write a minimal `session-digest.md` with an "Empty session" note rather than failing.
- If a child has no `Subagent.Completed` event but has a `Subagent.Failed` or `Subagent.Interrupted`, treat the child as terminated and include the error/reason in the digest.
