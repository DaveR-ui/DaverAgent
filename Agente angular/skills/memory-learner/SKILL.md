---
name: memory-learner
description: Orchestration & Learning skill. Manages routing and durable documentation updates. Captures architectural decisions and lessons learned to create a "compounding effect" for future agent precision.
last_updated: 2026-04-24
status: active
---

# 🧠 Skill: Memory Learner (Orchestration & Learning)

## Goal
Responsible for the long-term intelligence of the ecosystem. Transform ephemeral session data (fixes, pivots, errors, and user clues) into persistent architectural rules and logs, ensuring that the system evolves and avoids repeating past mistakes.

## Instructions

### 1. Information Capture (Post-Verification)
Triggered immediately after `solution-verifier` confirms a success or handles a failure.
*   **From Successes**: Extract the "Learning Point" from the Solution Memory.
*   **From Failures**: Capture the "Intuitive Clue" provided by the user, unresolved clues, and the root cause of the failure.
*   **From Hot Spots**: Document the architectural pivot validated by the user in `hot-spot-proposer`.
*   **From User Inputs**: Record which user-provided clues were high-signal, low-signal, or misleading.

### 2. Management of Routing and Durable Docs
Update the central ruleset to refine how `sdd_agent` routes tasks:
*   **Rule Compounding**: If a specific component pattern is repeatedly successful (or failing), codify it as a mandatory "Pre-flight" check in `.github/agent-workflows/orchestrate.md` or the relevant `.github/agent-context/` doc.
*   **Inconsistency Removal**: Prune rules that have become redundant due to new architectural standards (e.g., removing NgRx legacy rules once a feature is fully Signal-based).

### 3. Maintenance of the Learning Log
Maintain a chronological learning record in session memory and durable repo docs that includes:
*   **Decision Records**: Why a specific architectural choice was made (e.g., "Chose rxResource over linkedSignal for AuthWizard due to X").
*   **Pattern Evolution**: Tracks the migration from legacy to standard patterns.
*   **Clue Effectiveness Ledger**: `Clue → Interpretation → Outcome`.

### 4. Synchronization with SSOT
*   **Project Details**: If a new library or version was identified, invoke `project-details-generator` to update the SSOT.
*   **Component Map**: Ensure `AGENTS.md` reflects any new documentation created during the session.

## Decision Rules
*   **Patterns > Prose**: Do not record long stories. Record "Problem → Pattern Applied → Result".
*   **Evidence > Assumption**: Promote only clues that repeatedly correlate with correct outcomes.
*   **No Duplication**: Before adding a new routing or doc rule, verify if it's already covered by a generic standard in `project-rules.md`.
*   **Mandatory Context**: Every entry in the log must link to the specific `.github/agent-context/` file or `.github/agent-workflows/orchestrate.md` section it refers to.

## Output Format
Return a Knowledge Update Summary:
*   **New Rules Added**: List of updates to `.github/agent-workflows/orchestrate.md` or relevant `.github/agent-context/` docs.
*   **Log Entry**: A summary of the lesson learned for the `learning-log.md`.
*   **Clue Learning**: Which user clues improved precision and which stayed unresolved.
*   **Precision Impact**: Estimated improvement for future tasks (e.g., "Reduced ambiguity in Signal-syncing for future wizards").

## Constraints
- **PROHIBITED**: Recording long prose without a structured "Problem → Pattern → Result" format.
- **PROHIBITED**: Adding redundant rules that duplicate existing standards in `project-rules.md`.
- **MANDATORY**: Linking every log entry to a specific `.github/agent-context/` file or `.github/agent-workflows/orchestrate.md` section.
- **MANDATORY**: Capturing unresolved high-signal clues as follow-up gaps when they cannot be validated yet.

## Examples

### Example 1: Successful Fix Learning
**Source**: Solution Memory from `solution-verifier`.
**New Rules Added**:
- Pre-flight check: "Verify no manual `.subscribe()` exists in data-heavy services before adding new endpoints."

**Log Entry**:
- *Decision*: Migrated `data.service.ts` to `rxResource`.
- *Reason*: Manual subscriptions caused memory leaks in wizard flows.
- *Context*: `.github/agent-context/angular-reactivity/resource-api.md`

**Clue Learning**:
- *High-signal clue*: Stack trace pointing to manual `.subscribe()`.
- *Low-signal clue*: Generic screenshot with no error metadata.

**Precision Impact**: "Eliminates 90% of subscription leak bugs in future data integrations."

### Example 2: Hot Spot Pivot Learning
**Source**: Hot Spot validated by user in `hot-spot-proposer`.
**New Rules Added**:
- "For components >900 lines, always extract sub-components before adding new state."

**Log Entry**:
- *Decision*: Extracted `filter-bar` from `client-dashboard` instead of adding logic inline.
- *Reason*: User validated that inline logic would exceed complexity threshold.
- *Context*: `.github/agent-context/AGENTS.md`

**Precision Impact**: "Reduces architectural Hot Spots by forcing decomposition at the proposal phase."