# Agent Protocols

Reusable conventions that govern **how the agent system operates**. These are not project facts — they describe the internal machinery: how prompts are analyzed, how subagents coordinate, etc.

If a document mixes agent behavior with project facts, split it: agent behavior lives here, project facts live in `docs/context/`.

## Skill Migration Redirect

All former repo-local skills have been migrated to agent protocols. A repo-local `skills/` directory does not exist here and should not be created. If the opencode runtime lists skills in `available_skills` pointing to agent-system `skills/*/SKILL.md` paths, those are phantom entries from a previous installation.

Step 0 (Normalize) is now executed by the [`interpreter`](../agents/interpreter.md) subagent. Phase 2 (Reduce) is described by the `prompt-pipeline` protocol (see below).

| Former Skill / Protocol | Status |
|---|---|
| `canonical-prompter` | **Replaced** by [`agents/interpreter.md`](../agents/interpreter.md) (Step 0) |
| `context-reductor` | **Merged** into [`protocols/prompt-pipeline.md`](./prompt-pipeline.md) (Phase 2) |
| `api-endpoint-factory` | Project protocol: `docs/protocols/api-endpoint-factory.md` (per project) |
| `supabase-postgres-best-practices` | On-demand read from `docs/context/` — no preloaded protocol |
| `customize-opencode` | Built-in opencode runtime skill (not repo-local) |

## Index

| Protocol | Purpose | Who reads it |
|---|---|---|
| [`prompt-pipeline.md`](./prompt-pipeline.md) | Two-stage analysis convention that runs on EVERY prompt. Step 0 (Interpret) is delegated to the `interpreter` subagent — no prompt skips it. Phase 2 (Reduce) defines scope, complexity, hot spots, and verification path. | `delivery` (every prompt) |
| [`session-recovery.md`](./session-recovery.md) | Recovery flow for interrupted or STUCK sessions in the delivery→orchestrator→subagent hierarchy. Covers the 3 failure modes (delivery/orchestrator/child), opencode session API usage, and the `## Resume instructions (if restart)` handoff contract. | `delivery` (on STUCK), `orchestrator` (on cancellation) |
| [`broad-investigation-template.md`](./broad-investigation-template.md) | Compact 5-section scaffold (Goal / Search Strategy / Evidence / Coverage / DoD) for prompts that map, inventory, or audit a class of thing across the repo. Use when coverage > speed. | `orchestrator`, `explorer` |
| [`subagent-spec-template.md`](./subagent-spec-template.md) | Canonical shape for subagent specs: structural/variable split (parent subagent vs. per-specialization template), frontmatter spec, full vs. minimal shape, `output_schema` ↔ sibling schema bridge, composition and naming rules, the reduced role of `opencode.json`. | `orchestrator`, `delivery` (when creating or auditing subagents) |
| [`approval-gate.md`](./approval-gate.md) | Canonical propose → approve → execute rule for irreversible, secret-bearing, outward-facing, or config-mutating actions. The `delivery` review loop and the orchestrator Hard Limits are instances of it. | `delivery`, `orchestrator` (on any gated action) |
| [`task-plan.md`](./task-plan.md) | Machine-checkable JSON task plan: dependencies, parallelism, `suggested_agent` vs. `agent_id`, and `context_files` (standards) vs. `reference_files` (source). Executable form of the Phase 2 (Reduce) decomposition. | `orchestrator` (before releasing subagents) |

## Installer protocol (retired 2026-09-18)

The `agent-installer` protocol, `install.md`, `scripts/bootstrap.sh` and the
`templates/project-opencode.json` per-project shim were retired. The global
config is now installed by copying this folder to `~/.config/opencode`; a
project's `docs/` are authored by hand following the `documenter` subagent and
checked with the derived `templates/docs-validate.js`. See
[`readme.md`](../readme.md#install-per-machine).

## Former IA pipeline protocols (retired 2026-08-24)

The 4 retired protocols (`ia-learner`, `ia-catalog-manager`, `ia-docs-gen`, `ia-dev`) and their `references/p3-ia-dev/` material were consolidated on 2026-08-24. The core pipeline stages they documented (analyzer → explorer → supplier → proposer → verifier) and the supporting pruner/search/skill-creator/sync-checker were already removed on 2026-08-09 — native equivalents now cover them (interpreter ≈ analyzer, explorer ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline Phase 2 ≈ proposer, project-context ≈ supplier). Durable content was salvaged: catalog registry/Safety Guard/link-validation → `documenter` subagent, docs-gen frontmatter/component format → `docs/context/doc-conventions.md`; learner relevance filter retired (superseded by prompt-pipeline hot spots). Canonical shape is `subagent-spec-template.md`.

## Built-in protocols (from opencode runtime)

_(none — all opencode runtime skills have been replaced by agent protocols or on-demand `docs/context/` reads. The "customize-opencode" skill is built into the opencode runtime itself.)_

## On-demand context (not a protocol)

Some topics are **not codified as protocols** — they live as scattered info in `docs/context/` and the agent reads them on demand when the task requires it:

- **Database / ORM best practices** — the ORM conventions, indexes, soft deletes, error mapping. The relevant files are `docs/context/architecture.md` and `docs/context/rules.md`.
- **Permission system** — atomic permissions design (bitmask, BIGINT, role_permissions, user_permissions, cache invalidation by version, RequirePermission middleware). The design lives in `docs/context/permission-architecture.md`.

## How protocols relate to the rest of the agent system

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
- The information tells the agent **how to think before acting** -> use `workflows/`.
- The information is one-time reference (HTTP status codes, error catalog) -> already lives in `docs/context/`.
