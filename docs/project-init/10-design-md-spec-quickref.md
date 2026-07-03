# 10 — design.md Spec Quick Reference

> Experiential annotations on the design.md format specification from `google-labs-code/design.md` (24.4k stars). Describes visual identity to coding agents.

---

## Format overview

Two layers: **YAML front matter** (machine-readable tokens) + **markdown body** (human-readable rationale, do's and don'ts). The tokens are **normative**; prose provides context. If they conflict, **tokens win**.

---

## YAML schema

| Key | Type | Required |
|---|---|---|
| `version` | string (optional, `"alpha"`) | No |
| `name` | string | Yes |
| `description` | string | No |
| `colors` | `map<string, Color>` | No |
| `typography` | `map<string, Typography>` | No |
| `rounded` | `map<string, Dimension>` | No |
| `spacing` | `map<string, Dimension\|number>` | No |
| `components` | `map<string, map<string, string\|reference>>` | No |

### Primitives

- **Color**: any CSS color (hex `#RRGGBB` recommended, `rgb()`, `oklch()`, named, `color-mix()`). Converted to sRGB for WCAG checking.
- **Typography**: object with `fontFamily`, `fontSize`, `fontWeight` (number), `lineHeight` (Dimension or unitless), `letterSpacing`, `fontFeature`, `fontVariation`.
- **Dimension**: number + unit (`px`, `em`, `rem`).

---

## Token references

Syntax: `{path.to.token}`

- Must point to a **primitive** value (e.g., `{colors.primary}`), not a group.
- In `components` section, references to **composite** values (e.g., `{typography.label-md}`) are permitted.

---

## Canonical section order

Sections **must** appear in this sequence:

1. **Overview** (alias: Brand & Style)
2. **Colors**
3. **Typography**
4. **Layout** (alias: Layout & Spacing)
5. **Elevation & Depth** (alias: Elevation)
6. **Shapes**
7. **Components**
8. **Do's and Don'ts**

---

## Component properties

Available keys: `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, `width`.

Variants are separate entries: `button-primary`, `button-primary-hover`, `button-primary-active`.

---

## Recommended token names

| Category | Names |
|---|---|
| Colors | `primary`, `secondary`, `tertiary`, `neutral`, `surface`, `on-surface`, `error` |
| Typography | `headline-display`, `headline-lg`, `headline-md`, `body-lg`, `body-md`, `body-sm`, `label-lg`, `label-md`, `label-sm` |
| Rounded | `none`, `sm`, `md`, `lg`, `xl`, `full` |

---

## CLI

### Lint

```bash
npx @google/design.md lint DESIGN.md
```

**Windows/PowerShell variant** (the `.md` suffix collides with Markdown file association):

```powershell
npx -p @google/design.md designmd lint DESIGN.md
```

### Export formats

| Format | Output |
|---|---|
| `json-tailwind` | Tailwind v3 `theme.extend` |
| `css-tailwind` | Tailwind v4 `@theme` block |
| `dtcg` | W3C Design Tokens Format |

---

## Linting rules

| Rule | Severity | Description |
|---|---|---|
| `broken-ref` | error | Token reference points to nothing |
| `missing-primary` | warning | No `primary` color defined |
| `contrast-ratio` | warning | WCAG AA 4.5:1 failure |
| `orphaned-tokens` | warning | Token defined but never referenced |
| `token-summary` | info | Summary of all tokens |
| `missing-sections` | info | Canonical section missing |
| `missing-typography` | warning | No typography tokens |
| `section-order` | warning | Sections out of canonical order |
| `unknown-key` | warning | Unknown YAML key |

---

## Gotchas

- **`npm error ENOVERSIONS`** ("No versions available for @google/design.md") means npm is not querying the public registry. Check `npm config get registry` — should be `https://registry.npmjs.org/`.
- **On Windows/PowerShell, `npx @google/design.md lint` may produce no output or open DESIGN.md in an editor.** The `.md` suffix collides with Windows Markdown file association. Use `npx -p @google/design.md designmd lint DESIGN.md` instead.
- **Duplicate section headings are an ERROR** — the file is rejected. Don't repeat `## Colors` etc.
- **Unknown section headings are PRESERVED (not errors).** You can add custom sections like `## Iconography`.
- **Tokens are normative; prose is context.** If they conflict, tokens win. Don't "fix" a token to match prose — fix the prose.
- **Status: version `"alpha"`** — expect breaking changes as the spec matures. Pin the CLI version if reproducibility matters.

---

## Quick Reference

| Item | Value |
|---|---|
| Spec URL | `https://github.com/google-labs-code/design.md/blob/main/docs/spec.md` |
| Examples | `atmospheric-glass`, `paws-and-paths`, `totality-festival` |
| Examples URL | `https://github.com/google-labs-code/design.md/tree/main/examples` |
| Lint (Unix) | `npx @google/design.md lint DESIGN.md` |
| Lint (Windows) | `npx -p @google/design.md designmd lint DESIGN.md` |
| Token reference | `{path.to.token}` |
| Section count | 8 (canonical order) |
| Export formats | `json-tailwind`, `css-tailwind`, `dtcg` |

---

## Cross-references

- `08-web-fetching-strategy.md` — fetching the spec and examples via `raw.githubusercontent.com`.
- `09-material-theming-gotchas.md` — mapping DESIGN.md tokens to `--mat-sys-*` variables.
- `DESIGN.md` (repo root) — AB Ceramica's design.md file.