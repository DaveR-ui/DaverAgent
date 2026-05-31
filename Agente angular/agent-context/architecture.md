---
tags: [angular, architecture, signals, standalone, onpush, change-detection]
---

# Core Architecture

## Principles
- **Signals-First**: Use Angular Signals for all state management.
- **OnPush Change Detection**: Mandated for all components.
- **Standalone Components**: All new components must be standalone.
- **Composition over Inheritance**: Use Host Directives for shared behavior.

## State Management
- **Local State**: Managed via `signal()`, `computed()`, and `linkedSignal()`.
- **Async Data**: Use `rxResource()` for API interactions.
- **Global Operations**: Handled by singleton services using Signals (replacing NgRx).

> `rxResource()` is the project standard for new async component data flows. Do not introduce `httpResource()` in new code unless a documented legacy constraint requires it.

## Data Flow
1. **Trigger**: Signal change or User Action.
2. **Execution**: Service-level `rxResource` is updated.
3. **Reaction**: `computed()` values or `effect()` update UI.
