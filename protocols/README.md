# Agent Protocols

Reusable conventions that govern **how the agent system operates**. These are not project facts — they describe the internal machinery: how prompts are analyzed, how scope is reduced, how subagents coordinate, how sessions close, etc.

If a document mixes agent behavior with project facts, split it: agent behavior lives here, project facts live in `docs/protocols/`.

## Index

| Protocol | Purpose | Who reads it |
|---|---|---|
| [`canonical-prompter.md`](./canonical-prompter.md) | Phase 1 of the delivery pipeline. Analyzes raw prompts: term resolution, classification, module identification, hint extraction, acceptance criteria, edge cases, clarification decision. | `delivery` (Phase 1) |
| [`context-reductor.md`](./context-reductor.md) | Phase 2 of the delivery pipeline. Identifies scope, evaluates complexity (Baja→Muy Alta), detects hot spots, surfaces hidden assumptions, defines verification path. | `delivery` (Phase 2) |
| [`interruption.md`](./interruption.md) | File-based pause/resume bus (`traffic-light.md` + `interruption-log.md`) and per-agent memory (`reasoning-full.md` + `summary.md`). Semáforo states and checkpoint schedule. | every subagent |
| [`session-archiver.md`](./session-archiver.md) | Closes a session by reading every per-agent `reasoning-full.md` and producing a single cross-agent `session-digest.md`. | `delivery` (on session close) |
| [`sessions-setup.md`](./sessions-setup.md) | Opencode home bootstrap (`~/.config/opencode/`) and session-structure conventions. Includes `humano.md` and `project.md` two-tier policies. | `delivery`, `project-context` |
| [`doc-maintainer.md`](./doc-maintainer.md) | Documentation health checks: broken links, code-doc consistency, duplicate content, content placement, dead references. | `project-context`, `documenter` |
| [`agent-installer.md`](./agent-installer.md) | Install and reconfigure the agent system in a repo via the 4-phase installer script. | `delivery` (when human asks to install/update the agent) |
| [`slice-complexity-ladder.md`](./slice-complexity-ladder.md) | Phase 3 of the delivery pipeline. Climbs a 6-rung ladder (R0 SKIP → R5 CRITICAL) to assign complexity level per slice and determine agent routing, model selection, and human gates. Consumes `context-reductor` output. | `delivery`, `orchestrator` |

## Built-in protocols (from opencode runtime)

_(none — all opencode runtime skills have been replaced by project protocols, agent protocols, or on-demand context doc reads (see `.opencode/conventions.md`). The "customize-opencode" skill is also being migrated to a different mechanism.)_

## On-demand context (not a protocol)

Some topics are **not codified as protocols or skills** — they live as scattered info in the context docs (see `.opencode/conventions.md`) and the agent reads them on demand when the task requires it:

- **Database / ORM conventions** — query patterns, indexes, migrations, error mapping. The relevant files are in the context docs (architecture, rules, etc.). The agent reads them when working on queries, migrations, or schema design. There is no preloaded skill for this; the data is in the repo, not in a runtime tool.
- **Subsystem-specific architecture** — e.g., permission system, billing, auth. The full design lives in context doc files. The agent reads them on demand when the task involves that subsystem. There is no preloaded skill; the data is in the repo.

## How protocols relate to the rest of `.opencode/`

| Folder | Role |
|---|---|
| `protocols/` (this folder) | **Conventions, templates, and procedures** the agent reads as reference. |
| `workflows/` | **Thinking instructions** the agent applies before acting (e.g., `orchestrate.md`). |
| `context/` | **Strategic docs** about the opencode home itself (rarely changed). |
| `agents/` | Agent **definitions** (per-agent system prompt, permissions, tools). |
| `docs/` | Reference documentation for the three expert subagents. |

## When to add a new agent protocol

- The information describes how the **agent system** coordinates, persists state, or stays consistent.
- The information would be the same regardless of which project the agent is working on.
- A future agent (or human) would re-derive the same behavior if the protocol didn't exist.

## When NOT to add an agent protocol

- The information is about the **project's stack, layers, or naming** → use `docs/protocols/`.
- The information tells the agent **how to think before acting** → use `.opencode/workflows/`.
- The information is one-time reference (HTTP status codes, error catalog) → use the context docs (see `.opencode/conventions.md`).
