---
last_updated: 2026-05-28
description: migration notes and business rules for the cloud resource manage access refactor
tags: [cloud-resources, manage-access, signals, ngrx-migration, role-filtering]
---

# Cloud Resource Manage Access

## Purpose

This document captures the logic and migration details for the "Manage Access" flow in Cloud Resources, specifically regarding how resource access is fetched, filtered, and cleaned up after the NgRx migration.

## Business Rules: Role Filtering

When selecting or displaying roles for cloud resource access, the following rules apply:

- **Blocked Role IDs**: `8`, `22`, `23`, `35`
- **Visibility Logic**:
  - Blocked roles must be **hidden** from the selection list for *new* role assignments.
  - If the backend returns one of these roles as **already selected** (existing assignment), it must remain visible and selectable to preserve the current state.

## NgRx Migration Details

The cloud resource access read path has been migrated from NgRx to direct service ownership (`CloudResourcesService`).

### Safe Cleanup Pattern

The cleanup of the legacy `cloud-resources` state followed a strict "state-split" pattern:

1. **Read-Flow Migration**: Components were moved to consume data directly from services.
2. **State Splitting**: The old mixed state (containing both read data and write/status info) was split.
   - `selectCloudResourceAccess` (identity selector) became dead.
   - `cleanCloudResourceAccess` was retained until the final split because it reset the state bucket shared by remaining write actions.
3. **Selective Deletion**: Only after the read/write logic was fully decoupled were the obsolete read actions/effects/selectors removed.

## Focused Verification

Use these focused test suites to verify the cloud resource state and management logic:

```bash
npm run test:headless -- \
  --include=src/app/state/cloud-resources/cloud-resources.reducer.spec.ts \
  --include=src/app/state/cloud-resources/cloud-resources.effects.spec.ts \
  --include=src/app/state/cloud-resources/cloud-resources.selector.spec.ts \
  --include=src/app/core/grid/cell-renderers/cloud-resources-cell-render/cloud-resources-cell-render.component.spec.ts
```

### Known Test Issues

- **Router Events Toast Host Spec**: Execution of broader access-form specs might be blocked or slowed down by unrelated failures in the `router-events-toast-host` spec. If encountered, use the `--include` flag to isolate the relevant cloud resource specs.

## Related Documentation

- [Removing NgRx Store](../../agent-workflows/removing-ngrx-store.md): General guide on the migration strategy used here.
- [Access Modal](access-modal.md): Internal architecture of the modal where this data is consumed.
