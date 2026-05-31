---
last_updated: 2026-05-02
description: Unified design rules for all page-level layouts, buttons, inputs, empty states, and containers.
tags: [design-rules, layout, buttons, inputs, empty-states, containers]
status: ACTIVE
---

# 🎨 Unified Design Rules

> **MANDATORY**: All page-level layouts MUST follow these rules. No exceptions for new pages.
> **Existing pages**: Must be migrated to comply. See migration checklist at the end.

---

## Rule 1: Page Container

**All pages MUST use a single top-level container class: `.page-container`**

```scss
.page-container {
  display: flex;
  flex-direction: column;
  gap: var(--space-xl);
  padding: var(--space-xl);
  height: 100%;
}
```

**Prohibited**: Custom container names (`.user-list-page`, `.client-list-container`, `.dashboard`, `.centered-text`, etc.)

---

## Rule 2: Page Header

**All pages MUST use this exact structure:**

```html
<header class="page-header">
  <div class="title-group">
    <h1 class="page-title">Page Title</h1>
    <p class="page-subtitle">Brief description of this page.</p>
  </div>
  <div class="header-actions">
    <!-- Primary action button goes here -->
  </div>
</header>
```

**CSS:**
```scss
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: var(--space-lg);
}

.title-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-xs);
}

.page-title {
  margin: 0;
  font-size: var(--font-size-2xl);
  font-weight: var(--font-weight-bold);
  color: var(--color-gray-900);
  letter-spacing: -0.025em;
}

.page-subtitle {
  margin: 0;
  color: var(--color-gray-400);
  font-size: var(--font-size-lg);
}

.header-actions {
  display: flex;
  gap: var(--space-sm);
  align-items: center;
}
```

**Prohibited**:
- Bare `<h1>` without `.page-title` class
- `.subtitle` class (use `.page-subtitle`)
- `.list-header`, `.dashboard-header` (use `.page-header`)
- `align-items: flex-end` or `flex-start` on header (use `center`)

---

## Rule 3: Buttons — Single Source of Truth

**The `app-button` directive is the ONLY button system for page-level actions.**

### Usage:
```html
<!-- Primary action (add, create, submit) -->
<button app-button variant="primary" (buttonClick)="onAction()">
  <span class="material-icons">add</span>
  Action Label
</button>

<!-- Secondary action (cancel, view, navigate) -->
<button app-button variant="secondary" (buttonClick)="onAction()">
  Cancel
</button>

<!-- Danger action (delete, remove) -->
<button app-button variant="danger" (buttonClick)="onAction()">
  Delete
</button>

<!-- Small buttons (table row actions) -->
<button app-button variant="secondary" size="small" (buttonClick)="onAction()">
  Edit
</button>
```

### Variants:
| Variant | Background | Text Color | Use Case |
|---------|-----------|------------|----------|
| `primary` | `var(--color-primary)` | `white` | Main CTA, create, submit |
| `secondary` | `var(--color-gray-200)` | `var(--color-gray-700)` | Cancel, view, navigate |
| `danger` | `var(--color-error)` | `white` | Delete, destructive actions |

### Sizes:
| Size | Padding | Min-height | Use Case |
|------|---------|------------|----------|
| `small` | `var(--space-xs) var(--space-sm)` | `2rem` | Table row actions, compact UI |
| `medium` (default) | `var(--space-sm) var(--space-md)` | `2.5rem` | Standard buttons |
| `large` | `var(--space-md) var(--space-lg)` | `3rem` | Hero CTAs, login |

### Icons:
- Use `<span class="material-icons">icon_name</span>` inside buttons
- Place icon BEFORE text label
- No emoji icons (❌ `➕`, `👤`, etc.)

### Prohibited:
- **NO** Material buttons (`mat-raised-button`, `mat-flat-button`, `mat-button`) for page-level actions
- **NO** native `<button class="add-btn">` custom CSS buttons
- **NO** emoji as button icons
- **NO** hardcoded colors in button styles

### Migration Note:
Material buttons inside forms (Client Form, Invoice Form, Payment Modal) may remain as-is for now. The rule applies to **page-level action buttons** (headers, toolbars, empty states).

---

## Rule 4: Search / Input Fields

### For search bars on list pages:
**Use `mat-form-field` with `appearance="outline"`**

```html
<mat-form-field appearance="outline" class="search-field">
  <mat-label>Search label</mat-label>
  <input matInput type="text" placeholder="Placeholder text..." />
  <mat-icon matPrefix>search</mat-icon>
</mat-form-field>
```

### For form inputs:
**Use `<app-field>` component** (label + input + error handling)

```html
<app-field fieldId="email" label="Email" type="email" placeholder="user@example.com"
  [errorMessage]="formErrors.email()" (valueChange)="onEmailChange($event)" />
```

### CSS for search fields (shared):
```scss
.search-field {
  flex: 1;
  max-width: 600px;

  ::ng-deep {
    .mat-mdc-text-field-wrapper {
      --mdc-outlined-text-field-outline-color: var(--color-gray-600);
      --mdc-outlined-text-field-hover-outline-color: var(--color-gray-600);
      --mdc-outlined-text-field-focus-outline-color: var(--color-primary);
      --mdc-outlined-text-field-caret-color: var(--color-primary);
      --mdc-outlined-text-field-input-text-color: var(--color-gray-900);
      --mdc-outlined-text-field-label-text-color: var(--color-gray-400);
      --mdc-outlined-text-field-hover-label-text-color: var(--color-gray-400);
      --mdc-outlined-text-field-focus-label-text-color: var(--color-primary);
    }

    .mdc-text-field--outlined {
      --mdc-outlined-text-field-input-text-color: var(--color-gray-900);
    }

    .mat-mdc-form-field-icon-prefix .mat-icon,
    .mat-mdc-form-field-icon-suffix .mat-icon {
      --mat-icon-color: var(--color-gray-400);
      color: var(--color-gray-400);
    }

    .mat-mdc-form-field-focus-overlay {
      opacity: 0;
    }
  }
}
```

### Prohibited:
- **NO** `appearance="fill"` on any `mat-form-field`
- **NO** `<app-input>` standalone on list pages (use `mat-form-field` for search)
- **NO** native `<select>` elements (use `<mat-select>` inside `mat-form-field`)
- **NO** hardcoded `background: white` on inputs

---

## Rule 5: Empty States

**All pages MUST use this unified empty state structure:**

```html
<div class="empty-state">
  <div class="empty-icon-wrapper">
    <span class="material-icons">icon_name</span>
  </div>
  <h2 class="empty-title">No items found</h2>
  <p class="empty-description">
    Description of why the list is empty and what the user can do.
  </p>
  <button app-button variant="primary" (buttonClick)="onAction()">
    <span class="material-icons">add</span>
    Action Label
  </button>
</div>
```

**CSS:**
```scss
.empty-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: var(--space-2xl) var(--space-xl);
  text-align: center;
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  border: 2px dashed var(--color-border);
  margin-top: var(--space-xl);
}

.empty-icon-wrapper {
  width: 80px;
  height: 80px;
  background: var(--color-gray-700);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: var(--space-lg);

  span {
    font-size: var(--font-size-2xl);
    color: var(--color-gray-300);
  }
}

.empty-state .empty-title {
  font-size: var(--font-size-xl);
  font-weight: var(--font-weight-bold);
  margin-bottom: var(--space-sm);
  color: var(--color-gray-900);
}

.empty-state .empty-description {
  color: var(--color-gray-400);
  margin-bottom: var(--space-xl);
  max-width: 300px;
}
```

**Prohibited**:
- **NO** emoji icons (`👥`, `👤`, `&#128101;`)
- **NO** bare `<p>` tags as empty states
- **NO** `*matNoDataRow` as the only empty state feedback
- **NO** different heading levels (`<h3>` for empty title — use `<h2>`)

---

## Rule 6: Cards and Data Containers

**All cards MUST use theme-aware tokens:**

```scss
.card, .user-card, .stat-card, .activity-list, .status-grid {
  background: var(--color-card);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
}
```

**Prohibited**:
- **NO** `background: white`
- **NO** `border: 1px solid var(--color-gray-200)`
- **NO** `border-bottom: 1px solid var(--color-gray-100)`

---

## Rule 7: Typography Colors

| Element | Token |
|---------|-------|
| Page title (`h1`, `.page-title`) | `var(--color-gray-900)` |
| Page subtitle (`.page-subtitle`) | `var(--color-gray-400)` |
| Section title (`.section-title`) | `var(--color-gray-900)` |
| Body text | `var(--color-gray-700)` |
| Muted text | `var(--color-gray-400)` |
| Empty state title | `var(--color-gray-900)` |
| Empty state description | `var(--color-gray-400)` |
| Card/label text | `var(--color-gray-900)` |

**Prohibited**:
- **NO** `var(--color-text-card)` (context-dependent, unreliable)
- **NO** `var(--color-gray-800)` for primary text
- **NO** hardcoded hex colors

---

## Rule 8: Spacing

**All spacing MUST use design tokens:**

| Token | Value |
|-------|-------|
| `--space-xs` | `0.25rem` |
| `--space-sm` | `0.5rem` |
| `--space-md` | `1rem` |
| `--space-lg` | `1.5rem` |
| `--space-xl` | `2rem` |
| `--space-2xl` | `3rem` |

**Prohibited**:
- **NO** hardcoded `px` values (`24px`, `12px`, `16px`, `4px`, `48px`, etc.)
- **NO** `margin: 0 auto` without `max-width` context

---

## Rule 9: Language Consistency

**All UI text MUST be in Spanish** (the primary language of the application).

| English | Spanish |
|---------|---------|
| User Management | Gestión de Usuarios |
| Manage system users... | Administra los usuarios del sistema... |
| Add User | Nuevo Usuario |
| Search users... | Buscar usuarios... |
| All Roles | Todos los Roles |
| No users found | No se encontraron usuarios |
| Get started by adding... | Comienza agregando... |
| Add First User | Agregar mi primer usuario |
| Dashboard | Panel de Control |
| Welcome back... | ¡Bienvenido...! |
| Quick Stats | Estadísticas Rápidas |
| Recent Activity | Actividad Reciente |
| Quick Actions | Acciones Rápidas |
| System Status | Estado del Sistema |
| No recent activity | Sin actividad reciente |

---

## Migration Checklist

### Phase 1: User Management (`user-list`)
- [ ] Container: `.user-list-page` → `.page-container`
- [ ] Header: restructure to `.page-header` + `.title-group` + `.page-title` + `.page-subtitle`
- [ ] Title text: English → Spanish
- [ ] Subtitle text: English → Spanish
- [ ] Button: `app-button` with emoji → `app-button` with `<span class="material-icons">person_add</span>`
- [ ] Button text: "Add User" → "Nuevo Usuario"
- [ ] Search: `<app-input>` → `<mat-form-field appearance="outline">`
- [ ] Role filter: native `<select>` → `<mat-form-field>` with `<mat-select>`
- [ ] Empty state: emoji icons → Material Icons in `.empty-icon-wrapper`
- [ ] Empty state: English → Spanish
- [ ] Empty state: heading `<h3>` → `<h2>`
- [ ] Cards: `background: white` → `var(--color-card)`, `border: var(--color-gray-200)` → `var(--color-border)`
- [ ] Remove hardcoded spacing values

### Phase 2: Dashboard
- [ ] Container: `.dashboard` → `.page-container`
- [ ] Header: restructure to `.page-header` pattern
- [ ] Title text: English → Spanish
- [ ] Subtitle text: English → Spanish
- [ ] Section titles: English → Spanish
- [ ] Section titles color: `--color-gray-800` → `--color-gray-900`
- [ ] Stat cards: `background: white` → `var(--color-card)`, borders → `var(--color-border)`
- [ ] Activity list: `background: white` → `var(--color-card)`, borders → `var(--color-border)`
- [ ] Status grid: `background: white` → `var(--color-card)`, borders → `var(--color-border)`
- [ ] Empty state: add proper structure with icon wrapper
- [ ] Remove emoji icons from stat cards
- [ ] Remove hardcoded spacing

### Phase 3: Invoice List
- [ ] Container: keep `.page-container` (already correct name) but use token padding
- [ ] Hardcoded `24px` → `var(--space-lg)`, `12px` → `var(--radius-lg)`, `16px` → `var(--space-md)`, `4px` → `var(--space-xs)`
- [ ] Button: `mat-raised-button` → `app-button variant="primary"` with Material Icon
- [ ] Date pickers: keep `mat-form-field appearance="outline"` (already correct)
- [ ] Empty state: `*matNoDataRow` → proper `.empty-state` div

### Phase 4: Home Page
- [ ] Restructure to `.page-container` + `.page-header` pattern
- [ ] Text: Spanish (already correct)
- [ ] Add proper styling

### Phase 5: Global
- [ ] Move shared `.page-container`, `.page-header`, `.page-title`, `.page-subtitle`, `.header-actions`, `.empty-state` styles to a shared SCSS file (e.g., `src/styles.scss` or `src/shared/styles/page-layout.scss`)
- [ ] Remove duplicate styles from individual component SCSS files
