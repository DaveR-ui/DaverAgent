---
last_updated: 2026-05-12
status: active
ai_optimized: yes
tags: [agents, contracts, routing, governance]
---

# Agent Contracts

> Canonical contract registry for agent capabilities, routing fast paths, response sections, and documentation freshness rules.
> Use this file when changing agent roles or deciding which agent owns a request.

## Purpose

- Keep agent responsibilities and output contracts in one place.
- Reduce duplicated routing tables across `.github/`.
- Make agent changes auditable before the runtime prompts drift apart.

## Contract Ownership

- Agent-specific execution behavior still lives in each file under `agents/`.
- This file owns the cross-agent contract: capability boundaries, routing fast paths, response sections, and maintenance triggers.
- `agent-workflows/orchestrate.md` remains the routing workflow authority.
- `agents/sdd.agent.md` remains the orchestration workflow authority.

## Model Selection Policy

To optimize performance and cost, agents and the coordinator must select models based on task complexity.

| Complexity | Task Type | Primary Model | Decision Logic |
| --- | --- | --- | --- |
| **Low / Documentation** | Updates to `.github/` docs, logic-less markdown, small routing decisions, and prompt analysis. | **Gemini 3 Flash (Preview)** | Speed and cost efficiency for non-coding tasks. |
| **Medium / Code** | Standard feature implementation, bug fixes in single components, test creation, and routine refactors. | **GPT-5.3-Codex** | Balanced reasoning and code generation for standard tasks. |
| **High / Complex** | Multi-component refactors, complex state transitions, architectural changes, and high-risk logic. | **GPT-5.4** | Deep logical depth and complex reasoning for critical paths. |

### Complexity Classification (Hybrid)

Complexity is determined by a hybrid approach:
1.  **Objective Rules (Heuristics)**:
    - **High**: >3 files touched, logic involving race conditions or NgRx-to-Signals migration, or affecting shared core components.
    - **Medium**: 1-3 files touched, standard `rxResource` implementation, or localized bug fixes.
    - **Low**: Documentation only, manifest updates, or single-line configuration changes.
2.  **Manual Override**: The `sdd_agent` (coordinator) or the user may override the heuristic classification based on perceived risk or logical density.

## Capability Matrix

| Agent | Primary use | May edit files | May run build/test | Typical output |
| --- | --- | --- | --- | --- |
| `Custom asker` | Read-only questions, architecture lookup, codebase navigation | No | No | Answer with references and next route |
| `Explore` | Scope discovery, blast-radius mapping, documentation coverage | No | No | Scope report with evidence traceability |
| `Implementer` | Execute a validated plan with minimal edits | Yes | Yes, focused only | Execution evidence and changed files |
| `Reviewer` | Post-implementation review and verification | No | Yes | Verification report and closure evidence |
| `sdd_agent` | Orchestrate complex feature, bug, and test work by choosing the current slice and routing execution | No | No direct implementation | Readiness, context decision, plan, verification route |
| `Supplier` | Return only the local rules needed for a task | No | No | Delta context package |
| `Documentador` | Documentation-only updates inside `.github/` | Yes, `.github/` only | No | Updated docs and diff-based validation |
| `pr-reviewer` | Read-only PR and branch diff review | No | No | Findings-first review report |

## Routing Fast Paths

Use the smallest capable agent first.

| User intent | Route | Why |
| --- | --- | --- |
| Explain a feature, architecture, or likely root cause | `Custom asker` | Pure read-only analysis |
| Locate files, dependencies, or governing docs | `Explore` | Discovery without orchestration overhead |
| Review a PR or branch diff | `pr-reviewer` | Full-diff, read-only review path |
| Validate an existing implementation | `Reviewer` | Post-implementation verification path |
| Update docs, guides, skills, or agent files only | `Documentador` | Documentation writing without runtime execution |
| Fetch only the relevant rules and anti-patterns | `Supplier` | Minimal context packaging |
| Plan a complex feature, bug fix, or test change with unclear scope, ownership, or verification path | `sdd_agent` | Lightweight orchestration with bounded-slice decisions and explicit handoffs |
| Execute an already-approved plan | `Implementer` | Bounded implementation path |

## Response Contract Registry

| Agent | Required response sections |
| --- | --- |
| `Custom asker` | `Question Type`, `Primary References`, `Answer`, `Next Route` |
| `Explore` | `Scope Surface`, `Evidence Traceability`, `Identified Assets`, `Documentation Recommendation`, `Next Route` |
| `Implementer` | `Execution Summary`, `Files Changed`, `Validation`, `Next Route` |
| `Reviewer` | `Review Type`, `Primary References`, `Verification Report`, `Next Route` |
| `sdd_agent` | `Readiness Summary`, `Context Decision`, `Plan`, `Verification Route` |
| `Supplier` | `Task Type`, `Relevant Docs`, `Delta Context`, `Debt Alerts` |
| `Documentador` | Follow the documentation task format defined in the agent file |
| `pr-reviewer` | Findings-first review format defined in the agent file |

## Task-Scoped Session Artifacts

Every orchestrated slice must keep its session artifacts under a stable `task-id` so parallel handoffs do not overwrite each other.

| Artifact | Canonical path | Owner |
| --- | --- | --- |
| Approved plan | `/memories/session/plans/<task-id>.md` | `sdd_agent` |
| Verification / test summary | `/memories/session/test-runs/<task-id>.md` | `Implementer` or `Reviewer`, depending on who executed the check |

Rules:

1. Reuse the same `task-id` across all handoffs for the bounded slice.
2. Single-slot session files are not canonical for orchestrated tasks.
3. If a task is resumed, read and continue the existing task-scoped artifacts before creating new ones.
4. End-of-session summaries may aggregate task-scoped artifacts, but they must not replace them during active work.

## Shared Agent Shape

Each agent definition should keep this structure so routing and output contracts remain inspectable:

1. Frontmatter with `name`, `description`, `argument-hint`, `target`, tool budget, `route-aliases`, and `response-sections` when applicable.
2. Mission with a single responsibility.
3. Hard boundaries with explicit non-goals.
4. Primary sources of truth.
5. Workflow or process.
6. Output format aligned with `response-sections`.
7. Edge cases that route work elsewhere.

## Freshness Checks

Run this checklist whenever an agent role, route, or contract changes:

1. Update this file first.
2. Update the touched agent file under `agents/`.
3. Update `agent-workflows/orchestrate.md` only if routing logic changed.
4. Update `AGENT-GUIDE.md` only if operator-facing guidance changed.
5. If verification behavior changed, confirm the rule still matches `architecture-standards/index.md` and `architecture-standards/ai-orchestration-patterns.md`.

## Drift Signals

- An agent gains a new responsibility but this file is unchanged.
- `response-sections` in an agent file differ from this registry.
- `AGENT-GUIDE.md` starts carrying full routing tables again.
- `orchestrate.md` starts restating capability boundaries instead of referencing this registry.
- `sdd_agent` starts treating `Explore` and `Supplier` as mandatory serial phases instead of optional discovery helpers.