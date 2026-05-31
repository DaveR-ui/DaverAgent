---
last_updated: 2026-05-09
description: Catalog of reusable code recipes and validated patterns for the project.
tags: [patterns, catalog, recipes, angular, signals, snippets]
---

# 📖 Pattern Catalog (Recipe Box)

This document contains "Battle-Tested" code snippets and implementation patterns specifically approved for **Matafuegos Necochea**. Use these as base templates for new features.

## ⚛️ Reactivity Patterns

### 1. Unified Resource Loading (`rxResource`)
Standard for fetching data from an API with loading/error states.

```typescript
readonly items = rxResource({
  loader: () => this.service.getAll(),
});

// usage in HTML
@if (items.isLoading()) { <app-skeleton /> }
@else if (items.error()) { <app-error-state /> }
@else {
  @for (item of items.value(); track item.id) {
    <app-item-card [item]="item" />
  }
}
```

### 2. Form Auto-Save (`linkedSignal`)
Use `linkedSignal` to keep a local UI state in sync with a source signal but allowing local modifications.

```typescript
readonly originalValue = input.required<string>();
readonly draftValue = linkedSignal(() => this.originalValue());

// Logic to modify draftValue locally
updateValue(newValue: string) {
  this.draftValue.set(newValue);
}
```

## 🧩 Component Patterns

### 1. Conditional Action Button
Consistent pattern for buttons that require validation or state-based disabling.

```html
<button
  type="button"
  class="btn-primary"
  [disabled]="isProcessing() || !form.valid"
  (click)="submit()"
>
  @if (isProcessing()) {
    <lucide-icon name="loader-2" class="animate-spin" />
    Processing...
  } @else {
    <lucide-icon [name]="iconName()" />
    {{ label() }}
  }
</button>
```

### 2. Modal Confirmation Flow
Standard flow for destructive actions (Delete Extinguisher, Reset PH).

```typescript
async onDelete(id: string) {
  const confirmed = await this.modal.confirm({
    title: 'Delete Extinguisher?',
    message: 'This action is irreversible and will affect the client\'s equipment allocation.',
    confirmLabel: 'Delete',
    variant: 'danger'
  });

  if (confirmed) {
    await this.service.delete(id);
  }
}
```

## 🆘 Troubleshooting Patterns

### 1. Resource Cleanup
If a component is destroyed, ensure all external observers are cleaned up (though Signals handle this mostly).

```typescript
private readonly destroyRef = inject(DestroyRef);

constructor() {
  const sub = this.service.events$.subscribe();
  this.destroyRef.onDestroy(() => sub.unsubscribe());
}
```

---
> [!TIP]
> Found a new recurring pattern? Use `memory-learner` to add it here.
