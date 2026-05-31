---
last_updated: 2026-04-30
description: Testing patterns for Angular reactive HTTP data loading, resource error handling, and TestBed timing
tags: [testing, rxresource, signals, jasmine, vitest, testbed]
status: ACTIVE
---

# Testing Reactive HTTP Data & Signals

## Critical: TestBed.flushEffects() Timing

When testing components that use `rxResource` or `httpResource`, you **must** call `TestBed.flushEffects()` after triggering change detection and before asserting on `.value()`.

```ts
fixture.detectChanges();
TestBed.flushEffects();
const data = component.resource.value();
expect(data).toBeDefined();
```

Without `flushEffects()`, the signal computation is pending and `.value()` returns `undefined`.

## Critical: Error State Handling in Effects

When a resource enters an error state, guard against reading `.value()` directly:

```ts
// In component
@if (resource.hasValue()) {
  <p>{{ resource.value().name }}</p>
} @else if (resource.error()) {
  <p>Error loading data</p>
} @else {
  <p>Loading...</p>
}
```

## ControlContainer Mocking for ngModelGroup

Components using `ngModelGroup` require a `ControlContainer` provider to avoid `NG01353`:

```ts
TestBed.configureTestingModule({
  providers: [
    { provide: ControlContainer, useValue: null }
  ]
});
```

## Testing rxResource With Jasmine

```ts
it('should load data', fakeAsync(() => {
  const fixture = TestBed.createComponent(MyComponent);
  fixture.detectChanges();
  TestBed.flushEffects();
  
  const data = component.resource.value();
  expect(data).toBeTruthy();
}));
```

## Testing rxResource With Vitest

```ts
it('should load data', () => {
  const fixture = TestBed.createComponent(MyComponent);
  fixture.detectChanges();
  TestBed.flushEffects();
  
  const data = component.resource.value();
  expect(data).toBeTruthy();
});
```

## Provider-Only TestBed for Logic-Only Specs

When testing services or pure logic without templates, use a provider-only TestBed to avoid `ɵcmp` compilation issues:

```ts
it('should compute correctly', runInInjectionContext(TestBed.inject(Injector), () => {
  const service = TestBed.inject(MyService);
  expect(service.compute()).toBe(expected);
}));
```

## TestBed Teardown Ordering

If a spec uses `afterAll` or `disconnect` on resources, ensure proper teardown ordering:

```ts
afterEach(() => {
  TestBed.resetTestingModule();
});
```

## Common Test Pitfalls

| Symptom | Fix |
|---------|-----|
| `.value()` is `undefined` after `detectChanges()` | Add `TestBed.flushEffects()` |
| `NG01353` error with `ngModelGroup` | Provide `ControlContainer` |
| `ɵcmp` error after `resetTestingModule()` | Use `runInInjectionContext()` for logic-only specs |
| Resource error state not caught | Check `resource.error()` before `.value()` |
