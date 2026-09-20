# Protocol: Subagent Spec Template

Canonical shape for subagent definitions under `agents/`. Read this before creating a new subagent or auditing an existing one. Everything under `agents/` — recursively — is auto-loaded as an agent, so specs, templates, and partials must never live there.

> Design decisions ratified by the human on 2026-07-29 (orchestrator instance `subagent-spec-template-001`, CHECKPOINT 1).
> Centralization (frontmatter as the single source of truth for per-agent config; sibling `<id>.schema.json` files; `opencode.json` reduced to top-level runtime config) ratified on 2026-07-29 (orchestrator instance `centralize-002`).
> 3-section shell with anchor variant (Option A) ratified 2026-08-24 (Phase 1 of subagent standardization) — see §3.1.

## Purpose

One canonical shape for every subagent spec, so that:

1. The orchestrator, any future scaffolding tool, and human reviewers can rely on a predictable structure.
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
  - `## Contract`, `## Model`, `## When to use` / `## When NOT to use` (`external-scout`)
  - `## Approach` (`explorer` — grep/glob usage, fan-out guidance) — an operational slot inside Section 2, NOT an alias for `## Rules`
- **Knowledge (live in the template)** — describe WHAT the role must know about a stack; they change per specialization:
  - Stack facts, versions, doc pointers, coding standards, anti-patterns, reference catalogs.

Rationale: a future `explorer.typescript` fans out exactly like the base `explorer`; putting fan-out rules in each language template would invite drift between specializations.

## Frontmatter spec

| Field | Status | Notes |
|---|---|---|
| `description` | **required** | One line, routing-oriented — the orchestrator reads this to decide delegation. Name the discipline, the accepted task shapes, and the structured return if any. |
| `mode` | **required** | Literal value (`primary` for delivery, `subagent` for everything else). |
| `model` | optional | Fully qualified (`<provider>/<model>`). Declared in the agent's frontmatter as an explicit override; when omitted, the subagent inherits the invoking primary agent's model (per opencode docs). Part of the cost contract — see the orchestrator's subagent table. |
| `temperature` | optional | Declared in the agent's frontmatter. Omit when the model ignores it (e.g. `kimi-k3`, kimi family). On opencode V2 it is currently inert (moved into `request.body`, which is not sent); retained for V1 compatibility. |
| `tools` | optional | Tool allow/deny map. |
| `permission` | optional | Permission rules in the singular V1 block (e.g. read-only adapters, `task` fan-out grants; `task` is named `subagent` on V2). Keep it singular: V2 normalizes supported legacy frontmatter in memory without rewriting the file, and keys it does not recognize (`output_schema`, `temperature`) are accepted as unrecognized extras (`request.body`, preserved but not sent). There is no documented V2 rule that a native array here would drop agent-level rules; the singular V1 shape is simply the convention this repo standardizes on. V2 auto-maps `task`→`subagent`, `bash`→`shell`, `write`/`patch`→`edit`. |
| `output_schema` | optional | Relative path to the sibling JSON Schema (`./<id>.schema.json`) — see the bridge below. |

## Canonical full shape

Body sections, in canonical order, grouped into 3 macro sections with grep-stable HTML comment anchors. Each macro heading MUST carry its anchor on the same line; the comment is part of the heading and must not be removed. Ordering lint matches anchors, not bare heading text.

### 3.1 The 3-section shell

The 7+1 canonical headings are grouped into 3 macro sections. The mapping is lossless — no heading is removed, only grouped:

| Macro | Anchor (on `##` line) | Contains (`###` sub-headings) | Purpose |
|---|---|---|---|
| 1 — Init / Preconditions | `<!-- Section 1: Init -->` | `### Role`, `### Scope`, `### Stack / Context` | identity + acceptance + knowledge |
| 2 — Execution / Standards | `<!-- Section 2: Execution -->` | `### Standards`, `### Anti-Patterns`, (slot) role-specific operational sections | how to work + what to avoid |
| 3 — Finalization / Return | `<!-- Section 3: Finalization -->` | `### Structured Return`, `### Rules` | output contract + hard rules |

SSOT re-assertion (inside the shell, unchanged): frontmatter remains the single source of truth for per-agent config (`description`, `mode`, `model`, `temperature`, `permission`, `output_schema` → sibling `./<id>.schema.json`); `opencode.json` carries top-level runtime only (`$schema`, `default_agent`, `permissions` global, `references`, `compaction`, `experimental`) — no per-agent block (the only model entry is the built-in `agents.title.model` slot). The shell does not move frontmatter fields. A manually created subagent MUST emit the three macro anchors.

Original canonical order preserved (for reference):

1. `## Role` — who the agent is (1–3 sentences). The H1 title plus a short preamble may sit above it.
2. `## Scope` — the accept / decline contract: which task shapes it takes, which it re-routes (and to whom).
3. `## Stack / Context` — knowledge: stack facts, versions, project-doc pointers.
4. `## Standards` — checklists, principles, definitions of done.
5. `## Anti-Patterns` — what to avoid, phrased as prohibitions with brief reasons.
6. *(slot)* Role-specific sections, if any: operational ones in every specialization, knowledge ones only inside a template.
7. `## Structured Return` — the output contract (see the bridge below).
8. `## Rules` — hard behavioral rules, terse, one per line.

Existing sections keep working names where renaming adds no value (e.g. reviewer's `## Checklist` serves as `## Standards`; the audit harmonizes, it does not churn — see Alias tolerance below).

### Anchor contract

- Pattern: `<!-- Section N: <Name> -->` where `N ∈ {1,2,3}` and `<Name>` is `Init`, `Execution`, or `Finalization`.
- Placement: on the same line as the `## N — <Title>` heading, trailing after a space. Example: `## 1 — Init / Preconditions  <!-- Section 1: Init -->`.
- Ordering: anchors if present must be strictly increasing `1 < 2 < 3`, no duplicates. A file with fewer than 3 macros (thin variants) passes if present anchors are ordered.
- Grep stability: `grep -n '<!-- Section [123]:' <file>` is the source of truth for macro order. Do not rely on bare `##` text.
- Renderer tolerance: validators MUST strip trailing `<!-- ... -->` before matching the markdown heading, so a formatter that moves the comment to the next line still matches leniently, but the canonical form is same-line.
- Scope: anchors are required for NEW and edited subagent specs going forward. Existing subagents are not mass-retrofitted; audits harmonize, they do not churn.

### Alias tolerance (30-day migration)

During one cycle (30 days from this spec's `last_updated`), tolerant aliases are accepted via an HTML comment on the `###` line. The comment is grep-stable and exclusive-or with the canonical heading — a file MUST NOT contain both the canonical and an alias for the same concept (lint fails). After 30 days the alias is a hard error and the file must be rewritten to the canonical heading.

| Canonical (normative) | Tolerated aliases | Required annotation on `###` line | Example | Deadline |
|---|---|---|---|---|
| `### Standards` | `Principles`, `Checklist` | `<!-- alias: Standards -->` | `### Checklist <!-- alias: Standards -->` (reviewer) or `### Principles <!-- alias: Standards -->` (architect) | 30 days then rewrite to `### Standards` |
| `### Structured Return` | `Output`, `Structured Output` | `<!-- alias: Structured Return -->` | `### Output <!-- alias: Structured Return -->` | 30 days then rewrite |
| `### Rules` | `Guidelines` | `<!-- alias: Rules -->` | `### Guidelines <!-- alias: Rules -->` | 30 days then rewrite |

Notes:
- `### Approach` is NOT an alias for `### Rules`. `explorer.md` has both `## Approach` (operational, grep/glob + fan-out) and `## Rules` (hard rules) — `Approach` belongs to the operational slot inside Section 2.
- `### Contract` is NOT an alias for `### Structured Return`. In thin Variant B, `### Contract` means Role+Scope merged (the prose return is described inside `### Structured Return` or the contract itself for text-return adapters). Document its dual role explicitly; do not alias it to Structured Return.
- `Minimal shape` is a legacy term for thin adapters; treat it as an alias for "thin variants".

### Ordering lint examples

Macro order (anchors):

```bash
# Fail if anchors out of order or duplicated
grep -n '<!-- Section [123]:' agents/<id>.md \
  | grep -o 'Section [123]' | awk '{print $2}' | tr '\n' ' ' | grep -qE '^1 2 3 $|^1 3 $|^1 $|^2 3 $|^3 $' \
  || echo "anchor order violation"

# Python validator (strict on anchor order, tolerant on heading text)
import re, sys
txt = open(sys.argv[1]).read()
anchors = [int(m.group(1)) for m in re.finditer(r'<!-- Section (\d):', txt)]
assert anchors == sorted(anchors) and len(anchors) == len(set(anchors)), f"out-of-order or duplicate {anchors}"
```

Intra-macro H3 order (anchors alone are insufficient):

```bash
# Inside each macro, H3 order must be canonical (e.g., Sec1: Role→Scope→Stack/Context)
grep -n '^### ' agents/<id>.md
# Expected Sec1: Role, Scope, Stack / Context
# Expected Sec2: Standards (or alias), Anti-Patterns, slot
# Expected Sec3: Structured Return (or alias), Rules (or alias)
```

```python
# Dual lint: macro + H3
import re, sys
txt = open(sys.argv[1]).read()
# 1. macro anchor order
anchors = [int(m.group(1)) for m in re.finditer(r'<!-- Section (\d):', txt)]
assert anchors == sorted(anchors)
# 2. H3 order inside each macro (simplified)
h3s = re.findall(r'^### (.+?)(?:\s+<!-- alias:.*?-->)?\s*$', txt, re.M)
# Canonical H3 sequence (allow omission for thin variants, but if present order must hold)
canonical = ["Role","Scope","Stack / Context","Standards","Anti-Patterns","Structured Return","Rules"]
# Check alias-normalized names are in canonical order
```

Alias lint (warnings → errors after 30 days):

```bash
grep -n '^### .*<!-- alias:' agents/<id>.md  # emits warnings
# CI promotes to error after 30d via: git log --diff-filter=A --format=%ad --date=short -- <file> vs. deadline
# Exclusive-or check: fail if file contains both canonical and alias for same concept
grep -q '^### Standards' file && grep -q '<!-- alias: Standards -->' file && echo "exclusive-or violation: both Standards and alias"
```

## Macro section details

The following three macro sections instantiate the shell above. New subagents MUST use this shell; existing subagents are retrofitted only when edited.

## 1 — Init / Preconditions  <!-- Section 1: Init -->

### Role

Who the agent is (1–3 sentences). The H1 title plus a short preamble may sit above it.

### Scope

The accept / decline contract: which task shapes it takes, which it re-routes (and to whom).

### Stack / Context

Knowledge: stack facts, versions, project-doc pointers.

## 2 — Execution / Standards  <!-- Section 2: Execution -->

### Standards

Checklists, principles, definitions of done.

### Anti-Patterns

What to avoid, phrased as prohibitions with brief reasons.

### (slot) Role-specific operational sections

If any: operational ones in every specialization, knowledge ones only inside a template. Examples: `## Sampling and Fan-out`, `## Read/Write Workflow`, `## Contract` (Variant B), `## Approach` (explorer).

## 3 — Finalization / Return  <!-- Section 3: Finalization -->

### Structured Return

The output contract (see the bridge below).

### Rules

Hard behavioral rules, terse, one per line.

## Thin variants inside the 3-section shell

A subagent that is a **thin adapter over a single capability** — no `output_schema` or contract fits in ~50 lines — MAY use a reduced form INSIDE the same 3-section shell. The shell is not bypassed; macros are omitted by design and documented below. Do not force the full 7-section form onto thin adapters (would bloat 43–61L thin adapters to 79–128L full, ~60% overhead, and contradict the 2026-08-02 decision to delegate stack knowledge to `docs/context/`).

Two sanctioned variants:

| Variant | Shell sections used | Sub-headings present | Example files | Lines | When to use | Must contain |
|---|---|---|---|---|---:|---|
| Variant A: Stack/Context-delegating coder/tester | 1 (partial) + 3 | Sec1: only `### Stack / Context`; Sec2: omitted or only slot; Sec3: `### Rules` + `### Structured Return` | `coder.md`, `tester.md` (43–80L) | 43–80 | Coder/test specialist with `docs/context/` delegation (knowledge lives in `docs/context/`, not in spec) | `Stack / Context` pointing to `docs/context/` as truth, `Rules`, `Structured Return` (CoderOutput/TesterOutput via sibling schema), frontmatter with `output_schema` |
| Variant B: Contract minimal relay | 1 (merged) + 2/3 (partial) | `### Contract` (Role+Scope merged) + `### When to use` / `### When NOT to use` (+ `### Model` if needed) inside Sec1 or Sec2; Sec3 may be omitted if text return | `external-scout.md` (61L) | 61 | Single-capability relay/scout: one package+version lookup, no `output_schema`, text return, deny `edit`/`bash` | `Contract` (one capability), `When to use`, `When NOT to use`, `Model`; permission deny as needed |

Rules for thin variants:
- Variant A is explicitly exempt from `### Role` and `### Scope` in Sec1 — it delegates identity/scope to the `docs/context/` slice table. Do not add empty `Role`/`Scope` to satisfy the shell.
- Variant B's `### Contract` is the merged Role+Scope; it is NOT an alias for `### Structured Return` — the return is prose/text described in the contract.
- Both variants remain valid inside the 3-section shell via omitted macros + alias annotations where needed; the full shape (3 macros, all H3s) remains the default for all other subagents (`architect`, `explorer`, `reviewer`, `documenter`, `analista`, `interpreter`) — `tester` is Variant A (framework-parameterized thin adapter) alongside `coder`.

## The `output_schema` ↔ sibling schema bridge

- The schema lives in a **sibling file** `agents/<id>.schema.json`, referenced from the subagent's frontmatter via `output_schema: ./<id>.schema.json`. The `.md` frontmatter is the single source of truth for the return contract.
- The subagent's `## Structured Return` section documents the JSON shape, names the schema, shows an example, and points at the sibling file.
- The two MUST stay in sync: change one, change the other. The `.md` frontmatter and its sibling schema are authored together.
- Subagents without an `output_schema` return plain text (or markdown); their `## Structured Return` (full shape) or `## Contract` (minimal/thin Variant B) describes the expected return in prose. Current subagents without a schema, **by design**: `delivery` (markdown turn contract), `orchestrator` (markdown agent-snapshot), `external-scout` (plain-text contract). These three are **prose-only contracts** — no `output_schema` is intended.
- **`output_schema` is NOT runtime-enforced.** On opencode V2 it is not a recognized agent field: it is captured as a legacy rest key and routed to `request.body` (preserved, not sent), and the subagent tool returns the child's final text as an opaque string without validating it (the JSON is a convention the child is instructed to follow, not a runtime contract). Per `agents/orchestrator.md` → Hard Limits, verifying the return is a **MANUAL check the orchestrator performs**: a return that does not match its `output_schema` is a **subagent failure to be re-invoked**, and the raw text is never reinterpreted as a valid return. The runtime does not preserve raw text for diagnostics. This spec defers to the orchestrator contract. Never write `summary.md` / `output-full.md` / `manifest.md` to disk — the runtime captures returns on the EventV2 bus.

## `opencode.json` — top-level runtime knobs only

Since the 2026-07-29 centralization and the simplification ratified 2026-08-02, `opencode.json` carries **top-level runtime config only**: `$schema`, `default_agent`, `permissions` (global, V2 native array), `references`, `compaction`, `experimental`, `mcp`, `model`, `agents` (the built-in `title` model slot ONLY — not a per-agent block; `agents.title.model` supplies the title-generation model and is also read at dispatch time by the orchestrator as the cheap, different-family model-independence slot for `reviewer`/`analista` and the Typed-Decision Panel). There is **no per-agent block** — every per-agent field (including `model` and `temperature`) lives in the agent's `.md` frontmatter. Note that on V2 an agent `temperature` is currently inert (moved into `request.body`, which is not sent); the field is retained for V1 compatibility.

Every per-agent field lives in the agent's `.md` frontmatter:

| Field | Home |
|---|---|
| `description`, `mode`, `model`, `temperature` (inert on V2), `permission` | The agent `.md` frontmatter |
| `output_schema` | Frontmatter path → sibling `<id>.schema.json` |
| `permission.task` fan-out (which subagents `delivery` / `orchestrator` may call) | Frontmatter of `delivery.md` / `orchestrator.md` |
| Global `permissions` rules (`{action, resource, effect}`) | Stay in `opencode.json` |

**To change a model or temperature**: edit the agent's frontmatter (`agents/<id>.md`), then restart opencode. `opencode.json` is untouched.

Rationale: the `.md` is the canonical artifact the runtime loads; keeping `model`/`temperature` in the agent file makes each agent self-contained — one file to read for everything about that agent, with no frontmatter↔JSON drift. `opencode.json` shrinks to true runtime config.

## Naming convention for specializations

- Parent keeps the plain role name (e.g. `coder.md`).
- Template / specialization: `<role>.<specialization>.md`. No specialization files exist today — the coder is centralized into a single language-parameterized `coder.md` (Variant A) that branches by a `language=angular|go` task payload instead of per-language files.

## Realized example: `coder.md` — language-parameterized thin adapter (2026-08-24)

The coder is a single thin adapter (centralized 2026-08-24). `coder.md` is small, self-contained, and delegates stack knowledge to `docs/context/`, branching on the `language` parameter in the task payload:

```
coder.md
────────────────────────────────────────────
frontmatter: mode, permission,
  output_schema
## 1 — Init / Preconditions  (Section 1)
   ### Stack / Context → branch by language:
     language=angular → Angular docs in
       docs/context/ (source of truth)
     language=go     → Go docs in docs/context/
       (source of truth), gofmt/go vet
     fallback        → docs/project.md Slices
       table
## 2 — Execution / Standards  (Section 2)
   minimal slot — standards delegated to the
   language docs (no duplication)
## 3 — Finalization / Return  (Section 3)
   ### Structured Return → CoderOutput
   ### Rules → follow docs, canonical commands,
     English
```

It shares the sibling schema `coder.schema.json` (`CoderOutput`). `coder.md` declares no `model:` — it inherits the invoking primary agent's model (the global default in `opencode.json`). Under the 3-section shell this maps to Sec1 `Stack / Context` + Sec2 minimal slot + Sec3 `Rules` + `Structured Return` (Variant A).

## Composition rules (documented future)

1. A specialized subagent file = the parent's structural sections **verbatim** + the template's variable sections, ordered per the canonical full shape above.
2. Structural sections are **inherited, not copied-and-edited**: if a structural section must change, change the parent and re-compose every specialization.
3. Template resolution: `<role>.<specialization>.md` composes with `<role>.md`. **No runtime implementation exists yet** — this protocol fixes only the boundary. When the first template is introduced, decide storage (suggestion: a `templates/agents/` path outside the auto-loaded `agents/` tree — no such asset ships today) and the composition mechanism. Everything under `agents/` is auto-loaded recursively, so templates and partials must never live there.
4. Frontmatter composition: the child template's frontmatter **wins over the parent's for any field it declares**; undeclared fields are inherited from the parent. (`mode: subagent` and the `output_schema` bridge are normally inherited, not overridden.)

## Rules

- New subagents MUST follow this spec (full or minimal/thin shape) from day one — this file is the shape authority for any new subagent (and for any future scaffolding tool).
- Audits fill missing sections with sensible content; they do NOT rewrite sections that already work.
- Structural edits to a parent that has (future) specializations require re-composing all of them.
- All agent-system files in ENGLISH.
