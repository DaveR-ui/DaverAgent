---
last_updated: 2026-04-29
status: active
ai_optimized: yes
tags: [routing, workflows, reference]
---

# Task Routing Reference

> Use this file after the task is clear.
> This is a routing reference for `sdd_agent` and subagents, not a separate coordination layer.

## Pre-flight

Before routing the task:

1. Read [AGENTS.md](../agent-context/AGENTS.md) and check the Component Map.
2. Read [agent-contracts.md](agent-contracts.md) for the canonical capability, response-contract registry, and **Model Selection Policy**.
3. Use [_TAG-INDEX.md](../agent-context/_TAG-INDEX.md) when the right doc is unclear.
4. Confirm prompt clarity with [prompt-analyzer](../skills/prompt-analyzer/SKILL.md).
5. Apply repo guardrails from [project-rules.md](../agent-context/project-rules.md).

If the prompt contains multiple objectives, normalize before routing: split the objectives, identify the most bounded feasible slice, and keep the remaining objectives as explicit follow-up work. Do not route a multi-objective prompt as one broad "change everything" task.

## Intent Fast Paths

Route by user intent before invoking the full implementation workflow.

The canonical mapping for these fast paths lives in [agent-contracts.md](agent-contracts.md#routing-fast-paths).
This file owns the routing procedure, not the capability matrix or model policy.

When routing lands on `SDD Agent`, prefer lightweight orchestration:
1. discover the current slice and clue quality,
2. decide the bounded change, validation path, and **target model** based on complexity,
3. hand off to `Implementer` or `Reviewer`.

Do not force `Explore` and `Supplier` as serial steps when the task is already well bounded and the governing docs are clear.

## Task-Scoped Session State

For any orchestrated slice that reaches `SDD Agent`, use task-scoped session artifacts instead of single-slot files:

1. Assign or reuse a stable `task-id` for the bounded slice.
2. Persist the approved plan at `/memories/session/plans/<task-id>.md`.
3. Persist verification and test summaries at `/memories/session/test-runs/<task-id>.md`.
4. Preserve the same `task-id` across `SDD Agent` → `Implementer` → `Reviewer` handoffs.
5. Use session root summaries only for optional indexing or end-of-session compaction, never as the canonical per-task artifact.

## Routing Table

| Task keyword | Primary context | Skill |
|---|---|---|
| Feature flag / LaunchDarkly | [launchdarkly-flags.md](../agent-context/launchdarkly-flags.md) | [launchdarkly-flags](../skills/launchdarkly-flags/SKILL.md) |
| Access modal / IAM | [access-modal.md](../agent-context/simple-features/access-modal.md) | — |
| Access selector / async dropdown | [access-modal.md](../agent-context/simple-features/access-modal.md) | [angular-reactivity](../skills/angular-reactivity/SKILL.md) |
| Confirm / approval modal | [confirmation-modal.md](../agent-context/special-components/confirmation-modal.md) | [modal-creation](../skills/modal-creation/SKILL.md) |
| Generic modal | [modal-creation.md](../agent-context/modal-creation.md) | [modal-creation](../skills/modal-creation/SKILL.md) |
| AG Grid / sub-table | [ag-grid-implementation.md](../agent-context/aggrid/ag-grid-implementation.md) | [ag-grid-standard](../skills/ag-grid-standard/SKILL.md) |
| Dropdowns | [dropdown-components.md](../agent-context/special-components/dropdown-components.md) | — |
| Reactive HTTP data loading | [resource-api.md](../agent-context/angular-reactivity/resource-api.md) | [angular-http](../skills/angular-http/SKILL.md) |
| Signals / computed / linkedSignal | [resource-api.md](../agent-context/angular-reactivity/resource-api.md) | [angular-signals](../skills/angular-signals/SKILL.md) |
| Unit tests | [testing.md](../agent-context/angular-reactivity/testing.md) | [angular-testing](../skills/angular-testing/SKILL.md) |
| Form validators / feedback | [project-rules.md](../agent-context/project-rules.md) | [angular-forms](../skills/angular-forms/SKILL.md) |
| Component-scoped services | [service-management.md](../agent-context/service-management.md) | [angular-di](../skills/angular-di/SKILL.md) |
| Authview wizard | [wizard-logic.md](../agent-context/authviews/wizard-logic.md) | — |
| json-server / mock routes | [json-server-mocking.md](../agent-context/json-server-mocking.md) | [feature-mocking](../skills/feature-mocking/SKILL.md) |
| NgRx migration / removal | [removing-ngrx-store.md](removing-ngrx-store.md) | [angular-signals](../skills/angular-signals/SKILL.md) |
| New component skeleton | [coding-conventions.md](../agent-context/coding-conventions.md) | [angular-component](../skills/angular-component/SKILL.md) |
| Routing / guards / resolvers | [architecture.md](../agent-context/architecture.md) | [angular-routing](../skills/angular-routing/SKILL.md) |
| Create / update documentation | [AGENTS.md](../agent-context/AGENTS.md) | `Documentador` + [generate-documentation](../skills/generate-documentation/SKILL.md) |
| Read-only codebase question / architecture lookup | [AGENTS.md](../agent-context/AGENTS.md) | `Custom asker` |
| Scope / blast-radius discovery | [AGENTS.md](../agent-context/AGENTS.md) | `Explore` + [scope-explorer](../skills/scope-explorer/SKILL.md) |
| Pull request review / full diff code review | [github-pr-fetch.md](../agent-context/github-pr-fetch.md) | `pr-reviewer` + [gitkraken-pr-analysis](../skills/gitkraken-pr-analysis/SKILL.md) |
| Review / validate implementation | [project-rules.md](../agent-context/project-rules.md) | `Reviewer` + [solution-verifier](../skills/solution-verifier/SKILL.md) |

## Reusable Routing Notes

### Access Modal / IAM
1. Read [access-modal.md](../agent-context/simple-features/access-modal.md).
2. For async selection sync, also read [dropdown-components.md](../agent-context/special-components/dropdown-components.md) and [resource-api.md#linkedsignal--selection-synchronization](../agent-context/angular-reactivity/resource-api.md#linkedsignal--selection-synchronization).
3. For data-flow bugs, also apply the complex data flow rules section in [project-rules.md](../agent-context/project-rules.md).

### AG Grid
1. Read [ag-grid-implementation.md](../agent-context/aggrid/ag-grid-implementation.md).
2. Check [ag-grid-errors.md](../agent-context/aggrid/troubleshooting/ag-grid-errors.md) for known failures.

### Reactive HTTP Data
1. Read [resource-api.md](../agent-context/angular-reactivity/resource-api.md).
2. Guard against resource error state before reading `.value()`.
3. For tests, pair [testing.md](../agent-context/angular-reactivity/testing.md) with [angular-testing](../skills/angular-testing/SKILL.md).

### Documentation
1. Route documentation-only work to the `Documentador` agent.
2. Follow [generate-documentation](../skills/generate-documentation/SKILL.md).
3. After creating a context doc, update the Component Map in [AGENTS.md](../agent-context/AGENTS.md).
4. Documentation-only tasks do not require build/test/lint; validate by diff quality, markdown structure, and wording consistency.

### Read-Only Q&A
1. Route explanation, navigation, and architecture questions to the `Custom asker` agent.
2. Start with [AGENTS.md](../agent-context/AGENTS.md) and the matching local doc before reading implementation files.
3. If the user pivots from a question to a change request, escalate to `SDD Agent` for orchestration.

### Scope Discovery
1. Route blast-radius discovery and affected-file lookup to the `Explore` agent.
2. Apply [scope-explorer](../skills/scope-explorer/SKILL.md) to classify the scope and map clues to assets.
3. If dense undocumented logic is found, flag documentation debt before planning implementation.

### Review And Verification
1. Route post-implementation review or validation requests to the `Reviewer` agent.
2. Apply [solution-verifier](../skills/solution-verifier/SKILL.md) for consensus, verification mode, and reporting.
3. **Execution Rule**: Whenever any agent executes tests or verification commands, a concise summary of the run must be persisted to the canonical task-scoped session memory path: `/memories/session/test-runs/<task-id>.md`.
4. Use documentation-only validation instead of tests when the scope is limited to `.github/`.

### Pull Request Review
1. Route read-only PR review and branch diff assessment to the `pr-reviewer` agent.
2. Start with [github-pr-fetch.md](../agent-context/github-pr-fetch.md) and [gitkraken-pr-analysis](../skills/gitkraken-pr-analysis/SKILL.md).
3. Prefer VS Code active PR context plus local repository diff for full coverage before reporting findings.
4. Apply [project-rules.md](../agent-context/project-rules.md) as the anti-pattern baseline.

## Quick Error Lookup

| Error / Symptom | Go to |
|---|---|
| `Resource is currently in an error state` | [testing.md#critical-error-state-handling-in-effects](../agent-context/angular-reactivity/testing.md#critical-error-state-handling-in-effects) |
| `NG01353` with `ngModelGroup` | [testing.md#controlcontainer-mocking-for-ngmodelgroup](../agent-context/angular-reactivity/testing.md#controlcontainer-mocking-for-ngmodelgroup) |
| rxResource test timing failures | [testing.md#critical-testbedflusheffects-timing](../agent-context/angular-reactivity/testing.md#critical-testbedflusheffects-timing) |
| Dropdown not syncing with async data | [access-modal.md](../agent-context/simple-features/access-modal.md) and [resource-api.md#linkedsignal--selection-synchronization](../agent-context/angular-reactivity/resource-api.md#linkedsignal--selection-synchronization) |
| Modal not opening / `DialogRef` missing | [modal-creation.md](../agent-context/modal-creation.md) |
| Feature flag not toggling | [launchdarkly-flags.md](../agent-context/launchdarkly-flags.md) |
