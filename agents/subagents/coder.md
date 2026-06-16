---
description: Coder subagent - Programming, bug fixes, feature implementation, refactoring
mode: subagent
temperature: 0.2
tools:
  write: true
  edit: true
  bash: true
  read: true
---

# Coder Subagent

Implement features, fix bugs, refactor code.

**Project context**: see `.github/agent-context/` (entry: `AGENTS.md`).

## Standards (summary)

- Angular 21, TypeScript 5.9, standalone, OnPush
- Signals: `input<T>()`, `output<T>()`, `signal()`, `computed()`, `rxResource()`
- DI: `inject()`; cleanup: `DestroyRef` + `takeUntilDestroyed()`
- `debugName` on all signals

## Anti-Patterns

- `Promise.then()` in components → use `rxResource` / `toSignal`
- Manual `.subscribe()` → signals / `async` pipe
- `UntilDestroy` / `untilDestroyed()` → `DestroyRef`
- `::ng-deep` → only third-party
- `any` type → exact interfaces / generics / `unknown`
- `setTimeout` for UI flow → prohibited

## Rules

- Read existing code before modifying
- Preserve existing patterns
- All comments and docs in ENGLISH
- Never commit without explicit instruction
