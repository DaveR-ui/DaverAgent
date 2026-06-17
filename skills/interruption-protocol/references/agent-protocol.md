# Agent Interruption Protocol — Full Reference

This is the canonical reference for the file-based interruption protocol. Every agent in this project MUST follow it. The orchestrator and delivery agents coordinate; subagents execute.

## Overview

The protocol lets the human steer a running subagent by writing to two files in the session root:

- `traffic-light.md` — semáforo (🟢🟡🔴⚪) per agent
- `interruption-log.md` — append-only log of interventions

The human cannot reach the subagent directly through the chat. The orchestrator forwards by:
- Translating the human's message to English (delivery)
- Appending to `interruption-log.md` with `[HUMAN]` prefix
- Updating `traffic-light.md` (targeted agent → 🔴 RED, or all active → 🟡 YELLOW as default safe)
- Letting the subagent reach its next checkpoint (no abort)

The subagent reads both files at each checkpoint, acts on the semáforo, and acknowledges the hint by writing back to the log with its actor tag.

## Checkpoint schedule (all agents)

Before EACH of the following, READ both `../../traffic-light.md` and `../../interruption-log.md` (paths are relative to your `agents/{name}/` directory, i.e. the session root):

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

## Memory artifacts (per agent)

### `agents/{name}/reasoning-full.md` — required for write-capable agents only

Free-form chain of thought: considerations, alternatives, doubts, tool call log, errors, files touched, interruptions handled. Written incrementally and at completion.

### `agents/{name}/summary.md` — required for ALL agents

A 10-30 line executive summary written at the END of the subagent's work or when it pauses. Contains:

- Status (success / partial / paused / failed)
- What was done (1-3 bullets, executive level)
- Artifacts created (file paths)
- Files modified (file paths with brief description)
- Key decisions (any non-obvious choices)
- Open questions / next steps
- Link to `reasoning-full.md`

### Read-only agents (explorer, reviewer, angular-expert)

You do NOT write `reasoning-full.md` (you did not modify code). Write ONLY `summary.md` with: status, what you found (1-3 bullets), file paths and line numbers, key observations, open questions.

## End-of-work return format

After writing your memory files, return to the orchestrator with exactly this format:

- Write-capable: `"Work complete. Summary: agents/{name}/summary.md | Full reasoning: agents/{name}/reasoning-full.md"`
- Read-only: `"Work complete. Summary: agents/{name}/summary.md"`

## On resumption

If the orchestrator releases you with a previous `summary.md` path, READ it first to understand the state. Treat it as your starting point; do not redo work that is already summarized as complete.

## Special: Delivery (bootstrap)

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

On session close, if `humano.md` has `Distillation on session close: enabled`, delivery invokes the `session-archiver` skill.

## Special: Orchestrator (coordination)

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
| Delivery (interrupt) | `interruption-log.md` (append row) | `traffic-light.md`, `interruption-log.md` |
| Orchestrator (release) | previous `summary.md` if present | `traffic-light.md` (🟢) |
| Orchestrator (aggregate) | every `summary.md` | `traffic-light.md` (⚪) |
| Subagent (checkpoint) | `traffic-light.md`, `interruption-log.md` | `agents/{name}/reasoning-full.md` (incremental) |
| Subagent (complete/pause) | same as above | `agents/{name}/summary.md`, final `reasoning-full.md` |
