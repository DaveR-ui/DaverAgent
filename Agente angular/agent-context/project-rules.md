---
last_updated: 2026-04-14
tags: [standards, project-rules, anti-patterns, guardrails]
---

# Project Standards and Rules

This document consolidates all core operational rules, anti-patterns, and architectural standards for the project. 

## 0. Three-Pillar Rule Set
- **Project Rule**: Avoid adding new logic or state to the NGRX Store unless the need is truly global and clearly justified. Prefer local state, Signals, `computed`, `linkedSignal`, and `rxResource`.
- **Language Rule**: `setTimeout` is prohibited in this repository. Do not use timing hacks for UI flow, synchronization, or change detection.
- **AI Execution Rule**: Every orchestrated task must use a stable `task-id`, persist its approved plan to `/memories/session/plans/<task-id>.md`, and write any test or verification summary to `/memories/session/test-runs/<task-id>.md`.

## 1. 🚨 MISSION CRITICAL: Refactoring Priority
- **Legacy Code:** Do NOT use `src/` as a reference for patterns. The existing codebase is heavily deprecated.
- **Agent Rules:** Only patterns found in `.github/agent-context/` are considered "Best Practices".
- **Refactoring:** When working on a feature, if you encounter an anti-pattern (e.g., manual subscriptions), you are encouraged to refactor it to the new Signal-based standard.

## 2. 🛡️ Operational Guardrails
- **Value-Driven Replacement**: When tasked with CHANGING or REPLACING existing code, the agent MUST explicitly ask: *"Is the replacement code objectively better than the existing one?"* "Better" means:
  - Lower accidental complexity (no unnecessary wrapper divs, synthetic click handlers, or workarounds).
  - Improved alignment with modern repository standards (Signals, `rxResource`, etc.).
  - Better legibility, lower coupling, and smaller blast radius.
  - Improved accessibility or testability.
  - **REJECT** replacements that are merely cosmetic or add technical debt via "wrapper hell".
- **Style Encapsulation & Containment**: Component styles MUST be contained.
  - Do NOT affect parent or ancestor layout or styling from a component stylesheet.
  - `:host` should only be used to style the component's own root element (e.g., setting display, flex, or dimensions for itself).
  - `::ng-deep` is **PROHIBITED** except as a documented exception for third-party libraries (e.g., AG Grid) that do not support standard customization.
- **NO Automatic Commits**: AI agents must **NEVER** create a git commit automatically. Always ask for explicit user permission.
- **`any` Is Exception-Only**: Do **NOT** use `any` as a quick fix to silence TypeScript errors. Prefer exact interfaces, generics, indexed access types, or `unknown` plus narrowing.
  - **Allowed only in narrow edge cases**: third-party APIs with unusable typings, legacy interop boundaries, or temporary migrations that cannot be typed safely yet.
  - **Not allowed as a bypass**: `as any` in assertions, private-member access, or service mocks just to make tests compile.
  - **Testing rule**: prefer asserting public behavior and typed collaborators instead of writing patterns like `(expect(service['http']) as any).toBeTruthy()`.
- **No Focused Tests in Committed Code**: `fit()` and `fdescribe()` are **PROHIBITED** in this repository. Use `it()` and `describe()` only. If a focused test is needed temporarily during local debugging, it must be removed before finishing the task.
- **No `setTimeout` in Components**: Using `setTimeout` in components is **PROHIBITED** for UI flow/timing fixes.
  - **Zoneless alignment**: Angular is moving to Signals-first and zoneless change detection. Code must notify Angular explicitly instead of relying on macro-task timing.
  - **Use instead**: Signal updates, RxJS-driven state transitions, `ChangeDetectorRef.markForCheck()` for `OnPush` components, or explicit event control.
- **No `@ngneat/until-destroy` in New or Updated Code**: `UntilDestroy` and `untilDestroyed(...)` are legacy patterns and must not be introduced when touching a file.
  - **Use instead**: `inject(DestroyRef)` together with `takeUntilDestroyed(destroyRef)` from `@angular/core/rxjs-interop`.
  - **Why**: This aligns subscription cleanup with Angular's native lifecycle APIs and avoids expanding third-party lifecycle utilities.
- **Component Metadata Preservation**: NEVER replace `templateUrl` or `styleUrls` with empty values unless intentionally converting to a logic-only component.
- **Dead Code Prevention**: Before modifying the `@Component` decorator, verify the existence of HTML/SCSS. Deleting links while files exist creates dead code.
- **UI Integrity**: A UI component must always have its template linked.
- **No Massive Imports**: Importing entire libraries (e.g., `import _ from 'lodash'`) is **PROHIBITED**. Always use specific imports (e.g., `import { isEqual } from 'lodash'`).
- **Encapsulation of Logic**: Logic should be placed in the same location (service, component, module) where it is used. Avoid global shared services for specific, single-use methods.
- **Prefer Local Readability Over Tiny Indirection**: Keep straightforward logic readable where it is used. Extract helpers when they remove real complexity, capture domain meaning, or are reused, not just to split a short branch or one-line transformation into another method.
- **Method Size Floor**: Methods should generally be at least 10 lines long so the code does not fragment into trivial wrappers.
  - **Allowed exception**: a shorter method is acceptable when it isolates reusable or parameterizable logic with clear domain meaning, for example a predicate/helper such as `isRemovable(...)`.

## 3. 🧠 Store & Selectors: Minimalism First
- **Discourage Store Usage**: Before adding state to the NGRX Store, verify if it can be resolved with local state, Signals, `computed`, `linkedSignal`, `rxResource`, or component composition. The Store should be reserved for genuinely global or cross-feature state with clear justification.
- **Default Decision**: If there is any reasonable local solution, do not add store state.
- **Avoid Unnecessary Selectors**: Do not create new selectors for convenience or simple logic that can be resolved in the component (or via `computed`). Selectors add coupling and disperse logic, increasing cognitive cost.
- **Localized Logic**: Keep logic close to where it is consumed. The Store should not be the first resource for moving logic prematurely; only use it if it is the appropriate source of truth for multiple distant consumers.

## 4. 🛑 Anti-Patterns vs. ✅ Standards

| Anti-Pattern (AVOID)                  | Standard Pattern (USE)     | Why?                                                         |
| ------------------------------------- | -------------------------- | ------------------------------------------------------------ |
| `Promise.then()` in components        | `rxResource` / `toSignal`  | Better reactivity & lifecycle integration                    |
| Direct DOM manipulation (`document.`) | `ViewChild` / `Renderer2`  | SSR compatibility & Angular testing                          |
| Manual subscription (`.subscribe()`)  | `signals` / `async` pipe   | Prevent memory leaks & boilerplate                           |
| `UntilDestroy` / `untilDestroyed(...)`| `DestroyRef` + `takeUntilDestroyed(...)` | Native Angular lifecycle cleanup and less third-party coupling |
| Complex logic in HTML templates    | `computed()` in TypeScript | Testability & performance (Change Detection)                 |
| Excessive NGRX Store/Selectors     | Signals / Local State / `rxResource` | Reduce accidental complexity and logic fragmentation |
| Non-safe `resource()` access       | `resource.value()` check   | Prevents "Resource in error state" crash                     |
| Root injection for stateful tools     | `providers: [Service]`     | Prevents state pollution across sessions                     |

## 5. 📝 Form Validations & Error Handling
- Granular Feedback: Validations should be placed as close as possible to the affected data (e.g., at the project/account level instead of the global modal level).
- Custom Error Blocks: When using custom validators (e.g., `appAtLeastOneGroupOrServiceAccount`), **ALWAYS** include an `@if` block in the HTML to show the specific error message.
- Strict Mode Error: Specifically for `atLeastOneGroupOrServiceAccountStrict`, use a dedicated error block with the `alert-danger` class.
- Validation Icons: Use the `valid-key` / `invalid-key` pattern on icons to provide visual status in complex components like accordions.

## 6. 🔀 Complex Data Flow Rules
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

## 7. 🛠️ Angular MCP Tools & Project Guidelines
- **LaunchDarkly Flags**: All flag keys must include suffix `_AIR226766`. Example: `LD_FLAG_MY_FEATURE = 'my_feature_AIR226766'`. Full reference: [launchdarkly-flags.md](launchdarkly-flags.md)
- **MCP Priority**: Always prefer Angular MCP tools (`find_examples`, `get_best_practices`, `list_projects`) over manual file searches when looking for generic Angular patterns or best practices.
