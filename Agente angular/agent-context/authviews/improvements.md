---
tags: [authviews, improvements, technical-debt, state-management, wizard]
---

# Authviews Technical Debt & Improvements

## Critical Issues

### 1. Fragile State Management

- **Issue**: `AuthViewService` uses public mutable properties to hold wizard state.
- **Risk**: No protection against partial state leaks between wizard sessions if `clearAuthViewData()` isn't called or fails.
- **Improvement**: Refactor to use a single `Signal` or `Store` for the wizard state to ensure atomicity.

### 2. Manual DOM/Object Manipulation

- **Issue**: Extensive use of `delete` operator and `JSON.parse(JSON.stringify(obj))` for deep cloning and property cleaning.
- **Risk**: Performance overhead and loss of type safety.
- **Improvement**: Use structured cloning (`structuredClone`) and proper DTO mapping classes instead of manual object mutation.

### 3. Mixed Reactivity Patterns

- **Issue**: The codebase mixes `BehaviorSubject`, manual `Subscription`, and Angular `Signals`.
- **Risk**: Increased cognitive load and complexity in lifecycle management (mixing `untilDestroyed` with signals).
- **Improvement**: Standardize on **Angular Signals** for local component state and **rxResource** for remote data loading. Existing experimental resource APIs should be treated as migration candidates, not as the target pattern.

### 4. Excessive Business Logic in UI Components

- **Issue**: `AuthviewsComponent` contains the mapping logic for converting a child list item into a parent `AdministrationResource`.
- **Risk**: Logic is not testable and hard to reuse.
- **Improvement**: Move mapping logic to the `AuthViewService` or a dedicated mapper utility.

### 5. Type Safety (Any/Unknown)

- **Issue**: Several occurrences of `any` in `AuthViewService` and `AuthviewsComponent`.
- **Risk**: Runtime errors that bypass compiler checks.
- **Improvement**: Define strict interfaces for all API payloads and internal state.

## Suggested Refactor Steps

1. Create a `WizardState` interface.
2. Replace `AuthViewService` properties with a single `WritableSignal<WizardState>`.
3. Use `computed` signals in step components to derive specific step data.
4. Replace manual subscriptions in `AuthviewsComponent` with `effect()` or `toSignal()` where appropriate.
