---
tags: [angular, conventions, standards, inputs, outputs, inject, rxResource]
---

# Coding Conventions

## Angular v20+ Standards
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
