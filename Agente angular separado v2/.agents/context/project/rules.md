---
last_updated: 2026-04-14
description: Consolidated operational rules, anti-patterns, and project guardrails.
tags: [standards, project-rules, anti-patterns, guardrails]
---

# Project Standards and Rules

This document consolidates all core operational rules, anti-patterns, and architectural standards for the project. 

## 1. 🚨 MISSION CRITICAL: Refactoring Priority
- **Legacy Code:** Do NOT use `src/` as a reference for patterns. The existing codebase is heavily deprecated.
- **Agent Rules:** Only patterns found in `.agents/context/` are considered "Best Practices".
- **Refactoring:** When working on a feature, if you encounter an anti-pattern (e.g., manual subscriptions), you are encouraged to refactor it to the new Signal-based standard.

## 2. 🛡️ Operational Guardrails
- **NO Automatic Commits**: AI agents must **NEVER** create a git commit automatically. Always ask for explicit user permission.
- **`any` Is Exception-Only**: Do **NOT** use `any` as a quick fix to silence TypeScript errors. Prefer exact interfaces, generics, indexed access types, or `unknown` plus narrowing.
  - **Allowed only in narrow edge cases**: third-party APIs with unusable typings, legacy interop boundaries, or temporary migrations that cannot be typed safely yet.
  - **Not allowed as a bypass**: `as any` in assertions, private-member access, or service mocks just to make tests compile.
- **No `setTimeout` in Components**: Using `setTimeout` in components is **PROHIBITED** for UI flow/timing fixes.
  - **Zoneless alignment**: Angular is moving to Signals-first and zoneless change detection. Code must notify Angular explicitly instead of relying on macro-task timing.
  - **Why**: This aligns subscription cleanup with Angular's native lifecycle APIs and avoids expanding third-party lifecycle utilities.
- **Component Metadata Preservation**: NEVER replace `templateUrl` or `styleUrls` with empty values unless intentionally converting to a logic-only component.
- **Dead Code Prevention**: Before modifying the `@Component` decorator, verify the existence of HTML/SCSS. Deleting links while files exist creates dead code.
- **UI Integrity**: A UI component must always have its template linked.
- **No Massive Imports**: Importing entire libraries (e.g., `import _ from 'lodash'`) is **PROHIBITED**. Always use specific imports (e.g., `import { isEqual } from 'lodash'`).
- **Encapsulation of Logic**: Logic should be placed in the same location (service, component, module) where it is used. Avoid global shared services for specific, single-use methods.

## 3. 🛑 Anti-Patterns vs. ✅ Standards

| Anti-Pattern (AVOID)                  | Standard Pattern (USE)     | Why?                                                         |
| ------------------------------------- | -------------------------- | ------------------------------------------------------------ |
| `Promise.then()` in components        | `rxResource` / `toSignal`  | Better reactivity & lifecycle integration                    |
| Direct DOM manipulation (`document.`) | `ViewChild` / `Renderer2`  | SSR compatibility & Angular testing                          |
| Manual subscription (`.subscribe()`)  | `signals` / `async` pipe   | Prevent memory leaks & boilerplate                           |
| `UntilDestroy` / `untilDestroyed(...)`| `DestroyRef` + `takeUntilDestroyed(...)` | Native Angular lifecycle cleanup and less third-party coupling |
| Complex logic in HTML templates       | `computed()` in TypeScript | Testability & performance (Change Detection)                 |
| Non-safe `resource()` access          | `resource.value()` check   | Prevents "Resource in error state" crash                     |
| Root injection for stateful tools     | `providers: [Service]`     | Prevents state pollution across sessions                     |

## 4. 📝 Form Validations & Error Handling
- **Granular Feedback**: Validations should be placed as close as possible to the affected data (e.g., at the project/account level instead of the global modal level).
- **Custom Error Blocks**: When using custom validators (e.g., `appAtLeastOneGroupOrServiceAccount`), **ALWAYS** include an `@if` block in the HTML to show the specific error message.
- **Strict Mode Error**: Specifically for `atLeastOneGroupOrServiceAccountStrict`, use a dedicated error block with the `alert-danger` class.
- **Validation Icons**: Use the `valid-key` / `invalid-key` pattern on icons to provide visual status in complex components like accordions.

## 5. 🔀 Complex Data Flow Rules
Use these rules when a feature depends on multiple endpoints, layered state, derived state, or reconciliation between persisted and live data.

1. **Identify the symptom before the mechanism**: State the exact missing, stale, duplicated, or inconsistent UI behavior first.
2. **Identify the source of truth**: Name which endpoint, store, or signal is authoritative for the broken behavior.
3. **Map each visible UI output to its real data source**: Verify which request actually controls the broken options, selections, labels, or validation.
4. **Prefer the smallest correct fix**: If one targeted refresh fixes the issue, do not add broader hydration passes. Do not add new state flags if existing reactive state provides the necessary trigger.
5. **Do not mirror another workflow blindly**: A user-driven flow and an initial-load flow may look similar but have different data needs.
6. **Preserve valid user state during refresh**: Reconcile with current selections instead of replacing blindly.
7. **Every new request must justify a visible outcome**: Avoid adding parallel requests just because they exist elsewhere in the feature.
8. **Prefer reconciliation over duplication**: If live data must replace stale snapshots, merge the new snapshot into the existing selected state.
9. **Document endpoint responsibilities explicitly**.
10. **Test behavior, not just transport**: Validate the user-visible result.

## 6. 🛠️ Angular MCP Tools & Project Guidelines
- **MCP Priority**: Always prefer Angular MCP tools (`find_examples`, `get_best_practices`, `list_projects`) over manual file searches when looking for generic Angular patterns or best practices.
