---
name: memory-learner
description: Orchestration & Learning skill. Manages ORCHESTRATOR-RULES.md and the learning log. Captures architectural decisions and lessons learned to create a "compounding effect" for future agent precision.
last_updated: 2026-05-11
status: active
---

# 🧠 Skill: Memory Learner (Orchestration & Learning)

## Goal
Responsible for the long-term intelligence of the ecosystem. Transform ephemeral session data (fixes, pivots, errors) stored in `.agents/cache-session/<session-id>/` into persistent architectural rules and logs in `.agents/context/`, ensuring that the system evolves and avoids repeating past mistakes.

## Instructions

### 1. Information Capture (Post-Verification)
Triggered immediately after `solution-verifier` confirms a success or handles a failure.
*   **From Successes**: Extract the "Learning Point" from the Solution Memory.
*   **From Failures**: Capture the "Intuitive Clue" provided by the user and the root cause of the failure.
*   **From Hot Spots**: Document the architectural pivot validated by the user in `hot-spot-proposer`.

### 2. Management of Orchestrator Rules
Update the central ruleset to refine how the orchestrator routes tasks:
*   **Rule Compounding**: If a specific component pattern is repeatedly successful (or failing), codify it as a mandatory "Pre-flight" check in `.agents/context/memory/task-memory.md`.
*   **Inconsistency Removal**: Prune rules that have become redundant due to new architectural standards (e.g., removing NgRx legacy rules once a feature is fully Signal-based).

### 3. Maintenance of the Learning Log
Maintain a chronological log within `.agents/context/memory/task-memory.md` that includes:
*   **Decision Records**: Why a specific architectural choice was made (e.g., "Chose rxResource over linkedSignal for AuthWizard due to X").
*   **Pattern Evolution**: Tracks the migration from legacy to standard patterns.

### 4. Synchronization with SSOT
*   **Project Details**: If a new library or version was identified, invoke `project-details-generator` to update the SSOT.
*   **Component Map**: Ensure `AGENTS.md` reflects any new documentation created during the session.

## Decision Rules

### Relevance Filter (Noise Reduction)
Before recording any learning, the agent MUST evaluate if it meets the **Worthy of Record** threshold. A learning is only recorded if it satisfies at least ONE of the following criteria:
*   **Multi-Attempt Resolution**: Resolved an error that required more than 2 attempts or iterations to fix.
*   **Cross-Component Impact**: Involves an architectural decision that affects more than one component or service.
*   **User-Confirmed Style Preference**: Represents a style or UX preference explicitly confirmed by the user that is NOT already documented in `project-rules.md`.

If a learning does NOT meet any of these criteria, it is classified as **Noise** and MUST be discarded. Do not log trivial one-off fixes, typos, or obvious standard patterns.

### Rule Reconciliation Policy
Before adding a new rule to `.agents/context/memory/task-memory.md`, the skill MUST:
1.  **Scan `project-rules.md`** for existing rules that cover the same domain.
2.  **Check for Contradictions**: If the proposed rule contradicts or weakens an existing global rule, the **global rule (`project-rules.md`) takes precedence**.
3.  **Override Protocol**: If the user explicitly authorizes an override of a global rule, document it as:
    ```
    [OVERRIDE] Global rule: "{original rule}" → Session-specific override: "{new rule}" (Authorized by user on {date})
    ```
    Overrides MUST be flagged for review during the next pruning cycle.

### Pruning Mechanism
The skill MUST periodically scan `.agents/context/memory/task-memory.md` and identify entries eligible for removal or archival:
*   **Age Threshold**: Entries older than **10 sessions** that have not been referenced or triggered in recent sessions are candidates for archival.
*   **Framework Supersession**: Entries that have been rendered obsolete by a new framework version or completed migration (e.g., legacy patterns fully replaced by Signals, deprecated APIs removed) MUST be flagged for deletion.
*   **Override Expiration**: User-authorized overrides that have not been re-confirmed in the last 5 sessions are candidates for reversion to the global rule.

When pruning, the skill MUST output a **Pruning Report** listing entries removed, the reason (age/supersession/override expiration), and the session in which they were originally recorded.

### Compact Format Enforcement
Every log entry MUST follow the strict **"Problem → Pattern → Result"** format with a maximum of **3 lines per entry**. No exceptions. Prose, narratives, or multi-paragraph explanations are prohibited in the learning log.

## Output Format
Return a Knowledge Update Summary:
*   **New Rules Added**: List of updates to task memory and orchestrator rules.
*   **Log Entry**: A summary of the lesson learned for `.agents/context/memory/task-memory.md`.
*   **Precision Impact**: Estimated improvement for future tasks (e.g., "Reduced ambiguity in Signal-syncing for future wizards").
*   **Pruning Report** (if applicable): Entries removed or archived with reason.

## Constraints
- **PROHIBITED**: Recording long prose without a structured "Problem → Pattern → Result" format.
- **PROHIBITED**: Adding redundant rules that duplicate existing standards in `project-rules.md`.
- **PROHIBITED**: Recording learnings that do not pass the Relevance Filter (Noise Reduction).
- **PROHIBITED**: Adding rules that contradict `project-rules.md` without explicit user Override authorization.
- **MANDATORY**: Linking every log entry to a specific file or feature folder in `.agents/context/`.
- **MANDATORY**: Enforcing the 3-line maximum per log entry (Problem → Pattern → Result).
- **MANDATORY**: Running the Pruning Mechanism scan before appending new entries to prevent Token Bloat.

## Examples

### Example 1: Successful Fix Learning
**Source**: Solution Memory from `solution-verifier`.
**New Rules Added**:
- Pre-flight check: "Verify no manual `.subscribe()` exists in data-heavy services before adding new endpoints."

**Log Entry**:
- Problem: Manual subscriptions caused memory leaks in wizard flows.
- Pattern: Migrated `data.service.ts` to `rxResource()` with `toSignal()` for consumption.
- Result: Zero leak reports in subsequent sessions; `.agents/context/data-logic/`

**Precision Impact**: "Eliminates 90% of subscription leak bugs in future data integrations."

### Example 2: Hot Spot Pivot Learning
**Source**: Hot Spot validated by user in `hot-spot-proposer`.
**New Rules Added**:
- "For components >900 lines, always extract sub-components before adding new state."

**Log Entry**:
- Problem: `client-dashboard` exceeded 900 lines with inline filter logic.
- Pattern: Extracted `filter-bar` as standalone child component; parent delegates via signal input.
- Result: Component decomposed to 420 lines; `.agents/context/client-dashboard/`

**Precision Impact**: "Reduces architectural Hot Spots by forcing decomposition at the proposal phase."

### Example 3: Rejection by Relevance Filter
**Source**: Session fix for a typo in a template variable.
**Decision**: Discarded — does not meet Relevance Filter criteria (single-attempt fix, no cross-component impact, no style preference).
**Action**: No log entry created.

### Example 4: Rule Reconciliation with Override
**Source**: User requests exception to global rule for a specific legacy component.
**Conflict Detected**: Global rule in `project-rules.md` states "All new components MUST be standalone." User requests NgModule-based component for legacy integration.
**Resolution**: `[OVERRIDE] Global rule: "All new components MUST be standalone." → Session-specific override: "Allow NgModule declaration for `legacy-adapter` component only" (Authorized by user on 2026-05-11)`
**Log Entry**:
- Problem: Legacy backend requires NgModule-based lifecycle hooks not available in standalone.
- Pattern: Created `legacy-adapter` as NgModule component; isolated from rest of app.
- Result: Integration functional; override flagged for review in 5 sessions; `.agents/context/legacy-adapter/`
