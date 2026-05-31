---
last_updated: 2026-04-27
description: offline architecture standards for the SDD agent with minimal standard summaries and local references
tags: [architecture, standards, sdd, clean-architecture, agents]
status: ACTIVE
ai_optimized: yes
---

# Architecture Standards

Use this folder as the local source of truth for the SDD agent's architecture standards.

## Loading Rule
- Load the index first.
- Open only the standard that matches the current decision.
- Use linked local docs for detail instead of expanding this folder with narrative prose.

## Minimal Context Policy
- Each standard keeps only operational rules.
- Existing docs under `.github/agent-context/` remain the detailed source of truth.
- External book links are intentionally excluded from the core workflow.

## Standards
- [Communication First and Foremost](communication-first-and-foremost.md)
- [Hexagonal Architecture](hexagonal-architecture.md)
- [Clean Architecture](clean-architecture.md)
- [Clean Architecture in the Front End](clean-architecture-in-the-front-end.md)
- [Angular: Mastering the Framework](angular-mastering-the-framework.md)
- [AI-Driven Development](ai-driven-development.md)
- [AI Orchestration Patterns](ai-orchestration-patterns.md)

## Repo Defaults
- Angular architecture details: [architecture.md](../architecture.md)
- Coding defaults: [coding-conventions.md](../coding-conventions.md)
- Guardrails and anti-patterns: [project-rules.md](../project-rules.md)

## Always-Loaded Mandates
- Project pillar: avoid adding new Store state or selectors when Signals, local state, or `rxResource` solve the need.
- No `setTimeout` for component flow control.
- No manual `.subscribe()` in components.
- No constructor injection in new or updated Angular code.
- No massive library imports.
- Components larger than 900 lines must be decomposed.
- AI execution pillar: every orchestrated slice must keep task-scoped session artifacts, with plans in `/memories/session/plans/<task-id>.md` and test or verification summaries in `/memories/session/test-runs/<task-id>.md`.