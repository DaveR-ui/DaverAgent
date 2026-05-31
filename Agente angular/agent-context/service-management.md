---
last_updated: 2026-04-29
status: ACTIVE
ai_optimized: yes
tags: [services, dependency-injection, providers, angular, modal, orchestration]
---

# Service Management & Dependency Injection

This document outlines specific rules for service lifecycle and dependency injection in this project.

## Modal Service Orchestration Standard

For modal workflows triggered from grids or action buttons, use the following base model:

1. Trigger component (`cellRenderer` or button host) calls a specific method on the modal service.
2. Modal service adapts input data to the modal input contract.
3. Modal component only renders UI and returns one output contract.
4. Before implementation, decide output ownership per flow:
  - service-owned output: service executes submit/cancel side effects
  - caller-owned output: service returns typed output and caller executes side effects

### Responsibilities by Layer

| Layer | Allowed Responsibilities | Not Allowed |
| :--- | :--- | :--- |
| Trigger (cell renderer) | Invoke service method with row context | Parsing modal payload, submission side effects |
| Modal service | Open/close dialog, parse input/output, map client payload, guard double-open | Rich UI logic |
| Modal component | Capture user input and emit one result contract | API calls, client-module payload mapping |
| Client module/orchestrator | Execute business side effects with the parsed service result | Modal internals |

Choose one ownership mode per modal flow and keep it consistent.

## ⚠️ Component-Scoped Services (Non-Root)

Certain services in this architecture are **intentionally NOT** `providedIn: 'root'`.
They rely on the **Component Injector** lifecycle to manage ephemeral state (cleanup on destruction).

### core Rule

If a service manages state specific to a single interaction flow (e.g., a modal wizard, a form session), it **MUST** be provided in the `@Component` decorations `providers` array.

For modal orchestration services, this rule applies by default unless there is an explicit cross-feature sharing requirement.

### Service Registry

| Service Name | Scope Description | Critical Reason |
| :--- | :--- | :--- |
| `AdminAccessResourceModalService` | Component (Orchestrator) | Handles state (`_selectedResource`) for a specific modal interaction. Must reset/destroy when the host component is destroyed. |
| `DiscoveryWizardPageService` | Component (Page) | Manages wizard steps and form state. State must not leak to other pages/sessions. |

### Implementation Pattern

**❌ Anti-Pattern (Missing Provider):**
```typescript
@Component({
  // Missing providers array
  selector: 'app-my-feature'
})
export class MyFeatureComponent {
    // This will throw NoProviderError OR reuse a stale parent instance
    service = inject(AdminAccessResourceModalService);
}
```

**✅ Standard Pattern (Component Provider):**
```typescript
@Component({
  selector: 'app-my-feature',
  // Service is created NEW for this component instance
  providers: [AdminAccessResourceModalService] 
})
export class MyFeatureComponent {
    // Safe injection
    service = inject(AdminAccessResourceModalService);
}
```
