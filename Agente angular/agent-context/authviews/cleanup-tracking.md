---
tags: [authviews, cleanup, ngrx, migration, signals, refactoring]
---

# Cleanup Tracking - Authview Wizard Refactoring

## Deleted Legacy State (NgRx)

The following files and directories were removed after migrating to Signal-based `rxResource` logic:

### 1. Dataset Tables State

- **Path**: `src/app/state/dataset-tables/`
- **Files deleted**:
  - `dataset-tables.actions.ts`
  - `dataset-tables.effects.spec.ts`
  - `dataset-tables.effects.ts`
  - `dataset-tables.reducer.spec.ts`
  - `dataset-tables.reducer.ts`
  - `dataset-tables.selector.ts`

### 2. Tables Schemas State

- **Path**: `src/app/state/tables-schemas/`
- **Files deleted**:
  - `tables-schemas.actions.ts`
  - `tables-schemas.effects.spec.ts`
  - `tables-schemas.effects.ts`
  - `tables-schemas.reducer.spec.ts`
  - `tables-schemas.reducer.ts`
  - `tables-schemas.selector.ts`

## Configuration Updates

The following files were updated to remove references to the deleted states:

- `src/app/state/state.reducers.ts`: Removed reducers from `ActionReducerMap`.
- `src/app/state/models/state.interface.ts`: Removed state interfaces from `IState`.
- `src/app/state/index.ts`: Removed selector exports.
- `src/app/app.module.ts`: Removed effects from `EffectsModule.forRoot()`.

## Verification Status

- **Tables Selection**: Migrated to `TablesSelectorComponent` using `rxResource`.
- **Schemas Selection**: Migrated to `SchemasSelectorComponent` using `rxResource`.
- **Global Store**: No longer contains `datasetTables` or `tablesSchemas` slices.
