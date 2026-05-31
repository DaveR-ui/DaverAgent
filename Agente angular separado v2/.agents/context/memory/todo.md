# Project TODO List

This file contains the backlog of tasks, improvements, and pending bugs of the project.

## High Priority (Critical / Core)
- [x] Implement Refresh Token logic in `AuthService` using interceptors.
- [ ] Migrate remaining data services to the RxJS Observable + Signals pattern.
- [ ] Ensure login correctly handles session expiration state.

## Medium Priority (Functionality / UX)
- [ ] Complete Accessibility (A11Y) audit on complex components (Sidebar, Client Form).
- [x] Optimize core UI Atoms (Button, Input) for accessibility and performance.
- [ ] Implement Skeleton Screens for all table loading states.
- [ ] Improve form validations with dynamic error messages based on the status signal.

## Low Priority (Maintenance / Polish)
- [ ] Optimize bundle size by analyzing heavy dependencies.
- [ ] Refine route transition animations using the View Transitions API if possible.
- [ ] Document shared components in `src/shared/ui` within a Storybook or similar.

---

## 📝 Documentation Debt (`.agents/`)

> These are documentation-system improvements identified during schema review. They do not affect runtime behavior.

### Pending
- [ ] **`new-feature.md` restructuring** — The file (40 lines) mixes Scope Rule placement guidance with implementation steps. Separate "where logic goes" from "how to implement it" for cleaner single-responsibility docs.
- [ ] **`p3-ia-sync-checker` missing from AGENT-GUIDE.md tree** — The skill exists in `skills/`, is registered in `SKILLS_INDEX.md` and `tags-q3.md`, but is omitted from the visual tree diagram in `AGENT-GUIDE.md` (line ~67). Add it to keep the entry-point map consistent.
- [x] **Automated link validation script** — Created `validate-links.mjs` (skips code blocks and inline code), `repair-links.mjs` (auto-fix by filename match), npm scripts (`agents:validate-links`, `agents:repair-links`), and pre-commit hook installed in `.git/hooks/pre-commit`.

### Resolved
- [x] **P vs Q axis confusion** — Added explanatory note in `_TAG-INDEX.md` clarifying the difference between pillar (what) and stage (when) dimensions.
- [x] **AGENTS.md navigation** — Added quick index with anchors at the top for scannability.

---
*Note: Upon completion of a task, the agent will review this list and suggest the next logical step.*
