---
last_updated: 2026-02-03
status: CURRENT
ai_optimized: yes
tags: [dropdown, components, signals, legacy, migration, multi-select]
---

# Dropdown Components Documentation

## 🚨 CRITICAL: Component Selection Guide

**For NEW single-select dropdowns (simple):** Use `dropdown-select-remaster`
**For NEW single-select dropdowns (searchable):** Use `dropdown-select-autocomplete`
**For NEW multi-select dropdowns:** ⚠️ Use legacy `dropdown-multi-select` (no modern alternative yet)
**For NEW multi-select with search:** ⚠️ Use legacy `input-search-dropdown-multi-select` (no modern alternative yet)
**For EXISTING code:** Do NOT migrate without approval (80-120 hours effort for all 6 components)
**For filter grids:** Use `dropdown-select-extended` (legacy but functional)

> 🔴 **CRITICAL GAP**: No modern (signals-based, standalone) multi-select component exists yet. This is a priority for future development.

---

## Component Inventory

**Total Components: 6** (4 single-select + 2 multi-select)

### 1. dropdown-select (Legacy/Original)
**Path:** `src/app/shared/components/dropdown-select/`
**Status:** 🟡 LEGACY - Do not use for new features
**Usages:** 6 components actively use this

**Architecture:**
- Traditional `@Input/@Output` decorators
- Implements `ControlValueAccessor` + `Validator`
- Expects `IDropdownModel` with `detailList: IDropdownDetail[]`
- Emits `IFormDropdown` objects `{id, value, tag?}`
- Standalone component (Angular 18+)

**Key Inputs:**
```typescript
@Input() dropdownData: IDropdownModel;                // Required - contains detailList array
@Input() selectId: string;                            // Unique ID for form control
@Input() selectDisabled: boolean;                     // Disable dropdown
@Input() emptySelectionText: string = 'None';         // Placeholder text
@Input() hasErrors: boolean = false;                  // Show validation errors (is-invalid CSS)
@Input() hideTextLabel: boolean = false;              // Hide label (a11y maintained)
@Input() pretty: boolean = false;                     // "Badge" display mode (colored badges)
@Input() useStatusDisplayMapping: boolean = false;    // Transform via getStatusDisplay()
@Input() tooltipTemplate: TemplateRef | null = null;  // Custom tooltip content
@Input() dataCySuffix: string;                        // Test selector suffix
@Input() required: boolean = false;                   // Mark as required
```

**Key Outputs:**
```typescript
@Output() changeSelection$: EventEmitter<IFormDropdown>;       // Primary selection change event
@Output() changeAccessSelection$: EventEmitter<IFormDropdown>; // Secondary event (access-specific usage)
```

**⚠️ Naming Note:** The input `pretty` in code is conceptually "badge mode" - displays status values as colored badges.

**Template Features:**
- Native Bootstrap dropdown (`<div class="dropdown">`)
- Badge styling for status values (via `pretty` input)
- Error state: `is-invalid` CSS class (via `hasErrors` input)
- Empty state: `is-empty` CSS class
- Status transformation via `getStatusDisplay()` utility (when `useStatusDisplayMapping = true`)
- Label can be hidden with `hideTextLabel` while maintaining a11y

**CVA Implementation:**
```typescript
writeValue(value: IDropdownDetail | undefined) { /* Sets selectedOption */ }
onChange: (value: IFormDropdown) => void;  // Emits {id, value, tag?}
```

**Validator Implementation:**
```typescript
validate(control: AbstractControl): ValidationErrors | null {
  // Returns {required: true} if value.id is empty string
}
```

**Known Usages:**
1. `access-modal.component.ts` - Async data with RxJS
2. `configuration-details-table.component.ts` - Inside ngFor loop
3. `data-request-form.component.ts` - With ViewChild access
4. `sign-off.component.ts` - Reactive forms
5. `ticket-eng-form.component.ts` - 5 instances, uses `showError`
6. `role-id-table.component.ts` - Most complex: tooltipTemplate, dataCySuffix

---

### 2. dropdown-select-remaster (Modern)
**Path:** `src/app/shared/components/dropdown-select-remaster/`
**Status:** ✅ CURRENT - Use for all new features
**Usages:** Currently unused (brand new)

**Architecture:**
- **Standalone component**
- **Signals-based** reactivity
- Generic typing: `DropdownSelectRemasterComponent<T>`
- Implements `ControlValueAccessor` only (NO Validator)
- NgbDropdown module integration

**Key Inputs (Signals):**
```typescript
options = input.required<T[]>();                    // Generic array - FLEXIBLE
displayKey = input<keyof T | string>('value');      // Property to display
valueKey = input<keyof T | string>('id');          // Property for value
selectId = input<string>(/* auto-generated */);     // Unique ID
label = input<string>('');                          // Visible label
placeholder = input<string>('None');                // Empty state text
helpText = input<string>('');                       // Help text below
disabled = input<boolean>(false);                   // Disable control
hideLabel = input<boolean>(false);                  // Hide label (a11y OK)
required = input<boolean>(false);                   // Mark as required
tooltipTemplate = input<TemplateRef<any>>();        // Custom tooltip
```

**Key Output:**
```typescript
selectionChange = output<any>();  // Emits RAW VALUE (not object)
```

**Special Features:**
- **`returnObject` Input:** Added `returnObject = input<boolean>(false)`. When set to `true`, the component emits the full object instead of just the `valueKey` property, while still using `valueKey` internally to match the selected item correctly.

**CVA Implementation:**
```typescript
writeValue(value: any) { /* Sets selectedValue signal */ }
onChange: (value: any) => void;  // Emits raw value only (e.g., just the ID)
```

**Computed Signals:**
```typescript
selectedOption = computed(() => /* finds option by selectedValue */);
displayValue = computed(() => /* gets display text via displayKey */);
isEmpty = computed(() => /* checks if no selection */);
```

**Template Features:**
- NgbDropdown component
- Clean signal-based rendering
- Simplified data-cy attributes
- `expandUpwards` input toggles menu placement (`top-start` / `bottom-start`)
- Empty state: `text-muted` class
- NO badge support (yet)
- NO error styling (yet)
- NO status transformation (yet)

**Advantages over Original:**
- ✅ Generic typing - works with ANY data shape
- ✅ Modern Angular reactivity
- ✅ Cleaner computed values
- ✅ Better performance (signals)
- ✅ NgbDropdown accessibility

**Missing from Original:**
- ❌ `Validator` interface (form validation)
- ❌ `withBadge` mode
- ❌ `showError` visual feedback
- ❌ `is-invalid` CSS classes
- ❌ Status display mapping
- ❌ `IFormDropdown` payload (emits raw value)

---

### 3. dropdown-select-extended (Filter-Specific)
**Path:** `src/app/shared/components/dropdown-select-extended/`
**Status:** 🟡 LEGACY but FUNCTIONAL - Used for grid filters
**Usages:** 2 components (grid-filter-control, grid-filter-control-eng-ticket)

**Architecture:**
- **Extends** `dropdown-select` (inheritance)
- Adds delete functionality for saved filters
- Overrides template to add delete buttons

**Additional Inputs:**
```typescript
// Inherits all from dropdown-select
// No new inputs
```

**Additional Outputs:**
```typescript
@Output() deleteFilter$: EventEmitter<{id: string, value: string}[]>;
```

**Override Properties:**
```typescript
override emptySelectionText = CUSTOM_FILTER_NOT_SAVE;  // "Filters not saved"
defaultNoFilterId = DEFAULT_NO_FILTER_ID;
```

**Additional Methods:**
```typescript
delete(opt: IDropdownDetail) {
  this.deleteFilter$.emit([{id: opt.id, value: opt.value}]);
}

deleteAll() {
  this.deleteFilter$.emit(
    this.dropdownData?.detailList
      .filter(d => d.id !== this.defaultNoFilterId)
      .map(d => ({id: d.id, value: d.value}))
  );
}
```

**Template Additions:**
- Delete icon button next to each dropdown item
- "Delete All" button at bottom of dropdown
- Conditional rendering (hides delete for default "No Filter" option)

**Used By:**
- `grid-filter-control.component.ts` - Manages AG Grid saved filters
- `grid-filter-control-eng-ticket.component.ts` - Eng Tickets version

**Data Flow:**
```
Parent Component
  ↓ [dropdownData]="IDropdownModel"
dropdown-select-extended
  ↓ (changeSelection$)="IFormDropdown"  // Apply filter
  ↓ (deleteFilter$)="{id, value}[]"     // Delete filter(s)
Parent Component
  → Opens confirmation modal
  → Calls backend to delete
  → Refreshes filter list
```

---

### 4. dropdown-select-autocomplete (Modern Autocomplete)
**Path:** `src/app/shared/components/dropdown-select-autocomplete/`
**Status:** ✅ CURRENT - Use for searchable/autocomplete dropdowns
**Usages:** 1 component (confirm-admin-copy-resource)

**Architecture:**
- **Standalone component**
- **Signals-based** reactivity
- Generic typing: `DropdownSelectAutocompleteComponent<T>`
- Implements `ControlValueAccessor` only (NO Validator)
- **Custom HTML implementation** (NOT Material Autocomplete - see note below)
- **Client-side filtering** with computed signals
- **No built-in debouncing** (filtering happens on every keystroke)

**⚠️ CRITICAL CLARIFICATION:** Despite the name "autocomplete", this component does NOT use Angular Material's `mat-autocomplete`. It's a custom implementation using plain HTML `<input>` + `<ul>` dropdown with signals-based filtering.

**Key Inputs (Signals):**
```typescript
// Core Data
options = input<T[]>([]);                           // Generic array of options
displayKey = input<keyof T | string>('value');      // Property to display in dropdown
valueKey = input<keyof T | string>('id');          // Property for form value

// UI Configuration
label = input<string>('');                          // Visible label
placeholder = input<string>('Search...');           // Input placeholder text
disabled = input<boolean>(false);                   // Disable control
required = input<boolean>(false);                   // Mark as required
selectId = input<string>(/* auto-generated */);     // Unique ID for accessibility
isLoading = input<boolean>(false);                  // Show loading spinner

// Validation
selectedOptionValidationIcon = input<boolean>(false); // Show validation icon
ariaDescribedBy = input<string>();                    // ARIA describedby attribute
```

**Key Outputs:**
```typescript
selectionChange = output<any>();  // Emits RAW VALUE (valueKey)
inputChange = output<string>();   // Emits text input changes
inputBlur = output<void>();       // Input blur event
inputFocus = output<void>();      // Input focus event
```

**CVA Implementation:**
```typescript
writeValue(value: any) { 
  // Finds option by valueKey, sets selectedOption and internalValue signals
}
onChange: (value: any) => void;  // Emits raw value (e.g., just the ID)
```

**Computed Signals:**
```typescript
// Filtering logic
filteredOptions = computed(() => {
  // Filters options() based on internalValue()
  // Case-insensitive search on displayKey property
  // Returns full options list when internalValue is empty
});

// Display logic
displayValue = computed(() => {
  // Returns display text of selectedOption via displayKey
});

formattedLabel = computed(() => {
  // Formats label for data-cy attributes (lowercase, no spaces)
});
```

**Internal State Signals:**
```typescript
internalValue = signal<string>('');           // Current input text
selectedOption = signal<T | undefined>(undefined); // Currently selected option
isFocused = signal<boolean>(false);           // Input focus state
isDropdownOpen = signal<boolean>(false);      // Dropdown visibility
highlightedIndex = signal<number>(-1);        // Keyboard navigation index
```

**Template Features:**
- **Custom HTML implementation** (`<input>` + `<ul class="autocomplete-dropdown">`)
- **NOT Material UI** - Uses plain HTML with custom CSS
- Live filtering as you type (no debounce)
- Empty state messages: "Type at least 2 characters" / "No results found"
- Loading spinner support (via `isLoading` input)
- Validation states: `is-invalid` CSS class
- Full ARIA accessibility support
- Keyboard navigation (arrow keys, enter, escape)

**⚠️ Architecture Note:** This is a lightweight custom implementation, not a heavy UI framework component. Good for performance, but lacks advanced features like virtual scrolling or server-side search.

**Advantages over dropdown-select-remaster:**
- ✅ **Search/filter capability** - Users can type to find options
- ✅ **Progressive disclosure** - Shows filtered subset of options
- ✅ **Better UX for large lists** - Faster than scrolling through 100s of items
- ✅ **Keyboard navigation** - Arrow keys + Enter for selection
- ✅ **Lightweight** - No heavy UI framework dependencies

**Differences from google-projects-v2:**
- ✅ **Generic** - Works with any data type `T`
- ✅ **Static or dynamic** - Accepts `options` input (google-v2 is a legacy async pattern)
- ✅ **Reusable** - Not tied to Google Cloud Projects API
- ✅ **Configurable keys** - `displayKey`/`valueKey` like dropdown-select-remaster
- ❌ **No built-in rxResource integration** - Doesn't include built-in async data loading (yet)
- ❌ **No async error handling** - No loading/error states for API calls (yet)
- ❌ **No debouncing** - Filters on every keystroke (may need optimization for large datasets)

**When to Use:**
- ✅ Large dropdown lists (>20 options) where search improves UX
- ✅ User needs to quickly find specific option by typing
- ✅ Data is static but numerous (countries, states, products, etc.)
- ✅ Want lightweight implementation without UI framework dependencies
- ✅ Client-side filtering is acceptable (data already loaded)

**When NOT to Use:**
- ❌ Small dropdown lists (<10 options) - Use `dropdown-select-remaster`
- ❌ Need async data loading from API - Use pattern from `google-projects-v2` or extend component
- ❌ Need multi-select - Use `input-search-dropdown-multi-select` (legacy) or wait for modern alternative
- ❌ Need Material Design consistency - This uses custom HTML, not Material UI
- ❌ Need "badge" mode for status display - Use `dropdown-select` (legacy)
- ❌ Need delete functionality for filters - Use `dropdown-select-extended`
- ❌ Very large datasets (1000s+) requiring debouncing/throttling - Add debouncing or use server-side filtering

---

### 5. dropdown-multi-select (Legacy Multi-Select)
**Path:** `src/app/shared/components/dropdown-multi-select/`
**Status:** 🟡 LEGACY - Module-based, do not use for new features
**Usages:** 7-8 components (demand-form, ticket-eng-form, data-security-details-form, project-details-form, project-aia-details-form, settings-stage-status)

**Architecture:**
- Traditional `@Input/@Output` decorators
- **Module-based** (NOT standalone) - requires SharedModule import
- Implements `ControlValueAccessor` (NO Validator interface)
- Expects `IDropdownModel` with `detailList: IDropdownDetail[]`
- Emits `IFormDropdown[]` arrays (multiple values)
- UI: Bootstrap dropdown with multi-select checkboxes

**Key Inputs:**
```typescript
@Input() dropdownData: IDropdownModel | undefined;    // Required - contains detailList array
@Input() selectId: string = '';                       // Unique ID for form control
@Input() selectDisabled: boolean = false;             // Disable dropdown
@Input() emptySelectionText: string = 'None';         // Placeholder when no selection
@Input() placeHolder: string = '';                    // Alternative placeholder text
@Input() pretty: boolean = false;                     // Badge display mode
@Input() tooltipTemplate: TemplateRef<unknown> | null = null; // Custom tooltip content
@Input() hasErrors: boolean = false;                  // Show validation errors
@Input() required: boolean = false;                   // Mark as required
@Input() dataCySuffix: string = '';                   // Test selector suffix
@Input() customStyles: boolean = false;               // Apply custom dropdown styles (width: 100%, scrollable)
```

**Key Output:**
```typescript
@Output() changeSelection$: EventEmitter<IFormDropdown[]>; // Emits array of selected items
```

**Special Features:**

1. **"Select All" Functionality:**
   - Option with `id: 'all'` acts as toggle for all items
   - Selecting "all" checks/unchecks all non-"all" options
   - "All" checkbox reflects state: checked only when ALL items selected

2. **Badge Display Below Dropdown:**
   - Shows selected items as rounded pill badges
   - Badges display the `value` property of each selected item
   - Currently NO remove buttons on badges (display-only)
   - Badges automatically sorted by `order` property

3. **Checkbox UI:**
   - Each option rendered as checkbox in dropdown menu
   - `data-bs-auto-close="outside"` - dropdown stays open while selecting
   - Visual feedback with `checked` state on checkboxes

**CVA Implementation:**
```typescript
writeValue(value: IDropdownDetail[] | undefined) {
  // Pre-selects items by setting selectedOptions array
}

onChange: (ids: string[]) => void {
  // Emits array of IDs only (e.g., ['id1', 'id2', 'id3'])
}

// Additionally emits via changeSelection$:
changeSelection$.emit(IFormDropdown[]) 
// Full objects: [{id: 'id1', value: 'Option 1'}, ...]
```

**⚠️ Dual Output Pattern:**
- CVA `onChange` callback: Emits `string[]` (IDs only)
- `changeSelection$` EventEmitter: Emits `IFormDropdown[]` (full objects)
- Parent components typically use `changeSelection$` for rich data

**Template Features:**
- Bootstrap dropdown with `<div class="dropdown">`
- Checkboxes inside `<div class="px-3 py-2">` containers
- Badge list below dropdown: `<ul class="list-multi-select">`
- Scrollable menu option via `customStyles` input
- Data-cy attributes for testing: `app-dropdown-multi-select-text-{value}`

**Used By:**
1. `demand-form.component.ts` - Use Cases, Products, Tags multi-select
2. `ticket-eng-form.component.ts` - Multiple ticket field selections
3. `data-security-details-form.component.ts` - User types, Management standards (3 instances)
4. `project-details-form.component.ts` - Project configuration fields (2 instances)
5. `project-aia-details-form.component.ts` - AIA-specific multi-selections (2 instances)
6. `settings-stage-status.component.ts` - Workflow status selections

**When to Use:**
- ✅ **EXISTING code** that already uses it (maintain consistency)
- ✅ Multiple selection with checkboxes required
- ✅ "Select All" functionality needed
- ✅ Small to medium option lists (<50 items)
- ❌ **NEW features** - Consider waiting for modern signals-based alternative
- ❌ Large datasets requiring search - Use `input-search-dropdown-multi-select` instead

**Differences from dropdown-select (single-select):**
- ✅ **Multi-select capability** - Checkboxes allow multiple selections
- ✅ **Select All** - Built-in toggle for all items
- ✅ **Badge display** - Shows selected items as pills below dropdown
- ✅ **Array output** - Emits `IFormDropdown[]` instead of single object
- ❌ **No Validator interface** - Must add validators to FormControl manually
- ❌ **No search** - Plain dropdown, no filtering (use search variant for that)

**Known Limitations:**
- No remove buttons on badges (must reopen dropdown to deselect)
- No search/filter capability for large lists
- Module-based (not standalone) - requires SharedModule
- No signals-based reactivity
- CVA emits IDs only, must use `changeSelection$` for full objects

---

### 6. input-search-dropdown-multi-select (Typeahead Multi-Select)
**Path:** `src/app/shared/components/input-search-dropdown-multi-select/`
**Status:** 🟡 LEGACY/HYBRID - Uses NgbTypeahead, standalone component
**Usages:** 2 components (authview-wizard: schemas-selector, tables-selector)

**Architecture:**
- **Standalone component** (Angular 18+ style)
- Implements `ControlValueAccessor` + `Validator`
- Uses **NgbTypeahead** for search functionality
- Generic data model: `IInputSearchDropdownMultiSelectData[]`
- RxJS-based search with `focus$` and `click$` subjects
- **Smart search ranking**: "starts with" results before "contains" results

**Data Model:**
```typescript
interface IInputSearchDropdownMultiSelectData {
  id: string;
  value: string;
}
```

**Key Inputs:**
```typescript
@Input() searchId: string;      // Unique ID for search input (default: 'input-search-dropdown-multi-select-group-input')
@Input() selectAllId: string;   // ID for select all checkbox (default: 'authview-picker-form-check-select-all-input')
@Input() label: string = '';    // Visible label above component
@Input() emptySelectionText: string = ''; // Placeholder when no items selected
@Input() selectDisabled: boolean = false; // Disable entire control
@Input() required: boolean = false;       // Mark as required for validation
@Input() options: IInputSearchDropdownMultiSelectData[] = []; // Array of available options

// Signal input (modern):
selectAllInput = input<boolean>(false);   // Auto-select all items on init
```

**Key Output:**
- Uses CVA only (no custom `@Output` EventEmitters)
- Emits full `IInputSearchDropdownMultiSelectData[]` array via `onChange` callback

**Special Features:**

1. **NgbTypeahead Search:**
   - Live search as you type using NgbTypeahead component
   - `resultFormatter` - Displays option.value in dropdown
   - `inputFormatter` - Auto-selects item when clicked, clears input
   - Search triggers on focus, click, and typing

2. **Select All Checkbox:**
   - Checkbox above input to toggle all items at once
   - Auto-checks when all items manually selected
   - `selectAll()` / `deselectAll()` methods
   - Can auto-select all on init via `selectAllInput` signal

3. **Smart Search Ranking:**
   ```typescript
   // Priority 1: Options that START WITH search term
   // Priority 2: Options that CONTAIN search term (but don't start with it)
   // Results: Concatenated in order [startsWith, contains]
   ```

4. **Badge Display with Remove Buttons:**
   - Shows selected items as rounded pill badges
   - Each badge has clickable remove button (×)
   - `removeItem(item)` method to deselect individual items
   - Badges show item.value property
   - Ngb-highlight for search term emphasis in dropdown

5. **Filtered Dropdown:**
   - Hides already-selected items from search results
   - Only shows available (unselected) options
   - Dropdown updates as you select/remove items

**CVA Implementation:**
```typescript
writeValue(value: IInputSearchDropdownMultiSelectData[]) {
  // Pre-selects items by calling selectOpt() for each
  // Auto-checks "Select All" if all items selected
}

onChange: (selectedOptions: IInputSearchDropdownMultiSelectData[]) => void {
  // Emits FULL OBJECTS array, not just IDs
  // Called on every selection/deselection
}
```

**Validator Implementation:**
```typescript
validate(control: AbstractControl): ValidationErrors | null {
  const value = control.value as IInputSearchDropdownMultiSelectData[] ?? [];
  if (value.length === 0 && this.required) {
    return { requiredd: true }; // Note: typo in code "requiredd" with double 'd'
  }
  return null;
}
```

**Template Features:**
- NgbTypeahead input: `<input [ngbTypeahead]="search">`
- Select All checkbox above input
- Dropdown with ngb-highlight for search terms
- Badge list below: `<ul class="row list-multi-select">`
- Remove buttons on each badge: `<button ngbTooltip="Remove">`
- Full ARIA accessibility support
- Data-cy attributes: `app-input-search-dropdown-multi-select-{label}-{action}`

**RxJS Search Logic:**
```typescript
search: OperatorFunction<string, IInputSearchDropdownMultiSelectData[]> = (text$) => {
  const debouncedText$ = text$.pipe(
    distinctUntilChanged(),
    filter((term) => { this.term = term; return true; })
  );
  
  return merge(debouncedText$, this.focus$, this.click$).pipe(
    map((term) => {
      // 1. Filter by search term (startsWith first, then contains)
      // 2. Exclude already-selected items
      // 3. Return ranked results
    })
  );
}
```

**Used By:**
1. `schemas-selector.component.ts` - Authview wizard: Select database schemas for access request
2. `tables-selector.component.ts` - Authview wizard: Select database tables for access request

**When to Use:**
- ✅ **Multi-select with search/typeahead** functionality required
- ✅ **Large option lists** (50-1000s of items) where search is essential
- ✅ **"Select All"** + individual selection needed
- ✅ **Authview wizard patterns** (existing usage, maintain consistency)
- ✅ Need **remove buttons** on selected badges
- ❌ **NEW general-purpose features** - Consider building modern signals-based alternative
- ❌ Small option lists (<20 items) - Use `dropdown-multi-select` instead

**Comparison to dropdown-multi-select:**
- ✅ **Search/Typeahead** - NgbTypeahead for live search (vs. no search)
- ✅ **Remove badges** - Can remove individual items from badges (vs. display-only badges)
- ✅ **Validator interface** - Built-in form validation (vs. manual validators)
- ✅ **Smart ranking** - Search results ranked by relevance (vs. no search)
- ✅ **Filtered dropdown** - Hides already-selected items (vs. shows all)
- ✅ **Standalone** - No SharedModule needed (vs. module-based)
- ❌ **More complex** - RxJS operators, NgbTypeahead dependency (vs. simple checkboxes)
- ❌ **NgBootstrap dependency** - Tied to NgbTypeahead component (vs. plain Bootstrap)
- ⚠️ **Different data model** - Uses `IInputSearchDropdownMultiSelectData` (vs. `IDropdownModel`)

**When NOT to Use:**
- ❌ Small datasets without search needs
- ❌ Want to avoid NgBootstrap dependency
- ❌ Prefer IDropdownModel data structure (use dropdown-multi-select)

**Known Limitations:**
- Typo in validator: `requiredd` (double 'd') instead of `required`
- RxJS complexity may be overkill for simple use cases
- NgbTypeahead learning curve for customization

---

## 🚫 Compatibility Matrix

| Feature | Original | Extended | Remaster | Autocomplete | **Multi-Select** | **Search Multi-Select** |
|---------|----------|----------|----------|--------------|------------------|------------------------|
| **Selection Type** | Single | Single | Single | Single | **Multiple** | **Multiple** |
| **Data Model** | `IDropdownModel` | `IDropdownModel` | Generic `T[]` | Generic `T[]` | **`IDropdownModel`** | **`IInputSearchDropdown[]`** |
| **Output Payload** | `IFormDropdown` | `IFormDropdown` | Raw value | Raw value | **`IFormDropdown[]`** | **`IInputSearchDropdown[]`** |
| **Validator** | ✅ | ✅ (inherited) | ❌ | ❌ | **❌** | **✅** |
| **Signals** | ❌ | ❌ | ✅ | ✅ | **❌** | **Partial (1 input)** |
| **Search/Filter** | ❌ | ❌ | ❌ | ✅ (client-side) | **❌** | **✅ (NgbTypeahead)** |
| **Debouncing** | ❌ | ❌ | ❌ | ❌ | **❌** | **No (instant)** |
| **Multi-Select** | ❌ | ❌ | ❌ | ❌ | **✅ (checkboxes)** | **✅ (typeahead)** |
| **Select All** | ❌ | ❌ | ❌ | ❌ | **✅** | **✅** |
| **UI Component** | Bootstrap | Bootstrap | NgbDropdown | Custom HTML | **Bootstrap** | **NgbTypeahead** |
| **Delete Feature** | ❌ | ✅ (filters) | ❌ | ❌ | **❌** | **✅ (badge remove)** |
| **Badge Mode** | ✅ | ✅ (inherited) | ❌ | ❌ | **✅ (display-only)** | **✅ (removable)** |
| **Error Styling** | ✅ | ✅ (inherited) | ❌ | ✅ | **✅** | **❌** |
| **Standalone** | ✅ | ❌ (Module) | ✅ | ✅ | **❌ (Module)** | **✅** |
| **Async Loading** | ❌ | ❌ | ❌ | ❌ | **❌** | **❌** |
| **Drop-in Replace** | N/A | N/A | 🚫 NO | 🚫 NO | **🚫 NO** | **🚫 NO** |
| **Modern (Signals)** | ❌ | ❌ | ✅ | ✅ | **❌ (Legacy)** | **❌ (Hybrid)** |

**Legend:**
- **Original** = `dropdown-select` (legacy single-select)
- **Extended** = `dropdown-select-extended` (filter-specific with delete)
- **Remaster** = `dropdown-select-remaster` (modern single-select)
- **Autocomplete** = `dropdown-select-autocomplete` (modern searchable single-select)
- **Multi-Select** = `dropdown-multi-select` (legacy multi-select with checkboxes)
- **Search Multi-Select** = `input-search-dropdown-multi-select` (legacy/hybrid typeahead multi-select)

---

## 🎯 Migration Strategy

### ❌ Do NOT Attempt Direct Migration

**Remaster/Autocomplete are NOT drop-in replacements for legacy components.** Key incompatibilities:

1. **Data Model**
   - Legacy (Original, Extended, Multi-Select): `dropdownData: IDropdownModel` (with `detailList`)
   - Modern (Remaster, Autocomplete): `options: T[]` (generic array)
   - Search Multi-Select: `options: IInputSearchDropdownMultiSelectData[]` (specific interface)
   - Impact: ALL 15+ usages require data transformation

2. **Output Structure**
   - Original/Extended: Emits `{id: string, value: string, tag?: string}`
   - Multi-Select: Emits `IFormDropdown[]` (array of objects)
   - Search Multi-Select: Emits `IInputSearchDropdownMultiSelectData[]` (array of objects)
   - Remaster/Autocomplete: Emits raw value (e.g., just `"abc123"`)
   - Impact: Form handlers must be rewritten

3. **Validation**
   - Original, Extended, Search Multi-Select: Implement `Validator` interface
   - Remaster, Autocomplete, Multi-Select: Do NOT implement `Validator`
   - Impact: Form-level validation may break

4. **Multi-Select Capability**
   - NO modern (signals-based) multi-select alternative exists
   - Multi-Select and Search Multi-Select must remain as-is or be completely rewritten
   - Estimated effort for modern multi-select: 40-60 hours (new component from scratch)

5. **Extended Component**
   - Cannot extend remaster (different architecture)
   - Must be completely rewritten
   - Estimated effort: 8-16 hours

### ✅ Recommended Approach

**Option A: Coexistence (Recommended)**
```
┌─ NEW single-select features → dropdown-select-remaster OR dropdown-select-autocomplete
│
├─ NEW multi-select features → ⚠️ dropdown-multi-select (legacy) OR input-search-dropdown-multi-select (if search needed)
│   └─ Priority: Build modern signals-based multi-select component
│
├─ EXISTING single-select code → dropdown-select (no changes)
│
├─ EXISTING multi-select code → dropdown-multi-select (no changes)
│
├─ EXISTING search multi-select → input-search-dropdown-multi-select (no changes)
│
└─ Grid filters → dropdown-select-extended (no changes)
```

**Benefits:**
- Zero migration risk
- Modern code in new features
- Legacy code remains stable
- Gradual improvement over time
- Priority focus on missing modern multi-select component

**Option B: Gradual Migration (High Effort)**
```
1. Create adapter utilities:
   - transformIDropdownModelToArray(model: IDropdownModel): IDropdownDetail[]
   - transformValueToFormDropdown(value: any, options: T[]): IFormDropdown
   - transformMultiSelectData(data: IDropdownModel): IInputSearchDropdownMultiSelectData[]

2. Migrate components ONE at a time:
   - Update component TS to use adapter
   - Change template to modern component
   - Update form handlers for new payload
   - Test thoroughly

3. Keep extended and multi-select as-is until all singles migrated

4. Build new modern multi-select component (signals-based, standalone)

5. Migrate multi-select usages to new component

6. Finally rewrite extended as separate remaster component

Estimated effort: 80-120 hours for all 6 components + new multi-select
```

---

## 🧪 Testing Considerations

### Original/Extended (Legacy Single-Select)
- Mock `IDropdownModel` with `detailList: IDropdownDetail[]`
- Expect `IFormDropdown` in change event handlers
- Test `Validator` interface for required fields
- Test `pretty` mode rendering if used
- Test `hasErrors` styling

### Multi-Select (Legacy)
- Mock `IDropdownModel` with `detailList` including `{id: 'all', value: 'Select All'}`
- Expect `IFormDropdown[]` array in change event handlers
- Test "Select All" functionality (toggles all items)
- Test badge display below dropdown
- Test `changeSelection$` output vs CVA `onChange` (dual output pattern)
- NO Validator interface (test form-level validators manually)
- Test `customStyles` for scrollable dropdown

### Search Multi-Select (Legacy/Hybrid)
- Mock `IInputSearchDropdownMultiSelectData[]` array
- Test NgbTypeahead search functionality
- Test "Select All" checkbox above input
- Test search ranking (startsWith before contains)
- Test filtered dropdown (hides selected items)
- Test badge remove buttons
- Test `Validator` interface (note typo: `requiredd` instead of `required`)
- Test `selectAllInput` signal for auto-select on init

### Remaster (Modern Single-Select)
- Mock generic array: `[{id: 1, name: 'Test'}, ...]`
- Configure `displayKey` and `valueKey` to match mock
- Expect raw value in `selectionChange` event
- NO `Validator` interface (use form control validators)
- Test signal updates with `TestBed.flushEffects()`

### Autocomplete (Modern Searchable Single-Select)
- Mock generic array: `[{id: 1, name: 'Test'}, ...]`
- Test `filteredOptions()` computed signal
- Test keyboard navigation (arrow keys, enter, escape)
- Expect raw value in `selectionChange` event
- Test `isDropdownOpen`, `highlightedIndex` signals
- NO Validator interface (use form control validators)
- Test signal updates with `TestBed.flushEffects()`

---

## 📋 Code Examples

### Original Usage Pattern
```typescript
// Component TS
dropdownData: IDropdownModel = {
  detailList: [
    {id: '1', value: 'Option 1', order: 1},
    {id: '2', value: 'Option 2', order: 2}
  ]
};

onSelectionChange(selection: IFormDropdown) {
  console.log(selection.id, selection.value);
}

// Template
<app-dropdown-select
  [dropdownData]="dropdownData"
  [selectId]="'my-dropdown'"
  (changeSelection$)="onSelectionChange($event)">
</app-dropdown-select>
```

### Remaster Usage Pattern
```typescript
// Component TS
options = signal([
  {id: '1', name: 'Option 1'},
  {id: '2', name: 'Option 2'}
]);

onSelectionChange(value: string) {
  console.log('Selected ID:', value);
  // Need to find full object if needed:
  const selected = this.options().find(opt => opt.id === value);
}

// Template
<app-dropdown-select-remaster
  [options]="options()"
  [displayKey]="'name'"
  [valueKey]="'id'"
  [selectId]="'my-dropdown'"
  (selectionChange)="onSelectionChange($event)">
</app-dropdown-select-remaster>
```

### Autocomplete Usage Pattern
```typescript
// Component TS
airIdOptions = signal([
  {value: 'AIR-12345'},
  {value: 'AIR-67890'},
  {value: 'AIR-11111'}
]);

selectedAirId: string = '';

ngOnInit() {
  this.selectedAirId = 'AIR-12345'; // Pre-select value
}

onSelectionChange(value: string) {
  console.log('Selected AIR ID:', value);
}

// Template
<app-dropdown-select-autocomplete
  [options]="airIdOptions()"
  [label]="'Air ID'"
  [selectId]="'airId-dropdown'"
  displayKey="value"
  valueKey="value"
  [disabled]="false"
  [required]="true"
  [(ngModel)]="selectedAirId"
  [ngModelOptions]="{standalone: true}"
  (selectionChange)="onSelectionChange($event)"
  data-cy="app-air-id-dropdown">
</app-dropdown-select-autocomplete>
```

### Extended Usage Pattern (Grid Filters)
```typescript
// Component TS
gridFilters: IDropdownModel = {
  detailList: savedFilters  // From API
};

onChangeSelection(filter: IFormDropdown) {
  this.applyFilter(filter.id);
}

onDeleteFilter(filters: {id: string, value: string}[]) {
  // Open confirmation modal
  // Call backend to delete filter(s)
  // Refresh filter list
}

// Template
<app-dropdown-select-extended
  [dropdownData]="gridFilters"
  [selectDisabled]="!gridFilters?.detailList?.length"
  (changeSelection$)="onChangeSelection($event)"
  (deleteFilter$)="onDeleteFilter($event)">
</app-dropdown-select-extended>
```

### Multi-Select Usage Pattern
```typescript
// Component TS
useCasesDropdown: IDropdownModel = {
  value: 'Use Cases',
  detailList: [
    {id: 'all', value: 'Select All', order: 0},
    {id: '1', value: 'Analytics', order: 1},
    {id: '2', value: 'Reporting', order: 2},
    {id: '3', value: 'Machine Learning', order: 3}
  ]
};

selectedUseCases: IDropdownDetail[] = [];

onUseCasesChange(selections: IFormDropdown[]) {
  console.log('Selected:', selections);
  // selections = [{id: '1', value: 'Analytics'}, {id: '3', value: 'Machine Learning'}]
}

// Template
<app-dropdown-multi-select
  [selectId]="'use-cases-dropdown'"
  [dropdownData]="useCasesDropdown"
  [selectDisabled]="false"
  [required]="true"
  formControlName="useCases"
  (changeSelection$)="onUseCasesChange($event)">
</app-dropdown-multi-select>

<!-- Badges will automatically display below dropdown -->
```

### Search Multi-Select Usage Pattern
```typescript
// Component TS
availableSchemas: IInputSearchDropdownMultiSelectData[] = [
  {id: 'schema1', value: 'customer_data'},
  {id: 'schema2', value: 'product_catalog'},
  {id: 'schema3', value: 'sales_transactions'},
  {id: 'schema4', value: 'marketing_campaigns'}
];

selectedSchemas: IInputSearchDropdownMultiSelectData[] = [];

ngOnInit() {
  // Pre-select some schemas
  this.selectedSchemas = [this.availableSchemas[0]];
}

// Template
<app-input-search-dropdown-multi-select
  [searchId]="'schemas-search'"
  [selectAllId]="'schemas-select-all'"
  [label]="'Database Schemas'"
  [options]="availableSchemas"
  [required]="true"
  [selectAllInput]="false"
  formControlName="schemas">
</app-input-search-dropdown-multi-select>

<!-- Component automatically shows:
  1. "Select All" checkbox above input
  2. Typeahead search input
  3. Badges below with remove buttons
-->
```

---

## 🔍 Decision Tree: Which Dropdown to Use?

```
Are you building a NEW feature?
├─ Yes → What type of selection?
│   │
│   ├─ **SINGLE-SELECT** required?
│   │   │
│   │   ├─ Need search/filter capability?
│   │   │   │
│   │   │   ├─ Yes → Large dataset (>20 options)?
│   │   │   │   └─ Use dropdown-select-autocomplete ✅
│   │   │   │       (Custom HTML with client-side filtering)
│   │   │   │
│   │   │   └─ No → Small dataset (<20 options)?
│   │   │       └─ Use dropdown-select-remaster ✅
│   │   │           (Simple NgbDropdown)
│   │   │
│   │   └─ No search needed?
│   │       └─ Use dropdown-select-remaster ✅
│   │           (Simple NgbDropdown)
│   │
│   └─ **MULTI-SELECT** required?
│       │
│       ├─ Need search/typeahead capability?
│       │   │
│       │   ├─ Yes → Large dataset (>50 options)?
│       │   │   └─ ⚠️ Use input-search-dropdown-multi-select (legacy/hybrid) 🟡
│       │   │       (NgbTypeahead with smart ranking)
│       │   │       └─ TODO: Build modern signals-based alternative
│       │   │
│       │   └─ No → Small/medium dataset?
│       │       └─ ⚠️ Use dropdown-multi-select (legacy) 🟡
│       │           (Bootstrap checkboxes)
│       │           └─ TODO: Build modern signals-based alternative
│       │
│       └─ No search needed?
│           └─ ⚠️ Use dropdown-multi-select (legacy) 🟡
│               (Bootstrap checkboxes)
│               └─ TODO: Build modern signals-based alternative
│
└─ No → Modifying EXISTING code?
    │
    ├─ Is it grid-filter-control?
    │   └─ Use dropdown-select-extended (leave as-is) 🟡
    │       (Has delete functionality)
    │
    ├─ Is it using multi-select?
    │   │
    │   ├─ With search/typeahead?
    │   │   └─ Use input-search-dropdown-multi-select (leave as-is) 🟡
    │   │       (Authview wizard, schemas/tables selector)
    │   │
    │   └─ Without search (checkboxes only)?
    │       └─ Use dropdown-multi-select (leave as-is) 🟡
    │           (Demand form, project forms, data security)
    │
    └─ Single-select dropdown?
        └─ Use dropdown-select (leave as-is) 🟡
            └─ DO NOT migrate without approval
```

**Quick Selection Guide:**

| Scenario | Recommended Component | Why? |
|----------|----------------------|------|
| New feature, single-select, <10 options | `dropdown-select-remaster` | Simple, fast selection |
| New feature, single-select, >20 options | `dropdown-select-autocomplete` | Search improves UX |
| New feature, single-select, searchable list | `dropdown-select-autocomplete` | Built-in filtering |
| New feature, single-select, async API data | `dropdown-select-autocomplete` + `rxResource` in parent/container | Project standard async pattern |
| **New feature, multi-select, no search** | ⚠️ `dropdown-multi-select` **(legacy)** | No modern alternative yet |
| **New feature, multi-select, with search** | ⚠️ `input-search-dropdown-multi-select` **(legacy/hybrid)** | NgbTypeahead, best available option |
| **New feature, multi-select, large lists** | ⚠️ `input-search-dropdown-multi-select` **(legacy/hybrid)** | Search essential for UX |
| Existing single-select component | Leave as-is (`dropdown-select`) | Avoid migration risk |
| Existing multi-select component | Leave as-is (`dropdown-multi-select`) | Avoid migration risk |
| Existing search multi-select | Leave as-is (`input-search-dropdown-multi-select`) | Authview wizard pattern |
| Grid saved filters | `dropdown-select-extended` | Delete functionality |
| Status badges needed | `dropdown-select` (Original) | Has badge mode |

**🚨 CRITICAL GAP IDENTIFIED:**
- ❌ NO modern (signals-based, standalone) multi-select component exists
- ❌ All multi-select needs require using legacy components
- ✅ **PRIORITY**: Build modern multi-select as next component (see Future Improvements)

---

## 📝 Future Improvements

### 🔴 HIGHEST PRIORITY: Modern Multi-Select Component

**Critical Gap:** No modern (signals-based, standalone) multi-select component exists.

**Proposed: `dropdown-multi-select-modern` component**

**Requirements:**
- [ ] **Signals-based reactivity** - All inputs as signals, computed for derived state
- [ ] **Standalone component** - No module dependencies
- [ ] **Generic typing** - `DropdownMultiSelectModernComponent<T>`
- [ ] **Flexible data model** - Accept generic `T[]` arrays (not IDropdownModel)
- [ ] **ControlValueAccessor** - Standard form integration
- [ ] **Optional Validator** - Configurable validation interface
- [ ] **Checkbox UI** - Multi-select with visual feedback
- [ ] **Select All** - Toggle all items at once
- [ ] **Badge display** - Show selected items with remove buttons
- [ ] **Search capability** - Optional built-in filtering (like autocomplete)
- [ ] **Keyboard navigation** - Arrow keys, Enter, Space for selection
- [ ] **Configurable keys** - `displayKey` / `valueKey` like remaster
- [ ] **Output flexibility** - Emit raw values OR full objects (configurable)
- [ ] **Loading states** - Support for async data loading
- [ ] **Virtual scrolling** - For very large datasets (1000s of items)
- [ ] **Custom templates** - Optional item templates (avatars, icons, etc.)

**Estimated effort:** 40-60 hours (new component from scratch)

**Benefits:**
- ✅ Unifies `dropdown-multi-select` + `input-search-dropdown-multi-select` functionality
- ✅ Modern Angular 18+ patterns (signals, standalone)
- ✅ Better performance with computed signals
- ✅ Easier testing and maintenance
- ✅ Consistent API with remaster/autocomplete components
- ✅ Optional search instead of two separate components

**Migration path:** Once built, gradual migration from legacy multi-select components (15+ usages total).

---

### For Autocomplete (Enhancements)
- [ ] Add `rxResource`-friendly async data loading guidance
- [ ] Add loading/error states for API calls (currently has spinner support but no error UI)
- [ ] Add server-side filtering option (pass search term to API)
- [ ] Add debouncing/throttling for large datasets (currently filters on every keystroke)
- [ ] Add "create new option" feature for flexible input
- [ ] Add custom option templates (avatars, icons, etc.)
- [ ] Add keyboard navigation improvements (Ctrl+N/P for next/prev)
- [ ] Add infinite scroll for very large datasets

### For Remaster (To Achieve Parity)
- [ ] Add `Validator` interface implementation
- [ ] Add error styling support (like `hasErrors` in original)
- [ ] Add optional `pretty` (badge) mode
- [ ] Add `useStatusDisplayMapping` support
- [ ] Add `deleteItem` output for filter use cases
- [ ] Add `deleteAll` capability

### For Extended (If Keeping Long-Term)
- [ ] Extract delete logic to composition instead of inheritance
- [ ] Add tests for delete functionality
- [ ] Document modal confirmation pattern

### General
- [ ] Create `IDropdownModel` → generic array adapter utility
- [ ] Create `IFormDropdown` transformer for remaster output
- [ ] Create `IInputSearchDropdownMultiSelectData` → generic array adapter
- [ ] Update form builders to handle multiple payload types (single value, IFormDropdown, arrays)
- [ ] Establish deprecation timeline for legacy components (once modern multi-select exists)
- [ ] Add debouncing utility for search components (shared across autocomplete and multi-select)

---

## 🆘 Common Issues

### Multi-Select Issues

**"Multi-select not emitting changes"**
- Check if using CVA `onChange` (emits IDs array) vs `changeSelection$` (emits full objects)
- Parent components should typically use `(changeSelection$)="handler($event)"`
- CVA pattern: Component emits to form control, `changeSelection$` emits to parent

**"Select All not working"**
- Ensure data has option with `id: 'all'` in detailList/options array
- For `dropdown-multi-select`: `{id: 'all', value: 'Select All', order: 0}`
- For `input-search-dropdown-multi-select`: Use `selectAllInput` signal instead

**"Badges not showing selected items"**
- `dropdown-multi-select`: Check `selectedOptions` array in component state
- `input-search-dropdown-multi-select`: Badges auto-display from `selectedOptions`
- Verify `value` property exists on each selected item

**"Can't remove selected items from badges"**
- `dropdown-multi-select`: No remove buttons (by design) - reopen dropdown to deselect
- `input-search-dropdown-multi-select`: Has remove buttons - click × icon on badge
- Workaround for multi-select: Consider adding remove functionality (future enhancement)

**"Typeahead not showing results"**
- Only applies to `input-search-dropdown-multi-select` (NgbTypeahead)
- Check `options` array is populated
- Verify `resultFormatter` and `inputFormatter` functions
- Already-selected items are hidden from dropdown (by design)

**"Search ranking not working as expected"**
- `input-search-dropdown-multi-select` uses 2-tier ranking:
  1. Options that START WITH search term (shown first)
  2. Options that CONTAIN search term (shown second)
- Case-insensitive matching

**"Validator error: 'requiredd' instead of 'required'"**
- Known typo in `input-search-dropdown-multi-select` validator
- Returns `{ requiredd: true }` instead of `{ required: true }`
- Form still validates correctly, but error key name is misspelled
- Workaround: Check for `errors?.requiredd` in parent component

---

### Single-Select Issues

**"Autocomplete not filtering properly"**
- Check that `displayKey` matches the property you want to search on
- Ensure `internalValue` signal is updating (check with `console.log`)
- Verify `filteredOptions()` computed is being called (add logging)
- Remember: filtering is case-insensitive and matches anywhere in text
- NO debouncing - filters on every keystroke

**"Autocomplete shows 'Type at least 2 characters'" / "No results found"**
- ⚠️ **CORRECTION**: The autocomplete component does NOT enforce 2-character minimum in code
- Empty state messages controlled by template logic checking `internalValue().trim()`
- To customize: Modify template conditions in component HTML

**"Autocomplete not showing selected value on load"**
- Use `writeValue()` via `[(ngModel)]` or form control
- Ensure the value passed matches an option's `valueKey`
- Check that `options()` signal is populated BEFORE `writeValue` is called
- Example: `ngOnInit() { this.selectedValue = 'id-123'; }`

**"Autocomplete uses Material Design (conflicts with Bootstrap)"**
- ⚠️ **CORRECTION**: The component does NOT use Material Autocomplete
- Uses custom HTML: `<input>` + `<ul class="autocomplete-dropdown">`
- Styling is custom CSS, not Material or Bootstrap
- Easy to customize via component SCSS file

**"Dropdown shows empty even with data"**
- **Original/Multi-Select**: Check `dropdownData.detailList` is populated
- **Remaster/Autocomplete**: Check `options()` signal has values
- **Search Multi-Select**: Check `options` array prop has values
- **All**: Verify `selectedValue` matches an option's ID/valueKey

**"Form validation not working"**
- **Original, Extended, Search Multi-Select**: Use `Validator` interface - works automatically
- **Remaster, Autocomplete, Multi-Select**: Do NOT implement `Validator` - add validators to FormControl:
  ```typescript
  myControl = new FormControl('', [Validators.required]);
  ```

**"Change event not firing"**
- **Original/Extended/Multi-Select**: Use `(changeSelection$)` output
- **Remaster/Autocomplete**: Use `(selectionChange)` output
- **Search Multi-Select**: Uses CVA only (no custom output)
- **All**: Verify event handler is defined

**"Extended component inheritance error"**
- Extended MUST extend `dropdown-select` (original)
- Cannot extend remaster (different API)
- If migrating, must rewrite extended as separate component

**"TypeScript error: Property 'detailList' does not exist"**
- You're passing array to original/extended/multi-select component
- These expect: `{detailList: IDropdownDetail[]}`
- Wrap your array: `{detailList: yourArray}`
- OR use modern components (remaster/autocomplete) which accept plain arrays

**"How do I add async API data to autocomplete component?"**
- Prefer parent/container-managed `rxResource` and pass resolved `options` into the component
- Key steps:
  1. Add `rxResource()` in the parent/container with API URL
  2. Use `computed()` to extract `resource.value()` as options
  3. Add loading/error states in template
  4. Pass search term as query param
- Component already has `isLoading` input for spinner support
- Example in documentation's future improvements section

---

**Last Verified:** 2026-02-03 | **By:** AI Deep Review + Code Verification

**Changelog:**
- 2026-02-03: Complete documentation overhaul - added 2 missing components (multi-select variants)
- 2026-02-03: Corrected critical errors (autocomplete NOT Material, input name fixes)
- 2026-02-03: Enhanced with 6-component matrix, multi-select decision trees, code examples
- 2026-02-03: Identified priority gap: need modern signals-based multi-select component
- 2026-01-28: Initial documentation (4 components only)
