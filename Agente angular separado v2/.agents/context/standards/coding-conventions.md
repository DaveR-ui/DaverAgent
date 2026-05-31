---
last_updated: 2026-05-05
description: Coding standards for Angular v21+, Signals, and code readability.
tags: [angular, conventions, standards, inputs, outputs, inject, rxResource, readability]
---

# Coding Conventions

## Readability Principle
- **Explicit over clever**: Prefer code that is easy to read and follow over highly declarative one-liners or dense method chains.
- **Minimize navigation jumps**: Avoid patterns that force developers to jump across multiple files or deeply nested abstractions to understand simple logic.
- **Trade-off accepted**: A slightly more verbose but self-contained implementation is preferred over a "clean" one-liner that hides behavior behind indirection.

## Angular v21+ Standards
- **Component Inputs**: Always use `input<T>()` or `input.required<T>()`.
- **Component Outputs**: Prefer `output<T>()` over `EventEmitter`.
- **DI Mechanism**: Use `inject(Service)` instead of constructor injection.
- **Async Logic**: Avoid `Promises` or manual `Subscriptions`. Use `rxResource`.

## Naming Conventions
- **Feature Modules**: lazy-load from `app.routes.ts`.
- **Models**: suffix `*.interface.ts` or `*.domain.ts`.
- **Mocks**: keep in `mocks/data/` as JSON.

## State Hygiene
- **Service Scope**: Provide `root` only for global cross-feature state.
- **Component Scope**: Provide feature services directly in the component metadata.
- **Signal Debugging**: All `signal()`, `computed()`, and `linkedSignal()` declarations must include a `debugName` so Angular DevTools can identify them consistently.
