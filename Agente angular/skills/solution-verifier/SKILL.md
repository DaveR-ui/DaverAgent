---
name: solution-verifier
description: Verification and Memory phase skill. Executes verification plans (tests), generates "Solution Memory" on success for `sdd_agent` learning, and performs failure analysis with user feedback on error.
last_updated: 2026-04-24
status: active
---

# ✅ Skill: Solution Verifier (Verification & Memory)

## Goal
Act as the final gatekeeper of the development flow. Ensure that the intervention meets the success criteria defined in the `prompt-analyzer` phase and manage the post-execution knowledge cycle.
Testing is a dedicated stage that starts after the solution is consensuated with the user, so teams can focus on solution design first and avoid reworking tests on every intermediate change.

## Instructions

### 1. Consensus Gate (Mandatory)
Before running full verification, ask for explicit confirmation that the solution is stable enough to enter the test stage.
If consensus is not reached, keep iterating on the solution and defer full test execution.

### 2. Verification Mode Selection (Mandatory)
After consensus is confirmed, offer two modes and let the user choose:
*   **Agent-Executed Verification**: the agent runs tests and reports outcomes.
*   **User-Executed Verification (Guided)**: the user runs tests following instructions provided by the agent.

### 3. Test Execution & Validation
If **Agent-Executed Verification** is selected:
*   **Action**: Execute the post-consensus verification plan identified during the `prompt-analyzer` and `hot-spot-proposer` phases.
*   **Context**: Use `angular-testing` standards (Vitest/Jasmine) to run unit and integration tests.
*   **Result Persistence (MANDATORY)**:
    *   **Persist Summary**: Save a concise summary of the test execution to the canonical task-scoped session memory path: `/memories/session/test-runs/<task-id>.md`.
    *   **Summary Content**: Include the command executed, overall pass/fail status, failing test names when present, and the key diagnostic lines needed for the next decision.
    *   **Context Injection on Failure**: If tests fail, extract the failing test names, stack traces, and relevant diagnostic lines and inject them into the active context (via `insert` in session memory) to prevent rerunning tests blindly.
*   **Check**: Verify that the "Success Criteria" are met and that no regression occurs in the identified "Source of Truth".

If **User-Executed Verification (Guided)** is selected:
*   **Action**: Provide a concise testing handoff that includes:
    *   exact commands to run,
    *   prerequisites/environment assumptions,
    *   expected pass/fail signals,
    *   what evidence the user should return (command output summary, failed test names, screenshots/log snippets if needed).
*   **Status Handling**: mark the task as `AWAITING_USER_VERIFICATION` until the user shares results.
*   **Check**: Evaluate user evidence against the agreed success criteria before marking the task as PASSED or FAILED.

### 4. ✅ Case: SUCCESS (Solution Memory)
If all tests pass, generate a **"Solution Memory"** for `sdd_agent`. This document must be concise and formatted for AI consumption:
*   **Root Cause**: Briefly describe what was actually wrong.
*   **Fix Summary**: The specific logic or pattern applied (e.g., "Migrated to rxResource with status check").
*   **Files Touched**: List of modified files.
*   **Learning Point**: A specific tip for `sdd_agent` to avoid this error in the future or to reuse this pattern in similar components.
*   **Clue Effectiveness**: Which user-provided clues were high-signal, low-signal, or unresolved.

### 6. Session Preservation & Compounding
*   **Memory Management**: At the end of the session, review session memory (/memories/session/) and "compact" it.
    *   **Action**: Summarize successful task-scoped test runs and failure analysis into a single "Post-Session debrief" file.
    *   **Action**: Delete verbose raw test logs once the analysis is summarized.
    *   **Goal**: Ensure only actionable information remains for future sessions while keeping the context window clean.

## Decision Rules
*   **No Silent Failures**: If a test fails, you cannot proceed to commit. You must perform the failure analysis.
*   **Memory Mandate**: Every successful task must end with a Solution Memory in session memory and, when durable guidance changes, a follow-up update to `.github/agent-workflows/orchestrate.md` or the relevant `.github/agent-context/` doc.
*   **Task-Scoped Test Summary**: `/memories/session/test-runs/<task-id>.md` is the canonical session artifact for test and verification evidence tied to that bounded slice. Only compacted learnings and Solution Memories should be persisted to repository memory if durable knowledge was acquired.
*   **Standard Alignment**: Verification must include a check against "Anti-patterns" (e.g., ensuring no `setTimeout` was introduced during the fix).
*   **Mode Transparency**: Every report must state whether verification was agent-executed or user-executed guided.
*   **Deferred Full Testing**: Avoid rewriting/rerunning full suites on each intermediate implementation tweak before consensus; reserve full verification for the post-consensus test stage.

## Output Format
Return a Verification Report:
*   **Consensus Status**: [NOT_REACHED / REACHED]
*   **Verification Mode**: [Agent-Executed / User-Executed-Guided]
*   **Verification Status**: [PASSED / FAILED / AWAITING_USER_VERIFICATION]
*   **Test Results**: Summary of tests executed or user-provided evidence.
*   **User Test Guide (if User-Executed-Guided)**: commands, expected results, and evidence checklist.
*   **Solution Memory (if Success)**: Root Cause, Fix, Learning Point, and Clue Effectiveness.
*   **Recovery Plan (if Failure)**: Analysis of the diff and the specific question for the user.

## Constraints
- **PROHIBITED**: Proceeding to commit or task completion without running the verification plan.
- **PROHIBITED**: Generating a Solution Memory if tests have not passed.
- **PROHIBITED**: Marking PASSED in user-executed mode without user evidence.
- **PROHIBITED**: Running full verification before consensus unless the user explicitly asks for an early run.
- **MANDATORY**: Checking against Anti-patterns before declaring success.

## Examples

### Example 1: Successful Fix
**Verification Status**: PASSED
**Test Results**: 12/12 unit tests passed. No regressions.
**Solution Memory**:
- *Root Cause*: Memory leak from manual `.subscribe()` without unsubscription.
- *Fix Summary*: Replaced manual subscription with `toSignal()` in `data.service.ts`.
- *Files Touched*: `src/features/data/services/data.service.ts`
- *Learning Point*: Always prefer `toSignal()` or `rxResource()` over manual `.subscribe()` in Angular 21+ components.
- *Clue Effectiveness*: High-signal stack trace identified the leaking subscription; a generic UI screenshot was low-signal.

### Example 2: Failed Fix
**Verification Status**: FAILED
**Test Results**: 3/12 tests failed. `should update on input change` broke.
**Recovery Plan**:
- *Diff Analysis*: Change in `input()` binding caused missing `computed()` re-evaluation.
- *Question for User*: "Do you know of any downstream components that might depend on the old input signal name?"

### Example 3: User-Executed Verification (Guided)
**Verification Mode**: User-Executed-Guided
**Verification Status**: AWAITING_USER_VERIFICATION
**User Test Guide**:
- Run: `npm run test -- --watch=false`
- Expected: target specs pass and no new regressions in related suites.
- Share back: pass/fail summary, failing test names, and key error output.

### Example 4: Consensus Not Reached Yet
**Consensus Status**: NOT_REACHED
**Verification Status**: AWAITING_USER_VERIFICATION
**Next Step**:
- Continue refining the solution and defer full test stage until user confirms consensus.