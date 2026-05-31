---
name: modal-creation
description: Guidelines for creating a modern, signal-based Angular modal service and component.
---
# Modal Creation Skill

> **Description**: Create a modern, signal-based Angular modal service and component.
> **Triggers**: "create a modal", "add a dialog", "modal service", "popup", "dialog ref", "open modal from service"

> **Full reference**: [agent-context/modal-creation.md](../../agent-context/modal-creation.md)

## Strategy

| Trigger type | Pattern |
|---|---|
| Explicit user action (button, grid cell) | Service orchestration method (`openFromCell`/`openFromAction`) — store ref, guard against double-open |
| Secondary simple entrypoint | Direct wrapper that calls `openDialog(...)` |
| Output handling ownership | Decide explicitly: service-owned output or caller-owned output |

## Steps

1. Create a modal service that owns `MatDialog`, `dialogRef`, and private modal signals.
2. Define one typed modal input contract and one typed modal output contract.
3. Expose a specific service entrypoint for callers (`openFromCell(...)`, `openFromAction(...)`) instead of letting callers parse payloads.
4. Decide output ownership before implementation:
	- service-owned output: service executes submit/cancel side effects
	- caller-owned output: service returns typed output and caller executes side effects
5. In `afterClosed()`: null out `dialogRef`, then process output according to the chosen ownership model.
6. Create a standalone `@Component` that injects `MAT_DIALOG_DATA` and `MatDialogRef`, with only UI/data-capture responsibilities.

## Readability Rule

- Keep simple open/close guards, caller-context mapping, and short normalization branches in the modal service when they are only used there.
- Extract helpers only when the logic is reused, grows enough to hide the service flow, or represents a real modal-domain concept.

> Scope rule: for interaction-scoped modal state, provide the modal service in the host component `providers` array.

See the reference doc for full service and component templates.
