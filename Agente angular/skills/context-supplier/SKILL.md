---
name: context-supplier
description: Knowledge Middleware skill. Filters technical documentation based on task type (Bug, Feature, Test) and delivers only relevant context to minimize token usage and flag technical debt.
last_updated: 2026-04-24
status: active
---

# 🧠 Skill: Context Supplier (Knowledge Middleware)

## Goal
Serve as a precision filter for the Agent Knowledge Hub. Prevent token duplication by comparing `sdd_agent`'s current state with required documentation, align context with user-provided clues, and identify "Technical Debt" before any code is written.

## Instructions

### 1. Clue-to-Doc Alignment
Use `sdd_agent`'s User Clue Inventory as the primary selector for context retrieval:
*   Prioritize docs that directly explain the clues attached by the user.
*   If a clue has no mapped doc, flag it as unresolved instead of forcing a weak match.

### 2. Task-Based Context Filtering
Depending on the task type identified in the `prompt-analyzer` phase, retrieve only the specific rule sets:
*   **[BUG FIX]**: Provide the matching routing entry from `.github/agent-workflows/orchestrate.md`, the relevant `.github/agent-context/` feature doc, and specific anti-patterns from `project-rules.md`.
*   **[FEATURE]**: Provide the matching routing entry from `.github/agent-workflows/orchestrate.md` plus the relevant `.github/agent-context/` standard patterns (Signals, `rxResource`, component guidance).
*   **[TEST]**: Provide the matching routing entry from `.github/agent-workflows/orchestrate.md`, `.github/agent-context/angular-reactivity/testing.md`, and framework-specific guides (Vitest/Jasmine).

### 3. Token Optimization (Knowledge Delta)
*   **Action**: Analyze the current session context already assembled by `sdd_agent`.
*   **Deduplication**: If `project-rules.md` was already loaded, do not provide it again. Deliver only the "Delta" (the specific sections of the component doc or skill references that are new) and include unresolved clues.

### 4. Technical Debt & Inconsistency Scan
Before delivering the context package, scan the identified files for:
*   **Stale Docs**: Metadata older than 6 months or status marked as (WIP) or (TODO).
*   **Inconsistent Patterns**: If the component doc lists an "Anti-pattern" that `sdd_agent` just encountered in a recent search, flag it immediately.
*   **Missing SSOT**: Lack of a "Primary Doc" in the `AGENTS.md` map for a component involved in a "Complex" task.

## Decision Rules
*   **Strict Delivery**: Never send the full `.github/agent-context/` folder. Only send the specific files mapped in the routing table of `.github/agent-workflows/orchestrate.md`.
*   **Debt Blocker**: If "Inconsistent Patterns" are found (e.g., a service using `setTimeout` when the task is to add a Signal), the agent must issue a **🚨 TECHNICAL DEBT ALERT** and suggest refactoring as part of the plan.
*   **Clue Coverage Rule**: If high-signal clues are not covered by local docs, explicitly report the gap and request one targeted clarification.
*   **Language Guard**: All delivered context must be in English for AI consumption, but Debt Alerts for the user may be in Spanish if the project rules dictate.

## Output Format
Return a Context Package:
*   **Relevant Docs**: List of provided file paths from `.github/agent-context/` and `.github/agent-workflows/`.
*   **Delta Context**: Snippets of new rules/patterns not previously seen in the session.
*   **Clue-to-Context Match**: Mapped clues and unresolved clues.
*   **🚨 DEBT ALERTS**:
    *   *Detected Pattern*: [e.g., Manual Subscription found in Source of Truth].
    *   *Required Standard*: [e.g., Migration to rxResource required].
    *   *Impact*: [High/Medium/Low].

## Constraints
- **PROHIBITED**: Dumping the entire `.github/agent-context/` directory into the prompt.
- **PROHIBITED**: Ignoring stale or inconsistent documentation without flagging it.
- **MANDATORY**: Delivering only the "Delta" context to avoid token waste.
- **MANDATORY**: Reporting unresolved user clues when no reliable local mapping exists.

## Examples

### Example 1: Bug Fix Context Package
**Task Type**: BUG FIX
**Relevant Docs**:
- `.github/agent-workflows/orchestrate.md`
- `.github/agent-context/authviews/wizard-logic.md`

**Delta Context**:
- Rule: "Always check for manual `.subscribe()` leaks before fixing UI bugs."

**🚨 DEBT ALERTS**:
- *Detected Pattern*: Manual `.subscribe()` in `auth-wizard.service.ts`.
- *Required Standard*: Migrate to `rxResource` or `toSignal`.
- *Impact*: High.

### Example 2: Feature Context Package
**Task Type**: FEATURE
**Relevant Docs**:
- `.github/agent-workflows/orchestrate.md`
- `.github/agent-context/project-rules.md` (Signals-First section)

**Delta Context**:
- Pattern: "Use `input.required<string>()` for all public inputs."

**Clue-to-Context Match**:
- Mapped clue: "console error mentions rxResource status" → `resource-api.md`.
- Unresolved clue: "Screenshot shows disabled button with no stack trace".

**🚨 DEBT ALERTS**: None