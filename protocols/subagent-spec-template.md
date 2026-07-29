# Protocol: Subagent Spec Template

Canonical shape for subagent definitions under `.opencode/agents/subagents/`. Read this before creating a new subagent, auditing an existing one, or scaffolding subagents from the installer (Phase 4 of `agent-installer.md`).

> Design decisions ratified by the human on 2026-07-29 (orchestrator instance `subagent-spec-template-001`, CHECKPOINT 1).
> Centralization (frontmatter as the single source of truth for per-agent config; sibling `<id>.schema.json` files; `opencode.json` reduced to top-level runtime config) ratified on 2026-07-29 (orchestrator instance `centralize-002`).

## Purpose

One canonical shape for every subagent spec, so that:

1. The orchestrator, the installer, and human reviewers can rely on a predictable structure.
2. The agent system can be **specialized per language / stack in the future without duplicating structural content**: structural content lives in the **parent subagent**, variable content lives in a **per-specialization template**.

> A language-specialized subagent = parent + template, composed into a single file.

## The structural / variable split

| Parent subagent — STRUCTURAL (invariant across specializations) | Template — VARIABLE (per specialization) |
|---|---|
| Frontmatter | `## Stack / Context` |
| `## Role` | `## Standards` |
| `## Scope` | `## Anti-Patterns` |
| `## Structured Return` | Role-specific **knowledge** sections (e.g. a future `## Reference Catalog`) |
| `## Rules` | |
| Role-specific **operational** sections | |

### Operational vs. knowledge role-specific sections

- **Operational (stay in the parent)** — describe HOW the role operates; they do not change with the language or stack:
  - `## Sampling and Fan-out` (`explorer`, `reviewer`)
  - `## Read/Write Workflow` (`project-context`)
  - `## Contract`, `## Model`, `## When to use` / `## When NOT to use` (`vision-relay`, `external-scout`)
- **Knowledge (live in the template)** — describe WHAT the role must know about a stack; they change per specialization:
  - Stack facts, versions, doc pointers, coding standards, anti-patterns, reference catalogs.

Rationale: a future `explorer.typescript` fans out exactly like the base `explorer`; putting fan-out rules in each language template would invite drift between specializations.

## Frontmatter spec

| Field | Status | Notes |
|---|---|---|
| `description` | **required** | One line, routing-oriented — the orchestrator reads this to decide delegation. Name the discipline, the accepted task shapes, and the structured return if any. |
| `mode: subagent` | **required** | Literal value. |
| `model` | **required** | Fully qualified (`<provider>/<model>`). Part of the cost contract — see the orchestrator's subagent table. |
| `temperature` | optional | Omit when the model ignores it (e.g. `kimi-k3` — see `.opencode/llm-reference.md`). |
| `tools` | optional | Tool allow/deny map. |
| `permission` | optional | Permission rules (e.g. read-only adapters, `task` fan-out grants). |
| `output_schema` | optional | Relative path to the sibling JSON Schema (`./<id>.schema.json`) — see the bridge below. |

## Canonical full shape

Body sections, in canonical order:

1. `## Role` — who the agent is (1–3 sentences). The H1 title plus a short preamble may sit above it.
2. `## Scope` — the accept / decline contract: which task shapes it takes, which it re-routes (and to whom).
3. `## Stack / Context` — knowledge: stack facts, versions, project-doc pointers.
4. `## Standards` — checklists, principles, definitions of done.
5. `## Anti-Patterns` — what to avoid, phrased as prohibitions with brief reasons.
6. *(slot)* Role-specific sections, if any: operational ones in every specialization, knowledge ones only inside a template.
7. `## Structured Return` — the output contract (see the bridge below).
8. `## Rules` — hard behavioral rules, terse, one per line.

Existing sections keep working names where renaming adds no value (e.g. reviewer's `## Checklist` serves as `## Standards`; the audit harmonizes, it does not churn).

## Minimal shape (thin adapters)

A subagent that is a **thin adapter over a single capability** — no `output_schema`, contract fits in ~50 lines — MAY use the reduced form:

- Frontmatter (per the spec above)
- `## Contract` — role and scope merged
- `## When to use` / `## When NOT to use`
- `## Model`

Current minimal-shape subagents: `vision-relay`, `external-scout`. The minimal shape is an **explicit alternative, not a degenerate case** — do not force the 7-section form onto thin adapters.

## The `output_schema` ↔ sibling schema bridge

- The schema lives in a **sibling file** `.opencode/agents/subagents/<id>.schema.json`, referenced from the subagent's frontmatter via `output_schema: ./<id>.schema.json`. The `.md` frontmatter is the single source of truth — `opencode.json` carries no per-agent config.
- The subagent's `## Structured Return` section documents the JSON shape, names the schema, shows an example, and points at the sibling file.
- The two MUST stay in sync: change one, change the other. The installer (Phase 4) generates both from the same answer set.
- Subagents without an `output_schema` return plain text (or markdown); their `## Structured Return` (full shape) or `## Contract` (minimal shape) describes the expected return in prose. Current subagents without a schema: `project-context`, `vision-relay`, `external-scout`.
- The task tool validates the return against the schema; on mismatch it prepends a validation warning and keeps the raw text. Never write `summary.md` / `output-full.md` / `manifest.md` to disk — the runtime captures returns on the EventV2 bus.

## `opencode.json` — reduced role (top-level runtime config only)

Per the 2026-07-29 centralization, `opencode.json` carries **top-level runtime config only**: `$schema`, `default_agent`, `subagent_depth`, `small_model`, `compaction`, `plugin`, global `permission`, `instructions`. The `agent` block is removed.

Every per-agent field lives in the agent's `.md` frontmatter instead:

| Field | Home |
|---|---|
| `description`, `mode`, `model`, `temperature`, `tools`, per-agent `permission` | The agent `.md` frontmatter |
| `output_schema` | Frontmatter path → sibling `<id>.schema.json` |
| `permission.task` fan-out (which subagents `delivery` / `orchestrator` may call) | Frontmatter of `delivery.md` / `orchestrator.md` |
| Global `permission` rules | Stay in `opencode.json` |

Rationale: the `.md` is the canonical artifact the runtime loads; one source of truth eliminates frontmatter↔JSON drift, and a self-contained agent folder drops into any compatible runtime.

## Naming convention for specializations

- Parent keeps the plain role name: `coder.md`.
- Template / specialization: `<role>.<specialization>.md` — e.g. `coder.typescript.md`, `reviewer.python.md`.

## Worked example: `coder.md` + `coder.typescript.md` (documented future — no template file exists yet)

```
coder.md (parent — structural)           coder.typescript.md (template — variable)
────────────────────────────────         ──────────────────────────────────────────────
frontmatter: model, tools, mode          ## Stack / Context   → TypeScript ~5.9, Angular 21,
## Role      — implementation specialist    RxJS 7.8, docs/context/architecture.md
## Scope     — 2 accepted task shapes    ## Standards         → Signals-first, OnPush,
## Structured Return — CoderOutput          standalone, rxResource for loading
## Rules                                 ## Anti-Patterns     → any, setTimeout-for-sync,
                                             NGRX-first, skipping debugName
```

Composed `coder.typescript` subagent (one file), sections in canonical order:

```
frontmatter (parent's; model/temperature may be overridden)
## Role                  (verbatim from parent)
## Scope                 (verbatim from parent)
## Stack / Context       (from template)
## Standards             (from template)
## Anti-Patterns         (from template)
## Structured Return     (verbatim from parent; schema in sibling <id>.schema.json)
## Rules                 (verbatim from parent)
```

## Composition rules (documented future)

1. A specialized subagent file = the parent's structural sections **verbatim** + the template's variable sections, ordered per the canonical full shape above.
2. Structural sections are **inherited, not copied-and-edited**: if a structural section must change, change the parent and re-compose every specialization.
3. Template resolution: `<role>.<specialization>.md` composes with `<role>.md`. **No runtime implementation exists yet** — this protocol fixes only the boundary. When the first template is introduced, decide storage (suggestion: `.opencode/agents/templates/`, not auto-loaded) and the composition mechanism (installer Phase 4 is the natural place).
4. Frontmatter composition: the child template's frontmatter **wins over the parent's for any field it declares**; undeclared fields are inherited from the parent. (`mode: subagent` and the `output_schema` bridge are normally inherited, not overridden.)

## Dual-file convention (pre-existing, not unified by this protocol)

Some subagents declare a runtime-loaded twin at `.opencode/agents/<id>.md` (twins currently exist for `coder`, `architect`, `interpreter`, `vision-relay`). The declared relationship varies per file (e.g. `subagents/coder.md` claims to be the canonical spec from which the installer regenerates the top level; `subagents/vision-relay.md` declares the top level canonical). When editing a `subagents/` file that declares a twin, **check the twin and keep them consistent**; flag drift to the human instead of silently propagating.

## Audit results — 2026-07-29

Status of the 10 subagents under `.opencode/agents/subagents/` after the canonical-shape audit (Phase B of the same change that introduced this protocol):

| Subagent | Shape | Gaps found (before) | Status (after) |
|---|---|---|---|
| `architect` | full | Missing Role, Scope, Anti-Patterns; Principles served as Standards; context inline | Canonical |
| `coder` | full | Missing Role; stale "Go implementation" reference in description (Q3 fix) | Canonical |
| `documenter` | full | Missing Role, Stack / Context, Standards | Canonical |
| `explorer` | full | Missing Role, Scope, Anti-Patterns; stale opencode-monorepo references (Q3 fix) | Canonical |
| `external-scout` | minimal | — (thin adapter) | Minimal |
| `interpreter` | full | Missing Role, Scope (partial in "When you are called"), Stack / Context, Standards, Anti-Patterns | Canonical |
| `project-context` | full | Missing Role, Scope, Standards, Anti-Patterns; text return undocumented | Canonical |
| `reviewer` | full | Missing Role, Scope, Anti-Patterns; Stack / Context partial | Canonical |
| `tester` | full | Missing Role, Scope, Anti-Patterns; Stack / Context partial | Canonical |
| `vision-relay` | minimal | — (thin adapter) | Minimal |

## Audit results — 2026-07-29 (centralization)

Frontmatter is now the single source of truth for per-agent config; `output_schema` moved from `opencode.json` name-strings into frontmatter paths pointing at sibling `<id>.schema.json` files; the `agent` block was removed from `opencode.json`; the `permission.task` fan-out for `delivery` / `orchestrator` lives in their frontmatter.

| Subagent | `permission` in frontmatter | `output_schema` in frontmatter | Sibling schema file |
|---|---|---|---|
| `coder` | ✅ | `./coder.schema.json` | batch 1 |
| `tester` | ✅ | `./tester.schema.json` | batch 1 |
| `reviewer` | ✅ | `./reviewer.schema.json` | batch 1 |
| `architect` | ✅ | `./architect.schema.json` | batch 2 |
| `explorer` | ✅ | `./explorer.schema.json` | batch 2 |
| `documenter` | ✅ | `./documenter.schema.json` (net-new) | batch 2 |
| `interpreter` | ✅ | `./interpreter.schema.json` (net-new) | batch 2 |
| `project-context` | ✅ | — (text return) | — |
| `vision-relay` | ✅ (tool allow/deny map) | — (text return) | — |
| `external-scout` | ✅ (tool allow/deny map) | — (text return) | — |

(Sibling schema files are generated in two batches — `coder`/`tester`/`reviewer` first for ratification, then `architect`/`explorer`/`documenter`/`interpreter`. Flip the "batch N" markers to ✅ once the files land.)

## Rules

- New subagents MUST follow this spec (full or minimal shape) from day one — the installer references this file as the Phase 4 shape authority.
- Audits fill missing sections with sensible content; they do NOT rewrite sections that already work.
- Structural edits to a parent that has (future) specializations require re-composing all of them.
- All `.opencode/` files in ENGLISH.
