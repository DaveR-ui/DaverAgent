# Protocol: Slice Complexity Ladder

The best orchestration is the one that never runs. Before dispatching agents, the orchestrator climbs this ladder from the bottom and stops at the first rung that holds. No higher.

Inspired by [Ponytail](https://github.com/DietrichGebert/ponytail): lazy about the solution, never about reading.

## Inputs

1. **Structured analysis** from `canonical-prompter` (classification, modules, hints, acceptance criteria).
2. **Scope definition** from `context-reductor` (complexity level, hot spots, key files, dependencies).
3. **Slice row** from the Slices table in the project entry point (see `.opencode/conventions.md`).
4. **Codebase awareness**: the orchestrator reads the code the change touches and traces the real flow before picking a rung.

## The Ladder

Climb from R0 upward. Stop at the first rung whose gate condition is satisfied.

```
R0  SKIP       Does this need to exist?           → no: skip it (YAGNI)
R1  TRIVIAL    One file, no logic, no risk?       → one agent, no orchestrator
R2  KNOWN      Already solved in this codebase?   → reuse the pattern, coder + reference
R3  STANDARD   2-5 files, known layer, clear API? → orchestrator + coder + reviewer
R4  COMPLEX    Multi-module, design decisions?     → orchestrator + architect + coder + reviewer + tester
R5  CRITICAL   Migration, breaking change, security? → full ladder + mandatory human gate
```

## Rung Definitions

### R0 — SKIP

**Gate**: The task is unnecessary, already done, or the human's problem statement resolves to "nothing to change."

| Dimension | Value |
|---|---|
| **Agents** | None |
| **Model route** | N/A |
| **Verification** | Confirm nothing was missed; report why skipping is correct |
| **Human gate** | Only if the human explicitly asked for something and you're saying no |
| **Anti-pattern** | Creating work where none is needed. Refactoring code that already works. Adding abstractions "for the future." |

**Output**: One-line rationale in the agent-snapshot explaining why the task is skipped. Return `STATUS: DONE`.

### R1 — TRIVIAL

**Gate**: Single file change, no cross-module dependency, no logic branching, no security surface. Config tweaks, copy changes, single-field additions, simple renames.

| Dimension | Value |
|---|---|
| **Agents** | `coder` direct (skip orchestrator) |
| **Model route** | Docs/Read-Only or Exploration per `llm-routing.md` if applicable; otherwise Important/Execution |
| **Verification** | Build passes. Existing tests pass. |
| **Human gate** | No |
| **Anti-pattern** | Wrapping a one-line change in a service class. Adding a config file for a single constant. Creating a utility function used once. |

**Delivery route**: Direct to `coder`. No orchestrator instantiation.

### R2 — KNOWN

**Gate**: The exact pattern already exists in the codebase. The task is "do what we did for X, but for Y." CRUD endpoint following established factory. New field following existing migration pattern. New route following existing handler structure.

| Dimension | Value |
|---|---|
| **Agents** | `coder` direct, with mandatory reference to existing implementation |
| **Model route** | Important/Execution per `llm-routing.md` |
| **Verification** | Build passes. Diff compared against reference implementation. Reviewer if hot spot detected. |
| **Human gate** | No |
| **Anti-pattern** | Inventing a new pattern when one exists. "Improving" the existing pattern while copying it. Abstracting prematurely across two instances. |

**Handoff must include**: The file path of the reference implementation the coder should mirror.

### R3 — STANDARD

**Gate**: 2-5 files across known layers (domain → repo → service → handler → routes). Clear API contract. No architectural decisions required. The architecture doc covers the pattern.

| Dimension | Value |
|---|---|
| **Agents** | `orchestrator` → `coder` + `reviewer` (parallel where independent) |
| **Model route** | Important/Execution per `llm-routing.md` |
| **Verification** | Build passes. Tests pass. Reviewer validates against architecture doc and rules doc. |
| **Human gate** | Only if hot spots detected by `context-reductor` |
| **Anti-pattern** | Adding a middleware for a one-off check. Creating a base class for two implementations. Splitting a 50-line service into three files. |

**This is the default rung.** When in doubt between R2 and R3, pick R3. When in doubt between R3 and R4, pick R3 and let the reviewer escalate.

### R4 — COMPLEX

**Gate**: Multi-module changes (6+ files), cross-cutting concerns, new subsystem, design decisions not covered by existing architecture, or the `context-reductor` flagged complexity as Alta/Muy Alta with design implications.

| Dimension | Value |
|---|---|
| **Agents** | `orchestrator` → `architect` (first) → `coder` + `reviewer` + `tester` (parallel after design) |
| **Model route** | Important/Execution per `llm-routing.md` |
| **Verification** | Build passes. Tests pass. Architect validates design. Reviewer validates implementation. Tester validates behavior. |
| **Human gate** | After architect phase — present design before implementation |
| **Anti-pattern** | Skipping the architect. Implementing before design is agreed. Building the "general" solution when a specific one works. Over-decomposing into micro-services for a monolith feature. |

**Execution order**: Architect produces design → human reviews (strategic pause) → coder implements → reviewer + tester validate.

### R5 — CRITICAL

**Gate**: Data migration, schema changes, breaking API changes, security-sensitive modifications, or any change the `context-reductor` flagged with a mandatory Hot Spot question.

| Dimension | Value |
|---|---|
| **Agents** | `orchestrator` → `architect` → `coder` + `reviewer` + `tester` (sequential, gated) |
| **Model route** | Important/Execution per `llm-routing.md` |
| **Verification** | Build passes. Tests pass. Migration tested on copy. Rollback plan documented. Security review. |
| **Human gate** | **Mandatory before execution.** Present: design, migration plan, rollback plan, risk assessment. |
| **Anti-pattern** | Running migration without rollback. Changing auth without security review. Modifying shared schemas without impact analysis. "We'll fix it in the next sprint." |

**Execution order**: Architect designs → human approves → coder implements → reviewer audits → tester validates → human confirms.

## Rung Selection Algorithm

```
1. Read the task. Read the code it touches. Trace the real flow.
2. Start at R0. Is the task unnecessary? → R0.
3. R1. Single file, no logic, no risk? → R1.
4. R2. Does the exact pattern exist in the codebase? → R2.
5. R3. 2-5 files, known layers, architecture doc covers it? → R3.
6. R4. Multi-module, design decisions, Alta/Muy Alta? → R4.
7. R5. Migration, breaking change, security, mandatory hot spot? → R5.
8. If between two rungs: pick the LOWER one. Escalation is cheaper than over-engineering.
```

### Override signals

These signals bump the rung UP regardless of the algorithm:

| Signal | Bump |
|---|---|
| `context-reductor` flagged a mandatory Hot Spot | +1 rung minimum |
| Task touches >5 files with logic changes (Compute Guard) | → R4 minimum |
| Task modifies auth, permissions, or payment | → R5 minimum |
| Multiple slices involved | +1 rung minimum |
| Human explicitly requests architecture review | → R4 minimum |

These signals do NOT bump the rung down:

- "It seems simple" — simplicity is measured by the ladder, not by intuition
- "I've done this before" — the codebase may have changed
- "It's just a small change" — small changes in the wrong place cascade

## Integration with Existing Protocols

### Pipeline position

```
Raw Prompt
    → canonical-prompter (Phase 1: structured analysis)
    → context-reductor (Phase 2: scope + complexity + hot spots)
    → SLICE COMPLEXITY LADDER (Phase 3: rung selection + routing)
    → orchestrator or direct dispatch (Phase 4: execution)
```

### Mapping: context-reductor complexity → ladder rung

The `context-reductor` produces a complexity level (Baja → Muy Alta). This is an **input** to the ladder, not the output:

| Context-Reductor Level | Ladder Starting Point | Notes |
|---|---|---|
| Baja | Start at R1 | May resolve to R0 or R2 |
| Media | Start at R2 | Most common path to R3 |
| Media-Alta | Start at R3 | Check override signals |
| Alta | Start at R4 | Verify R3 isn't sufficient |
| Muy Alta | Start at R5 | Mandatory human gate applies |

The ladder may resolve to a **lower** rung than the starting point if the gate conditions allow it. This is intentional — the context-reductor estimates, the ladder decides.

### Handoff annotation

The delivery agent includes the selected rung in the orchestrator handoff:

```markdown
## Ladder Rung
- **Rung**: R3 (STANDARD)
- **Starting point**: R3 (from context-reductor: Media-Alta)
- **Override signals**: none
- **Rationale**: 3 files across handler + service + repo layers. Architecture doc covers the pattern. No hot spots.
```

The orchestrator validates the rung on receipt and may adjust if codebase reading reveals a different reality. Any adjustment must be documented in the agent-snapshot under `Decisions`.

## Output Template

```markdown
## Ladder Assessment

### Rung Selected
- **Rung**: [R0 | R1 | R2 | R3 | R4 | R5]
- **Label**: [SKIP | TRIVIAL | KNOWN | STANDARD | COMPLEX | CRITICAL]

### Climbing Log
| Rung | Gate Question | Answer | Result |
|------|---------------|--------|--------|
| R0 | Does this need to exist? | [yes/no] | [skip/continue] |
| R1 | Single file, no logic? | [yes/no] | [stop/continue] |
| R2 | Pattern exists in codebase? | [yes/no] | [stop/continue] |
| R3 | 2-5 files, known layers? | [yes/no] | [stop/continue] |
| R4 | Multi-module, design decisions? | [yes/no] | [stop/continue] |
| R5 | Migration/breaking/security? | [yes/no] | [stop/continue] |

### Override Signals
- [Signal detected, or "none"]

### Routing Decision
- **Agents**: [list]
- **Model route**: [route from llm-routing.md]
- **Human gate**: [yes/no, and at which phase]
- **Verification**: [what must pass]

### Anti-Pattern Watch
- [The specific over-engineering trap to avoid at this rung]
```

## Decision Rules

1. **Lower is better.** When two rungs are defensible, pick the lower one. A reviewer can always escalate; an architect can never un-spend its tokens.
2. **Read before climbing.** The ladder runs after understanding the problem, not instead of it. Read the code the change touches before picking a rung.
3. **Lazy about the solution, never about reading.** Skipping the codebase scan is not allowed.
4. **The code you never wrote scales infinitely.** Zero bugs, zero CVEs, 100% uptime since forever. Apply this thinking at every rung.
5. **Trust boundaries are not on the chopping block.** Validation, error handling, security, and accessibility are never cut regardless of rung.
6. **Escalation is a feature.** If R3 turns out to need R4 during execution, the reviewer or orchestrator bumps it and documents the reason.

## Notes

- The ladder is evaluated **per slice**, not per session. A session may involve multiple slices at different rungs.
- When multiple slices are involved, the **highest rung wins** for orchestrator dispatch, but each slice retains its own rung annotation.
- The ladder replaces the ad-hoc complexity routing in `delivery.md` and `orchestrator.md` with a formal, auditable decision process.
- This protocol does not replace `context-reductor` complexity evaluation — it consumes it as input and adds the routing decision layer.
