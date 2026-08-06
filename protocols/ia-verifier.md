# Protocol: IA Verifier

Verification and memory phase: run the verification plan defined in [analyzer](./ia-analyzer.md) and [proposer](./ia-proposer.md), produce a Solution Memory on success for orchestrator learning, and run a failure analysis with user feedback on error.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-verifier`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

Last stage of the IA pipeline, immediately after execution. The verifier is the final gatekeeper: it confirms the intervention meets the success criteria defined upstream and starts the post-execution knowledge cycle. Skipping it (or its native equivalent) is treated as silent failure.

## Test execution and validation

- Execute the verification plan identified during [analyzer](./ia-analyzer.md) and [proposer](./ia-proposer.md).
- Use the slice's testing standards (e.g. Vitest / Playwright for frontend, `go test` for backend) to run unit and integration tests.
- Confirm the **success criteria** are met and that no regression occurs in the identified **source of truth**.
- Check the result against "Anti-patterns" in `docs/context/rules.md` to make sure the fix did not introduce a banned pattern (e.g. `setTimeout` re-introduced during a refactor).

## Success path — solution memory

If all tests pass, generate a **Solution Memory** for the orchestrator. This document must be concise and formatted for AI consumption:

- **Root cause** — briefly describe what was actually wrong.
- **Fix summary** — the specific logic or pattern applied (e.g. "migrated to `rxResource` with status check").
- **Files touched** — list of modified files.
- **Learning point** — a specific tip for the orchestrator to avoid this error in the future, or to reuse this pattern in similar components.

## Failure path — analysis and recovery

If tests fail or the success criteria are not met, follow this recovery protocol:

- **Local diff analysis** — perform a `git diff` to analyze recent changes against the standards in `docs/context/rules.md`.
- **PR context** — if working on a Pull Request, fetch comments or previous review feedback that might explain the failure.
- **Intuitive-clue seeking** — stop and ask the user for "intuitive clues":
  > "The fix failed verification. Based on your knowledge of the system, do you have any 'gut feeling' or clues about side effects or hidden dependencies I might be missing?"
- **Retry logic** — incorporate the user's clue into a refined plan and return to the [proposer](./ia-proposer.md) phase.

## Decision rules

- **No silent failures** — if a test fails, you cannot proceed to commit. You must perform the failure analysis.
- **Memory mandate** — every successful task must end with a Solution Memory persisted to the session cache, to eventually populate `docs/context/memory/`.
- **Standard alignment** — verification must include a check against "Anti-patterns" (e.g. ensuring no `setTimeout` was introduced during the fix).
- **One question block** — group all clarifications into a single message; do not pepper the user across multiple turns.

## Output format

Return a Verification Report:

- **Verification status** — `PASSED` or `FAILED`.
- **Test results** — summary of tests executed.
- **Solution memory** (if success) — root cause, fix, and learning point.
- **Recovery plan** (if failure) — analysis of the diff and the specific question for the user.

## Constraints

- **PROHIBITED**: proceeding to commit or task completion without running the verification plan.
- **PROHIBITED**: generating a Solution Memory if tests have not passed.
- **MANDATORY**: checking against anti-patterns before declaring success.

## Integration

In the opencode runtime, this role is split across two native subagents:

- [tester](../agents/subagents/tester.md) — runs the test plan and reports coverage / pass / fail.
- [reviewer](../agents/subagents/reviewer.md) — performs the standards / anti-pattern check and the diff analysis.

The orchestrator composes their outputs and decides whether to declare success, request a retry, or hand back to [proposer](./ia-proposer.md) (Phase 2 Reduce) for a refined plan. The Solution Memory format above is a useful input to the [learner](./ia-learner.md) protocol when memory is ready to be promoted.
