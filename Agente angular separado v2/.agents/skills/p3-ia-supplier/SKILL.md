---
name: context-supplier
description: Knowledge Middleware skill. Filters technical documentation based on task type (Bug, Feature, Test) and delivers only relevant context to minimize token usage and flag technical debt.
last_updated: 2026-04-24
status: active
---

# 🧠 Skill: Context Supplier (Knowledge Middleware)

## Goal
Serve as a precision filter for the Agent Knowledge Hub. Prevent token duplication by comparing the orchestrator's current state with required documentation and identify "Technical Debt" before any code is written.

## Instructions

### 1. Task-Based Context Filtering
Depending on the task type identified in the `prompt-analyzer` phase, retrieve only the specific rule sets:
*   **[BUG FIX]**: Provide `.agents/context/project/rules.md` (anti-patterns section) and specific "Anti-patterns" from the relevant component doc.
*   **[FEATURE]**: Provide `.agents/context/project/rules.md` (standards section) and "Standard Patterns" (Signals, rxResource).
*   **[TEST]**: Provide `.agents/context/standards/angular-reactivity/testing.md` and framework-specific guides (Vitest/Jasmine).

### 2. Token Optimization (Knowledge Delta)
*   **Action**: Analyze the "Orchestrator Context" (what has already been read in this session).
*   **Deduplication**: If `project-rules.md` was already loaded, do not provide it again. Deliver only the "Delta" (the specific sections of the component doc or skill references that are new).

### 3. Technical Debt & Inconsistency Scan
Before delivering the context package, scan the identified files for:
*   **Stale Docs**: Metadata older than 6 months or status marked as (WIP) or (TODO).
*   **Inconsistent Patterns**: If the component doc lists an "Anti-pattern" that the orchestrator just encountered in a recent search, flag it immediately.
*   **Missing SSOT**: Lack of a "Primary Doc" in the `AGENTS.md` map for a component involved in a "Complex" task.

## Decision Rules
*   **Strict Delivery**: Never send the full `.agents/context/` folder. Only send the specific files mapped in the routing table of `orchestrate.md`.
*   **Debt Blocker**: If "Inconsistent Patterns" are found (e.g., a service using `setTimeout` when the task is to add a Signal), the agent must issue a **🚨 TECHNICAL DEBT ALERT** and suggest refactoring as part of the plan.
*   **Language Guard**: All delivered context must be in English for AI consumption, but Debt Alerts for the user may be in Spanish if the project rules dictate.

## Output Format
Return a Context Package:
*   **Relevant Docs**: List of provided file paths from `.agents/context/`.
*   **Delta Context**: Snippets of new rules/patterns not previously seen in the session.
*   **🚨 DEBT ALERTS**:
    *   *Detected Pattern*: [e.g., Manual Subscription found in Source of Truth].
    *   *Required Standard*: [e.g., Migration to rxResource required].
    *   *Impact*: [High/Medium/Low].

## Constraints
- **PROHIBITED**: Dumping the entire `.agents/context/` directory into the prompt.
- **PROHIBITED**: Ignoring stale or inconsistent documentation without flagging it.
- **MANDATORY**: Delivering only the "Delta" context to avoid token waste.

## Examples

### Example 1: Bug Fix Context Package
**Task Type**: BUG FIX
**Relevant Docs**:
- `.agents/context/project/rules.md` (anti-patterns section)
- `.agents/context/memory/troubleshooting/common-errors.md`

**Delta Context**:
- Rule: "Always check for manual `.subscribe()` leaks before fixing UI bugs."

**🚨 DEBT ALERTS**:
- *Detected Pattern*: Manual `.subscribe()` in `auth-wizard.service.ts`.
- *Required Standard*: Migrate to `rxResource` or `toSignal`.
- *Impact*: High.

### Example 2: Feature Context Package
**Task Type**: FEATURE
**Relevant Docs**:
- `.agents/context/project/rules.md` (standards section)
- `.agents/context/project/rules.md` (Signals-First section)

**Delta Context**:
- Pattern: "Use `input.required<string>()` for all public inputs."

**🚨 DEBT ALERTS**: None
