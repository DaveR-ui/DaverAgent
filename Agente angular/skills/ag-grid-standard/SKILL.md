---
name: ag-grid-standard
description: Standard configurations and patterns for implementing AG Grid in Angular v20+.
---

# AG Grid Standard Skill

This skill defines the standard way to implement complex data tables using `ag-grid-angular`.

## 🛠️ Core Implementation Rules
1. **No External State in Logic**: Avoid using `rxResource` or `httpResource` directly for grid data logic. Use `IServerSideDatasource`.
2. **Local Assets**: Keep constants, interfaces, and specific services within the same folder as the grid component.
3. **Lifecycle Management**:
   *   `onGridReady`: Capture the `gridApi`.
   *   `onFirstDataRendered`: Apply `autoSizeAllColumns` and restore previous state (Filters/Sort) from the Store.
4. **Excel Export Strategy (Full Data)**:
   *   Send `startRow: -1` and `endRow: -1` to the API.
   *   **Crucial**: Update `cacheBlockSize` to match `totalRows` during export.
   *   **Reset**: Revert `cacheBlockSize` to `currentPageSize` immediately after export to avoid UI lag.
5. **Robust Cache Control**: In `getRefreshParams()`, always force `cacheBlockSize` to match current pagination size to prevent cache state bugs.

## 📋 Component Structure Template
```typescript
  // Excel Export Strategy
  exportDataToFile(data: IBaseRequestEntity<T>) {
    // 1. Set cache to total row count for export
    this.gridApi.updateGridOptions({ cacheBlockSize: data.totalRows });
    
    // 2. Load data into server-side cache
    this.gridApi.applyServerSideRowData({
      successParams: { rowData: data.listOfResources, rowCount: data.totalRows }
    });

    // 3. Trigger export
    if (this.exportFileType === ExportFileType.Excel) this.gridApi.exportDataAsExcel();

    // 4. RESET CACHE to original size
    this.gridApi.updateGridOptions({ cacheBlockSize: this.currentPageSize });
  }

  // Refresh with Cache safety
  getRefreshParams(): RequestListParams {
    this.gridApi.updateGridOptions({ cacheBlockSize: this.gridApi.paginationGetPageSize() });
    return {
      startRow: this.gridApi.paginationGetPageSize() * this.gridApi.paginationGetCurrentPage(),
      // ...
    };
  }
```

## 🎨 Styling & Configuration
- **Class**: Always use `class="ag-theme-data"`.
- **Excel Styles**: Use the shared `excelStyles` from `@core/models/aggridModels.domain`.
- **Icons**: Use Material Icons for group expansion (`expand_more`, `expand_less`).

## 🔍 Sub-tables (Master-Detail)
When implementing sub-tables:
- Set `masterDetail: true`.
- Define `detailCellRendererParams` with `detailGridOptions`.
- Use a local service method to fetch detail data.

---

## 📚 Further Reading
For more in-depth information, refer to the files in the `agent-context/aggrid/` folder:
- [ag-grid-implementation.md](../../agent-context/aggrid/ag-grid-implementation.md) — architectural standards, project organization, export strategy, and UX rules.
- [troubleshooting/ag-grid-errors.md](../../agent-context/aggrid/troubleshooting/ag-grid-errors.md) — known errors and fixes (export row count, infinite loading state).
