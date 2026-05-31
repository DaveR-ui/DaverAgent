---
last_updated: 2026-04-14
tags: [angular, testing, rxResource, fakeAsync, jasmine, httpResource]
---

# Testing rxResource

> Part of [angular-reactivity/](index.md) · See also [resource-api.md](resource-api.md)

> **Project standard:** new data-loading flows should use `rxResource`. `httpResource` guidance in this file is retained only for maintaining existing legacy implementations.

---

## CRITICAL: Jasmine Matcher Types in spec.ts Files

If VS Code reports Jasmine matchers like `toBeTruthy()`, `toBeNull()`, `toEqual()` or `toHaveBeenCalled()` as missing and resolves `expect(...)` to `Assertion`, add the Jasmine type reference at the top of the spec and explicitly type `expect`.

```typescript
/// <reference types="jasmine" />

const expect = globalThis.expect as unknown as (actual: unknown) => jasmine.Matchers<unknown>;
```

Use this in Jasmine/Karma specs when editor diagnostics do not pick up Jasmine globals correctly.

Do **NOT** fix this by casting assertions or dependencies to `any`, for example:

```typescript
// ❌ Wrong
(expect(service['http']) as any).toBeTruthy();
```

That bypasses typing instead of fixing it. In tests, `any` should be a last resort and only at narrow interop boundaries. Prefer one of these options:

```typescript
// ✅ Fix matcher typing once per file
const expect = globalThis.expect as unknown as (actual: unknown) => jasmine.Matchers<unknown>;

// ✅ Prefer public behavior over private member assertions
expect(service).toBeTruthy();
```

Do **NOT** use `fit()` or `fdescribe()` in repository test files. Focused specs are allowed only as a short-lived local debugging step and must be reverted to `it()` / `describe()` before the work is considered complete.

---

## CRITICAL: TestBed.flushEffects() Timing

When testing components with `rxResource`, call `TestBed.flushEffects()`:
1. After input changes — to evaluate resource params
2. After `tick()` — to process completed observables and run effects

```typescript
it('should load rxResource data', fakeAsync(() => {
  fixture.componentRef.setInput('environment', 'prod');
  fixture.detectChanges();
  TestBed.flushEffects(); // 1. Evaluate resource params

  tick();                 // 2. Resolve observable
  fixture.detectChanges();
  TestBed.flushEffects(); // 3. Process result in effects

  expect(component.myResource.hasValue()).toBeTrue();
}));
```

---

## CRITICAL: Error State Handling in Effects

Calling `resource.value()` when the resource is in error state throws:
```
Error: Resource is currently in an error state (see Error.cause for details)
```

```typescript
// ❌ UNSAFE:
effect(() => {
  const data = this.myResource.value(); // ⚠️ Throws if resource has error
  this.process(data);
});

// ✅ SAFE:
effect(() => {
  if (this.myResource.status() === 'success') {
    const data = this.myResource.value();
    this.process(data);
  }
});
```

**Testing error states:**
```typescript
it('should handle error state', fakeAsync(() => {
  mockService.getData.and.returnValue(throwError(() => new Error('API Error')));

  fixture.detectChanges();
  TestBed.flushEffects();
  tick();

  expect(component.myResource.status()).toBe('error');
  expect(component.myResource.hasValue()).toBeFalse();
}));
```

---

## ControlContainer Mocking for ngModelGroup

Use actual `NgForm` instead of a mock to avoid `NG01353`:

```typescript
// ❌ WRONG (Causes NG01353):
mockControlContainer = { control: new FormGroup({}), valueChanges: new BehaviorSubject<any>({}) };

// ✅ CORRECT:
const ngForm = new NgForm([], []);
mockControlContainer = ngForm;
Object.defineProperty(mockControlContainer, 'valueChanges', {
  value: new BehaviorSubject<any>({}),
  writable: true
});
```

---

## Testing rxResource (Mocking Observables)

> **Important:** Create fresh fixtures per test when mocking different behaviors.

```typescript
it('should load data correctly', fakeAsync(() => {
  mockService.getData.and.returnValue(of([{ id: 1, name: 'Test' }]));

  const fixture = TestBed.createComponent(MyComponent);
  const component = fixture.componentInstance;
  fixture.componentRef.setInput('someInput', 'value');

  fixture.detectChanges();
  TestBed.flushEffects(); // Evaluate params

  tick();
  fixture.detectChanges();
  TestBed.flushEffects(); // Process result

  expect(component.myResource.hasValue()).toBeTrue();
  expect(component.myResource.value()).toEqual([{ id: 1, name: 'Test' }]);
}));
```

**Testing dependent resources:**
```typescript
it('should load dependent resource after first resolves', fakeAsync(() => {
  mockService.getAllData.and.returnValue(of([...]));
  mockService.getSelectedData.and.returnValue(of([...]));
  mockService.isEditMode.next(true);

  fixture = TestBed.createComponent(MyComponent);
  fixture.detectChanges();
  TestBed.flushEffects();

  // Resolve first resource
  tick();
  fixture.detectChanges();
  TestBed.flushEffects();

  expect(component.firstResource.hasValue()).toBeTrue();

  // Trigger second resource
  fixture.detectChanges();
  TestBed.flushEffects();
  tick();
  fixture.detectChanges();
  TestBed.flushEffects();

  expect(component.secondResource.hasValue()).toBeTrue();
}));
```

---

## Testing Legacy httpResource (HttpTestingController)

```typescript
it('should fetch data from API', fakeAsync(() => {
  const httpMock = TestBed.inject(HttpTestingController);

  fixture.detectChanges();

  const req = httpMock.expectOne('/api/data/123');
  req.flush({ id: 123, status: 'Active' });

  tick();
  fixture.detectChanges();

  expect(component.myHttpResource.value()).toEqual({ id: 123, status: 'Active' });
}));
```

**Setup:**
```typescript
TestBed.configureTestingModule({
  providers: [provideHttpClient(), provideHttpClientTesting()]
});
```

---

## Testing Error States (404 example)

```typescript
it('should handle 404 error', fakeAsync(() => {
  const httpMock = TestBed.inject(HttpTestingController);

  fixture.detectChanges();

  const req = httpMock.expectOne('/api/data/999');
  req.flush('Not Found', { status: 404, statusText: 'Not Found' });

  tick();
  fixture.detectChanges();

  expect(component.myHttpResource.error()).toBeDefined();
  expect(component.myHttpResource.statusCode()).toBe(404);

  const errorMsg = fixture.nativeElement.querySelector('.alert-danger');
  expect(errorMsg.textContent).toContain('Resource not found');
}));
```

---

## CRITICAL: Testing rxResource with computed() Signals

Components that have `computed()` depending on `rxResource` can cause **"ApplicationRef.tick is called recursively"** if `TestBed.flushEffects()` is overused.

**❌ WRONG (causes recursive tick):**
```typescript
component.selectedAirId.set('999');
TestBed.flushEffects(); // ← CAUSES RECURSION when computed() is present
```

**✅ CORRECT:**
```typescript
// After resolving the resource:
tick();
fixture.detectChanges(); // computed signals update automatically

// Change signals directly — no flushEffects needed
component.selectedAirId.set('999');

// computed re-evaluates automatically on read
expect(component.newResourceNamePreview()).toBe('expected-name');

flush();
```

**Rule:** With `computed() + rxResource` — prefer `fixture.detectChanges()` over `TestBed.flushEffects()`.

---

## Testing Dependent rxResource (chained resources)

```typescript
it('should load dependent resource', fakeAsync(() => {
  fixture.detectChanges();

  // First resource
  const airReq = httpMock.expectOne('/api/air');
  airReq.flush([{ airId: 111 }]);
  tick();
  fixture.detectChanges();

  expect(component.airOptions.hasValue()).toBe(true);

  // Trigger dependent resource
  component.onAirIdChange(111);
  fixture.detectChanges(); // triggers second resource params

  const aiaReq = httpMock.expectOne('/api/aia/111');
  aiaReq.flush([{ aiaId: 'aia-1' }]);
  tick();
  fixture.detectChanges();

  expect(component.aiaOptions.hasValue()).toBe(true);

  flush();
}));
```

---

## Key Testing Utilities

| Utility | Purpose | When to Use |
|:--|:--|:--|
| `fakeAsync` + `tick()` | Resolve internal state transitions | Every rxResource test |
| `TestBed.flushEffects()` | Flush pending effects — use sparingly | Only when changing inputs mid-test (avoid with computed()) |
| `fixture.detectChanges()` | Sync signal values with template | After `tick()`, before assertions |
| `resource.isLoading()` | Assert loading state | Before `tick()` (true) / after (false) |
| `resource.hasValue()` | Assert successful resolution | All success tests |
| `resource.status()` | Check: `'idle'`, `'loading'`, `'success'`, `'error'` | Error state tests |
