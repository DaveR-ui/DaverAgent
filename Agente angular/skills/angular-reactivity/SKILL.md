---
name: angular-reactivity
description: Guidelines for Angular Signals, rxResource, legacy httpResource compatibility, and linkedSignal.
---

# Angular Reactivity Skill

This skill provides the mandatory patterns for using Angular's reactive primitives (Signals).

> [!IMPORTANT]
> This is a localized version of the project standard. 
> Full reference: [angular-reactivity/index.md](../../agent-context/angular-reactivity/index.md)

## 🔄 Resource Lifecycle & Sync Flow
1. **rxResource**: Use for async data fetching in new code.
2. **linkedSignal**: Use to sync writable state with source signals.
3. **computed**: Use for derived read-only state.

## ⚠️ CRITICAL: Resource Template Pattern
Always follow this order in templates to avoid "Resource in error state" crashes:

```html
@if (resource.hasValue()) {
  <user-details [user]="resource.value()" />
} @else if (resource.error()) {
  @if (resource.statusCode() === 404) {
    <div class="alert alert-danger">Not found</div>
  } @else {
    <div class="alert alert-warning">{{ resource.error() }}</div>
  }
} @else if (resource.isLoading()) {
  <div class="alert alert-info">Loading...</div>
}
```

## 🛠️ rxResource Standard Pattern
Transformation MUST happen inside the `stream` function using RxJS `map`. The `transform` property is NOT supported.

```typescript
import { map } from 'rxjs/operators';

myResource = rxResource({
  params: () => this.mySignal(),
  stream: (param) => this.http.get(`/api/data/${param.request}`).pipe(
    map((data) => new Model(data)) 
  )
});
```

## 🚫 Anti-Patterns to Avoid
- **Directly setting values from a resource without linkedSignal**: Leads to sync issues.
- **Ignoring the error state**: Causes runtime exceptions.
- **Using transform property in resource**: Deprecated/Not supported in this version.
- **Starting new component data flows with `httpResource`**: In this repo, prefer `rxResource` unless maintaining legacy behavior.
