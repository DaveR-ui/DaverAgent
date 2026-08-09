# Agent Protocols

Reusable conventions that govern **how the agent system operates**. These are not project facts — they describe the internal machinery: how prompts are analyzed, how subagents coordinate, etc.

If a document mixes agent behavior with project facts, split it: agent behavior lives here, project facts live in `docs/context/`.

## Skill Migration Redirect

All former repo-local skills have been migrated to agent protocols. The `.opencode/skills/` directory does not exist and should not be created. If the opencode runtime lists skills in `available_skills` pointing to `.opencode/skills/*/SKILL.md`, those are phantom entries from a previous installation.

Step 0 (Normalize) is now executed by the [`interpreter`](../agents/subagents/interpreter.md) subagent. Phase 2 (Reduce) is described by the `prompt-pipeline` protocol (see below).

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
| [`prompt-pipeline.md`](./prompt-pipeline.md) | Two-stage analysis convention that runs on EVERY prompt. Step 0 (Interpret) is delegated to the `interpreter` subagent — no prompt skips it. Phase 2 (Reduce) defines scope, complexity, hot spots, and verification path. | `delivery` (every prompt) |
| [`agent-installer.md`](./agent-installer.md) | Install and reconfigure the agent system in a repo via the 4-phase installer script. | `delivery` (when human asks to install/update the agent) |
| [`session-recovery.md`](./session-recovery.md) | Recovery flow for interrupted or STUCK sessions in the delivery→orchestrator→subagent hierarchy. Covers the 3 failure modes (delivery/orchestrator/child), opencode session API usage, and the `## Resume instructions (if restart)` handoff contract. | `delivery` (on STUCK), `orchestrator` (on cancellation) |
| [`broad-investigation-template.md`](./broad-investigation-template.md) | Compact 5-section scaffold (Goal / Search Strategy / Evidence / Coverage / DoD) for prompts that map, inventory, or audit a class of thing across the repo. Use when coverage > speed. | `orchestrator`, `explorer` |
| [`subagent-spec-template.md`](./subagent-spec-template.md) | Canonical shape for subagent specs: structural/variable split (parent subagent vs. per-specialization template), frontmatter spec, full vs. minimal shape, `output_schema` ↔ sibling schema bridge, composition and naming rules, the reduced role of `opencode.json`. | `orchestrator`, `delivery` (when creating or auditing subagents), installer Phase 4 |

## IA orchestration pipeline (transformed from `p3-ia-*` skills)

The 4 protocols below document the supporting roles of the original IA orchestration pipeline (catalog-manager, docs-gen, learner, dev). The core pipeline stages (analyzer → explorer → supplier → proposer → verifier) and the supporting pruner / search / skill-creator / sync-checker protocols were **removed on 2026-08-09** — the opencode runtime now provides native equivalents (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline Phase 2 ≈ proposer, project-context ≈ supplier). When a remaining protocol conflicts with an opencode native agent or protocol, the native one wins.

> These protocols were transformed on 2026-08-06 from the frontend skill tree at `frontend/.agents/skills/p3-ia-*/SKILL.md`. The entire `frontend/.agents/` tree (skills + legacy strategy) was removed on 2026-08-09; references to it in legacy docs are stale.

| Protocol | Purpose | Source skill |
|---|---|---|
| [`ia-learner.md`](./ia-learner.md) | Long-term learning. Converts session data (fixes, pivots, errors) into persistent architectural rules and learning logs, with a strict relevance filter that discards noise. | `p3-ia-learner` |
| [`ia-catalog-manager.md`](./ia-catalog-manager.md) | Unified CRUD for `docs/context/`, `docs/protocols/`, and `.opencode/protocols/`. Create, read, update, move/rename, or delete docs with automatic registry sync and link validation. | `p3-ia-catalog-manager` |
| [`ia-docs-gen.md`](./ia-docs-gen.md) | Standards for creating AI-optimized documentation: required frontmatter, the component-doc format, the skill-to-doc reference rule, and the index-registration checklist. | `p3-ia-docs-gen` |
| [`ia-dev.md`](./ia-dev.md) | Guidelines for designing and managing autonomous agents: triggering conditions, system-prompt structure, file layout, and the canonical subagent spec. Carries the original Claude-Code-derived reference material under [`references/p3-ia-dev/`](./references/p3-ia-dev/). | `p3-ia-dev` |

## Built-in protocols (from opencode runtime)

_(none — all opencode runtime skills have been replaced by agent protocols or on-demand `docs/context/` reads. The "customize-opencode" skill is built into the opencode runtime itself.)_

## On-demand context (not a protocol)

Some topics are **not codified as protocols** — they live as scattered info in `docs/context/` and the agent reads them on demand when the task requires it:

- **Database / ORM best practices** — the ORM conventions, indexes, soft deletes, error mapping. The relevant files are `docs/context/architecture.md` and `docs/context/rules.md`.
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
