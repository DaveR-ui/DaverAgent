---
last_updated: 2026-05-05
description: authoritative guide for consuming security permissions from NgRx today without coupling docs to RxJS pipelines, with a migration path toward signals
tags: [security, permissions, ngrx, signals, access-control, role-support]
---

# Security Permissions

> [!CAUTION]
> **Selector contract only.** When this document references an NgRx selector, it refers to the raw selector output only. Do **not** document or recommend RxJS pipes on top of the selector here. Each component owns its own `skipWhile`, `map`, `combineLatest`, `toSignal`, `takeUntilDestroyed`, or equivalent local transformation until the permissions flow is migrated to signals.

## Path & Overview

- Current backend permission shape: `src/app/core/models/security-roles.domain.ts`
- Default permission values: `src/app/core/constants/security-roles.constants.ts`
- Test permission fixtures: `src/app/core/constants/unit-test-mocked-data.constant.ts`
- Selector entry point: `src/app/state/security-roles/security-roles.selector.ts`

This permission model is the source of truth for role-gated UI behavior. Components can read the store state today through NgRx selectors, but the **meaning** of each permission must remain stable even if the transport moves from selectors to signals later.

## Data Flow

1. Backend permission payload arrives in the raw `IPermissions` shape.
2. `SecurityRoles` maps backend flags into the normalized `{ create, read, update, delete }` structure.
3. Components read permission state from the security roles selectors.
4. Each component decides locally how to combine permissions with other state such as LaunchDarkly flags, resource type, or platform.

## Standard Selector Reference

Use one of these selectors as the input boundary, depending on the granularity the component needs:

- `selectSecurityPermissionsLoadDataSelector`: full security roles state, including `loaded` and normalized permissions.
- `selectSecurityPermissionsSelector`: normalized permissions object.
- `selectSecurityPermissionsReadSelector`: read permissions only.
- `selectSecurityPermissionsCreateSelector`: create permissions only.
- `selectSecurityPermissionsUpdateSelector`: update permissions only.

### Rule: Do Not Push Pipes Into The Selector Contract

Document selectors like this:

```typescript
this.store.select(selectSecurityPermissionsLoadDataSelector)
```

Do **not** document selectors like this:

```typescript
this.store.select(selectSecurityPermissionsLoadDataSelector).pipe(
  skipWhile(...),
  map(...)
)
```

The second form is component-specific orchestration, not selector documentation.

## Permission Gates In Current Use

| Backend permission | Normalized field | Current UI meaning | Notes |
| --- | --- | --- | --- |
| `Access_AdminAdministration` | `read.accessAdminAdministration` | Allows administration-only behavior when the component also passes any required LaunchDarkly gate | No current Access Modal cross-env dependency |
| `Role_Support` | `read.role_Support` | Marks support users that must not edit resource access from the Data Requests manage-access action | UI should treat this as a hard disable gate |

## Current Component Rules

### Access Modal

- The cross-env toggle is not controlled by LaunchDarkly alone.
- The toggle requires `LD_FLAG_ADMIN_EDIT_CROSSENV`.
- The toggle must stay disabled when the modal is opened from the Data Requests flow (`openedByDrflag === true`).
- The toggle must stay hidden for Azure resources.
- The toggle must stay hidden for Integrations resources.

### Data Requests Manage Access Cell Render

- The manage-access button requires an allowed resource type.
- The manage-access button requires an active resource status.
- The manage-access button must stay disabled for `read.role_Support === true`.
- The manage-access button must stay disabled for Integrations resources.
- LaunchDarkly remains an additional gate, not a replacement for permissions.

## Anti-Patterns To Avoid

| Anti-Pattern | Why it is wrong | Standard |
| --- | --- | --- |
| Documenting selector usage with baked-in RxJS pipes | Couples docs to one component implementation and makes the future signals migration harder | Document the raw selector; let each component decide its local orchestration |
| Treating LaunchDarkly as the only access gate | Flags toggle features, but they do not replace permission semantics | Evaluate permission and flag together in the owning component |
| Adding new permission flags only to one mock shape | Breaks tests that rely on `IFieldsSecurityRoles` or `IPermissions` completeness | Update domain interfaces, empty defaults, and unit-test fixtures together |
| Encoding permission meaning in a reusable selector pipeline | Prevents future signal migration and blurs component ownership | Keep semantic interpretation in the component or a future signal facade |

## Standard Pattern

Use this documentation model when adding or changing permission-gated behavior:

1. Add or confirm the backend field in `IPermissions`.
2. Map it into the normalized `SecurityRoles` read/create/update/delete structure.
3. Update `SECURITY_ROLE_EMPTY` and all test fixtures.
4. Reference the raw selector in docs.
5. Let the owning component decide how to combine permission state with flags, resource metadata, and local UI state.

## Testing Rules

- `provideMockStore({ selectors: [...] })` is the preferred documentation example for selector-backed permission tests.
- Mock the normalized structure the selector returns, not just the raw backend shape.
- When adding a new permission field, update both:
  - `IFieldsSecurityRoles` mocks
  - `IPermissions` mocks

### Minimal Mock Shapes

Normalized selector-backed state:

```typescript
{
  loaded: true,
  data: {
    permissions: {
      read: {
        accessAdminAdministration: true,
        role_Support: false,
      }
    }
  }
}
```

Raw backend payload:

```typescript
{
  Access_AdminAdministration: true,
  Role_Support: false,
}
```

## Future Migration To Signals

- The migration target is a signal-based permission consumption layer.
- To keep that migration cheap, permission docs must describe **semantic gates** and **selector contracts**, not RxJS operator chains.
- If a future signal facade is introduced, this document should be updated to map the same permission meanings to the new signal API without changing the permission semantics.
