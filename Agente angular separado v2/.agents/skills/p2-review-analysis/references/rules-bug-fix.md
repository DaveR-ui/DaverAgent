# 🛑 Rules for Old Components / Bug Fixes

When analyzing a Pull Request (PR) and you determine that the changes involve **modifying an EXISTING component** or doing a **Bug Fix**, you MUST evaluate the code against the following rules.

*Note: For older components, architectural shifts (like OnPush or Standalone) are not critical blockers but are strongly advised as warnings to encourage refactoring.*

## ⚠️ ADVERTENCIAS (WARNING)
If these are violated, warn the user that there are code quality issues to improve (or legacy patterns to refactor):
- `changeDetection: ChangeDetectionStrategy.OnPush` should ideally be present. (If missing, warn them).
- `standalone: true` should ideally be used. (If missing, warn them).
- HTTP queries should be migrated to `rxResource` where possible instead of raw `subscribe()`.
- Dependency Injection should use the `inject(SomeComponent)` pattern instead of constructor injection.
- `setTimeout()` should be avoided.
- Barrel imports (e.g., importing the entire `lodash` library instead of specific methods) should be avoided.
- Method and variable names must be highly descriptive.
- EVERYTHING must be typed. Avoid the use of `any` explicitly or implicitly.
- Avoid over-checking (e.g., using `if (a && a.b && a.b.c)` instead of optional chaining `a?.b?.c`).
- Styles (`.scss`/`.css`) must use variables (e.g., `var(--primary-color)`) and NOT hardcoded values.
- Warn the user that they should NOT be creating new elements (actions, reducers, selectors, etc.) for the NgRx store.

## 💡 IDEAS (RECOMMENDATIONS)
Provide these suggestions to improve the architecture and maintainability:
- Components should NOT parse or mutate data payloads. The parsing should be handled by the backend (sender) or mapped via a mapper method in a helper Service.
- Recommend generating **INLINE documentation** (JSDoc comments directly inside the `.ts` file above the component class and complex methods) describing its exact purpose. **DO NOT** suggest creating external Markdown files, as this causes unnecessary documentation bloat.
- If it's a complex component, ensure its inline comments are updated and clearly explain the logic.
- If the file exceeds **900 lines of code**, explicitly recommend breaking it down into smaller, focused sub-components.
- Ask the user to validate if the main inline description of the component accurately describes its real functionality.

## 📝 RESUMEN Y VALIDACIÓN (SUMMARY & VALIDATION)
At the very end of your review, you MUST include a summary section:
1. Provide a brief, high-level summary of what changes the user actually made.
2. Explicitly ask the user: **"¿Este resumen de los cambios coincide con tu User Story o la tarea que te fue encargada?"** (Does this summary of the changes match your User Story or assigned task?).