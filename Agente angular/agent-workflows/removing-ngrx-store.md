# Removing NgRx Store - Migration Guide

**Status:** ACTIVE MIGRATION  
**Last Updated:** 2026-01-23  
**Priority:** HIGH

## ⚠️ Important Notice

**DO NOT USE NgRx Store for new features.** The project is actively migrating away from NgRx to simpler, more maintainable patterns. NgRx will be completely removed in the near future.

## Why Remove NgRx?

1. **Unnecessary Complexity:** Most features only do: HTTP request → success/error → show toast. NgRx adds 5+ files for this simple flow.
2. **Hard to Maintain:** Changes require modifying actions, effects, reducers, selectors, and components.
3. **Angular Evolution:** Modern Angular has better built-in solutions (signals, `rxResource`, etc.)
4. **Testing Overhead:** NgRx requires extensive mocking and boilerplate in tests.

## Recommended Alternatives

### For Simple HTTP Requests
Use `rxResource` as the project-standard resource API:

```typescript
// OLD: NgRx way
store.dispatch(getData());
// Requires: actions.ts, effects.ts, reducer.ts, selector.ts

// NEW: Direct way
data = rxResource({
  stream: () => this.http.get<Data>(this.apiUrl + '/data')
});
```

### For Component Communication
Use Angular's built-in patterns:

```typescript
// For parent-child: Use @Input() and @Output()
@Output() dataChanged = output<DataType>();

// For unrelated components: Use a service with BehaviorSubject
private dataSubject = new BehaviorSubject<DataType | null>(null);
data$ = this.dataSubject.asObservable();
```

### For Form State
Keep it local to the component or use signals:

```typescript
formData = signal<FormType>({ /* initial */ });
```

## Migration Flow

Follow these steps when removing NgRx from a feature:

### Step 1: Identify the Feature
Find where `store.dispatch()` is called:
```typescript
// Example: Finding dispatches
this.store.dispatch(sendAuthViewData({ data }));
```

### Step 2: Safe Migration Order
To avoid breaking the application during refactoring, follow this sequence:

1. **Move Read Consumers First**: Migrate components that read data to use direct services or `rxResource`.
2. **Apply Logic at Mapping Layer**: Move logic (filtering, sorting, mapping) from selectors to the new direct-read service layer.
3. **Split State Buckets**: If the state is mixed (e.g., read data + write status), split them. Keep writing status in NgRx temporarily if needed, but move the reading data out.
4. **Remove Dead Read Flow**: Only after all consumers are moved, delete the read actions, effects, and selectors.

### Step 3: Trace the NgRx Chain
Locate all related files:
- **Actions:** `feature.actions.ts` - Define action types
- **Effects:** `feature.effects.ts` - Handle side effects (HTTP calls)
- **Reducer:** `feature.reducer.ts` - Manage state updates
- **Selectors:** `feature.selector.ts` - Query state
- **State Interface:** Usually in `state.interface.ts` or `state.model.ts`

### Step 4: Replace with Direct Pattern

#### Pattern A: Component → Service (Most Common)
**Before (NgRx):**
```typescript
// component.ts
this.store.dispatch(sendData({ data }));

// effects.ts
sendData$ = createEffect(() => {
  return this.actions$.pipe(
    ofType(sendData),
    switchMap(({ data }) => 
      this.service.sendData(data).pipe(
        map(() => sendDataSuccess()),
        catchError(error => of(sendDataFail({ error })))
      )
    )
  );
});
```

**After (Direct):**
```typescript
// component.ts
this.service.sendData(data).pipe(
  catchError((error: HttpErrorResponse) => {
    const formatted = HttpErrorResponseManager.manage(error);
    this.toastService.showError(formatted.errorMsg);
    return of(null);
  })
).subscribe(result => {
  if (result) {
    this.toastService.showSuccess('Data saved successfully');
    this.closeModal('success');
  }
});
```

#### Pattern B: Component → rxResource (Read-Only Data)
**Before (NgRx):**
```typescript
// component.ts
ngOnInit() {
  this.store.dispatch(loadData());
  this.data$ = this.store.select(selectData);
}

// effects.ts (20+ lines)
// reducer.ts (15+ lines)
// selector.ts (10+ lines)
```

**After (rxResource):**
```typescript
// component.ts
data = rxResource({
  stream: () => this.http.get<Data>(this.apiUrl + '/data')
});

// Use in template:
@if (data.isLoading()) { ... }
@if (data.error()) { ... }
@if (data.value()) { ... }
```

#### Pattern C: Shared State Between Components
**Before (NgRx):**
```typescript
// Multiple components dispatch/select from store
store.dispatch(updateSharedData({ data }));
store.select(selectSharedData);
```

**After (Service with Signal):**
```typescript
// shared-data.service.ts
@Injectable({ providedIn: 'root' })
export class SharedDataService {
  private dataSubject = new BehaviorSubject<DataType | null>(null);
  data$ = this.dataSubject.asObservable();
  
  setData(data: DataType) {
    this.dataSubject.next(data);
  }
  
  clearData() {
    this.dataSubject.next(null);
  }
}

// component.ts
constructor(private sharedData = inject(SharedDataService)) {}

ngOnInit() {
  this.sharedData.data$.subscribe(data => {
    // Handle data
  });
}
```

### Step 5: Update Component
1. Remove `Store` injection
2. Remove store-related imports (actions, selectors)
3. Replace `store.dispatch()` with direct service calls
4. Replace `store.select()` with service observables or `rxResource`
5. Add error handling with `catchError` operator
6. Add success/error toasts if needed

### Step 6: Clean Up State Management
Remove the feature state from global state:

```typescript
// state.model.ts
export enum StateType {
  // Remove: AuthViewData = 'authViewData',
}

// state.interface.ts
export interface IState {
  // Remove: authViewData: IAuthViewState;
}

// app.module.ts - Remove from StoreModule.forRoot()
StoreModule.forRoot(
  {
    // Remove: authViewData: AuthViewReducer,
  }
)
```

**Lesson: Distinguish Dead from Secondary Logic**
During cleanup, verify every "dead" selector or action.
- **Identity Selectors**: Selectors like `selectCloudResourceAccess` become dead once consumers move.
- **Shared State Buckets**: Reset actions (e.g., `cleanCloudResourceAccess`) might still be needed if the state bucket is shared between a migrated read-flow and a remaining write-flow. Separate the state buckets first to reach 100% dead-code removal.

### Step 7: Delete NgRx Files
Once the feature is migrated and tested, delete:
- `feature.actions.ts`
- `feature.effects.ts`
- `feature.reducer.ts`
- `feature.reducer.spec.ts`
- `feature.selector.ts`

**Warning**: Do not "delete everything at once" if the store manages both read data and write status. Separate them first to ensure write feedback (toasts, loading bars) continues to work while read data moves to signals.

**Important:** Remove from `app.module.ts` imports BEFORE deleting files!

### Step 8: Test Thoroughly
- Test the happy path (success case)
- Test error handling
- Test edge cases (empty data, network errors, etc.)
- Verify toasts appear correctly
- Check that no console errors appear

## Real-World Examples

### Example 1: AuthView Wizard (Completed ✅)
**What was removed:**
- `auth-view.effects.ts`
- `auth-view.actions.ts`
- `auth-view.reducer.ts`
- `auth-view.reducer.spec.ts`
- `auth-view.selector.ts`

**Changes made:**
```typescript
// BEFORE: authview-wizard.component.ts
onSubmit() {
  this.store.dispatch(sendAuthViewData({ data }));
}

// AFTER: authview-wizard.component.ts
onSubmit() {
  this.authViewService.sendAuthViewData(data).pipe(
    catchError((error: HttpErrorResponse) => {
      const formatted = HttpErrorResponseManager.manage(error);
      this.toastService.showError(formatted.errorMsg);
      return of(null);
    })
  ).subscribe(result => {
    if (result) {
      this.submitAuthViewSubject.next('success');
    }
  });
}
```

**Result:** Removed 5 files, ~150 lines of code. Logic is now easier to follow and maintain.

### Example 2: Google Projects V2 Typeahead (Completed ✅)
**What was removed:**
- `Store` dependency from component
- `getEnaListProject` dispatch

**Changes made:**
```typescript
// BEFORE: google-projects-v2.component.ts
effect(() => {
  const projectId = this.googleProjects.value().projectId;
  if (projectId) {
    this.store.dispatch(getEnaListProject({ projectId }));
  }
});

// AFTER: google-projects-v2.component.ts
projectSelected = output<string>(); // Emits projectId

effect(() => {
  const projectId = this.googleProjects.value().projectId;
  if (projectId) {
    this.projectSelected.emit(projectId);
  }
});
```

**Result:** Component is now pure and reusable. Parent components handle the projectId event as needed.

## Common Pitfalls

### ❌ Don't Copy NgRx Patterns
```typescript
// BAD: Creating a custom "store-like" service
class CustomStore {
  private state = new BehaviorSubject({});
  dispatch(action) { /* complex logic */ }
  select(selector) { /* complex logic */ }
}
```

### ✅ Keep It Simple
```typescript
// GOOD: Simple service with focused methods
class DataService {
  getData(): Observable<Data> {
    return this.http.get<Data>(this.url);
  }
  
  saveData(data: Data): Observable<void> {
    return this.http.post<void>(this.url, data);
  }
}
```

### ❌ Don't Store Everything
```typescript
// BAD: Storing transient UI state
private modalOpenSubject = new BehaviorSubject<boolean>(false);
```

### ✅ Use Local Component State
```typescript
// GOOD: Local signal for UI state
modalOpen = signal<boolean>(false);
```

## Migration Checklist

Use this checklist for each feature migration:

- [ ] Identified all `store.dispatch()` calls for the feature
- [ ] Located all related NgRx files (actions, effects, reducer, selectors)
- [ ] Replaced dispatch with direct service calls
- [ ] Added proper error handling (`catchError`)
- [ ] Added success/error toasts
- [ ] Replaced `store.select()` with service observables or `rxResource`
- [ ] Removed `Store` injection from component
- [ ] Removed NgRx imports from component
- [ ] Removed feature state from `state.model.ts` and `state.interface.ts`
- [ ] Removed effects registration from `app.module.ts`
- [ ] Deleted NgRx files (actions, effects, reducer, selectors)
- [ ] Tested happy path
- [ ] Tested error scenarios
- [ ] Verified no console errors
- [ ] Updated documentation

## Current Status

### ✅ Completed Migrations
- Auth View Wizard (2026-01-23)
- Google Projects V2 Typeahead (2026-01-23)

### 🔍 Remaining NgRx Usage
Search for these patterns to find remaining usage:
```bash
# Find all store dispatches
grep -r "store.dispatch" src/

# Find all store selects
grep -r "store.select" src/

# Find all effects files
find src/ -name "*.effects.ts"
```

Common areas still using NgRx:
- `ena-list-project` - Used in multiple components (table-access-form, cloud-access-form, data-requests-list-grid, etc.)
- `router-events-info` - Toast notifications
- Various form and grid components

## Questions?

When in doubt:
1. **Ask:** "Does this need to be in global state?" (Usually NO)
2. **Ask:** "Can I use rxResource instead?" (Usually YES for read-oriented reactive data loading)
3. **Ask:** "Can I keep this state local?" (Usually YES for UI state)
4. **Default:** Use the simplest approach that works

---

**Remember:** The goal is to make the codebase simpler, more maintainable, and easier to understand. When removing NgRx, always choose the most straightforward alternative.
