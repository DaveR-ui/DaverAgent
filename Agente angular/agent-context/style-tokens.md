---
last_updated: 2026-03-30
description: index of shared Sass tokens and runtime CSS custom properties used by the application
tags: [styles, css-variables, scss, design-tokens, ag-grid, bootstrap, material]
---

# Style Tokens and CSS Variable Index

## Source of Truth

- Shared Sass tokens live in `src/assets/styles/_variables.scss`.
- AG Grid runtime custom properties live primarily in `src/assets/styles/core/_ag-theme.scss`.
- Bootstrap runtime overrides live in `src/assets/styles/core/_bootstrap.scss` and component-level `.scss` files.
- Angular Material runtime overrides live in `src/assets/styles/components/_materialTheme.scss` and component-level `.scss` files.

> [!CAUTION]
> `$...` values are Sass compile-time tokens. `--...` values are runtime CSS custom properties. They are not interchangeable.

## Fast Index

### Sass Tokens

- [Font families](#font-families)
- [Font sizes](#font-sizes)
- [Typography](#typography)
- [Core colors](#core-colors)
- [Semantic colors](#semantic-colors)
- [Spacing and layout](#spacing-and-layout)
- [Radii](#radii)
- [Shadows](#shadows)
- [Transitions](#transitions)
- [Special constants](#special-constants)

### CSS Custom Properties

- [AG Grid theme variables](#ag-grid-theme-variables)
- [Bootstrap overrides](#bootstrap-overrides)
- [Angular Material overrides](#angular-material-overrides)
- [Component-local custom properties](#component-local-custom-properties)

## Usage Rules

| Use case | Standard |
|---|---|
| Shared design token | Prefer a Sass token from `src/assets/styles/_variables.scss` |
| Runtime theming / third-party override | Use a CSS custom property `--...` |
| Component-specific one-off constant | Keep it local to the component `.scss` |
| Alias token | Use the existing alias instead of duplicating a literal value |

## Sass Tokens

### Font Families

| Token | Value |
|---|---|
| `$font-family-base` | `"Graphik-Regular", sans-serif !default` |
| `$font-family-light` | `"Graphik-Light", sans-serif !default` |
| `$font-family-medium` | `"Graphik-Medium", sans-serif !default` |
| `$font-family-semibold` | `"Graphik-Semibold", sans-serif !default` |
| `$font-family-bold` | `"Graphik-Bold", sans-serif !default` |
| `$font-family-black` | `"Graphik-Black", sans-serif !default` |
| `$material-icon` | `'Material Icons' !default` |

### Font Sizes

| Token | Value |
|---|---|
| `$font-size-base` | `1rem` |
| `$font-size-10` | `0.625rem` |
| `$font-size-11` | `0.688rem` |
| `$font-size-12` | `0.75rem` |
| `$font-size-13` | `0.813rem` |
| `$font-size-14` | `0.875rem` |
| `$font-size-15` | `0.938rem` |
| `$font-size-16` | `1rem` |
| `$font-size-17` | `1.063rem` |
| `$font-size-18` | `1.125rem` |
| `$font-size-19` | `1.188rem` |
| `$font-size-20` | `1.25rem` |
| `$font-size-22` | `1.375rem` |
| `$font-size-24` | `1.5rem` |
| `$font-size-28` | `1.75rem` |
| `$font-size-32` | `2rem` |
| `$font-size-40` | `2.5rem` |
| `$font-size-56` | `3.5rem` |

### Typography

| Token | Value |
|---|---|
| `$font-weight-bold` | `600` |
| `$font-weight-base` | `400` |
| `$font-weight-medium` | `500` |
| `$letter-spacing-32` | `.32px` |
| `$letter-spacing--2` | `-.02em` |
| `$line-height-100` | `100%` |
| `$line-height-110` | `110%` |
| `$line-height-120` | `120%` |
| `$line-height-150` | `150%` |
| `$font-color-ux-black-discovery` | `#2B2733` |

### Core Colors

| Token | Value |
|---|---|
| `$transparent` | `#ffffff00` |
| `$primary-color` | `#0041F0` |
| `$purple-1` | `#A100FF` |
| `$purple-2` | `#7500C0` |
| `$purple-3` | `#460073` |
| `$black` | `#000` |
| `$white` | `#FFF` |
| `$acc-purple-1` | `#b455aa` |
| `$acc-purple-2` | `#a055f5` |
| `$acc-purple-3` | `#be82ff` |
| `$acc-purple-4` | `#dcafff` |
| `$acc-purple-5` | `#e6dcff` |
| `$secondary-blue` | `#0041F0` |
| `$secondary-light-blue` | `#00ffff` |
| `$secondary-blue-green` | `#05f0a5` |
| `$secondary-green` | `#64ff50` |
| `$secondary-yellow` | `#ffeb32` |
| `$secondary-orange` | `#ff7800` |
| `$secondary-red` | `#D62F00` |
| `$secondary-pink` | `#ff50a0` |
| `$data-purple-1` | `#dfadff` |
| `$data-purple-2` | `#9f50d1` |
| `$data-purple-3` | `#6b05ac` |
| `$blue-1` | `#86a7ff` |
| `$blue-2` | `#3068fd` |
| `$blue-3` | `#324288` |
| `$blue-4` | `#76bbe3` |
| `$blue-5` | `#C1E3F7` |
| `$grey-100` | `#FAFAFA` |
| `$grey-150` | `#f6f6f6` |
| `$grey-200` | `#F2F2F2` |
| `$grey-300` | `#E5E5E5` |
| `$grey-400` | `#CCCBCE` |
| `$grey-500` | `#B3B2B5` |
| `$grey-600` | `#837F89` |
| `$grey-700` | `#4f4b53` |
| `$grey-800` | `#3b3944` |
| `$grey-900` | `#1D1823` |
| `$grey-1000` | `#03000F` |
| `$blue` | `$secondary-blue` |
| `$bg-body` | `#F7F8FC` |
| `$body-copy` | `#5E5464` |
| `$blue-bg-gradient` | `#270957` |

### Semantic Colors

| Token | Value |
|---|---|
| `$success-100` | `#daf5da` |
| `$success-200` | `#48cb48` |
| `$success-300` | `#3E8629` |
| `$success-400` | `#C8EBC8` |
| `$warning-100` | `#fcebdb` |
| `$warning-200` | `#f19b4c` |
| `$warning-300` | `#b36200` |
| `$error-100` | `#fdeeee` |
| `$error-200` | `#eb5757` |
| `$error-300` | `#B10B02` |
| `$error-400` | `#F2C6C6` |
| `$info-100` | `#e6f5ff` |
| `$info-200` | `#009dff` |
| `$info-300` | `#00558A` |
| `$status-blue` | `#60A5FA` |
| `$status-green` | `#71D1AE` |
| `$status-red` | `#F5F5F5` |
| `$status-orange` | `#FFAD5D` |

### Spacing and Layout

| Token | Value |
|---|---|
| `$spacer` | `.625rem` |
| `$spacing-2` | `.125rem` |
| `$spacing-4` | `.25rem` |
| `$spacing-6` | `.375rem` |
| `$spacing-8` | `.5rem` |
| `$spacing-9` | `.563rem` |
| `$spacing-10` | `.625rem` |
| `$spacing-11` | `.688rem` |
| `$spacing-12` | `.75rem` |
| `$spacing` | `1rem` |
| `$spacing-17` | `1.0625rem` |
| `$spacing-20` | `1.25rem` |
| `$spacing-24` | `1.5rem` |
| `$mx-ncard` | `-1.3rem` |
| `$nav-header-h` | `72px` |
| `$container-pt` | `$nav-header-h` |

### Radii

| Token | Value |
|---|---|
| `$border-radius-4` | `.25rem` |
| `$border-radius-8` | `.5rem` |
| `$border-radius` | `.625rem` |
| `$border-radius-16` | `1rem` |
| `$border-radius-pill` | `50rem` |

### Shadows

| Token | Value |
|---|---|
| `$box-shadow-100` | `0 4px 8px rgba(0,0,0,.16)` |
| `$box-shadow-200` | `0 8px 8px rgba(0,0,0,.16)` |
| `$box-shadow-300` | `0 12px 16px rgba(0,0,0,.12)` |
| `$box-shadow-400` | `0 24px 28px rgba(0,0,0,.08)` |
| `$box-shadow` | `0 4px 8px rgba(0,0,0,.12)` |
| `$box-shadow-s` | `0 2px 4px rgba(0,0,0,.12)` |
| `$box-shadow-l` | `0 8px 16px rgba(0,0,0,.16)` |
| `$box-shadow-xl` | `0 12px 16px rgba(0,0,0,.20)` |
| `$box-shadow-focus` | `inset 0 0 0 1px $purple-2` |
| `$box-shadow-valid` | `inset 0 0 0 1px $success-300` |
| `$box-shadow-invalid` | `inset 0 0 0 1px $error-300` |
| `$box-shadow-btn-focus` | `inset 0 0 0 2px $acc-purple-3` |
| `$box-shadow-btn-focus-out` | `0 0 0 .25rem rgba(0,0,0,.16)` |
| `$box-shadow-dropdown` | `0 12px 16px rgba(0,0,0,.20)` |
| `$box-shadow-modal` | `0 12px 16px rgba(0,0,0,.20)` |
| `$box-shadow-toast` | `0 13px 27px -5px rgba(50,50,93,0.25), 0 8px 16px -8px rgba(0,0,0,0.3)` |
| `$box-shadow-card` | `0 7px 13px -3px rgba(0, 0, 0, .07)` |
| `$box-shadow-card-small` | `0 4px 14px 0 rgba(0, 0, 0, .07)` |

### Transitions

| Token | Value |
|---|---|
| `$transition-2` | `all .2s ease-out` |
| `$transition-3` | `all .3s ease-out` |
| `$transition-4` | `all 0.45s cubic-bezier(.65, 0, .076, 1)` |
| `$transition-5` | `all .5s ease-out` |
| `$btn-transition` | `all 0.45s cubic-bezier(.65, 0, .076, 1)` |
| `$btn-transition-acc` | `all 0.8s cubic-bezier(0.65, 0, 0.076, 1)` |

### Special Constants

| Token | Value |
|---|---|
| `$height-commentary` | `280px` |

## CSS Custom Properties

### AG Grid Theme Variables

Primary source: `src/assets/styles/core/_ag-theme.scss`

| Variable | Notes |
|---|---|
| `--ag-theme-active-color` | Main theme accent |
| `--ag-selected-row-background-color` | Selected row background |
| `--ag-row-hover-color` | Row hover color |
| `--ag-column-hover-color` | Column hover color |
| `--ag-input-focus-border-color` | Focus border color |
| `--ag-range-selection-background-color` | Range selection background |
| `--ag-range-selection-background-color-2` | Range selection intensity 2 |
| `--ag-range-selection-background-color-3` | Range selection intensity 3 |
| `--ag-range-selection-background-color-4` | Range selection intensity 4 |
| `--ag-background-color` | Grid background |
| `--ag-foreground-color` | Grid text color |
| `--ag-border-color` | Grid border color |
| `--ag-secondary-border-color` | Secondary border color |
| `--ag-header-background-color` | Header background |
| `--ag-tooltip-background-color` | Tooltip background |
| `--ag-odd-row-background-color` | Odd row background |
| `--ag-control-panel-background-color` | Tool panel background |
| `--ag-subheader-background-color` | Subheader background |
| `--ag-invalid-color` | Validation color |
| `--ag-checkbox-unchecked-color` | Checkbox unchecked color |
| `--ag-advanced-filter-join-pill-color` | Advanced filter join pill |
| `--ag-advanced-filter-column-pill-color` | Advanced filter column pill |
| `--ag-advanced-filter-option-pill-color` | Advanced filter option pill |
| `--ag-advanced-filter-value-pill-color` | Advanced filter value pill |
| `--ag-checkbox-background-color` | Checkbox background |
| `--ag-checkbox-checked-color` | Checkbox checked color |
| `--ag-range-selection-border-color` | Range border color |
| `--ag-secondary-foreground-color` | Secondary text color |
| `--ag-input-border-color` | Input border |
| `--ag-input-border-color-invalid` | Invalid input border |
| `--ag-input-focus-box-shadow` | Focus shadow |
| `--ag-panel-background-color` | Panel background |
| `--ag-menu-background-color` | Menu background |
| `--ag-disabled-foreground-color` | Disabled text color |
| `--ag-chip-background-color` | Chip background |
| `--ag-input-disabled-border-color` | Disabled input border |
| `--ag-input-disabled-background-color` | Disabled input background |
| `--ag-borders` | Border width |
| `--ag-border-radius` | Radius |
| `--ag-borders-side-button` | Side button border |
| `--ag-side-button-selected-background-color` | Selected side button background |
| `--ag-header-column-resize-handle-display` | Resize handle display |
| `--ag-header-column-resize-handle-width` | Resize handle width |
| `--ag-header-column-resize-handle-height` | Resize handle height |
| `--ag-grid-size` | Base spacing unit |
| `--ag-icon-size` | Icon size |
| `--ag-row-height` | Row height |
| `--ag-header-height` | Header height |
| `--ag-list-item-height` | List item height |
| `--ag-column-select-indent-size` | Column tree indent |
| `--ag-set-filter-indent-size` | Set filter indent |
| `--ag-advanced-filter-builder-indent-size` | Builder indent |
| `--ag-cell-horizontal-padding` | Cell horizontal padding |
| `--ag-cell-widget-spacing` | Cell widget spacing |
| `--ag-widget-container-vertical-padding` | Widget vertical padding |
| `--ag-widget-container-horizontal-padding` | Widget horizontal padding |
| `--ag-widget-vertical-spacing` | Widget vertical spacing |
| `--ag-toggle-button-height` | Toggle height |
| `--ag-toggle-button-width` | Toggle width |
| `--ag-font-family` | Grid font family |
| `--ag-font-size` | Grid font size |
| `--ag-icon-font-family` | Grid icon font |
| `--ag-selected-tab-underline-color` | Selected tab underline color |
| `--ag-selected-tab-underline-width` | Selected tab underline width |
| `--ag-selected-tab-underline-transition-speed` | Underline transition |
| `--ag-tab-min-width` | Minimum tab width |
| `--ag-card-shadow` | Card shadow |
| `--ag-popup-shadow` | Popup shadow |
| `--ag-side-bar-panel-width` | Sidebar panel width |
| `--ag-value-change-value-highlight-background-color` | Value-change highlight |
| `--ag-header-font-size` | Header font size |
| `--ag-icon-size-18` | Custom icon size helper |

Component-level AG Grid overrides:

| Variable | Files |
|---|---|
| `--ag-font-size` | `data-security-access-lineage.component.scss`, `data-security-bulk-upload.component.scss`, `data-security-entitlement-upload.component.scss`, `data-security-self-enablement-list.component.scss`, `data-security-se-mapping-button.component.scss` |
| `--ag-theme-active-color` | Same family of data-security pages above |
| `--ag-selected-row-background-color` | Same family of data-security pages above |

### Bootstrap Overrides

| Variable | Files |
|---|---|
| `--bs-dropdown-divider-bg` | `src/assets/styles/core/_bootstrap.scss` |
| `--bs-dropdown-divider-margin-y` | `src/assets/styles/core/_bootstrap.scss` |
| `--bs-btn-disabled-border-color` | `access-modal.component.scss`, `mass-copy-modal.component.scss`, `mass-refresh-modal.component.scss`, `ttl-extension-modal.component.scss`, `dropdown-select-autocomplete.component.scss`, `google-projects-v2.component.scss` |
| `--bs-accordion-bg` | `dw-accordeon.component.scss`, `accordion-group.component.scss`, `accordion-stage.component.scss` |
| `--bs-accordion-color` | `dw-accordeon.component.scss`, `accordion-group.component.scss`, `accordion-stage.component.scss` |
| `--bs-accordion-border-color` | `dw-accordeon.component.scss`, `accordion-group.component.scss`, `accordion-stage.component.scss` |
| `--bs-accordion-btn-bg` | `dw-accordeon.component.scss`, `accordion-group.component.scss`, `accordion-stage.component.scss` |
| `--bs-accordion-active-bg` | `dw-accordeon.component.scss`, `accordion-group.component.scss`, `accordion-stage.component.scss` |
| `--bs-accordion-active-color` | `dw-accordeon.component.scss`, `accordion-group.component.scss`, `accordion-stage.component.scss` |
| `--bs-accordion-body-padding-x` | `dw-accordeon.component.scss`, `accordion-group.component.scss`, `accordion-stage.component.scss` |
| `--bs-accordion-transition` | `accordion-stage.component.scss` |
| `--bs-accordion-button-active-icon` | `accordion-stage.component.scss` |
| `--bs-accordion-button-icon` | `accordion-stage.component.scss` |

### Angular Material Overrides

| Variable | Files |
|---|---|
| `--mat-option-label-text-font` | `src/assets/styles/components/_materialTheme.scss` |
| `--mat-sys-label-large-font` | `src/assets/styles/components/_materialTheme.scss` |
| `--mat-chip-container-height` | `chip.answers.component.scss` |
| `--mat-chip-container-shape-radius` | `chip.answers.component.scss` |
| `--mat-chip-outline-width` | `chip.answers.component.scss` |
| `--mat-chip-outline-color` | `chip.answers.component.scss` |
| `--mat-chip-elevated-container-color` | `chip.answers.component.scss` |
| `--mat-chip-label-text-color` | `chip.answers.component.scss` |
| `--mat-chip-label-text-font` | `chip.answers.component.scss` |
| `--mat-chip-label-text-line-height` | `chip.answers.component.scss` |
| `--mat-chip-label-text-size` | `chip.answers.component.scss` |
| `--mat-chip-label-text-tracking` | `chip.answers.component.scss` |
| `--mat-chip-label-text-weight` | `chip.answers.component.scss` |
| `--mat-datepicker-calendar-date-selected-state-background-color` | `admin-ttl-extensions-filter.component.scss` |
| `--mdc-outlined-text-field-focus-outline-color` | `admin-ttl-extensions-filter.component.scss` |
| `--mdc-outlined-text-field-focus-label-text-color` | `admin-ttl-extensions-filter.component.scss` |

### Component-Local Custom Properties

| Variable | Files |
|---|---|
| `--left-padding-container` | `discovery-wizard-page.component.scss` |
| `--right-padding-container` | `discovery-wizard-page.component.scss` |
| `--badge-top-offset` | `header.new.component.scss` |
| `--size` | `upload-documentation.component.scss` |
| `--value` | `upload-documentation.component.scss` |
| `--fg` | `upload-documentation.component.scss` |
| `--bg` | `upload-documentation.component.scss` |

## Notes and Traps

| Item | Why it matters |
|---|---|
| `$secondary-red` is declared twice | The second declaration (`#D62F00`) wins and becomes the effective value |
| `$blue` aliases `$secondary-blue` | Prefer the alias only when the semantic meaning is blue, not brand-primary |
| `$container-pt` aliases `$nav-header-h` | Header height changes affect global top padding |
| Many `--bs-*` and `--mat-*` variables are local overrides | Do not assume they are globally available outside their component scope |
| `--ag-*` variables are theme-driven | Prefer setting them in the AG Grid theme file before overriding per-page |
