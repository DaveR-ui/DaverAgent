# Protocol: IA Supplier

Knowledge middleware: filter the project's canonical documentation based on task type (Bug, Feature, Test) and deliver only the relevant "delta" to downstream phases, while flagging technical debt before code is written.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-supplier`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

After [explorer](./ia-explorer.md) has produced a scope report and before [proposer](./ia-proposer.md) builds the action plan. The supplier narrows what the proposer sees, so that the plan is grounded in the right slice of documentation without flooding the prompt.

## Task-based context filtering

Depending on the task type identified in the [analyzer](./ia-analyzer.md) phase, retrieve only the specific rule sets:

| Task type | Documentation to load |
|---|---|
| **Bug fix** | `docs/context/rules.md` (anti-patterns section), the slice's `common-errors.md` or equivalent, and the anti-pattern entries in the relevant component doc. |
| **Feature** | `docs/context/rules.md` (standards section) and the slice's "Standard Patterns" (Signals, `rxResource`, etc.). |
| **Test** | The slice's testing standards (Vitest / Playwright / Go test) and the framework-specific guides. |

The mapping from frontend-skill paths to this workspace:

| Frontend path | Workspace equivalent |
|---|---|
| `.agents/context/project/rules.md` | `docs/context/rules.md` |
| `.agents/context/standards/angular-reactivity/testing.md` | The relevant slice's testing doc |
| `.agents/context/memory/troubleshooting/common-errors.md` | The slice's `errors.md` or `common-errors.md` |

## Token optimization (knowledge delta)

- Analyze the **orchestrator context** (what has already been read in this session).
- **Deduplicate**: if `rules.md` was already loaded, do not provide it again. Deliver only the delta — the specific sections of the component doc or skill references that are new.

## Technical-debt and inconsistency scan

Before delivering the context package, scan the identified files for:

- **Stale docs**: metadata older than 6 months, or status marked `(WIP)` or `(TODO)`.
- **Inconsistent patterns**: if the component doc lists an "Anti-pattern" that the orchestrator just encountered in a recent search, flag it immediately.
- **Missing SSOT**: lack of a primary doc for a component involved in a "Complex" task.

## Decision rules

- **Strict delivery**: never send the full `docs/context/` folder. Only send the specific files mapped in the routing table of `docs/project.md` (Slices).
- **Debt blocker**: if inconsistent patterns are found (e.g. a service using `setTimeout` when the task is to add a signal), the agent must issue a **DEBT ALERT** and suggest refactoring as part of the plan.
- **Language guard**: all delivered context must be in English for AI consumption. Debt alerts for the user may follow the project doc language (this workspace: English).

## Output format

Return a Context Package:

- **Relevant docs** — list of provided file paths from `docs/context/`.
- **Delta context** — snippets of new rules/patterns not previously seen in the session.
- **DEBT ALERTS**:
  - *Detected pattern* — e.g. manual subscription found in source of truth.
  - *Required standard* — e.g. migration to `rxResource` required.
  - *Impact* — High / Medium / Low.

## Constraints

- **PROHIBITED**: dumping the entire `docs/context/` directory into the prompt.
- **PROHIBITED**: ignoring stale or inconsistent documentation without flagging it.
- **MANDATORY**: delivering only the delta context to avoid token waste.

## Integration

In the opencode runtime, the [project-context subagent](../agents/subagents/project-context.md) is the canonical read-only doc lookup. Use the supplier protocol above when the orchestrator wants **filtered + delta + debt-flagging** delivery, which is more than a raw lookup. The supplier should be invoked by the orchestrator (or by Delivery on a non-trivial routed prompt) once the [explorer](./ia-explorer.md) has set the scope and before the [proposer](./ia-proposer.md) drafts the plan.
