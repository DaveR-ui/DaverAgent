---
tags: [authviews, wizard, edit, create, state, flow, rxResource]
---

# Authview Wizard Context

## File Map

- **Orchestrator:** `src/app/core/components/authviews/authviews.component.ts`
- **Wizard Container:** `src/app/core/components/authviews/authview-wizard/authview-wizard.component.ts`
- **Data Service:** `src/app/core/components/authviews/auth-view.service.ts`
- **Trigger (Grid):** `src/app/core/grid/cell-renderers/authview-cell-render/authview-crud-buttons-cell-render.component.ts`

## Data Flow: Edit Mode (onEdit)

1. **Trigger**: `AutoviewCrudButtonsCellRenderComponent.onEdit()` emits the selected row data via `authService.editAuthViewSubject`.
2. **Detection**: `AuthviewsComponent` subscribes to this subject.
3. **Setup**:
   - Calls `authViewService.clearAuthViewData()` to reset state.
   - Maps row data to `AdministrationResource` and sets it in `authViewService.dataset`.
   - Sets `authViewService.tables` with the single resource name.
4. **Modal Launch**: Opens `AuthviewWizard` with a restricted step list:
   - `[Tables, Schemas, Filters, Summary]`
   - Skip: `Datasets`, `Access`, `Config`.
5. **Component Logic**: `TablesSelectorComponent` detects the existing selection and disables table changes (`disableEdition = true`).

## Data Flow: Create Mode

1. **Trigger**: `AuthviewsComponent.openAuthviewModal()`.
2. **Setup**: Clears service data.
3. **Modal Launch**: Opens wizard with full step list:
   - `[Datasets, Tables, Schemas, Filters, Access, Config, Summary]`

## State Management

- The `AuthViewService` acts as a synchronous data store for the wizard steps.
- Each step component reads/writes directly to the service properties (`dataset`, `tables`, `schemas`, etc.).
- **Submission**: `AuthviewWizardComponent` handles the final click:
  - If `editAuthViewSubject` has a value AND `config` is null -> Calls `sendDataToEdit()`.
  - Otherwise -> Calls `sendAuthViewData()` directly from `AuthViewService`.

## ✅ FIXED: editAuthViewSubject State Leak (2026-01-23)

### Problem (RESOLVED)
When the modal closed, `editAuthViewSubject` retained its value, preventing the same item from being edited twice without a page refresh.

**Root Cause:** `editAuthViewSubject` was only cleared in `ngOnDestroy()` of `AuthviewsComponent`, which doesn't fire when the modal closes.

### Solution Implemented

**1. Cleanup after successful edit submission** (`authview-wizard.component.ts`):

```typescript
this.authviewWizardService.sendDataToEdit(lastId).subscribe(() => {
  this.authviewWizardService.submitAuthViewSubject.next(lastId);
  this.authviewWizardService.editAuthViewSubject.next(null); // Clear edit state
});
```

**2. Cleanup on modal close** (`authviews.component.ts`):

```typescript
const modalRef = this.authviewModal.open(MODAL_WRAPPER_COMPONENT.AuthviewWizard, {
  wizardItemListDef: [WizardItemEnum.Tables, WizardItemEnum.Schemas, WizardItemEnum.Filters, WizardItemEnum.Summary]
});

if (modalRef && modalRef.result) {
  modalRef.result.then(
    () => this.authViewService.editAuthViewSubject.next(null), // Normal close
    () => this.authViewService.editAuthViewSubject.next(null)  // Dismissed (ESC, backdrop)
  );
}
```

**3. Modal wrapper enhancement** (`modal-wrapper.component.ts`):
Changed `open()` return type from `void` to `NgbModalRef | undefined` to enable promise handling.

### Current Cleanup Points
1. ✅ After successful edit submission
2. ✅ On modal close/dismiss
3. ✅ `AuthviewsComponent.ngOnDestroy()` - on component destroy

**Result:** Now supports editing the same authview multiple times without page refresh.
