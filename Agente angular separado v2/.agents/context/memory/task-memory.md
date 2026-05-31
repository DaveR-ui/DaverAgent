# Task Memory

This document tracks the ongoing work, recent milestones, and pending actions to provide continuity between agent sessions.

## Current Status
- **Date**: 2026-05-02
- **Focus**: Documentation coherence cleanup and null reference removal.

## Recent Milestones
1. **API Contracts Refactor**: Split contracts into feature-specific files (`auth`, `clients`, `invoices`) under `.agents/context/project/api-contracts/`.
2. **Smart Skill System**: Migrated manual documentation files to automated, task-oriented Skills.
3. **UI Optimization (Vercel Standards)**: Audited and refactored `Button` and `Input` components.
4. **AutoSkill Ecosystem Integration**: Synchronized external skills (Playwright, Vitest, Accessibility, SEO) via `skills-lock.json` and updated `SKILLS_INDEX.md`.

## Next Steps
1. **Signal Migration**: Continue migrating any remaining RxJS-only flows to Signal-based reactive patterns where appropriate (`linkedSignal`, `resource`).
2. **A11Y Audit**: Conduct a full accessibility audit on the Sidebar and Login components.
3. **Skeleton Screens**: Implement visual feedback for data loading in the Invoice list.

---
*Related Documents*: [Backlog (todo.md)](todo.md)
