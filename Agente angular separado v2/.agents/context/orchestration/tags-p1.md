---
last_updated: 2026-05-09
status: ACTIVE
ai_optimized: yes
pillar: P1
purpose: Tag-based lookup for Language & Framework Standards (Angular v21+, TypeScript, testing).
---

# Tag Dictionary — Pillar 1: Language & Framework Standards

> Use this file to locate docs and skills by keyword for P1 concerns.
> All doc paths are relative to `.agents/context/`.
> Skills reference `.agents/skills/SKILLS_INDEX.md` for full descriptions.

---

## angular
**Docs:**
- [architecture.md](../project/architecture.md)
- [coding-conventions.md](../standards/coding-conventions.md)
- [angular-reactivity/index.md](../standards/angular-reactivity/index.md)
- [angular-reactivity/resource-api.md](../standards/angular-reactivity/resource-api.md)
- [domain-logic.md](../project/domain-logic.md)

**Skills:**
- `p1-framework-angular-developer` — Core framework architecture & patterns
- `p1-framework-angular-component` — Standalone components, signals, host bindings
- `p1-framework-angular-di` — Dependency injection with `inject()`
- `p1-framework-angular-directives` — Custom attribute and structural directives
- `p1-framework-angular-tooling` — Angular CLI, code generation, build config
- `p1-ref-core` — Angular Core package architecture
- `p1-ref-compiler-cli` — Angular Compiler CLI architecture
- `p1-ref-signal-forms` — Angular Signal-based Forms architecture

---

## change-detection / onpush / standalone
**Docs:**
- [architecture.md](../project/architecture.md)
- [coding-conventions.md](../standards/coding-conventions.md)

**Skills:**
- `p1-framework-angular-component` — OnPush change detection, standalone components

---

## computed / linkedSignal / signals
**Docs:**
- [angular-reactivity/index.md](../standards/angular-reactivity/index.md)
- [angular-reactivity/resource-api.md](../standards/angular-reactivity/resource-api.md)

**Skills:**
- `p1-framework-angular-developer` — Signals, computed, linkedSignal patterns

---

## conventions / standards / coding-style
**Docs:**
- [coding-conventions.md](../standards/coding-conventions.md)

**Skills:**
- `p1-lang-typescript` — Advanced generics and type safety
- `p1-review-angular` — PR review guidelines for Angular

---

## dependency-injection / inject / providers
**Docs:**
- [coding-conventions.md](../standards/coding-conventions.md)

**Skills:**
- `p1-framework-angular-di` — DI with `inject()`, injection tokens, provider config
- `p1-framework-angular-developer` — Hierarchical injectors, defining providers

---

## httpResource / rxResource / legacy resource
**Docs:**
- [angular-reactivity/resource-api.md](../standards/angular-reactivity/resource-api.md)
- [angular-reactivity/testing.md](../standards/angular-reactivity/testing.md)
- [coding-conventions.md](../standards/coding-conventions.md)

**Skills:**
- `p1-framework-angular-developer` — Resource API, loading strategies

---

## reactivity / signals / computed
**Docs:**
- [angular-reactivity/index.md](../standards/angular-reactivity/index.md)
- [angular-reactivity/resource-api.md](../standards/angular-reactivity/resource-api.md)
- [architecture.md](../project/architecture.md)

**Skills:**
- `p1-framework-angular-developer` — Signals, effects, linkedSignal
- `p1-framework-angular-component` — Signal-based inputs/outputs

---

## testing / unit-test / vitest
**Docs:**
- [angular-reactivity/testing.md](../standards/angular-reactivity/testing.md)

**Skills:**
- `p1-framework-angular-testing` — Vitest testing patterns and harnesses
- `p1-test-vitest` — Fast unit testing framework
- `p1-test-playwright` — E2E Testing and POM patterns
- `p1-review-angular` — PR review guidelines

---

## typescript / types / generics
**Docs:**
- [coding-conventions.md](../standards/coding-conventions.md)

**Skills:**
- `p1-lang-typescript` — Advanced generics, conditional types, utility types
