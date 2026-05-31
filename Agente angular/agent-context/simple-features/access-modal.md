---
last_updated: 2026-05-12
description: architecture reference for the access modal component, its internal state partitions, boundaries, and supporting files
tags: [component, access-modal, architecture, angular, signals, modal]
---

# Access Modal Component

## Purpose

This document describes the component architecture of the access modal:

- which files belong to the feature
- which responsibilities stay inside the component
- how state is partitioned
- how the template consumes the state graph
- where the component starts and stops

It intentionally does not define product policy or business rules.

## Component Path

- `src/app/core/components/access-modal/access-modal.component.ts`
- `src/app/core/components/access-modal/access-modal.component.html`
- `src/app/core/components/access-modal/access-modal.component.scss`

## Architectural Role

The modal is the UI composition root for access editing of one resource.

- It owns orchestration for local UI state.
- It does not own final submission side effects.
- It coordinates resource loading, selector inventory, working selection, and form output.
- It delegates payload normalization to a pure utility.
- It delegates modal opening and post-close handling to a service.

## Related Files

- `admin-access-resource-modal.service.ts`: orchestration boundary outside the component
- `access-modal.models.ts`: modal input/output contracts and API DTOs
- `access-selector-models.components.ts`: domain shape for projects, accounts, and roles
- `access-modal-payload.utils.ts`: pure transformation layer used during submit
- `project-access-form/`: nested editor for one selected project

## File Structure

### `access-modal.component.ts`

Contains the architectural core of the feature:

- dependency wiring
- resource definitions
- derived state graph
- user actions
- dialog close behavior

### `access-modal.component.html`

Contains only view composition:

- header block
- project accordion
- selector and control actions
- global alert block
- footer actions

### `access-modal.component.scss`

Contains local modal presentation rules only. It is not part of the state model.

## High-Level Boundaries

### Inbound Boundary

The component receives all external context through injected collaborators:

- `MAT_DIALOG_DATA` for the modal input
- `MatDialogRef` for closing
- `MatDialog` for nested confirmation dialogs
- `HttpClient` for data retrieval
- `Store` for user and flag signals
- `AdminAccessResourceModalService` for origin/context state

### Outbound Boundary

The component emits one dialog result object on close. It does not persist data itself.

### Internal Boundary

Inside the component, architecture is divided into four layers:

1. load layer
2. derived-state layer
3. interaction layer
4. payload layer

## API Endpoints

| Method | Endpoint | Used For |
| :--- | :--- | :--- |
| `GET` | `/api/workflow/resource/{resourceId}` | Resource security handshake |
| `GET` | `/api/workflow/resource/{resourceId}/access-manage` | Initial selected projects/accounts snapshot |
| `POST` | `/api/workflow/resource/administration/{environment}/getObjectAccess` | Account-demand metadata used by the form |
| `POST` | `/api/workflow/Resource/administration/{environment}/project/list` | GCP project inventory for the selector |
| `POST` | `/api/workflow/Resource/administration/{environment}/getObjectAccessByProject` | Extra object-access metadata when a GCP project is added |
| `GET` | `/api/workflow/Resource/administration/{cloudProjectSubscriptionId}/iam-access/{resourceName}/{environment}` | Per-project IAM refresh when a GCP project is added |
| `GET` | `/api/workflow/Resource/administration/{cloudProjectSubscriptionId}/iam-access-table/{resourceId}/{environment}` | Same as above for table resources |
| `GET` | `/api/workflow/resource/administration/{environment}/Azure/Subscriptions` | Azure project inventory |

## Architecture Layers

### 1. Load Layer

The load layer is responsible for obtaining external data and stopping downstream work when prerequisites fail.

- `securityCheck` gates the entire modal
- `resourceData` loads the initial selected project snapshot
- `objectAccessData` loads account-demand metadata
- `crossEnvProjects` and `azureSubscriptions` provide selector inventory

This layer is reactive and request-driven. It should not know about template structure beyond the state it exposes.

### 2. Derived-State Layer

The derived-state layer turns loaded data into UI-consumable structures.

- platform labels
- selector labels
- active inventory source
- visible project list
- tab selection
- alert state
- submit/disable state

This layer is where the modal's internal architecture is most concentrated. The template should read from this layer instead of recomputing logic.

### 3. Interaction Layer

The interaction layer owns user-triggered transitions:

- `toggleCrossEnvProjectFilter()`
- `addProject()`
- `removeProject()`
- `confirm()`
- `cancel()`

This layer mutates local working state but does not own server persistence.

### 4. Payload Layer

The payload layer converts form state into the final close contract.

- `getProjectAccessData()` gathers the current form state
- `buildProjectAccessData()` performs the normalization and reconciliation

This keeps submit-time shape building separate from UI orchestration.

## State Partitions

| State | Type | Responsibility |
| :--- | :--- | :--- |
| `securityCheck` | `httpResource` | Controls whether the modal can continue loading |
| `resourceData` | `httpResource` | Owns the initial selected project snapshot |
| `objectAccessData` | `rxResource` | Owns account-demand metadata |
| `crossEnvProjects` | `rxResource` | Owns the GCP selector inventory |
| `azureSubscriptions` | `rxResource` | Owns the Azure selector inventory |
| `projectInventory` | `computed` | Chooses the active inventory source |
| `projects` | `linkedSignal` | Owns the mutable working selection shown by the modal |
| `visibleProjects` | `computed` | Readonly projection of `projects` used by the accordion |
| `projectSelectorOptions` | `computed` | Inventory minus already-selected projects |
| `projectTabSelectedIndex` | `linkedSignal` | Active accordion tab index over `visibleProjects` |
| `mergedObjectAccessData` | `linkedSignal` | Extended object-access metadata after project additions |
| `enaListByProject` | `computed` | Demand options grouped by project |
| `accountDemandsMap` | `computed` | Demand availability grouped by project and account |
| `globalAlert` | `computed` | Single source for modal banners |

## Internal State Model

### Source State

- external dialog input
- backend resource responses
- store-backed user and flag values

### Working State

- `projects` is the mutable local source of truth.
- `removedProjects` tracks local removals from the original snapshot
- `hasPendingChanges` tracks whether the modal has unsaved local edits
- `crossEnvProjectFilterRequested` tracks selector mode

### Projection State

- `visibleProjects` is a readonly projection of `projects`
- `projectSelectorOptions` is a readonly projection of inventory minus selected items
- `projectHeader` is a readonly projection of the active tab
- `globalAlert` is a readonly projection of resource and blocking states

### Form Projection State

- `enaListByProject` exposes demand options per project
- `accountDemandsMap` exposes demand availability per account
- `isSubmitDisabled` and `isSelectorDisabled` convert multiple states into button/control guards

## Structural Relationships

### Service to Component

- The service opens the modal.
- The component owns the local interaction session.
- The service consumes the close result.

### Component to Child Form

- The parent owns project-level orchestration.
- The child form owns per-project editing UI.
- The parent passes project data, ENA data, and account-demand mapping into each child instance.

### Component to Utility

- The component owns current session state.
- The utility owns pure payload reconciliation.
- The utility must not own modal orchestration.

### Resource Layer to Template

- resources feed computed state
- computed state feeds the template
- the template does not decide state ownership

## Template Structure

The template is organized into five architectural blocks:

1. modal header
2. resource summary header
3. project accordion region
4. alert region
5. footer action region

### Project Accordion Region

This is the central rendering block of the component.

- it iterates over `visibleProjects`
- it binds one accordion panel per visible project
- it mounts one `app-project-access-form` per panel
- it uses `projectTabSelectedIndex` as the active panel controller

### Selector

- The selector is architecturally separate from the accordion.
- It operates on inventory state, not on the rendered selected-project collection.
- Its job is to extend the working selection, not to edit existing project content.

### Global Alert

- `globalAlert` is the status composition point for the modal.
- The template renders one alert block from one computed source.
- This keeps resource status rendering centralized instead of scattering conditions across the template.

### Submit Button

- The submit button is not a source of truth.
- It is only a UI gate over existing derived state.

## Dialog Contract

### Input Contract

- Input enters through `AccessModalData`.
- The component assumes one resource context per modal instance.

### Output Contract

The component closes with one object containing:

- confirmation status
- normalized project access payload
- requestor
- comments

## Architectural Notes

- `projects` is the central session state of the modal.
- `visibleProjects` exists to support a readonly render-specific projection.
- `projectTabSelectedIndex` must follow the same collection used by the template.
- Inventory state and selected-project state must remain separate architectural concepts.
- The component is an orchestrator, not a persistence service and not a business-rules registry.

## Out of Scope

This file does not define:

- test strategy
- generic Angular anti-patterns unrelated to this component's structure
- permission policy
- product rule definitions
