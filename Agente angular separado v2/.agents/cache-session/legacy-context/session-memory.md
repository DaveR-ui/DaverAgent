# Session Memory: Complete Design Unification — All Pages

## Root Cause
Three screenshots revealed severe design inconsistencies across pages: 3 competing button systems (app-button, native CSS, Material), 4 different header structures, emoji icons vs Material Icons, English vs Spanish text, hardcoded `background: white`, and hardcoded `px` spacing values.

## Fix Summary
Applied complete design unification across 4 pages following `.agents/context/design/unified-design-rules.md`:

### New Files Created
- `.agents/context/design/unified-design-rules.md` — 9 mandatory design rules (container, header, buttons, inputs, empty states, cards, typography, spacing, language)
- `src/shared/styles/page-layout.scss` — Shared base styles (container, header, empty state) imported globally via `styles.scss`
- `src/shared/styles/material-fields.scss` — Shared Material field `::ng-deep` overrides imported per-component

### Pages Migrated

**User Management** (most changes):
- Container: `.user-list-page` → `.page-container`
- Header: restructured to `.page-header` + `.title-group` + `.page-title` + `.page-subtitle`
- All text: English → Spanish
- Button: emoji `➕` → `<span class="material-icons">person_add</span>`
- Search: `<app-input>` → `<mat-form-field appearance="outline">`
- Role filter: native `<select>` → `<mat-select>` inside `mat-form-field`
- Avatar/empty icons: emoji → Material Icons
- Cards: `background: white` → `var(--color-card)`, borders → `var(--color-border)`
- Removed unused `Input` component import from TypeScript

**Dashboard**:
- Container: `.dashboard` → `.page-container`
- Header: restructured to standard pattern
- All text: English → Spanish
- Stat/action icons: emoji → Material Icons
- Cards: `background: white` → `var(--color-card)`, borders → `var(--color-border)`
- Empty state: added proper structure with icon wrapper

**Invoice List**:
- Header: flattened (removed `.header-content` wrapper)
- Button: `mat-raised-button` → `app-button variant="primary"`
- Row actions: `mat-icon-button` → `app-button` with text labels
- All spacing: hardcoded `px` → `var(--space-*)` tokens
- Empty state: `*matNoDataRow` → proper `.empty-state` div

**Home Page**:
- Restructured to `.page-container` + `.page-header` pattern
- Title casing: "SISTEMA DE MATAFUEGOS" → "Sistema de Matafuegos"

### Style Deduplication
- Moved shared styles (`.page-container`, `.page-header`, `.page-title`, `.page-subtitle`, `.header-actions`, `.empty-state`, `.empty-icon-wrapper`, `.empty-title`, `.empty-description`) to `src/shared/styles/page-layout.scss`
- Imported globally via `@use` in `src/styles.scss`
- Component SCSS files now only contain page-specific styles

### Build Fixes
- Fixed `@use` ordering in `styles.scss` (must come before `@include`)
- Fixed `Input` component unused import warning in `user-list.ts`
- Fixed `(input)` event type error: `$event` → `$any($event.target).value`
- Fixed `handleRoleFilterChange` signature: `Event` → `{ value: string }` for `MatSelectChange`

## Files Touched (12 total)
- **New**: `.agents/context/design/unified-design-rules.md`, `src/shared/styles/page-layout.scss`, `src/shared/styles/material-fields.scss`
- **Modified**: `src/styles.scss`, `src/features/user-management/user-list.html`, `src/features/user-management/user-list.scss`, `src/features/user-management/user-list.ts`, `src/features/dashboard/dashboard.html`, `src/features/dashboard/dashboard.scss`, `src/features/invoice/page/invoice-list/invoice-list.html`, `src/features/invoice/page/invoice-list/invoice-list.scss`, `src/features/home/home.html`, `src/features/home/home.scss`

## Learning Points
- `@use` rules must come before any `@include` or other CSS rules in Sass
- `mat-select` `(selectionChange)` emits `{ value: string }`, not `Event`
- `matInput` `(input)` event requires `$any($event.target).value` to extract string
- Shared `::ng-deep` styles must be imported per-component (not globally) due to view encapsulation
- Build succeeded with only `@import` deprecation warnings (non-blocking)

## Clue Memory
- **High-signal**: 3 screenshots showing visual inconsistencies (buttons, colors, margins)
- **High-signal**: User request for Spanish text and uniform design
- **High-signal**: Existing `app-button` component as the single source of truth for buttons
