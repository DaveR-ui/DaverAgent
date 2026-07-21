# Agent Protocols

Reusable conventions that govern **how the agent system operates**. These are not project facts — they describe the internal machinery: how prompts are analyzed, how subagents coordinate, etc.

If a document mixes agent behavior with project facts, split it: agent behavior lives here, project facts live in `docs/context/`.

## Skill Migration Redirect

All former repo-local skills have been migrated to agent protocols. The `.opencode/skills/` directory does not exist and should not be created. If the opencode runtime lists skills in `available_skills` pointing to `.opencode/skills/*/SKILL.md`, those are phantom entries from a previous installation.

Phase 1 (Normalize) is now executed by the [`interpreter`](../agents/subagents/interpreter.md) subagent as Step 0. Phase 2 (Reduce) is described by the `prompt-pipeline` protocol (see below).

| Former Skill / Protocol | Status |
|---|---|
| `canonical-prompter` | **Replaced** by [`.opencode/agents/subagents/interpreter.md`](../agents/subagents/interpreter.md) (Step 0) |
| `context-reductor` | **Merged** into [`.opencode/protocols/prompt-pipeline.md`](./prompt-pipeline.md) (Phase 2) |
| `api-endpoint-factory` | Project protocol: [`docs/protocols/api-endpoint-factory.md`](../../docs/protocols/api-endpoint-factory.md) |
| `supabase-postgres-best-practices` | On-demand read from `docs/context/` — no preloaded protocol |
| `customize-opencode` | Built-in opencode runtime skill (not repo-local) |

## Index

| Protocol | Purpose | Who reads it |
|---|---|---|
| [`prompt-pipeline.md`](./prompt-pipeline.md) | Two-stage analysis convention for non-trivial prompts. Step 0 (Interpret) is delegated to the `interpreter` subagent. Phase 2 (Reduce) defines scope, complexity, hot spots, and verification path. | `delivery` (every non-trivial prompt) |
| [`agent-installer.md`](./agent-installer.md) | Install and reconfigure the agent system in a repo via the 4-phase installer script. | `delivery` (when human asks to install/update the agent) |
| [`broad-investigation-template.md`](./broad-investigation-template.md) | Compact 5-section scaffold (Goal / Search Strategy / Evidence / Coverage / DoD) for prompts that map, inventory, or audit a class of thing across the repo. Use when coverage > speed. | `orchestrator`, `explorer` |

## Built-in protocols (from opencode runtime)

_(none — all opencode runtime skills have been replaced by agent protocols or on-demand `docs/context/` reads. The "customize-opencode" skill is built into the opencode runtime itself.)_

## On-demand context (not a protocol)

Some topics are **not codified as protocols** — they live as scattered info in `docs/context/` and the agent reads them on demand when the task requires it:

- **Postgres / GORM best practices** — GORM conventions, indexes, soft deletes, error mapping. The relevant files are `docs/context/architecture.md` and `docs/context/rules.md`.
- **Permission system** — atomic permissions design (bitmask, BIGINT, role_permissions, user_permissions, cache invalidation by version, RequirePermission middleware). The design lives in `docs/context/permission-architecture.md`.

## How protocols relate to the rest of `.opencode/`

| Folder | Role |
|---|---|
| `protocols/` (this folder) | **Conventions, templates, and procedures** the agent reads as reference. |
| `workflows/` | **Thinking instructions** the agent applies before acting (e.g. `orchestrate.md`). |
| `agents/` | Agent **definitions** (per-agent system prompt, permissions, tools). |
| `docs/` | Reference documentation for subagents. |

## When to add a new agent protocol

- The information describes how the **agent system** coordinates or stays consistent.
- The information would be the same regardless of which project the agent is working on.
- A future agent (or human) would re-derive the same behavior if the protocol didn't exist.

## When NOT to add an agent protocol

- The information is about the **project's stack, layers, or naming** -> use `docs/context/`.
- The information tells the agent **how to think before acting** -> use `.opencode/workflows/`.
- The information is one-time reference (HTTP status codes, error catalog) -> already lives in `docs/context/`.
