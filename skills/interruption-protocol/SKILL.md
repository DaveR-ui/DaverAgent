---
name: interruption-protocol
description: Use when a subagent is running and the human wants to inject a hint, pause the agent, or steer it mid-execution. Also covers the file-based bus (traffic-light.md, interruption-log.md) and per-agent persistent memory (reasoning-full.md, summary.md). Trigger on mentions of "interrupt", "pause subagent", "inject hint", "change course", "session memory", "agent resume", "traffic light".
---

# Interruption Protocol

File-based protocol that lets the human steer subagents mid-execution and lets subagents persist memory across resumptions. Works even when the LM does not print a pause marker, because all signals live on disk.

## When to Use This Protocol

Use this protocol whenever:

- A subagent is executing and the human sends a new message in the same session.
- The orchestrator releases a subagent that has prior session memory to load.
- The session is closing and memory needs to be preserved.
- A subagent returns and the orchestrator needs to aggregate only the summary (not the full chain of thought).
- The human asks to "pause", "stop", "redirect", "inject hint", or "resume" a subagent.

Do NOT use this protocol for:

- A standalone chat (no subagent running, no memory needed).
- Cross-session recall (use the project-context agent against `.github/agent-context/` instead).
- Sub-second steering (the file bus has poll latency; for fast edits just edit and re-run).

## The 4 Artifacts

All paths below are relative to the active session root (typically `~/.config/opencode/sessions/{human}/{project}/{DDMMYYYY-keywords}/`).

### 1. `traffic-light.md` — Shared status board

A single table that lists every known agent in the session and its current semáforo color. Subagents read it before any major step; the delivery agent writes to it when a new interruption arrives.

States and their meaning:

| State | Meaning | Subagent action |
|---|---|---|
| 🟢 **GREEN** | Agent working normally. May proceed. | Continue with the next planned step. |
| 🟡 **YELLOW** | Agent working, will pause after current step. Human can inject hint. | Finish the current atomic step (one file write or one command), then stop, write a note to `summary.md`, and return. |
| 🔴 **RED** | Agent MUST stop at next checkpoint. Waits for human instruction. | Stop immediately, write a short note to `summary.md` describing what was being done, and return to the orchestrator. Do not start new work. |
| ⚪ **IDLE** | Agent not yet released by orchestrator. | N/A — only the orchestrator transitions an agent out of IDLE. |

The default safe action when an interruption arrives with no targeted agent is to set ALL active agents to 🟡 YELLOW. This lets each agent finish its current atomic step before pausing.

### 2. `interruption-log.md` — Append-only audit trail

Every human intervention and every agent acknowledgment is appended here with an ISO-8601 timestamp and an actor tag. The log is append-only; entries are never edited or removed. Subagents read it to discover new hints since their last read.

Format:

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

### 3. `agents/{name}/reasoning-full.md` — Per-agent long-form memory

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

## How to Read and Write Each Artifact

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

## How the Orchestrator Coordinates Resumption

The orchestrator's role in the interruption protocol:

1. **On release** — When calling a subagent via `task`, the orchestrator passes in the prompt:
   - The path to the subagent's previous `agents/{name}/summary.md` (if it exists) as resume context.
   - The path to `agents/{name}/reasoning-full.md` (if it exists) as deeper history.
   - The current `traffic-light.md` and `interruption-log.md` paths so the subagent knows where to read and write.
2. **On return** — The orchestrator expects TWO things from the subagent:
   - A short summary message in the chat reply.
   - The path to its updated `summary.md` (and confirmation that `reasoning-full.md` was written).
3. **On aggregation** — The orchestrator reads each `summary.md` and synthesizes them into one response to delivery. It does NOT inline `reasoning-full.md`; that file stays on disk for the session-archiver and future sessions.
4. **On re-release** — If a subagent must be called again, the orchestrator passes the freshly written `summary.md` path as resume context. This gives the subagent the latest state without re-running past work.

The orchestrator should also remind each subagent (in the release prompt) to read `traffic-light.md` and `interruption-log.md` between every tool call, and to write `reasoning-full.md` incrementally and `summary.md` at completion.

## How `session-archiver` Consumes the Memory Files

The `session-archiver` skill is the distillation partner of this protocol. When a session closes:

1. The session-archiver reads every `agents/{name}/reasoning-full.md` in the session.
2. It synthesizes a `session-digest.md` at the session root with:
   - Decisions made (cross-agent)
   - Lessons learned (cross-agent)
   - Open questions
   - Links to each `summary.md` (so the per-agent executive view is reachable)
3. It marks each `reasoning-full.md` as archived (prepend a `<!-- archived: {timestamp} -->` comment) so future sessions do not re-read stale chains of thought.
4. It preserves `summary.md` files as the resume anchors for the next session.

The interruption protocol and the session-archiver together form a complete write/distill cycle: subagents write `reasoning-full.md` and `summary.md` during work, and the archiver distills the reasoning files into a single digest at session close.

## Quick Reference

| You are the... | Read | Write |
|---|---|---|
| Delivery (interruption arrives) | `interruption-log.md` (append row reference) | `traffic-light.md`, `interruption-log.md` |
| Orchestrator (releasing subagent) | previous `summary.md` if present | new rows in `traffic-light.md` |
| Orchestrator (aggregating) | every `summary.md` | nothing (read-only aggregation) |
| Subagent (before major step) | `traffic-light.md`, `interruption-log.md` | `agents/{name}/reasoning-full.md` (incremental) |
| Subagent (at completion or pause) | same as above | `agents/{name}/summary.md`, final `reasoning-full.md` |

## Notes

- The protocol is file-based by design: it survives LLM non-determinism and works even if the model does not print a pause marker.
- All paths in this protocol are relative to the active session root. The delivery agent resolves the absolute path and tells each subagent in its release prompt.
- Human-injected messages are translated to English by the delivery agent before being logged. The subagents never receive the human's source language.
- The protocol is additive: existing agents can be migrated one at a time. The strategic-pause mechanism in the orchestrator remains valid; the interruption protocol augments it.
