---
last_updated: 2026-03-12
status: complete
ai_optimized: yes
tags: [modal, confirmation, administration, dialog, requestor]
---

# Confirmation Modal

## Purpose
- `AccessConfirmationDialogComponent` collects the final approval metadata required before a caller submits an administrative change.
- It does **not** call any backend directly.
- It returns a dialog result shaped like `{ confirmed, requestor, comments }`.

## Component Path
- `src/app/core/components/administration-modals/confirmation-modal/access-confirm-modal.ts`
- `src/app/core/components/administration-modals/confirmation-modal/access-confirm-modal.html`
- `src/app/core/components/administration-modals/confirmation-modal/access-confirm-modal.spec.ts`

## Current Callers
- `AccessModalComponent` opens it before returning access-change payloads.
- `EditMetadataModalComponent` opens it before returning metadata-update payloads.
- In both flows, this modal is the final gate that captures:
  - `requestor: Employee`
  - `comments: string`

## Dialog Contract

### Input (`AccessConfirmDialogData`)
```ts
type AccessConfirmDialogData = {
  title?: string;
  message?: string;
  confirmText?: string;
  cancelText?: string;
};
```

### Output
```ts
{ confirmed: true, requestor: Employee | null, comments: string }
{ confirmed: false }
```

## UI Behavior
- Header title uses `data.title || 'Confirm'`.
- Body message uses `data.message || 'Do you want to proceed?'`.
- `Requestor` uses `app-typeahead` with `[(ngModel)]="requestor"`.
- `Comments` uses a plain textarea with `[(ngModel)]="comments"`.
- Submit button stays disabled until `requestor` is selected.
- Close button and top-right `X` both resolve to `cancel()`.

## Data Flow
1. Caller opens `AccessConfirmationDialogComponent` through `MatDialog.open(...)`.
2. Caller provides contextual title/message.
3. User selects a requestor from the people picker.
4. User optionally writes comments.
5. `confirm()` closes the dialog with `{ confirmed: true, requestor, comments }`.
6. `cancel()` closes the dialog with `{ confirmed: false }`.
7. Caller decides whether to continue with the real save/access-change operation.

## Critical Notes
- This modal is a **data-capture dialog**, not the actual mutation step.
- The parent component owns submission side effects.
- `confirmText` and `cancelText` exist in the input interface but are **not used in the template** right now; labels are hardcoded to `Submit` and `Close`.
- Validation is minimal: only `requestor` gates submit. `comments` are optional.
- Returned `requestor` can be typed as `Employee`, but the component state is `Employee | null` until selection.

## Standard Usage Pattern
```ts
const confirmationDialogRef = this.dialog.open(AccessConfirmationDialogComponent, {
  minWidth: '40vw',
  height: '50vh',
  data: {
    title: 'Edit Metadata',
    message: 'Are you sure you want to save these metadata changes?'
  },
  disableClose: true
});

confirmationDialogRef.afterClosed().subscribe((result) => {
  if (result?.confirmed) {
    // parent continues with actual submit flow
  }
});
```

## Known Legacy/Local Anti-Patterns
- Uses template-driven forms with `ngModel` instead of the newer signals/forms patterns.
- Parent callers currently use imperative `afterClosed().subscribe(...)` flows.
- Button labels are duplicated/hardcoded instead of honoring dialog input config.

## Guidance For Future Changes
- Keep this modal focused on collecting `requestor` + `comments`; do not move API submission logic here.
- Preserve the simple result contract so existing callers keep working.
- If configurable button text is needed, wire `confirmText` / `cancelText` into the template instead of introducing new fields.
- If validation becomes stricter, keep the rule in the modal and keep callers submission-only.

## Testing Strategy
- Current spec is logic-focused and overrides the template to test only dialog close payloads.
- Core assertions:
  - initial state is `requestor = null`, `comments = ''`
  - `confirm()` closes with `{ confirmed: true, requestor, comments }`
  - `cancel()` closes with `{ confirmed: false }`
- If template behavior is expanded, add DOM tests for submit disabled state and close actions.
