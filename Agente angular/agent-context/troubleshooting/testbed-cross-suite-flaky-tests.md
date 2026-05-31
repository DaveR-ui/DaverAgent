---
last_updated: 2026-04-23
description: diagnose and fix Jasmine/Karma flaky failures that appear only in combined runs with ngModule, ɵcmp, afterAll, or browser disconnect errors
tags: [testing, jasmine, karma, testbed, flaky-tests, ngmodule, ɵcmp, afterAll, disconnected]
---

# TestBed Cross-Suite Flaky Errors (ngModule / ɵcmp)

## Path & Overview
- **Observed in**:
  - `src/app/core/grid/cell-renderers/authview-cell-render/actions-button-cell-render.component.spec.ts`
  - `src/app/core/components/admin-resources-list-grid/admin-resources-list-grid.component.spec.ts`
  - `src/app/core/components/demand-workflow-new/settings-stage-status/settings-stage-status.component.spec.ts`
  - `src/app/core/containers/modal-wrapper/modal-wrapper.component.spec.ts` (inject() override pattern)
  - `src/app/core/grid/cell-renderers/admin-resources-cell-render/admin-resources-cell-render.component.spec.ts` (ViewChild modal mocking pattern)
  - `src/app/core/components/documentation-list/documentation-list.component.spec.ts` (logic-only provider setup)
  - `src/app/core/components/cloud-resources/cloud-resources.component.spec.ts` (logic-only provider setup + `ngOnDestroy()` cleanup)
  - `src/app/core/pages/project-details-page/project-details-page.component.spec.ts` (provider-only teardown order for `@UntilDestroy()` subscriptions)
  - `src/app/core/components/step-form/step-form.component.spec.ts` (logic-only provider setup to avoid unnecessary template/runtime load)
- **Symptom**:
  - The same specs can pass in isolation but fail in a combined run.
  - First failing test can move between suites.
- **Typical errors**:

```text
TypeError: Cannot read properties of undefined (reading 'ngModule')
TypeError: Cannot read properties of undefined (reading 'ɵcmp')
```

```text
Error: Spy 'select' received a call with arguments [ Function ] but all configured strategies specify other arguments.
```

```text
Chrome ... ERROR
  An error was thrown in afterAll
TypeError: Cannot read properties of undefined (reading 'msg')

Chrome ... DISCONNECTED (no message in 30000 ms)
```

## Data Flow
- Karma runs all included specs in a shared browser runtime.
- Angular TestBed compiles metadata and template scopes lazily.
- Large transitive template/module imports can leak setup complexity across suites.
- Combined execution increases the chance of declaration/scope timing conflicts.

## Fast Triage

| If you observe... | Then suspect... | First fix to try |
|---|---|---|
| Spec passes alone but fails when grouped with unrelated specs | Cross-suite TestBed contamination | `TestBed.resetTestingModule()` as first line of `beforeEach`, never in `afterEach` |
| `ɵcmp` or `ngModule` is thrown from `configureTestingModule()` | Broken standalone import graph or partially cleared metadata | Empty-template isolation with `overrideComponent(..., { set: { template: '', imports: [] } })` |
| `ɵcmp` still happens after empty-template isolation and the spec does not assert DOM | The spec does not need compilation at all | Switch to provider-only TestBed + `TestBed.runInInjectionContext(() => new Component())` |
| A ViewChild modal is undefined | Lifecycle ordering bug in the spec | Assign modal doubles before `fixture.detectChanges()` |
| `Spy 'select' received a call with arguments [ Function ]...` | Missing selector coverage | Add all selectors touched by `ngOnInit()` / child tree |
| JUnit shows `errors="1"` and `failures="0"`, runner reports `afterAll`, then Chrome disconnects | A provider-only spec left subscriptions alive while selector cleanup ran | Destroy the component before `mockStore.resetSelectors()` in `afterEach` |

## When to Use Logic-Only Specs
- Use the logic-only pattern when the spec only checks class behavior: getters, dispatches, emitted outputs, method calls, subscription side effects, or simple derived state.
- Do **not** use it when the test asserts rendered HTML, queries DOM nodes, depends on Angular binding timing, or needs `fixture.whenStable()`.
- Strong signal to switch: `ɵcmp` keeps failing inside `configureTestingModule()` even after `resetTestingModule()` and `overrideComponent(... template: '', imports: [])`.

## Root Causes & Solutions

### Root Cause 1: TestBed State Leakage
When one spec calls `TestBed.resetTestingModule()` in its `afterEach`, it can corrupt the TestBed state for the next spec. The TestBed may be left with partially cleared component metadata, causing `ɵcmp` errors.

**Solution**: Call `TestBed.resetTestingModule()` at the **BEGINNING** of `beforeEach`, not the end of `afterEach`.

```typescript
beforeEach(async () => {
  TestBed.resetTestingModule(); // ← DO THIS (first line of beforeEach)
  // ... rest of setup
});
```

### Root Cause 2: inject() Not Mocked with overrideProvider
When a component uses `inject()` (e.g., `modalService = inject(NgbModal)`), providing the mock via `providers: [{ provide: NgbModal, useValue: mockModal }]` does NOT override the `inject()` call. The component gets the real service.

**Solution**: Use `TestBed.overrideProvider()` AFTER `configureTestingModule()` but BEFORE `compileComponents()`.

```typescript
await TestBed.configureTestingModule({
  imports: [ModalWrapperComponent, HttpClientTestingModule],
  providers: [
    CopyResourceService,
    { provide: AppConfigService, useValue: appConfigSpy },
    { provide: Store, useValue: storeSpy }
  ]
});

TestBed.overrideProvider(NgbModal, { useValue: mockNgbModal }); // ← AFTER configureTestingModule, BEFORE compileComponents

await TestBed.compileComponents();
```

### Root Cause 3: ViewChild Modals Undefined After TestBed Reset
Components that use `@ViewChild` for modal references (e.g., `@ViewChild('copyResourceFormModal') public copyResourceFormModal!: ModalWrapperComponent`) have those properties undefined until `fixture.detectChanges()` runs. Tests that try to spy on these properties before they're set will fail.

**Solution**: Mock the ViewChild properties BEFORE `fixture.detectChanges()`, not after.

```typescript
fixture = TestBed.createComponent(AdminResourcesCellRenderComponent);
component = fixture.componentInstance;

// Set mocks BEFORE detectChanges
component.copyResourceFormModal = {
  open: jasmine.createSpy('open'),
  dismissAll: jasmine.createSpy('dismissAll')
} as any;

component.deleteSubscriptionModal = {
  open: jasmine.createSpy('open'),
  dismissAll: jasmine.createSpy('dismissAll')
} as any;

// NOW call detectChanges
fixture.detectChanges();
```

### Root Cause 4: NgRx MockStore Selector Residue
When using `@ngrx/store/testing` (`provideMockStore()`), values set via `mockStore.overrideSelector()` or `mockStore.setState()` can persist between tests or even between different spec suites if the browser context isn't fully cleared. This leads to tests receiving data from a previous test suite.

**Solution**: Use `mockStore.resetSelectors()` in an `afterEach` block to ensure all overridden selectors are cleared.

```typescript
let mockStore: MockStore;

afterEach(() => {
  mockStore?.resetSelectors();
});
```

### Root Cause 5: Shared State in Global Spec Variables
Variables defined at the top level of a `.spec.ts` file (outside `describe`) or shared inside `describe` but not properly reset in `beforeEach` (especially `Subjects` and `LDFlagSet`) will maintain their state (subscribers, values) across all `it` blocks.

**Solution**: Initialize ALL shared variables inside `beforeEach` and ensure `Subjects` are fresh instances.

```typescript
describe('MyComponent', () => {
  let activatedRouteSubject: Subject<any>; // Declare here
  let LDState: LDFlagSet;

  beforeEach(() => {
    activatedRouteSubject = new Subject<any>(); // Initialize here
    LDState = { flags: {} };
  });
});
```

### Root Cause 6: Underspecified Store Spies in Child Components
When testing a parent component that hosts child components requiring specific Store selects (e.g., `selectAirInfo`), the `spyOn(mockStore, 'select').withArgs(...)` must include all possible arguments the component tree might call. If a child component calls a selector not configured in the spy, the test fails with:
`Error: Spy 'select' received a call with arguments [ Function ] but all configured strategies specify other arguments.`

**Solution**: Ensure `withArgs` covers all selectors called during the `fixture.detectChanges()` lifecycle.

```typescript
spyOn(mockStore, 'select')
  .withArgs(selectA)
  .and.returnValue(of(valA))
  .withArgs(selectB) // Required by ChildComponent
  .and.returnValue(of(valB));
```

### Root Cause 7: Logic-Only Spec Still Compiles a Broken Standalone Import Graph
Some specs exercise only component class behavior, but still call `TestBed.configureTestingModule({ imports: [TargetComponent] })` and `TestBed.createComponent(TargetComponent)`. If `TargetComponent` has a large standalone `imports` graph, combined runs can still fail with `ɵcmp` during compilation even after template override and proper reset ordering.

**Solution**: Skip component compilation entirely. Configure only the providers you need, instantiate with `TestBed.runInInjectionContext(() => new TargetComponent())`, call `ngOnInit()` manually when needed, and call `ngOnDestroy()` in `afterEach` for components that register subscriptions/timers.

```typescript
beforeEach(async () => {
  TestBed.resetTestingModule();

  await TestBed.configureTestingModule({
    providers: [
      provideMockStore(),
      { provide: Router, useValue: routerSpy }
    ]
  });

  mockStore = TestBed.inject(MockStore);
  mockStore.overrideSelector(selectA, valueA as any);
  mockStore.overrideSelector(selectB, valueB as any);

  component = TestBed.runInInjectionContext(() => new TargetComponent());
});

afterEach(() => {
  component?.ngOnDestroy?.();
  mockStore?.resetSelectors();
});
```

**Observed good fits**:
- `DocumentationListComponent`: getters, store-driven side effects, modal method calls, no DOM assertions.
- `CloudResourcesComponent`: getters, store dispatches, `ngOnInit()`/`ngOnDestroy()` logic, no DOM assertions.
- `StepFormComponent`: form logic, dispatches, emitted outputs, and validation checks that do not need template rendering.

### Root Cause 8: Provider-Only Spec Resets Selectors Before Destroying `@UntilDestroy()` Subscriptions
Provider-only specs often call `component.ngOnInit()` manually. If the component uses `@UntilDestroy()` or long-lived store subscriptions, those subscriptions remain active until the component is destroyed. If `mockStore.resetSelectors()` runs first in `afterEach`, the live subscription can receive an incomplete selector shape during teardown and crash in `afterAll`. In combined runs this often surfaces as a late browser disconnect, even though individual test cases already passed.

**Solution**: In provider-only specs, always destroy the component before resetting selectors.

```typescript
afterEach(() => {
  component?.ngOnDestroy?.();
  mockStore?.resetSelectors();
});
```

**Observed good fit**:
- `ProjectDetailsPageComponent`: `selectDocumentation` remained subscribed after each test; resetting selectors before teardown produced `TypeError: Cannot read properties of undefined (reading 'msg')` in `afterAll` and then Chrome disconnected.

## Known Anti-Patterns (AVOID)

| Anti-Pattern | Why It Fails in Combined Runs |
|---|---|
| `TestBed.resetTestingModule()` in `afterEach` | Leaves TestBed in inconsistent state for next spec |
| `providers: [{ provide: SomeService, useValue: mock }]` for `inject()`-based services | Does not override `inject()` calls; service still real |
| `spyOn(component.modal, 'open')` after `fixture.detectChanges()` | Modal is `undefined` until ViewChild resolution; spy fails |
| Compiling a standalone component for class-only tests | Forces Angular to resolve an unnecessary import graph and can re-trigger `ɵcmp` conflicts |
| Importing full feature/module graphs for class-only unit behavior | Pulls unrelated declarations/providers and increases `ngModule/ɵcmp` risk |
| Calling `mockStore.resetSelectors()` before `component.ngOnDestroy()` in provider-only specs | Live subscriptions receive torn-down selector values and can explode in `afterAll` |
| Not awaiting `compileComponents()` | Leaves template compilation timing nondeterministic |
| Re-spying already spied methods (`spyOn` twice) | Produces additional non-deterministic setup errors |

## Standard Pattern (USE)

### Basic Isolation Pattern
```typescript
beforeEach(async () => {
  TestBed.resetTestingModule(); // Reset FIRST to clear residual state from previous suite

  await TestBed.configureTestingModule({
    imports: [TargetComponent],
    providers: [provideMockStore()],
  }).compileComponents();

  fixture = TestBed.createComponent(TargetComponent);
  component = fixture.componentInstance;
});

afterEach(() => {
  fixture?.destroy();
  // Do NOT call resetTestingModule here - it breaks the next spec
});
```

### inject() Provider Override Pattern
When the component uses `inject()` for dependencies (e.g., `modalService = inject(NgbModal)`), `useValue` in `providers[]` does NOT work. Must use `overrideProvider`:

```typescript
beforeEach(async () => {
  TestBed.resetTestingModule();

  const mockModal = jasmine.createSpyObj('NgbModal', ['open', 'dismissAll']);

  await TestBed.configureTestingModule({
    imports: [MyComponent],
    providers: [
      { provide: SomeService, useValue: mockService } // Works for constructor-based DI
    ]
  });

  TestBed.overrideProvider(NgbModal, { useValue: mockModal }); // ← MUST use this for inject() DI

  await TestBed.compileComponents();

  fixture = TestBed.createComponent(MyComponent);
  component = fixture.componentInstance;
});
```

### ViewChild Modal Mocking Pattern
When component has `@ViewChild` modal references, mock them BEFORE `detectChanges()`:

```typescript
beforeEach(async () => {
  TestBed.resetTestingModule();

  await TestBed.configureTestingModule({
    imports: [CellRenderComponent],
    providers: [provideMockStore()]
  }).compileComponents();

  fixture = TestBed.createComponent(CellRenderComponent);
  component = fixture.componentInstance;

  // Mock ViewChild modals BEFORE detectChanges
  component.copyResourceFormModal = {
    open: jasmine.createSpy('open'),
    dismissAll: jasmine.createSpy('dismissAll')
  } as any;

  component.deleteSubscriptionModal = {
    open: jasmine.createSpy('open'),
    dismissAll: jasmine.createSpy('dismissAll')
  } as any;

  fixture.detectChanges();
});
```

### Logic-Only Isolation Pattern
When HTML rendering is irrelevant and compilation itself is the failure point, avoid `imports: [TargetComponent]` entirely:

```typescript
beforeEach(async () => {
  TestBed.resetTestingModule();

  await TestBed.configureTestingModule({
    providers: [provideMockStore({ initialState })]
  });

  mockStore = TestBed.inject(MockStore);
  mockStore.overrideSelector(selectLaunchdarklyFlags as any, { flags: {} });
  mockStore.overrideSelector(selectProjectDocuments as any, { data: null, loading: false, loaded: false, error: '' });

  component = TestBed.runInInjectionContext(() => new DocumentationListComponent());
});

afterEach(() => {
  component?.ngOnDestroy?.();
  mockStore?.resetSelectors();
});
```

- Call `component.ngOnInit()` explicitly inside tests that verify lifecycle behavior.
- Call `component.ngOnDestroy()` in cleanup before selector reset if the component uses `untilDestroyed`, timers, or manual subscriptions.
- Keep this pattern limited to specs that do not touch template rendering.

- Keep tests behavior-focused and isolate from view dependency graphs when HTML rendering is not under test.
- Stub modal/view-child dependencies directly in the spec when only dispatch/logic behavior is asserted.
- If a known first-run compile race persists, use a short guarded setup retry as temporary stabilization.

## Reproduction Command

### Batch Execution Strategy
- Prefer `npm run test:headless` for deterministic runs (`--watch=false`, `ChromeHeadless`).
- Angular's Karma builder treats `include` as an array option, so pass repeated `--include=...` flags rather than a single comma-separated string.
- When the browser gets unstable with too many affected suites loaded together, validate in batches of 3 first, then rerun the full affected set.

```bash
npm run test:headless -- \
  --include=src/app/spec-a.spec.ts \
  --include=src/app/spec-b.spec.ts \
  --include=src/app/spec-c.spec.ts \
  --progress=false
```

```bash
npm run test:headless -- \
  --include=src/app/core/grid/cell-renderers/authview-cell-render/actions-button-cell-render.component.spec.ts \
  --include=src/app/core/components/admin-resources-list-grid/admin-resources-list-grid.component.spec.ts \
  --include=src/app/core/components/demand-workflow-new/settings-stage-status/settings-stage-status.component.spec.ts \
  --progress=false
```

## Verification Criteria
- Each target suite passes alone.
- Small batches (for example, groups of 3) pass together in one run.
- The final grouped run of all affected suites also passes.
- Final output includes:

```text
TOTAL: ... SUCCESS
```

> [!CAUTION]
> Use `TestBed.resetTestingModule()` only when there is evidence of cross-suite contamination.
> Keep it close to affected specs to avoid unnecessary global test slowdown.
