---
description: Step-by-step methodology to implement a new feature in the application.
---

When a new "feature" is requested, the agent MUST follow these steps in order to guarantee adherence to the project's architecture and rules.

### 1. Context Preparation
- Consult `architecture.md` to verify where the logic should reside.
- Follow the **Scope Rule**: If it's for a single functionality, it goes in `src/features/[name]`.

### 2. Model Definition
- Create types/interfaces in `src/features/[name]/models/`.
- Use strict typing, avoid `any`.
- If data comes from an API, check [api-contracts.md](../context/project/api-contracts.md).

### 3. Service Implementation
- Create the service in `src/features/[name]/services/`.
- Use `inject(HttpClient)` and Signals for state.
- Implement error handling with RxJS (`catchError`).

### 4. Main Component (Feature Shell)
- Create the component in `src/features/[name]/[name].ts`.
- **Critical Rules**:
  - Must be Standalone (default behavior).
  - Use `ChangeDetectionStrategy.OnPush`.
  - Use `input()` and `output()` instead of decorators.
  - Use the new control flow `@if`, `@for`.

### 5. User Interface (UI)
- Use components from `src/shared/ui/` for common elements (buttons, inputs).
- Apply the design principles defined in [coding-conventions.md](../context/standards/coding-conventions.md).
- Ensure the design is "Premium" (Glassmorphism, smooth animations).

### 6. Route Registration
- Add the new functionality to `src/app/app.routes.ts`.
- Use Lazy Loading for the feature component.

### 7. Final Verification
- Run `npm run build` to ensure there are no linting or type errors.
- Update `task-memory.md` with the progress completed.
