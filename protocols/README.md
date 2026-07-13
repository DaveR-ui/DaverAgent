# Agent Protocols

Reusable conventions that govern **how the agent system operates**. These are not project facts — they describe the internal machinery: how prompts are analyzed, how scope is reduced, how subagents coordinate, how sessions close, etc.

If a document mixes agent behavior with project facts, split it: agent behavior lives here, project facts live in `docs/context/`.

## Skill Migration Redirect

All former repo-local skills have been migrated to agent protocols. The `.opencode/skills/` directory does not exist and should not be created. If the opencode runtime lists skills in `available_skills` pointing to `.opencode/skills/*/SKILL.md`, those are phantom entries from a previous installation.

| Former Skill | Canonical Protocol |
|---|---|
| `canonical-prompter` | [`.opencode/protocols/canonical-prompter.md`](./canonical-prompter.md) |
| `context-reductor` | [`.opencode/protocols/context-reductor.md`](./context-reductor.md) |
| `doc-maintainer` | [`.opencode/protocols/doc-maintainer.md`](./doc-maintainer.md) |
| `interruption-protocol` | [`.opencode/protocols/interruption.md`](./interruption.md) |
| `session-archiver` | [`.opencode/protocols/session-archiver.md`](./session-archiver.md) |
| `sessions-setup` | [`.opencode/protocols/sessions-setup.md`](./sessions-setup.md) |
| `api-endpoint-factory` | [`docs/protocols/api-endpoint-factory.md`](../../docs/protocols/api-endpoint-factory.md) (project protocol) |
| `supabase-postgres-best-practices` | On-demand read from `docs/context/` — no preloaded skill or protocol |
| `customize-opencode` | Built-in opencode runtime skill (not repo-local) |

## Index

| Protocol | Purpose | Who reads it |
|---|---|---|
| [`canonical-prompter.md`](./canonical-prompter.md) | Phase 1 of the delivery pipeline. Analyzes raw prompts: term resolution, classification, module identification, hint extraction, acceptance criteria, edge cases, clarification decision. | `delivery` (Phase 1) |
| [`context-reductor.md`](./context-reductor.md) | Phase 2 of the delivery pipeline. Identifies scope, evaluates complexity (Baja→Muy Alta), detects hot spots, surfaces hidden assumptions, defines verification path. | `delivery` (Phase 2) |
| [`session-archiver.md`](./session-archiver.md) | Closes a session by reading the durable `Subagent.*` and `Step.*` event stream from EventV2 (SQLite) and producing a single cross-agent `session-digest.md`. | `delivery` (on session close) |
| [`sessions-setup.md`](./sessions-setup.md) | Opencode home bootstrap (`~/.config/opencode/`) and session-structure conventions. Includes `humano.md` and `project.md` two-tier policies. | `delivery`, `project-context` |
| [`doc-maintainer.md`](./doc-maintainer.md) | Documentation health checks: broken links, code-doc consistency, duplicate content, content placement, dead references. | `project-context`, `documenter` |
| [`agent-installer.md`](./agent-installer.md) | Install and reconfigure the agent system in a repo via the 4-phase installer script. | `delivery` (when human asks to install/update the agent) |
| [`broad-investigation-template.md`](./broad-investigation-template.md) | Compact 5-section scaffold (Goal / Search Strategy / Evidence / Coverage / DoD) for prompts that map, inventory, or audit a class of thing across the repo. Use when coverage > speed. | `orchestrator`, `explorer` |

## Built-in protocols (from opencode runtime)

_(none — all opencode runtime skills have been replaced by project protocols, agent protocols, or on-demand `docs/context/` reads. The "customize-opencode" skill is also being migrated to a different mechanism.)_

## On-demand context (not a protocol)

Some topics are **not codified as protocols or skills** — they live as scattered info in `docs/context/` and the agent reads them on demand when the task requires it:

- **Postgres / SQL best practices** — GORM conventions, indexes, soft deletes, error mapping, BIGINT bitmask for permissions. The relevant files are `docs/context/architecture/architecture.md` and `docs/context/conventions/project-rules.md`. The agent reads them when working on queries, migrations, or schema design. There is no preloaded skill or protocol for this; the data is in the repo, not in a runtime tool.
- **Permission system** — atomic permissions design (bitmask, BIGINT, role_permissions, user_permissions, cache invalidation by version, RequirePermission middleware). The full design lives in `docs/context/auth-identity/security-permissions.md`. The agent reads it on demand when the task involves permissions. There is no preloaded skill or protocol; the data is in the repo.

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

- The information is about the **project's stack, layers, or naming** → use `docs/context/`.
- The information tells the agent **how to think before acting** → use `.opencode/workflows/`.
- The information is one-time reference (HTTP status codes, error catalog) → use `docs/context/`.
