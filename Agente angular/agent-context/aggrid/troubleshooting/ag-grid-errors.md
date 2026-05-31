---
last_updated: 2026-03-26
status: ACTIVE
ai_optimized: yes
tags: [ag-grid, errors, troubleshooting]
---

# AG Grid — Common Errors & Solutions

## Excel export generates fewer rows than expected

**Symptom**: The exported Excel/CSV file contains fewer rows than the total record count returned by the API.

**Cause**: The grid's `cacheBlockSize` is still set to the current page size during export, so only the current page block is written to the file.

**Solution**: Before injecting the full dataset, update `cacheBlockSize` to match the total row count returned by the backend. Reset it back to `currentPageSize` immediately after the export finishes.

```typescript
exportDataToFile(data: IBaseRequestEntity<T>) {
  // 1. Expand cache to hold all rows
  this.gridApi.updateGridOptions({ cacheBlockSize: data.totalRows });

  // 2. Load the full dataset into the server-side cache
  this.gridApi.applyServerSideRowData({
    successParams: { rowData: data.listOfResources, rowCount: data.totalRows }
  });

  // 3. Trigger export
  this.gridApi.exportDataAsExcel(); // or exportDataAsCsv()

  // 4. CRITICAL: Reset cache to original page size
  this.gridApi.updateGridOptions({ cacheBlockSize: this.currentPageSize });
}
```

---

## Grid stuck in infinite loading state

**Symptom**: The grid spinner never stops; rows never appear after navigating to a page or filtering.

**Cause**: The `startRow` / `endRow` values passed to the server-side datasource `getRows` callback are incorrect (e.g., both are `-1` outside an export context, or the request was not constructed relative to the current page).

**Solution**: Ensure `startRow` and `endRow` are derived from the grid's pagination state, not hardcoded. Only use `startRow: -1` / `endRow: -1` as the export-trigger convention; revert to normal values for all other requests.

```typescript
getRows(params: IServerSideGetRowsParams): void {
  const pageSize = this.gridApi.paginationGetPageSize();
  const currentPage = this.gridApi.paginationGetCurrentPage();

  const request: RequestListParams = {
    startRow: pageSize * currentPage,  // ✅ correct
    endRow: pageSize * (currentPage + 1),
    // ...filters, sort
  };

  this.service.fetchData(request).subscribe({
    next: (data) => params.success({ rowData: data.rows, rowCount: data.totalRows }),
    error: () => params.fail()
  });
}
```
