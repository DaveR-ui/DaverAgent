---
last_updated: 2026-04-29
status: active
ai_optimized: yes
tags: [modal, dialog, service, signals, angular, dialogref, cdk, cell-renderer, contracts, orchestration]
changelog:
  - 2026-03-26: Extracted from modal-creation SKILL.md
  - 2026-04-29: Added canonical cell-renderer orchestration flow, single input/output contract, and service-first parsing rules
  - 2026-04-29: Simplified alternative variant by removing signal/effect intermediary state
  - 2026-04-29: Replaced outputless pattern with an explicit output ownership decision model
---

# Modal Creation Patterns

Decouples Modal UI from triggering logic using a **Signal-based Service**.

## Canonical Orchestration Flow (Grid/Cell Renderer)

Use this as the default architecture for modal workflows triggered from AG Grid:

1. `cellRenderer` calls a specific service method (`openFromCell(...)`) with row context.
2. Modal service parses/adapts cell data into a **single modal input contract**.
3. Service opens modal and passes exactly one input object via dialog data.
4. Modal closes with exactly one output object (or cancel).
5. Service parses/normalizes modal output and returns client-ready data to the host module.

This keeps parse logic and integration concerns out of the modal UI component.

## Contract Standard (Single Input / Single Output)

For new modal implementations, define one typed input and one typed output:

```typescript
export interface MyModalInput {
  resourceId: string;
  displayName: string;
  context: 'create' | 'edit';
}

export interface MyModalOutput {
  confirmed: boolean;
  requestorId?: string;
  comments?: string;
}
```

The modal component receives only `MyModalInput` and emits only `MyModalOutput` through `close(...)`.

## Strategy Selection

| When | Use |
|---|---|
| Triggered by an explicit user action (grid cell, button, menu) | **Direct service entrypoint** (`openFromCell`/`openFromAction`) |
| Need a lightweight second entrypoint without extra state | **Direct wrapper** that calls `openDialog(...)` |
| Need to define where submit/cancel side effects run | **Choose ownership explicitly**: Service-owned output or Caller-owned output |

## 1. Direct Method-Based Modal Service (Preferred)

```typescript
import { Injectable, inject } from '@angular/core';
import { MatDialog, MatDialogRef } from '@angular/material/dialog';
import { Observable, finalize, map, of, take } from 'rxjs';
import { MyModalComponent, MyModalInput, MyModalOutput } from './my-modal.component';

@Injectable()
export class MyModalService {
  private readonly dialog = inject(MatDialog);
  private dialogRef: MatDialogRef<MyModalComponent> | null = null;

  openFromCell(cell: { id: string; name: string }): Observable<{ resourceId: string; approvedBy: string } | undefined> {
    const input = this.toModalInput(cell);
    if (this.dialogRef) return of(undefined); // Guard against double-open

    this.dialogRef = this.dialog.open(MyModalComponent, {
      data: input,
      width: '600px',
      disableClose: true,
      autoFocus: false
    });

    return this.dialogRef.afterClosed().pipe(
      take(1),
      map((result: MyModalOutput | undefined) => this.toClientPayload(input, result)),
      finalize(() => {
        this.dialogRef = null;
      })
    );
  }

  close(): void {
    this.dialogRef?.close({ confirmed: false });
  }

  private toModalInput(cell: { id: string; name: string }): MyModalInput {
    return {
      resourceId: cell.id,
      displayName: cell.name,
      context: 'edit'
    };
  }

  private toClientPayload(
    input: MyModalInput,
    result: MyModalOutput | undefined
  ): { resourceId: string; approvedBy: string } | undefined {
    if (!result?.confirmed || !result.requestorId) return undefined;

    return {
      resourceId: input.resourceId,
      approvedBy: result.requestorId
    };
  }
}
```

> [!IMPORTANT]
> For interaction-scoped modal flows, provide the service at the host/orchestrator component (`providers: [MyModalService]`) to avoid stale state leaks.
> Use `providedIn: 'root'` only when a modal service is intentionally shared across features and has no per-flow ephemeral state.

## 2. Alternative Direct Wrapper (No Intermediary State)

```typescript
import { Injectable, inject } from '@angular/core';
import { MatDialog } from '@angular/material/dialog';

@Injectable()
export class MyModalServiceWrapper {
  private readonly dialog = inject(MatDialog);

  open(item: MyModalInput): void {
    this.openDialog(item);
  }

  private openDialog(item: MyModalInput): void {
    const dialogRef = this.dialog.open(MyModalComponent, {
      data: item, width: '600px', disableClose: true, autoFocus: false
    });
    dialogRef.afterClosed().subscribe((result?: MyModalOutput) => {
      if (result) this.handleResult(result);
    });
  }

  private handleResult(result: MyModalOutput): void { /* ... */ }
}
```

## 2.1 Output Ownership Decision (Required)

Before implementing a modal flow, decide who owns the final output side effects.

| Ownership mode | Who executes submit/cancel side effects | Recommended when |
|---|---|---|
| **Service-owned output** | Modal service (`postData`, toasts, cleanup, refresh) | Flow is reused and side effects are shared across callers |
| **Caller-owned output** | Caller/orchestrator module | Side effects differ per caller or depend on caller context |

### Service-owned output

- Service opens modal and handles `afterClosed()` internally.
- Service executes backend calls and cleanup directly.
- Caller only triggers `open...()`.

### Caller-owned output

- Service opens modal and returns typed result (`Observable<MyModalOutput | undefined>`).
- Caller decides what to do with confirmed/cancelled output.
- Service stays focused on modal orchestration.

Do not mix ownership modes in the same modal flow.

## 3. Standalone Modal Component

```typescript
export interface MyModalInput { resourceId: string; displayName: string; context: 'create' | 'edit'; }
export interface MyModalOutput { confirmed: boolean; requestorId?: string; comments?: string; }

@Component({
  selector: 'app-my-modal',
  standalone: true,
  imports: [CommonModule, MatDialogModule, MatButtonModule],
  template: `
    <h2 mat-dialog-title>{{ data.displayName }}</h2>
    <mat-dialog-content>
      <p>Processing ID: {{ data.resourceId }}</p>
    </mat-dialog-content>
    <mat-dialog-actions align="end">
      <button mat-button (click)="cancel()">Cancel</button>
      <button mat-flat-button color="primary" (click)="confirm()">Confirm</button>
    </mat-dialog-actions>
  `,
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class MyModalComponent {
  readonly dialogRef = inject(MatDialogRef<MyModalComponent>);
  readonly data = inject<MyModalInput>(MAT_DIALOG_DATA);

  confirm(requestorId: string, comments = ''): void {
    this.dialogRef.close({ confirmed: true, requestorId, comments });
  }

  cancel(): void {
    this.dialogRef.close({ confirmed: false });
  }
}
```

## Key Rules

- Always store `dialogRef` on the service; guard `open()` against duplicate calls.
- Keep internal state minimal; do not expose selection-derived signals unless they are used by callers.
- Keep modal component contracts minimal: one typed input and one typed output.
- Keep input/output parsing and client payload mapping in the service, not in the modal component.
- Prefer direct service entrypoints and avoid intermediary signal/effect state unless strictly required by the feature.
- Decide output ownership explicitly per modal flow (service-owned or caller-owned) and keep it consistent.
- Prefer observable-based dialog result flows (`afterClosed()`) over promise chains in callers.