---
name: jasmine-test-standard
description: Standardized recipes for creating, auditing, and reordering Jasmine/Karma unit tests. Ensures clean setup, teardown, and prevents cross-suite contamination.
triggers: [creating unit test, writing jasmine test, fixing flaky test, angular testbed setup, auditing tests against standard, refactoring test structure, reordering spec file]
last_updated: 2024-05-11
tags: [jasmine, karma, testing, standard, audit, refactor]
---

# Jasmine Test Standardization

This skill provides a concrete recipe for creating, auditing, and reordering unit tests (Jasmine/Karma) in this repository. It enforces patterns that prevent "flaky" tests and ensure proper resource cleanup.

## 🎯 When to Invoke This Skill

Invoke this skill when:
- **Creating**: Building new `.spec.ts` files from scratch.
- **Auditing**: Reviewing existing tests to identify deviations from the repository standard.
- **Reordering/Refactoring**: Normalizing a spec's structure (imports, setup, teardown) to match the "Golden Template" without changing the test's functional intent.

> **MANDATORY**: All spec files MUST begin with the following directive at line 1 to ensure correct type resolution:
> `/// <reference types="jasmine" />`

## 🏗️ Structural Normalization (Reordering)

When "reordering" a spec to match the standard, ensure the following sequence:

1.  **Reference Directive**: `/// <reference types="jasmine" />` must be the very first line.
2.  **Imports**: Grouped by (Angular/Library, Project Components/Services, Mocks).
3.  **Variable Declarations**: Typed declarations for `component`, `fixture`, `mockStore`, and services.
4.  **beforeEach (Async)**: `TestBed.resetTestingModule()`, configuration, and initialization.
5.  **afterEach**: Cleanup logic (resetting selectors, destroying fixtures).
6.  **Tests**: Organized in `describe` blocks mirroring the component's internal logic.

## 🚀 The "Golden Template" (Full Component Spec)

Use this pattern for components that require DOM assertions or `fixture` interactions.

```typescript
/// <reference types="jasmine" />
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { HttpClientTestingModule } from '@angular/common/http/testing';
import { provideMockStore, MockStore } from '@ngrx/store/testing';
import { MyComponent } from './my.component';

describe('MyComponent', () => {
    let component: MyComponent;
    let fixture: ComponentFixture<MyComponent>;
    let mockStore: MockStore;

    beforeEach(async () => {
        // 1. ALWAYS reset at the top of beforeEach
        TestBed.resetTestingModule();

        await TestBed.configureTestingModule({
            imports: [
                MyComponent, 
                HttpClientTestingModule
            ],
            providers: [
                provideMockStore({ initialState: {} }),
                // Add dependencies here
            ]
        }).compileComponents();

        mockStore = TestBed.inject(MockStore);
        
        // 2. Create fixture but DO NOT detectChanges yet if you need to mock ViewChild
        fixture = TestBed.createComponent(MyComponent);
        component = fixture.componentInstance;
    });

    afterEach(() => {
        // 3. CLEANUP: Reset selectors and destroy fixture
        mockStore?.resetSelectors();
        fixture?.destroy(); 
    });

    it('should create', () => {
        fixture.detectChanges();
        expect(component).toBeTruthy();
    });
});
```

## 🧠 Logic-Only Spec (High Stability)

Use this for complex components where you only test class logic (getters, methods, dispatches) and want to avoid `ɵcmp` errors or template complexity.

```typescript
describe('MyComponent (Logic-Only)', () => {
    let component: MyComponent;
    let mockStore: MockStore;

    beforeEach(() => {
        TestBed.resetTestingModule();

        TestBed.configureTestingModule({
            providers: [
                provideMockStore(),
                // ... other mocked services
            ]
        });

        mockStore = TestBed.inject(MockStore);
        
        // Use runInInjectionContext to handle inject() calls inside the constructor
        component = TestBed.runInInjectionContext(() => new MyComponent());
    });

    afterEach(() => {
        // IMPORTANT: Manually trigger destroy if component has subscriptions/timers
        component?.ngOnDestroy?.(); 
        mockStore?.resetSelectors();
    });

    it('should calculate derived value', () => {
        component.someMethod();
        expect(component.someValue()).toBe(true);
    });
});
```

## 🚿 Teardown Expectations

To maintain suite health and prevent "Memory Leak" or "Cross-Suite" contamination, every `afterEach` (or `afterAll` if applicable) must explicitly:
1.  **Reset Selectors**: Call `mockStore.resetSelectors()` if NgRx Mock Store is used.
2.  **Destroy Components**: Call `fixture.destroy()` to trigger `ngOnDestroy`.
3.  **Clear Timers/Subscriptions**: If the component or service uses `setTimeout` or `setInterval`, ensure they are cleared.
4.  **Disconnect Observables**: Ensure any manual subscriptions or testing observers are disconnected.

## 📝 Usage Example: Auditing

When asked to "audit" a test, read the target `.spec.ts` file and compare it against the sections above. Identify:
- Missing `/// <reference types="jasmine" />`.
- Missing `TestBed.resetTestingModule()` in `beforeEach`.
- Lack of explicit cleanup in `afterEach`.
- Incorrect import ordering.

## 📝 Usage Example: Reordering

When asked to "reorder" or "normalize" a spec, move blocks of code to match the structural sequence defined in the **Structural Normalization** section above. Do not alter `it` block logic unless an error is identified during the audit phase.

## 🛠️ Mandatory Conventions

### 1. TestBed Reset
Always call `TestBed.resetTestingModule()` as the **first line** of `beforeEach`. Never rely on `afterEach` for resetting the module, as a failure in `it` can skip `afterEach` and leak state to the next suite.

### 2. Async/Await & Compilation
*   Use `beforeEach(async () => { ... })`.
*   Always `await` `TestBed.configureTestingModule(...).compileComponents()`.
*   For `rxResource` or `effect` testing, use `TestBed.flushEffects()` if timing issues occur.

### 3. Cleanup Pattern (The "Teardown Order")
Improper teardown is the #1 cause of `afterAll` errors and Chrome disconnects. Follow this order in `afterEach`:
1.  `fixture.destroy()` or `component.ngOnDestroy()` (Stops subscriptions).
2.  `mockStore.resetSelectors()`.
3.  `jasmine.getEnv().allowRespy(false)` (if used).

### 4. ViewChild Mocking
If your component uses `@ViewChild`, assign the mock **before** the first `fixture.detectChanges()`.

```typescript
fixture = TestBed.createComponent(MyComponent);
component = fixture.componentInstance;

// Mock ViewChild
component.myModal = { open: jasmine.createSpy('open') } as any;

fixture.detectChanges(); // Now lifecycle hooks like ngOnInit run safely
```

### 5. `inject()` vs `TestBed.inject()`
*   Use `TestBed.inject(Service)` to get instances in your test.
*   If the component uses the `inject(Service)` function, you must use `TestBed.overrideProvider(Service, { useValue: spy })` if you need to swap it after `configureTestingModule`.

### 6. Correct Type Resolution
Always include `/// <reference types="jasmine" />` at the very first line of any new spec file to ensure the TypeScript compiler correctly identifies Jasmine global functions (like `describe`, `it`, `expect`).

## 🆘 Troubleshooting
If you see `TypeError: Cannot read properties of undefined (reading 'ɵcmp')`, it means the standalone import graph is broken or leaking. 
→ **Action**: Switch the spec to the **Logic-Only** pattern.