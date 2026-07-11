# Agent Protocols

Reusable conventions that govern **how the agent system operates**. These are not project facts — they describe the internal machinery: how prompts are analyzed, how scope is reduced, how subagents coordinate, how sessions close, etc.

If a document mixes agent behavior with project facts, split it: agent behavior lives here, project facts live in `docs/protocols/`.

## Index

| Protocol | Purpose | Who reads it |
|---|---|---|
| [`canonical-prompter.md`](./canonical-prompter.md) | Phase 1 of the delivery pipeline. Analyzes raw prompts: term resolution, classification, module identification, hint extraction, acceptance criteria, edge cases, clarification decision. | `delivery` (Phase 1) |
| [`context-reductor.md`](./context-reductor.md) | Phase 2 of the delivery pipeline. Identifies scope, evaluates complexity (Baja→Muy Alta), detects hot spots, surfaces hidden assumptions, defines verification path. | `delivery` (Phase 2) |
| [`session-archiver.md`](./session-archiver.md) | Closes a session by reading the durable `Subagent.*` and `Step.*` event stream from EventV2 (SQLite) and producing a single cross-agent `session-digest.md`. | `delivery` (on session close) |
| [`sessions-setup.md`](./sessions-setup.md) | Opencode home bootstrap (`~/.config/opencode/`) and session-structure conventions. Includes `humano.md` and `project.md` two-tier policies. | `delivery`, `project-context` |
| [`doc-maintainer.md`](./doc-maintainer.md) | Documentation health checks: broken links, code-doc consistency, duplicate content, content placement, dead references. | `project-context`, `documenter` |
| [`agent-installer.md`](./agent-installer.md) | Install and reconfigure the agent system in a repo via the 4-phase installer script. | `delivery` (when human asks to install/update the agent) |

## Built-in protocols (from opencode runtime)

_(none — all opencode runtime skills have been replaced by project protocols, agent protocols, or on-demand `docs/context/` reads. The "customize-opencode" skill is also being migrated to a different mechanism.)_

## On-demand context (not a protocol)

Some topics are **not codified as protocols or skills** — they live as scattered info in `docs/context/` and the agent reads them on demand when the task requires it:

- **SQLite + Drizzle best practices** — Drizzle conventions, snake_case column names (see `AGENTS.md` Schema Definitions section), indexes, soft deletes, migrations, and the Session/Prompt/Permission schema design. The relevant files are `AGENTS.md`, `packages/core/src/storage/`, and `packages/schema/src/`. The agent reads them when working on queries, migrations, or schema design. There is no preloaded skill for this; the data is in the repo, not in a runtime tool.
- **Permission system** — atomic permissions design and the durable permission model. The design lives next to the code at `packages/core/src/permission/` (and the `Permission` / `PermissionSaved` schemas in `packages/schema/src/`); there is no `docs/context/permission-architecture.md` or `docs/context/permission-troubleshooting.md`. The agent reads these files on demand when the task involves permissions. There is no preloaded skill; the data is in the repo.

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
- The information is one-time reference (HTTP status codes, error catalog) → use `docs/context/`.
