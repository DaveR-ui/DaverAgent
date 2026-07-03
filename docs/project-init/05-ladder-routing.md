# 05 — Ladder Routing

> Experiential annotations on the slice complexity ladder — rung selection, override signals, and routing decisions. See `.opencode/protocols/slice-complexity-ladder.md` for the full spec.

---

## How the Ladder Works

Climb from **R0 upward** and **stop at the FIRST rung** whose gate condition is satisfied. Do not keep climbing past a satisfied gate.

**Lower is better.** When genuinely between two rungs, pick the LOWER one. A reviewer can escalate; an architect can never un-spend its tokens.

**R3 is the DEFAULT rung.** When in doubt between R2 and R3, pick R3. When in doubt between R3 and R4, pick R3 and let the reviewer escalate.

---

## Rungs

| Rung | Name | Gate condition |
|---|---|---|
| R0 | SKIP | The work is unnecessary or already done |
| R1 | TRIVIAL | Single file, no logic change |
| R2 | KNOWN | A pattern already exists in the codebase to copy |
| R3 | STANDARD | 2–5 files, known layers, no design decisions |
| R4 | COMPLEX | 6+ files, or design decisions needed |
| R5 | CRITICAL | Migration, breaking changes, security, auth/permissions/payment |

### Human gates

- **R4**: human gate AFTER the architect phase — present the design before implementation begins.
- **R5**: MANDATORY human gate BEFORE execution — design, migration plan, rollback plan, and risk assessment must all be approved.

---

## Override Signals (bump UP)

| Signal | Effect |
|---|---|
| Multiple slices involved | +1 rung |
| Human explicitly requests architecture | → R4 minimum |
| >5 files with logic changes | → R4 minimum |
| Auth / permissions / payment | → R5 minimum |

Override signals are cumulative but capped at R5.

---

## Context-Reductor → Ladder Starting Point

The context-reductor estimates complexity; the ladder decides the final rung.

| Context-reductor level | Ladder starting point |
|---|---|
| Baja | R1 |
| Media | R2 |
| Media-Alta | R3 |
| Alta | R4 |
| Muy Alta | R5 |

The ladder may resolve to a **LOWER** rung than the starting point. The context-reductor is an estimate; the ladder is the decision. For example, an Alta estimate may drop to R3 if the codebase already has the pattern and only 3 files change.

---

## Anti-Patterns per Rung

| Rung | Anti-pattern |
|---|---|
| R0 | Creating work where none is needed |
| R1 | Wrapping a one-line change in a service |
| R2 | Inventing a new pattern when one already exists |
| R3 | Adding middleware for a one-off check |
| R4 | Skipping the architect; implementing before design is agreed |
| R5 | Running a migration without a rollback plan |

---

## Gotchas

- The ladder is evaluated **PER SLICE**, not per session. A session may involve multiple slices at different rungs.
- When multiple slices are involved, the **HIGHEST rung wins** for orchestrator dispatch, but each slice retains its own rung for its own work.
- "It seems simple" does NOT bump the rung down — simplicity is measured by the ladder's gate conditions, not by intuition.
- "I've done this before" does NOT bump the rung down — the codebase may have changed since the last time.
- The ladder replaces ad-hoc complexity routing. It is a **formal, auditable** decision process. If you're routing by gut, you're doing it wrong.
- R3 is the safe default. Don't overthink R2 vs R3 — pick R3 and let the reviewer escalate if needed.
- The context-reductor's estimate is a STARTING POINT, not a verdict. The ladder can go lower.

---

## Quick Reference

| Rung | Gate | Human gate? |
|---|---|---|
| R0 SKIP | Unnecessary / done | No |
| R1 TRIVIAL | Single file, no logic | No |
| R2 KNOWN | Pattern exists | No |
| R3 STANDARD | 2–5 files, known layers | No (default) |
| R4 COMPLEX | 6+ files / design decisions | After architect |
| R5 CRITICAL | Migration / breaking / security | Before execution (mandatory) |

**Override signals**: multiple slices (+1), human requests architecture (→R4 min), >5 logic files (→R4 min), auth/permissions/payment (→R5 min).

**Default rung**: R3.

**Rule of thumb**: lower is better; reviewer can escalate, architect tokens cannot be recovered.

**Cross-reference**: `.opencode/protocols/slice-complexity-ladder.md`.