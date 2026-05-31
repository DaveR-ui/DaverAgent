---
name: solution-verifier
description: Verification and Memory phase skill. Executes verification plans (tests), generates "Solution Memory" on success for orchestrator learning, and performs failure analysis with user feedback on error.
last_updated: 2026-04-24
status: active
---

# ✅ Skill: Solution Verifier (Verification & Memory)

## Goal
Act as the final gatekeeper of the development flow. Ensure that the intervention meets the success criteria defined in the `prompt-analyzer` phase and manage the post-execution knowledge cycle.

## Instructions

### 1. Test Execution & Validation
*   **Action**: Execute the verification plan identified during the [prompt-analyzer](../p3-ia-analyzer/SKILL.md) and [hot-spot-proposer](../p3-ia-proposer/SKILL.md) phases.
*   **Context**: Use [angular-testing](../p1-framework-angular-testing/SKILL.md) standards (Vitest/Jasmine) to run unit and integration tests.
*   **Check**: Verify that the "Success Criteria" are met and that no regression occurs in the identified "Source of Truth".

### 2. ✅ Case: SUCCESS (Solution Memory)
If all tests pass, generate a **"Solution Memory"** for the Orchestrator. This document must be concise and formatted for AI consumption:
*   **Root Cause**: Briefly describe what was actually wrong.
*   **Fix Summary**: The specific logic or pattern applied (e.g., "Migrated to rxResource with status check").
*   **Files Touched**: List of modified files.
*   **Learning Point**: A specific tip for the orchestrator to avoid this error in the future or to reuse this pattern in similar components.

### 3. ❌ Case: FAILURE (Analysis & Recovery)
If tests fail or the success criteria are not met, follow this recovery protocol:
*   **Local Diff Analysis**: Perform a `git diff` to analyze recent changes against the standards in `.agents/context/project/rules.md`.
*   **PR Context**: If working on a Pull Request, fetch comments or previous review feedback that might explain the failure.
*   **Intuitive Clue Seeking**: Stop and ask the user for "intuitive clues".
    *   *Prompt*: "The fix failed verification. Based on your knowledge of the system, do you have any 'gut feeling' or clues about side effects or hidden dependencies I might be missing?"
*   **Retry Logic**: Incorporate the user's clue into a refined plan and return to the `hot-spot-proposer` phase.

## Decision Rules
*   **No Silent Failures**: If a test fails, you cannot proceed to commit. You must perform the failure analysis.
*   **Memory Mandate**: Every successful task must end with a Solution Memory persisted to `.agents/cache-session/<session-id>/session-memory.md` to eventually populate the `.agents/context/memory/` index.
*   **Standard Alignment**: Verification must include a check against "Anti-patterns" (e.g., ensuring no `setTimeout` was introduced during the fix).

## Output Format
Return a Verification Report:
*   **Verification Status**: [PASSED / FAILED]
*   **Test Results**: Summary of tests executed.
*   **Solution Memory (if Success)**: Root Cause, Fix, and Learning Point.
*   **Recovery Plan (if Failure)**: Analysis of the diff and the specific question for the user.

## Constraints
- **PROHIBITED**: Proceeding to commit or task completion without running the verification plan.
- **PROHIBITED**: Generating a Solution Memory if tests have not passed.
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

### Example 2: Failed Fix
**Verification Status**: FAILED
**Test Results**: 3/12 tests failed. `should update on input change` broke.
**Recovery Plan**:
- *Diff Analysis*: Change in `input()` binding caused missing `computed()` re-evaluation.
- *Question for User*: "Do you know of any downstream components that might depend on the old input signal name?"
