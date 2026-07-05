# Protocol: Interruption Bus

## Deprecation

> Este protocolo está **deprecado** desde la Etapa 2 del `agent-improvement-plan`.
>
> **Reemplazo nativo**:
> - Cancelación: `POST /session/:id/abort` → `SessionRunState.cancel(sessionID)`.
> - Observabilidad: eventos `Subagent.Interrupted` en el bus EventV2, y `Step.Failed` con `metadata.interrupted = true`.
> - Memoria: el `reasoning-full.md` se reemplaza por compactación nativa (Etapa 4).
>
> Las secciones marcadas como **legacy** se conservan solo como referencia histórica. No usar en código nuevo.

File-based bus that lets the human steer subagents mid-execution and lets subagents persist memory across resumptions. Works even when the LM does not print a pause marker, because all signals live on disk.

## When this protocol applies

- A subagent is executing and the human sends a new message in the same session.
- The orchestrator releases a subagent that has prior session memory to load.
- The session is closing and memory needs to be preserved.
- A subagent returns and the orchestrator needs to aggregate only the summary (not the full chain of thought).
- The human asks to "pause", "stop", "redirect", "inject hint", or "resume" a subagent.

Do **not** use this protocol for:

- A standalone chat (no subagent running, no memory needed).
- Cross-session recall (use the project-context agent against `docs/` instead).
- Sub-second steering (the file bus has poll latency; for fast edits just edit and re-run).

## The 4 artifacts

All paths are relative to the active session root (typically `~/.config/opencode/sessions/{human}/{project}/{DDMMYYYY-keywords}/`).

### 1. `traffic-light.md` — Shared status board [Legacy]

A single table that lists every known agent in the session and its current semáforo color. Subagents read it before any major step; the delivery agent writes to it when a new interruption arrives.

| State | Meaning | Subagent action |
|---|---|---|
| 🟢 **GREEN** | Agent working normally. May proceed. | Continue with the next planned step. |
| 🟡 **YELLOW** | Agent working, will pause after current step. Human can inject hint. | Finish the current atomic step (one file write or one command), then stop, write a note to `summary.md`, and return. |
| 🔴 **RED** | Agent MUST stop at next checkpoint. Waits for human instruction. | Stop immediately, write a short note to `summary.md` describing what was being done, and return to the orchestrator. Do not start new work. |
| ⚪ **IDLE** | Agent not yet released by orchestrator. | N/A — only the orchestrator transitions an agent out of IDLE. |

The default safe action when an interruption arrives with no targeted agent is to set ALL active agents to 🟡 YELLOW. This lets each agent finish its current atomic step before pausing.

### 2. `interruption-log.md` — Append-only audit trail [Legacy]

Every human intervention and every agent acknowledgment is appended here with an ISO-8601 timestamp and an actor tag. The log is append-only; entries are never edited or removed. Subagents read it to discover new hints since their last read.

```markdown
# Interruption Log

Append-only log of human interventions and agent acknowledgments. Most recent at the bottom.

<!-- Format:
- [ISO-8601 timestamp] [ACTOR] message
-->

- [2026-06-17T14:30:00Z] [SYSTEM] Session started
- [2026-06-17T14:35:12Z] [HUMAN] (translated to English) please use vitest instead of jasmine
- [2026-06-17T14:35:30Z] [CODER] Acknowledged. Switching to vitest for new tests.
```

The delivery agent is responsible for translating the human's message to English before appending. The orchestrator and subagents always log in English.

### 3. `agents/{name}/reasoning-full.md` — Per-agent long-form memory [Legacy]

> Deprecado desde la Etapa 4. El reemplazo es la compactación nativa (SessionCompaction).
> Los subagentes write-capable (`coder`, `tester`, `architect`) ya no necesitan escribir
> `reasoning-full.md` a disco. Los subagentes read-only (`explorer`, `reviewer`) nunca lo
> escribieron.

Free-form chain of thought for one agent in one session. Subagents write to it incrementally (after every 3-5 tool calls) and on completion. The orchestrator does NOT inline this into its final response; it is kept for the session-archiver and for future resumptions.

Typical sections:

- Chain of thought (considerations, alternatives, doubts)
- Tool calls log (table of time, tool, args, result)
- Errors encountered
- Files touched (with rationale)
- Interruptions handled (timestamp + hint + how it was incorporated)

For read-only subagents (explorer, reviewer, angular-expert) this file is optional — light reasoning is fine since they do not modify code.

### 4. `agents/{name}/summary.md` — Per-agent executive summary

A 10-30 line executive summary, written at the END of the subagent's work or when it pauses. The orchestrator aggregates ONLY this file into the final response to delivery. Contains:

- Status (success / partial / paused / failed)
- What was done (1-3 bullets, executive level)
- Artifacts created (file paths)
- Files modified (file paths with brief description)
- Key decisions (any non-obvious choices)
- Open questions / next steps
- Link to `reasoning-full.md`

## How to read and write each artifact

### Writing `traffic-light.md`

- Always update the entire table; do not append rows.
- Use the current ISO-8601 timestamp in the `Updated` column.
- Put a short reason in the `Notes` column whenever a state is not 🟢 GREEN.
- When transitioning to ⚪ IDLE (e.g., before releasing an agent), the orchestrator writes a new row.

### Writing `interruption-log.md`

- ALWAYS append. NEVER edit or delete existing entries.
- Use the format: `- [{ISO-8601 timestamp}] [{ACTOR}] {message}`.
- Actors: `SYSTEM`, `HUMAN`, `DELIVERY`, `ORCHESTRATOR`, `CODER`, `TESTER`, `REVIEWER`, `ARCHITECT`, `EXPLORER`, `DOCUMENTER`, `ANGULAR_EXPERT`.
- Keep the message short (one line, one idea). If a hint is long, put the full text in `agents/{name}/reasoning-full.md` and reference it from the log.

### Reading `traffic-light.md`

- Subagents read it before any major step (before any `write` or `edit` tool call, and after every 3-5 tool calls).
- Read the entire file; the table is small.
- If your agent's row is missing, assume 🟢 GREEN but log the anomaly to your `reasoning-full.md`.

### Reading `interruption-log.md`

- Subagents read it at the same checkpoints as `traffic-light.md`.
- Track which entries you have already incorporated (by timestamp).
- If there are new entries since your last read, incorporate them before continuing.

## Checkpoint schedule (all agents)

Before EACH of the following, READ both `traffic-light.md` and `interruption-log.md` (paths are relative to your `agents/{name}/` directory, i.e. the session root):

- Before any `write` tool call
- Before any `edit` tool call
- After every 3-5 tool calls (whichever comes first)
- At the end of any atomic step that modifies a file

If either file is missing, log the anomaly to your `reasoning-full.md` and assume 🟢 GREEN.

## How to act on `traffic-light.md`

Read your own row in the table (the row with your agent name):

| State | Action |
|---|---|
| 🟢 **GREEN** | Continue with the next planned step. |
| 🟡 **YELLOW** | Finish the current atomic step (one file write or one command), then stop. Write a short note to `summary.md` saying you paused at this step. Return to the orchestrator with: "Paused (YELLOW). Summary: agents/{name}/summary.md". |
| 🔴 **RED** | STOP immediately. Do not start new work. Write a short note to `summary.md` describing what you were doing and the reason. Return to the orchestrator with: "Paused (RED). Summary: agents/{name}/summary.md". |
| ⚪ **IDLE** | N/A — only the orchestrator transitions an agent out of IDLE. |

If your row is missing, assume 🟢 GREEN and log the anomaly.

## How to act on `interruption-log.md`

- Track which entries you have already incorporated (by timestamp).
- If there are new entries with `[HUMAN]` since your last read, incorporate the hint before continuing. Log an acknowledgment entry with `[{NAME_UPPER}]` prefix on the same file.
- A `[HUMAN]` entry may also flip your semáforo to 🟡 YELLOW or 🔴 RED — re-read `traffic-light.md` after reading the log.

## End-of-work return format

After writing your memory files, return to the orchestrator with exactly this format:

- Write-capable: `"Work complete. Summary: agents/{name}/summary.md | Full reasoning: agents/{name}/reasoning-full.md"`
- Read-only: `"Work complete. Summary: agents/{name}/summary.md"`

## On resumption

If the orchestrator releases you with a previous `summary.md` path, READ it first to understand the state. Treat it as your starting point; do not redo work that is already summarized as complete.

## Roles in the bus

### Delivery (bootstrap)

On session start, before delegating, the delivery agent MUST create in the session root:

- `traffic-light.md` (all known agents ⚪ IDLE)
- `interruption-log.md` (with one `[SYSTEM] Session started` entry)
- `agents/` directory (with `.gitkeep`)
- `agents/{name}/` subdirs after first subagent release

When a human message arrives while a subagent is running, delivery:

1. Translates the human's message to English
2. Appends to `interruption-log.md` with `[HUMAN]` prefix
3. Updates `traffic-light.md` (targeted → 🔴 RED, or all active → 🟡 YELLOW as default safe)
4. Does NOT abort the running subagent
5. Acknowledges to the human in their language

On session close, if `humano.md` has `Distillation on session close: enabled`, delivery invokes the session-archiver protocol.

### Orchestrator (coordination)

On subagent release (via `task` tool), the orchestrator includes in the prompt:

- Path to the subagent's previous `summary.md` (if exists) — resume context
- Path to previous `reasoning-full.md` (if exists) — deeper history
- Paths to `traffic-light.md` and `interruption-log.md`
- Updates `traffic-light.md` to 🟢 GREEN for the released agent

On subagent return, the orchestrator:

- Aggregates ONLY the contents of `summary.md` from each subagent
- Does NOT inline `reasoning-full.md` (stays on disk for archiver and future sessions)
- Updates `traffic-light.md` to ⚪ IDLE for the returning agent

On re-release of the same subagent, the orchestrator passes the freshly written `summary.md` path as resume context.

## Quick reference

| You are the... | Read | Write |
|---|---|---|
| Delivery (interrupt) | `interruption-log.md` (append row reference) | `traffic-light.md`, `interruption-log.md` |
| Orchestrator (releasing subagent) | previous `summary.md` if present | new rows in `traffic-light.md` |
| Orchestrator (aggregating) | every `summary.md` | nothing (read-only aggregation) |
| Subagent (before major step) | `traffic-light.md`, `interruption-log.md` | `agents/{name}/reasoning-full.md` (incremental) |
| Subagent (at completion or pause) | same as above | `agents/{name}/summary.md`, final `reasoning-full.md` |

## Notes

- The protocol is file-based by design: it survives LLM non-determinism and works even if the model does not print a pause marker.
- All paths in this protocol are relative to the active session root. The delivery agent resolves the absolute path and tells each subagent in its release prompt.
- Human-injected messages are translated to English by the delivery agent before being logged. The subagents never receive the human's source language.
- The protocol is additive: existing agents can be migrated one at a time. The strategic-pause mechanism in the orchestrator remains valid; the interruption protocol augments it.
