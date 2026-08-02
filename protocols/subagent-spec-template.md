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
| `mode` | **required** | Literal value (`primary` for delivery, `subagent` for everything else). |
| `model` | **required** | Fully qualified (`<provider>/<model>`). Declared in the agent's frontmatter. Part of the cost contract — see the orchestrator's subagent table. |
| `temperature` | optional | Declared in the agent's frontmatter. Omit when the model ignores it (e.g. `kimi-k3`, kimi family). |
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

- The schema lives in a **sibling file** `.opencode/agents/subagents/<id>.schema.json`, referenced from the subagent's frontmatter via `output_schema: ./<id>.schema.json`. The `.md` frontmatter is the single source of truth for the return contract.
- The subagent's `## Structured Return` section documents the JSON shape, names the schema, shows an example, and points at the sibling file.
- The two MUST stay in sync: change one, change the other. The installer (Phase 4) generates both from the same answer set.
- Subagents without an `output_schema` return plain text (or markdown); their `## Structured Return` (full shape) or `## Contract` (minimal shape) describes the expected return in prose. Current subagents without a schema: `project-context`, `vision-relay`, `external-scout`.
- The task tool validates the return against the schema; on mismatch it prepends a validation warning and keeps the raw text. Never write `summary.md` / `output-full.md` / `manifest.md` to disk — the runtime captures returns on the EventV2 bus.

## `opencode.json` — top-level runtime knobs only

Since the 2026-07-29 centralization and the simplification ratified 2026-08-02, `opencode.json` carries **top-level runtime config only**: `$schema`, `default_agent`, `plugin`, `permission` (global), `instructions`, `references`, `compaction`. There is **no `agent` block** — every per-agent field (including `model` and `temperature`) lives in the agent's `.md` frontmatter.

Every per-agent field lives in the agent's `.md` frontmatter:

| Field | Home |
|---|---|
| `description`, `mode`, `model`, `temperature`, `permission` | The agent `.md` frontmatter |
| `output_schema` | Frontmatter path → sibling `<id>.schema.json` |
| `permission.task` fan-out (which subagents `delivery` / `orchestrator` may call) | Frontmatter of `delivery.md` / `orchestrator.md` |
| Global `permission` rules | Stay in `opencode.json` |

**To change a model or temperature**: edit the agent's frontmatter (`.opencode/agents/subagents/<id>.md`), then restart opencode. `opencode.json` is untouched.

Rationale: the `.md` is the canonical artifact the runtime loads; keeping `model`/`temperature` in the agent file makes each agent self-contained — one file to read for everything about that agent, with no frontmatter↔JSON drift. `opencode.json` shrinks to true runtime config.

## Naming convention for specializations

- Parent keeps the plain role name (e.g. `coder.md`).
- Template / specialization: `<role>.<specialization>.md` — e.g. `coder-angular.md`, `coder-go.md`.

## Realized example: `coder-angular.md` + `coder-go.md` (2026-08-02)

The first specialization landed on 2026-08-02 as **thin adapters** — each file is small, self-contained, and delegates stack knowledge to `docs/context/` instead of embedding it:

```
coder-angular.md                        coder-go.md
────────────────────────────           ─────────────────────────────
frontmatter: mode, tools,              frontmatter: mode, tools,
  permission, output_schema              permission, output_schema
## Stack / Context  → "Angular docs in ## Stack / Context  → "Go docs in
   docs/context/ are the source of truth" docs/context/ are the source of truth"
## Rules            → follow docs,       ## Rules            → follow docs,
   canonical commands, English            gofmt, canonical commands, English
## Structured Return → CoderOutput       ## Structured Return → CoderOutput
```

Both share the sibling schema `coder.schema.json` (`CoderOutput`). Model + temperature live in each coder's frontmatter (`model: opencode-go/kimi-k3`). The full parent/template **composition mechanism** (verbatim inheritance, runtime merge) remains documented future work — the thin-adapter form is the pattern used today.

## Composition rules (documented future)

1. A specialized subagent file = the parent's structural sections **verbatim** + the template's variable sections, ordered per the canonical full shape above.
2. Structural sections are **inherited, not copied-and-edited**: if a structural section must change, change the parent and re-compose every specialization.
3. Template resolution: `<role>.<specialization>.md` composes with `<role>.md`. **No runtime implementation exists yet** — this protocol fixes only the boundary. When the first template is introduced, decide storage (suggestion: `.opencode/agents/templates/`, not auto-loaded) and the composition mechanism (installer Phase 4 is the natural place).
4. Frontmatter composition: the child template's frontmatter **wins over the parent's for any field it declares**; undeclared fields are inherited from the parent. (`mode: subagent` and the `output_schema` bridge are normally inherited, not overridden.)

## Dual-file convention (retired 2026-08-02)

The old top-level twins at `.opencode/agents/<id>.md` (previously `coder`, `architect`, `interpreter`, `vision-relay`) were **deleted**. Every agent now has exactly **one** definition file under `.opencode/agents/subagents/` — the runtime loads it directly (opencode scans `agent(s)/**/*.md`). Do not recreate a twin: a second file with the same agent name creates a duplicate agent.

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

Frontmatter is the source of truth for per-agent config; `output_schema` lives in frontmatter as a path pointing at a sibling `<id>.schema.json` file; `opencode.json` carries no per-agent config (simplification ratified 2026-08-02); the `permission.task` fan-out for `delivery` / `orchestrator` lives in their frontmatter.

| Subagent | `permission` in frontmatter | `output_schema` in frontmatter | Sibling schema file |
|---|---|---|---|
| `coder-angular` | ✅ | `./coder.schema.json` | ✅ |
| `coder-go` | ✅ | `./coder.schema.json` | ✅ |
| `tester` | ✅ | `./tester.schema.json` | ✅ |
| `reviewer` | ✅ | `./reviewer.schema.json` | ✅ |
| `architect` | ✅ | `./architect.schema.json` | ✅ |
| `explorer` | ✅ | `./explorer.schema.json` | ✅ |
| `analista` | ✅ | `./analista.schema.json` | ✅ |
| `documenter` | ✅ | `./documenter.schema.json` | ✅ |
| `interpreter` | ✅ | `./interpreter.schema.json` | ✅ |
| `project-context` | ✅ | — (text return) | — |
| `vision-relay` | ✅ (tool allow/deny map) | — (text return) | — |
| `external-scout` | ✅ (tool allow/deny map) | — (text return) | — |

## Rules

- New subagents MUST follow this spec (full or minimal shape) from day one — the installer references this file as the Phase 4 shape authority.
- Audits fill missing sections with sensible content; they do NOT rewrite sections that already work.
- Structural edits to a parent that has (future) specializations require re-composing all of them.
- All `.opencode/` files in ENGLISH.
