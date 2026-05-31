---
tags: [ag-grid, grid, excel-export, pagination, datasource, server-side, cell-renderer, sub-table]
---

# AG Grid Implementation Guidelines

## 📋 Overview
This document describes the architectural standards for implementing tables using `ag-grid-angular` in this project. All grids should follow these rules to ensure consistency and maintainability.

---

## 🏗️ 1. Project Organization
Grids are self-contained. All supporting files should be in the same folder as the component:
- `grid-name.component.ts` / `.html` / `.scss`
- `grid-name.constants.ts` (Column definitions, translations)
- `grid-name.service.ts` (Specific API calls for this grid)
- `grid-name.domain.ts` (Interfaces/Models specific to the data returned)

**Note:** Do NOT use barrel files (`index.ts`). All imports should be explicit and direct to the specific file.

---

## 🛠️ 2. Core Implementation Rules

### 🚫 2.1 Avoid `rxResource` or `httpResource` in Grid Logic
The grid should manage its own data lifecycle whenever possible.
- **Server-side Mode**: Use `IServerSideDatasource`. This provides built-in support for pagination, sorting, and filtering.
- **Manual Data Fetching**: If needed, use a `LocalGridService` and handle it within the `getRows` method of the datasource.
- **Why**: Bypassing the grid's datasource API leads to state drift and inconsistent loading indicators.

### � 2.2 Lifecycle & State Restore
- **`onGridReady`**: Always capture the `gridApi`.
- **`onFirstDataRendered`**: 
  - Call `autoSizeAllColumns(false)` to optimize column widths.
  - Subscribe to the Store (Navigation state) and apply previous filters (`setFilterModel`) and sorting (`applyColumnState`).

### 📥 2.3 Excel Export Strategy (Full Data)
To export all rows while being on a paginated grid:
1. **Request**: Send `startRow: -1` and `endRow: -1` to the backend.
2. **Cache Swap**: 
   - Before data injection: `gridApi.updateGridOptions({ cacheBlockSize: totalRows })`.
   - Update rows: `gridApi.applyServerSideRowData({ successParams: { rowData, rowCount } })`.
3. **Trigger**: Call `gridApi.exportDataAsExcel()` or `csv`.
4. **Cleanup**: **CRITICAL** revert `cacheBlockSize` to `currentPageSize`.

### ⚡ 2.4 Cache Resilience
In `getRefreshParams()`, always add an extra control:
```typescript
this.gridApi.updateGridOptions({ cacheBlockSize: this.gridApi.paginationGetPageSize() });
```
This ensures the grid does not become unresponsive if an export operation fails to reset the cache.

---

## 🎨 3. Visual & UX Standards
- **Theme**: Always use `class="ag-theme-data"`.
- **Expansion Icons**:
  - `expand_more` (Material) for contracted rows.
  - `expand_less` (Material) for expanded rows.
- **Pagination**: 
  - Standard sizes: `[10, 20, 50]`.
  - Preferred to use `IServerSideDatasource` for large datasets.

---

## 📥 4. Exporting Data
- Always provide both **Excel** and **CSV** export options if data allows.
- Centralize export styles using the shared `excelStyles` domain object.

---

## 📝 5. Documentation for New Grids
Each grid folder **MUST** contain a `README.md` file summarizing its purpose, endpoints, and any specific behaviors (e.g., custom cell renderers).
