---
last_updated: 2026-05-09
status: active
ai_optimized: yes
tags: [routing, workflows, reference]
---

# Task Routing Reference

> Use this file after the task is clear.
> This is a routing reference for the SDD agent and subagents, not a second orchestrator.

## Pre-flight

Before routing the task:

1. Read [AGENTS.md](../context/orchestration/AGENTS.md) and check the Component Map.
2. Use the pillar tag dictionaries when the right doc is unclear: [tags-p1.md](../context/orchestration/tags-p1.md) · [tags-p2.md](../context/orchestration/tags-p2.md) · [tags-p3.md](../context/orchestration/tags-p3.md)
   Use the stage tag dictionaries when the right doc is unclear: [tags-q0.md](../context/orchestration/tags-q0.md) · [tags-q1.md](../context/orchestration/tags-q1.md) · [tags-q2.md](../context/orchestration/tags-q2.md) · [tags-q3.md](../context/orchestration/tags-q3.md)
3. Confirm prompt clarity with `p3-ia-analyzer`.
4. Apply repo guardrails from [rules.md](../context/project/rules.md).

If the prompt contains multiple objectives, normalize before routing: split the objectives, identify the most bounded feasible slice, and keep the remaining objectives as explicit follow-up work. Do not route a multi-objective prompt as one broad "change everything" task.

## Intent Fast Paths

Route by user intent before invoking the full implementation workflow.

| Intent | Route | Notes |
| --- | --- | --- |
| Read-only question, explanation, navigation, architecture lookup | `Ask` | Prefer this over the orchestrator when no file changes are requested |
| Scope discovery, blast-radius mapping, or asset lookup | `Explore` | Use when the main need is locating files, dependencies, and doc coverage |
| Pull request review, branch diff review, or diff-only code review | `pr-reviewer` | Prefer this over `Reviewer` when the task is a read-only PR assessment based on full diff coverage |
| Post-implementation review or verification | `Reviewer` | Use after a solution exists and evidence or test execution is needed |
| Documentation-only update | `Documentador` | No build/test/lint gate |
| Non-trivial feature, bug, or test change | `SDD Agent` | Use the full 5-phase orchestration flow |

## Routing by Pillar

> Full skill details (path, focus, trigger) are in [SKILLS_INDEX.md](../skills/SKILLS_INDEX.md). Context docs per keyword are in the pillar tag dictionaries.

| Task keyword | Tag Dictionary | Primary Context | Skill |
|---|---|---|---|
| Confirm / approval modal | [tags-p2](../context/orchestration/tags-p2.md) | [confirmation-modal.md](../context/project/special-components/confirmation-modal.md) | `p2-ui-modal` |
| Generic modal | [tags-p2](../context/orchestration/tags-p2.md) | [modal-creation.md](../context/project/modal-creation.md) | `p2-ui-modal` |
| Dropdowns | [tags-p2](../context/orchestration/tags-p2.md) | [dropdown-components.md](../context/project/special-components/dropdown-components.md) | — |
| Tooltips | [tags-p2](../context/orchestration/tags-p2.md) | [tooltip.md](../context/project/special-components/tooltip.md) | — |
| Reactive HTTP / rxResource | [tags-p1](../context/orchestration/tags-p1.md) | [resource-api.md](../context/standards/angular-reactivity/resource-api.md) | `p1-framework-angular-developer` |
| Signals / computed / linkedSignal | [tags-p1](../context/orchestration/tags-p1.md) | [resource-api.md](../context/standards/angular-reactivity/resource-api.md) | `p1-framework-angular-developer` |
| Unit tests | [tags-p1](../context/orchestration/tags-p1.md) | [testing.md](../context/standards/angular-reactivity/testing.md) | `p1-framework-angular-testing` |
| New component skeleton | [tags-p1](../context/orchestration/tags-p1.md) | [coding-conventions.md](../context/standards/coding-conventions.md) | `p1-framework-angular-component` |
| API contracts | [tags-p2](../context/orchestration/tags-p2.md) | [api-contracts.md](../context/project/api-contracts.md) | `p2-proj-navigator` |
| Design / tokens | [tags-p2](../context/orchestration/tags-p2.md) | [design/identity.md](../context/project/design/identity.md) | `p2-design-web` |
| Troubleshooting | [tags-p3](../context/orchestration/tags-p3.md) | [troubleshooting/common-errors.md](../context/memory/troubleshooting/common-errors.md) | `p3-ia-verifier` |
| New feature implementation | [tags-p3](../context/orchestration/tags-p3.md) | [new-feature.md](new-feature.md) | `SDD Agent` + `p1-framework-angular-developer` |
| Storybook component docs | [tags-p3](../context/orchestration/tags-p3.md) | [storybook.md](storybook.md) | `Documentador` |
| Create / update documentation | [tags-p3](../context/orchestration/tags-p3.md) | [AGENTS.md](../context/orchestration/AGENTS.md) | `Documentador` + `p3-ia-docs-gen` |
| Read-only question / architecture lookup | [tags-p3](../context/orchestration/tags-p3.md) | [AGENTS.md](../context/orchestration/AGENTS.md) | `Ask` |
| Scope / blast-radius discovery | [tags-p3](../context/orchestration/tags-p3.md) | [AGENTS.md](../context/orchestration/AGENTS.md) | `Explore` + `p3-ia-explorer` |
| PR review / full diff | [tags-p3](../context/orchestration/tags-p3.md) | [github-pr-fetch.md](../context/orchestration/github-pr-fetch.md) | `pr-reviewer` + `p2-review-analysis` |
| Review / validate implementation | [tags-p2](../context/orchestration/tags-p2.md) | [rules.md](../context/project/rules.md) | `Reviewer` + `p3-ia-verifier` |
| External API / docs lookup | — | — | `WebSearch` + `p3-ia-search` |

## Reusable Routing Notes

### Reactive HTTP Data
1. Read [resource-api.md](../context/standards/angular-reactivity/resource-api.md).
2. Guard against resource error state before reading `.value()`.
3. For tests, pair [testing.md](../context/standards/angular-reactivity/testing.md) with `p1-framework-angular-testing`.

### Documentation
1. Route documentation-only work to the `Documentador` agent.
2. Follow `p3-ia-docs-gen`.
3. After creating a context doc, update the Component Map in [AGENTS.md](../context/orchestration/AGENTS.md) and the matching [pillar tag dictionary](../context/orchestration/tags-p1.md).
4. Documentation-only tasks do not require build/test/lint; validate by diff quality, markdown structure, and wording consistency.

### Read-Only Q&A
1. Route explanation, navigation, and architecture questions to the `Ask` agent.
2. Start with [AGENTS.md](../context/orchestration/AGENTS.md) and the matching local doc before reading implementation files.
3. If the user pivots from a question to a change request, escalate to `SDD Agent` for orchestration.

### Scope Discovery
1. Route blast-radius discovery and affected-file lookup to the `Explore` agent.
2. Apply `p3-ia-explorer` to classify the scope and map clues to assets.
3. If dense undocumented logic is found, flag documentation debt before planning implementation.

### Review And Verification
1. Route post-implementation review or validation requests to the `Reviewer` agent.
2. Apply `p3-ia-verifier` for consensus, verification mode, and reporting.
3. Use documentation-only validation instead of tests when the scope is limited to `.agents/`.
4. Persist the final verification results and Solution Memory to `.agents/cache-session/<session-id>/session-memory.md`.

### Pull Request Review
1. Route read-only PR review and branch diff assessment to the `pr-reviewer` agent.
2. Start with [github-pr-fetch.md](../context/orchestration/github-pr-fetch.md) and `p2-review-analysis`.
3. Prefer VS Code active PR context plus local repository diff for full coverage before reporting findings.
4. Apply [rules.md](../context/project/rules.md) as the anti-pattern baseline.

### External Web Research
1. Route external API lookups, documentation verification, and URL validation to `WebSearch` agent.
2. Apply `p3-ia-search` to structure delegation requests.
3. Use `WebSearch` when local `.agents/context/` docs cannot fill knowledge gaps.
4. Limit to 3 concurrent web search delegations per SDD cycle to avoid context overload.
5. Cross-reference WebSearch findings with local docs and flag contradictions.

### New Feature Implementation
1. Start with [new-feature.md](new-feature.md) for the step-by-step methodology.
2. Consult [architecture.md](../context/project/architecture.md) for placement rules (Scope Rule).
3. Check [api-contracts.md](../context/project/api-contracts.md) for existing endpoint definitions.
4. Review [api-strategy.md](../context/project/api-strategy.md) for proxy and connection patterns.
5. Follow the full 5-phase orchestration flow via `SDD Agent`.

## Quick Error Lookup

| Error / Symptom | Tag Dictionary | Go to |
|---|---|---|
| `Resource is currently in an error state` | [tags-p1](../context/orchestration/tags-p1.md) | [testing.md](../context/standards/angular-reactivity/testing.md) |
| `NG01353` with `ngModelGroup` | [tags-p1](../context/orchestration/tags-p1.md) | [testing.md](../context/standards/angular-reactivity/testing.md) |
| rxResource test timing issues | [tags-p1](../context/orchestration/tags-p1.md) | [testing.md](../context/standards/angular-reactivity/testing.md) |
| Modal not opening / `DialogRef` missing | [tags-p2](../context/orchestration/tags-p2.md) | [modal-creation.md](../context/project/modal-creation.md) |
