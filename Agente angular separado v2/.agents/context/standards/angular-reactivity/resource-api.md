---
last_updated: 2026-03-30
tags: [angular, rxResource, linkedSignal, computed, signals, httpResource]
---

# Resource API & Patterns

> Part of [angular-reactivity/](index.md) · See also [testing.md](testing.md)

## Project Standard

- **Preferred standard for new async data loading:** `rxResource`
```typescript
myResource = rxResource({
  params: () => this.mySignal(),
  stream: ({ params }) => this.http.get(`/api/data/${params.request}`).pipe(
    map((data) => new Model(data))
  )
});
```

> **⚠️ CRITICAL:** `rxResource` does NOT support a `transform` property. All data transformation must happen inside `stream` via `pipe(map(...))`.

## linkedSignal — Selection Synchronization

Use when a dropdown selection needs to stay in sync with asynchronously loaded data.

```typescript
dropdownData = linkedSignal({
  source: () => ({
    list: this.enalist.value() ?? [],
    demandId: this.resourceData.value()[this.projectTabSelectedIndex()]?.demandId ?? ''
  }),
  computation: (source) => this.getDropDownOptions(source.demandId, source.list)
});
```

---
## Resource Template Structure (REQUIRED)

This guard order is mandatory when rendering resource state, including legacy `httpResource` usages.

Always use this exact order — `hasValue()` first, then `error()`, then `isLoading()`:

```html
@if (resource.hasValue()) {
  <!-- Render content -->
  <user-details [user]="resource.value()" />
} @else if (resource.error()) {
  <!-- Nest statusCode checks INSIDE the error block -->
  @if (resource.statusCode() === 404) {
    <div class="alert alert-danger">Resource not found</div>
  } @else {
    <div class="alert alert-warning">{{ resource.error() }}</div>
  }
} @else if (resource.isLoading()) {
  <div class="alert alert-info">Loading...</div>
}
```

> **Never** use `(resource.error() as any)?.status`. Use `resource.statusCode()`.

**❌ Wrong (shows loading even when there's an error):**
```html
@if (resource.isLoading()) {
  <div>Loading...</div>
} @else if (resource.hasValue()) {
  <div>{{ resource.value() }}</div>
}
```

---

## computed — Derived State

```typescript
projectHeader = computed(() => {
  const platform = this.data.projectType === 'gcp' ? 'GCP' : 'Azure';
  const projectName = this.resourceData.value()[this.projectTabSelectedIndex()]?.projectCloudValue ?? '';
  return projectName ? `${platform} project: ${projectName}` : '';
});
```

> `computed()` must track at least one reactive dependency (signal call). Never reference plain variables inside `computed()`.

---

## Anti-Patterns

| Anti-Pattern (AVOID) | Standard Pattern (USE) | Why |
|:--|:--|:--|
| `effect(() => this.mySignal.set(val))` | `linkedSignal()` | Prevents infinite loops |
| `resource.value()` without guard | `@if (resource.hasValue())` or `?? []` | Prevents error state crashes |
| `(resource.error() as any).status` | `resource.statusCode()` | Official API for status codes |
| `transform` in `rxResource` options | `stream: () => obs$.pipe(map(...))` | `transform` is not supported |
| `computed(() => someGlobalVar)` | `computed(() => someSignal())` | Must track a reactive dependency |
| New component data loading with `httpResource` by default | `rxResource` | Project standard is `rxResource` for new async flows |
