# 04 — The Prompt Pipeline

> Experiential annotations on the canonical-prompter → context-reductor → slice-complexity-ladder pipeline. This is NOT an API reference — it captures what actually happens during prompt analysis and what would have saved time.

---

## Pipeline Overview

```
Raw Prompt
  → Phase 1: canonical-prompter   (term resolution, classification, hints)
  → Phase 2: context-reductor     (complexity, hot spots, hidden assumptions)
  → Phase 3: slice-complexity-ladder (rung selection, routing)
  → Phase 4: routing              (agent dispatch, model selection)
```

The delivery agent executes Phases 1–3 **informally** — it reads the protocols and applies them inline. There are no separate subagents for canonical-prompter or context-reductor. They are **protocols** (instructions), not agents.

See `.opencode/protocols/canonical-prompter.md`, `.opencode/protocols/context-reductor.md`, and `.opencode/protocols/slice-complexity-ladder.md` for the full specs.

---

## Phase 1 — canonical-prompter

The delivery agent performs:

- **Term resolution**: map ambiguous terms to project vocabulary (e.g., "galería" → `gallery` slice).
- **Classification**: bug / task / feature-design / update.
- **Module identification**: which slice(s) and entry points are involved.
- **Hint extraction**: implicit constraints, tone, urgency, references to past work.
- **Acceptance criteria**: what "done" looks like — concrete, testable.
- **Edge cases**: what could go wrong, boundary conditions.
- **Clarification decision**: is a user question needed BEFORE work begins, or can we proceed?

---

## Phase 2 — context-reductor

The delivery agent produces:

- **Complexity level**: Baja → Media → Media-Alta → Alta → Muy Alta.
- **Hot spots**: conditions that trigger mandatory user questions (see below).
- **Hidden assumption**: MANDATORY output — the one thing the plan takes for granted.
- **Scope boundaries**: explicitly state what is OUT of scope, with module names and file paths.
- **Key files**: the files most likely to be touched.
- **Input/output analysis**: what data flows in and out.
- **Dependencies**: internal modules, external packages.
- **Verification path**: how the reviewer will validate success — write it BEFORE implementation.

### The Hidden Assumption (mandatory)

Express in one sentence:

> "This plan assumes [X]. If [X] is wrong, [consequence]."

This is the single most important output of Phase 2. It surfaces invisible risk that nobody is actively thinking about. Skipping it means flying blind.

### Hot Spots (trigger mandatory user questions)

| Hot Spot | Meaning |
|---|---|
| State Ownership Pivot | Changing which signal/service owns a piece of state |
| Breaking Refactor (>900 lines) | Large file rewrite with breaking surface |
| Ambiguous Data Flow | Unclear where data comes from or goes |
| Standard Supremacy Violation | Plan conflicts with a documented standard |
| Compute Guard (>5 files with logic changes) | Too many files with real logic changes |
| Security / Guardrails | Auth, permissions, payment, data exposure |

### Compute Guard rule

The compute guard counts **files with LOGIC changes**. Documentation files, config tweaks, and copy changes do NOT count. A 20-file docs update does not trigger the guard; a 6-file logic change does.

### Complexity levels

| Level | Meaning |
|---|---|
| Baja | Single file, no branching |
| Media | 2–3 files |
| Media-Alta | Conditional branching, multiple paths |
| Alta | Multi-environment, external integrations |
| Muy Alta | Migration, schema changes, breaking changes |

For **Alta** and **Muy Alta**: the plan MUST be validated by the user before implementation begins.

---

## Gotchas

- The delivery agent does the prompt analysis **informally** — it does NOT invoke separate subagents for canonical-prompter and context-reductor. These are protocols, not agents. Treating them as agents wastes a round-trip.
- The **hidden assumption** is the most important output — it surfaces invisible risk. Always write it, even when it feels obvious.
- Don't skip the **scope boundaries** — explicitly state what is OUT of scope, with specific module names and file paths. Vague scope breeds scope creep.
- The **verification path** defines how the reviewer validates success. Write it before implementation, not after. If you can't define verification, the acceptance criteria are incomplete.
- The compute guard is about **logic changes**, not file count. A 50-file docs rename is R1; a 6-file logic refactor is R4+.
- "It seems simple" is not a complexity assessment — the ladder decides, not intuition.

---

## Quick Reference

| Phase | Output | Owner |
|---|---|---|
| 1 canonical-prompter | Classification, hints, acceptance criteria, edge cases | delivery (inline) |
| 2 context-reductor | Complexity, hot spots, hidden assumption, scope, verification path | delivery (inline) |
| 3 slice-complexity-ladder | Rung selection, routing | delivery (inline) |
| 4 routing | Agent dispatch, model selection | delivery / orchestrator |

**Complexity levels**: Baja → Media → Media-Alta → Alta → Muy Alta.

**Hot spot triggers**: State Ownership Pivot, Breaking Refactor (>900 lines), Ambiguous Data Flow, Standard Supremacy Violation, Compute Guard (>5 files with logic changes), Security/Guardrails.

**Compute guard rule**: counts files with LOGIC changes only. Docs/config/copy do not count.

**Mandatory user validation**: Alta and Muy Alta require user sign-off before implementation.

**Cross-reference**: `.opencode/protocols/canonical-prompter.md`, `.opencode/protocols/context-reductor.md`, `.opencode/protocols/slice-complexity-ladder.md`.