# 09 — Angular Material 21 Theming Gotchas

> Experiential annotations on Angular Material 21 theming pitfalls and customization for the ab-ceramica project.

---

## How Material 21 theming works

Angular Material 21 uses the `mat.theme()` Sass mixin to generate `--mat-sys-*` CSS variables (Material 3 / Material You system). The scaffold file is `src/material-theme.scss`.

### `mat.theme()` signature

```scss
@include mat.theme((
  color: (
    primary: <palette>,
    tertiary: <palette>,
  ),
  typography: <font-name-or-config>,
  density: <0 | -1 | -2>,
));
```

- `density`: `0` = default, `-1` = comfortable, `-2` = compact.
- `typography`: accepts a font name string or a full typography config.

### `--mat-sys-*` variable categories

| Category | Examples |
|---|---|
| Color | `--mat-sys-primary`, `--mat-sys-surface`, `--mat-sys-on-surface`, `--mat-sys-error` |
| Typography | `--mat-sys-headline-large`, `--mat-sys-body-medium`, `--mat-sys-label-large` |
| Shape | `--mat-sys-shape-small`, `--mat-sys-shape-medium`, `--mat-sys-shape-large` |
| Elevation | `--mat-sys-elevation-level1`, `--mat-sys-elevation-level2`, ... |

### Body usage (from scaffold)

```scss
body {
  background-color: var(--mat-sys-surface);
  color: var(--mat-sys-on-surface);
  font: var(--mat-sys-body-medium);
  color-scheme: light; /* or dark, or light dark for system preference */
}
```

---

## Custom palettes

```scss
$my-primary: mat.define-color-palette($base-color, $lighter-darker-variants...);
```

`mat.define-color-palette()` creates a Material 3 tonal palette from a base color. The scaffold uses `mat.$magenta-palette` and `mat.$violet-palette` (pre-defined) — these need replacement for any real brand.

---

## Tailwind CSS 4 integration

- `src/styles.css` contains `@import "tailwindcss";`
- `.postcssrc.json` contains `@tailwindcss/postcss`
- **Use Tailwind for layout utilities ONLY** (flex, grid, spacing, responsive).
- **Never use Tailwind for component theming** — use `--mat-sys-*` variables for colors, typography, shapes.

---

## DESIGN.md token mapping

Map DESIGN.md color tokens to Material 3 color roles:

| DESIGN.md token | Material 3 variable |
|---|---|
| `colors.primary` | `--mat-sys-primary` |
| `colors.surface` | `--mat-sys-surface` |
| `colors.on-surface` | `--mat-sys-on-surface` |
| `colors.error` | `--mat-sys-error` |

See `docs/context/design-system.md` for the full mapping.

---

## Gotchas

- **Scaffold `material-theme.scss` may have a DUPLICATED theme block.** Lines 1-37 and 39-74 can be identical, with a second `@use '@angular/material' as mat;` at line 44. This causes: `"@use rules must come before other rules."` **Fix: remove the duplicate block, keep only the first.** This is a known scaffold issue.
- **`@use` MUST come before any other rules in SCSS.** Comments, variables, or anything before `@use` triggers a Sass error. Put `@use` at the very top.
- **`mat.$magenta-palette` and `mat.$violet-palette` are pre-defined palettes**, not custom. For brand colors, use `mat.define-color-palette()`.
- **Material docs at `material.angular.dev` are JS-rendered** — `webfetch` returns empty/minimal content. Theming info comes from scaffold comments and the `mat.theme()` mixin signature, not the docs site. See `08-web-fetching-strategy.md`.
- **Don't mix Material 3 theming with old Material 2 patterns.** No `::ng-deep`, no deep selectors, no `$theme` map overrides. Material 21 is CSS-variable-based via `--mat-sys-*`.

---

## Quick Reference

| Item | Value |
|---|---|
| Scaffold file | `src/material-theme.scss` |
| Theme mixin | `mat.theme((color: ..., typography: ..., density: ...))` |
| Custom palette | `mat.define-color-palette($base-color, ...)` |
| Pre-defined palettes | `mat.$magenta-palette`, `mat.$violet-palette` (replace for real brand) |
| CSS variables | `--mat-sys-{primary,surface,on-surface,error,...}` |
| Tailwind role | Layout utilities only — never component theming |
| Density values | `0` (default), `-1` (comfortable), `-2` (compact) |
| `@use` rule | Must be the first statement in the SCSS file |

---

## Cross-references

- `08-web-fetching-strategy.md` — why `webfetch` can't read Material docs.
- `10-design-md-spec-quickref.md` — DESIGN.md format spec for token definitions.
- `docs/context/design-system.md` — full token-to-`--mat-sys-*` mapping.
- `DESIGN.md` (repo root) — AB Ceramica's design tokens.