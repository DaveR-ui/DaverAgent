---
name: prompt-analyzer
description: Validate task prompts before implementation so agents start with a clear problem statement, explicit constraints, expected outcomes, and the minimum ambiguity possible.
---

# Prompt Analyzer Skill

## Purpose

Use this skill at the start of complex work to validate whether the task prompt is precise enough to produce a minimal, correct implementation.
The first objective is to detect and classify all user-provided clues, including any attachments or referenced artifacts.

This skill is mandatory for:
- `sdd_agent` before routing non-trivial work.
- New subagents at startup before they begin analysis or implementation.

## What To Check

Review the incoming prompt and confirm whether it clearly states:

1. **Problem**
   - What is broken, missing, or expected to change?
   - What user-visible symptom is happening?

2. **User Clues & Attachments**
   - What did the user provide as evidence: logs, errors, stack traces, screenshots, snippets, links, file paths, commands, or PR references?
   - Consume existing task-scoped session-memory evidence (e.g., `/memories/session/test-runs/<task-id>.md`) if provided from a previous run.
   - **Crucial**: `prompt-analyzer` must NOT execute tests; it only consumes user-provided or session-memory evidence.
   - Which clues are **Direct Evidence** vs **Context Hints** vs **Assumptions**?
   - Which clues are unresolved and require follow-up?

3. **Source of Truth**
   - Which data source, endpoint, state owner, or workflow is authoritative?
   - Which state is stale versus derived?

4. **Task Identity**
   - Does the request continue an existing bounded slice or start a new one?
   - Which `task-id` should be reused or created for the session artifacts?

5. **Expected Outcome**
   - What should be true after the fix?
   - What behavior must remain unchanged?

6. **Constraints & Value Check**
   - Minimal change requirement.
   - **Replacement check**: If the task is to replace existing logic, is the new solution objectively better (simpler, more reactive, less debt)?
   - **Entry point check**: If the prompt supports multiple paths (e.g., Azure vs GCP, Standard vs DRF) that require different source-of-truth or logic, is the entry point disambiguated?
   - **Store/Selector check**: Does the proposal add new NGRX store/selectors? Is it strictly necessary or can it be solved with Signals/local state to avoid accidental complexity and decoupling logic?
   - **Performance/network restrictions**.
   - State preservation requirements.
   - Scope exclusions.

7. **Style Guardrails**
   - Does it respect encapsulation (no parent-leaking styles)?
   - Avoids `:host` for external effects or `::ng-deep` for internal ones.

8. **Verification**
   - How to know the task is solved.
   - Required tests or concrete reproduction steps

## Decision Rules

- If the prompt is already clear enough, proceed without asking unnecessary questions.
- If a missing detail would likely change architecture, data flow, or endpoint choice, stop and ask a short clarifying question.
- If behavior and existing tests appear misaligned, use #tool:vscode/askQuestions to ask a plain-language question (e.g., "Should I update the test to match the new behavior, or fix the behavior to match the test?") instead of abstract "source of truth" terminology.
- If high-signal user clues conflict with each other, ask one targeted question before proceeding.
- Prefer identifying ambiguity early instead of compensating later with extra state flags, duplicate requests, or broad defensive logic.

## Guidance For Better Prompts

When a prompt is weak, suggest improvements in this order:

1. Add the exact broken behavior.
2. Name the source of truth.
3. State the expected final behavior.
4. Add explicit constraints.
5. Add how success should be verified.

## Recommended Prompt Shape

```md
Problem:
- What is wrong right now.

User clues:
- Logs/errors/screenshots/snippets/links/paths provided by the user.
- Classify clues as Direct Evidence, Context Hint, Assumption.

Source of truth:
- Which endpoint/state/workflow should win.

Expected result:
- What should happen after the fix.

Constraints:
- Minimal change.
- Avoid unnecessary requests/state.
- Preserve existing selections/data.

Verification:
- How to reproduce before/after.
- Which tests should pass.
```

## Output Format

Return a short readiness summary with:
- `Prompt clarity: clear` or `Prompt clarity: needs clarification`
- `User clue inventory:` short bullets with clue type and confidence
- `Missing pieces:` short bullets, only if needed
- `Open unknowns:` short bullets, only if needed
- `Implementation risks:` short bullets, only if relevant
- `Recommended refined prompt:` only when the original prompt is not sufficiently precise
