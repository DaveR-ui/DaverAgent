---
last_updated: 2026-05-02
description: Technical implementation guide for the SafeGuard design system in Angular/Tailwind.
tags: [implementation, tailwind, sass, technical]
---

# 🛠️ Implementation Guide

## Architecture

The system uses a **Hybrid Approach** to bridge the gap between Tailwind CSS v4 and Sass (for Angular Material).

1.  **Tailwind Config (`src/tailwind.css`)**: Pure CSS file containing `@import "tailwindcss"` and the `@theme` block. This is processed by the Tailwind engine.
2.  **Global Styles (`src/styles.scss`)**: Sass file containing Angular Material integration and legacy variable mapping.
3.  **Global SSOT (`DESIGN.md`)**: Root file following the `google-labs-code/design.md` spec.

## Standard Patterns

### Using Colors
Always use Tailwind utilities or the mapped CSS variables. **PROHIBITED: Hex codes in components.**

```html
<!-- USE THIS -->
<div class="bg-primary text-neutral-50 p-md rounded-md"> ... </div>

<!-- OR THIS (In SCSS) -->
.custom-card {
  background-color: var(--color-primary);
}
```

### Typography
Headings (`h1-h6`) are automatically styled with the **Outfit** font and the correct weight. Body text uses **Inter**.

### Integration with Angular Material
The Angular Material theme is synchronized with SafeGuard.
- `Primary` maps to `mat.$red-palette` (SafeGuard Primary).
- `Tertiary` maps to `mat.$slate-palette` (SafeGuard Secondary).

## Critical Safeguards
> [!IMPORTANT]
> To modify the theme, update `DESIGN.md` first, then replicate changes in `src/tailwind.css` (@theme block).

> [!CAUTION]
> Do NOT use Tailwind `@theme` directives inside `.scss` files, as they will cause Sass compilation errors. Use `src/tailwind.css` instead.
