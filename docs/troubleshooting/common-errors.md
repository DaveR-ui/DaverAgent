---
last_updated: 2026-04-23
description: quick reference for recurring Angular runtime and test errors with root cause and fixes
tags: [errors, troubleshooting, angular, signals, linksignal, ng0103, ng0600, ngmodule, ɵcmp]
---

# Common Errors & Solutions

## [NG0103] Input/Signal Modification During Template Execution
- **Issue**: Modifying a signal value inside a `computed()` or template.
- **Solution**: Use `linkedSignal()` or ensure data flows in one direction.

## [NG0600] Circular Dependency
- **Issue**: Cyclic imports between services/components.
- **Solution**: Decouple logic into Injection Tokens or shared utility files.

## [NG0506] Resource in Error State
- **Context**: Accessing `.value()` of a resource that failed (`rxResource` or legacy `httpResource`).
- **Fix**: Check `resource.status() === 'resolved'` before accessing `.value()`.

## [NG01353] ngModelGroup Error
- **Context**: Missing `ControlContainer` in component for `ngModelGroup`.
- **Fix**: Provide `ControlContainer` in `providers: [viewParentControlContainerProvider]`.

## [TypeError] Cannot read properties of undefined (reading 'ɵcmp')
- **Context**: Runtime error in browser console or unit tests.
- **Root cause**: A module/component declaration is duplicated through module imports (for example, importing two modules that both declare the same component).
- **Fix**: Verify module declarations and imports to ensure each declared component belongs to one module only, and avoid importing overlapping declaration modules together (common case: `SharedModule` + `CoreModule` declaring the same component).
- **TestBed-specific root cause**: When `TestBed.resetTestingModule()` is called AFTER another spec's `afterEach`, the TestBed can be left in an inconsistent state where component metadata (`ɵcmp`) is partially cleared. This causes `ɵcmp` errors in subsequent specs that try to configure TestingModule.
- **TestBed-specific fix**:
  1. Call `TestBed.resetTestingModule()` at the **BEGINNING** of `beforeEach`, not the end of `afterEach`.
  2. Use `TestBed.overrideProvider()` for providers created with `inject()`, not `useValue` in `providers[]` array.
  3. If the spec only validates class logic and `ɵcmp` still happens during `configureTestingModule()`, stop compiling the component and instantiate it with `TestBed.runInInjectionContext(() => new TargetComponent())` after configuring only the required providers.
- **Reference**: `troubleshooting/testbed-cross-suite-flaky-tests.md`

## [TypeError] Cannot read properties of undefined (reading 'ngModule')
- **Context**: Jasmine/Karma specs fail only when run together, but pass individually.
- **Root cause 1**: TestBed scope contamination and transitive template/module compilation interactions across suites.
- **Fix 1**: Isolate class-behavior tests with `overrideComponent(... template: '', imports: [])`, await `compileComponents()`, and apply `TestBed.resetTestingModule()` in affected specs. If compilation itself is still the failing step and the spec does not assert DOM, switch to a provider-only TestBed plus `runInInjectionContext()`.
- **Root cause 2**: Circular dependency between modules (e.g., CoreModule ↔ ProjectDetailsPageComponent) causing module metadata corruption during initialization.
- **Fix 2**: Extract shared interfaces to domain files, import enums directly from source, eliminate circular import chains.
- **References**: 
  - `troubleshooting/testbed-cross-suite-flaky-tests.md`
  - `troubleshooting/circular-dependency-core-module.md` (NEW - 2026-05-30)

## [Error] Cannot find control with name: '...'
- **Context**: Angular Reactive Forms tests (`FormGroup` / `FormControlName`).
- **Root cause**: The form is initialized asycnchronously (e.g., inside an `Observable.subscribe` in `ngOnInit`) but the test's `fixture.detectChanges()` triggers the template rendering before the form exists.
- **Fix**: Manually call the form initialization method (e.g., `component.initFormGroup()`) in the test's `beforeEach` block **before** `fixture.detectChanges()`.
- **Example**:
  ```typescript
  beforeEach(() => {
    fixture = TestBed.createComponent(MyComponent);
    component = fixture.componentInstance;
    component.initFormGroup(); // Force sync init before template binding
    fixture.detectChanges();
  });
  ```

## Recurring Login Redirections / Redirect Loops
- **Context**: App keeps redirecting to login even after successful sign-in.
- **Root Cause**: Race condition between MSAL status and account hydration in `RebarAuthService`.
- **Reference**: [Auth Flow & Race Conditions](auth-relogin-race-condition.md)
