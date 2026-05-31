# 🛑 Rules for New Components

When analyzing a Pull Request (PR) and you determine that a **NEW component** was added, you MUST evaluate the code against the following rules. Group your findings exactly under these categories:

## 🚨 CRÍTICOS (CRITICAL)
If any of these are violated, the PR should **NOT** be approved. Report these as major blockers:
- `changeDetection: ChangeDetectionStrategy.OnPush` MUST be present in the component decorator.
- `standalone: true` MUST be present in the component decorator.
- All HTTP queries MUST be handled with `rxResource` (no `subscribe()` directly on HTTP calls in components).
- Dependency Injection MUST exclusively use the `inject(SomeComponent)` pattern. Constructor injection is strictly forbidden.
- `setTimeout()` is strictly forbidden anywhere in the component.
- Barrel imports (e.g., importing the entire `lodash` library instead of specific methods like `lodash/isEmpty`) are strictly forbidden.

## ⚠️ ADVERTENCIAS (WARNING)
If these are violated, warn the user that there are code quality issues to improve:
- Check that method and variable names are highly descriptive.
- EVERYTHING must be typed. Avoid the use of `any` explicitly or implicitly.
- Avoid over-checking (e.g., using `if (a && a.b && a.b.c)` instead of optional chaining `a?.b?.c`).
- Styles (`.scss`/`.css`) must use variables (e.g., `var(--primary-color)`) and NOT hardcoded values or raw pixels for colors, margins, paddings, and font weights.
- Warn the user that they should NOT be creating new elements (actions, reducers, selectors, etc.) for the NgRx store.

## 💡 IDEAS (RECOMMENDATIONS)
Provide these suggestions to improve the architecture and maintainability:
- Components should NOT parse or mutate data payloads. The parsing should be handled by the backend (sender) or mapped via a mapper method in a helper Service.
- Recommend generating **INLINE documentation** (JSDoc comments directly inside the `.ts` file above the component class and complex methods) describing its exact purpose. **DO NOT** suggest creating external Markdown files, as this causes unnecessary documentation bloat.
- If it's a complex component, ensure its inline comments are updated and clearly explain the logic.
- If the new file exceeds **900 lines of code**, explicitly recommend breaking it down into smaller, focused sub-components.
- Ask the user to validate if the main inline description of the component accurately describes its real functionality.