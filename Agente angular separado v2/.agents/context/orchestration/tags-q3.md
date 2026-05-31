---
last_updated: 2026-05-09
status: ACTIVE
ai_optimized: yes
pillar: Q3
purpose: Tag-based lookup for SDD Stage 3 — Cierre (Verification + Testing + Learning).
---

# Tag Dictionary — Q3: Cierre (Verification + Testing + Learning)

> Use this file to locate docs and skills by keyword for Q3 concerns.
> This stage covers test execution, solution verification, PR review, and learning capture.
> All doc paths are relative to `.agents/context/`.
> Skills reference `.agents/skills/SKILLS_INDEX.md` for full descriptions.

---

## testing / unit-test / vitest
**Docs:**
- [angular-reactivity/testing.md](../standards/angular-reactivity/testing.md)
- [coding-conventions.md](../standards/coding-conventions.md)

**Skills:**
- `p1-framework-angular-testing` — Vitest testing patterns and harnesses
- `p1-test-vitest` — Fast unit testing framework
- `p1-test-playwright` — E2E Testing and POM patterns

---

## verification / solution-memory / consensus
**Docs:**
- [flow.md](flow.md) — Phase 5: Verification gate
- [task-memory.md](../memory/task-memory.md) — Recent milestones & solution memory
- [patterns-catalog.md](../memory/patterns-catalog.md) — Reusable recipes
- [troubleshooting/common-errors.md](../memory/troubleshooting/common-errors.md)

**Skills:**
- `p3-ia-verifier` — Test execution & solution memory generation
- `p3-ia-sync-checker` — Routing sync, stale dates, link integrity audit

---

## learning / memory / rules-update
**Docs:**
- [task-memory.md](../memory/task-memory.md) — Post-implementation lessons
- [rules.md](../project/rules.md) — Technical debt and anti-patterns
- [patterns-catalog.md](../memory/patterns-catalog.md) — Pattern consolidation

**Skills:**
- `p3-ia-learner` — ORCHESTRATOR-RULES.md and learning log management

---

## review / pr / validation
**Docs:**
- [rules.md](../project/rules.md) — Anti-pattern baseline for review
- [github-pr-fetch.md](github-pr-fetch.md) — PR fetch and diff guide

**Skills:**
- `p1-review-angular` — Specialized PR review guidelines for Angular
- `p3-ia-verifier` — Post-implementation verification

---

## playwright / e2e / pom
**Docs:**
- [angular-reactivity/testing.md](../standards/angular-reactivity/testing.md)
- [../../skills/p1-test-playwright/SKILL.md](../../skills/p1-test-playwright/SKILL.md) — Playwright skill details

**Skills:**
- `p1-test-playwright` — E2E Testing and Page Object Model patterns
