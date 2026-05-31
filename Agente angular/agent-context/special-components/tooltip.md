---
last_updated: 2026-05-27
status: complete
ai_optimized: yes
tags: [tooltip, overlay, cdk, directive, shared-components, signals]
---

# Tooltip

## Purpose
- `AppTooltipDirective` renders lightweight hover/focus help content using Angular CDK Overlay.
- `AppTooltipPanelComponent` is the visual container attached into the overlay.
- The contract supports both plain text and `TemplateRef` content so callers can choose between a simple hint and richer markup.

## Component Path
- `src/app/shared/components/tooltip/app-tooltip.directive.ts`
- `src/app/shared/components/tooltip/app-tooltip-panel.component.ts`
- `src/app/shared/components/tooltip/app-tooltip-panel.component.html`
- `src/app/shared/components/tooltip/app-tooltip-panel.component.scss`

## Inputs And Outputs

### `AppTooltipDirective` Inputs
- `appTooltip: string | TemplateRef<unknown> | null | undefined`
- Purpose: main tooltip body.
- Use a string for short text.
- Use a `TemplateRef` for line breaks, paragraphs, or richer structure.

- `placement: TooltipPlacement | string`
- Purpose: preferred tooltip position.
- Supported values: `top`, `bottom`, `left`, `right`, `top-start`, `top-end`, `bottom-start`, `bottom-end`, `left-start`, `left-end`, `right-start`, `right-end`.
- Invalid values fall back to `top`.

- `tooltipClass: string`
- Purpose: extra CSS classes forwarded to the panel.
- Common usage: width modifiers such as `tooltip-xl`.

- `openDelay: number | string`
- Purpose: delay before opening in milliseconds.
- Accepts numeric strings because many template bindings come from HTML attributes.

- `tooltipDataCy: string`
- Purpose: optional `data-cy` forwarded to the rendered tooltip panel.
- Use it when e2e tests need to assert tooltip text through a stable selector.

### `AppTooltipDirective` Outputs
- None.
- The directive is display-only and does not emit custom events.

### `AppTooltipPanelComponent` Inputs
- `content: string | TemplateRef<unknown> | undefined`
- Purpose: normalized content passed from the directive.

- `tooltipClass: string`
- Purpose: space-delimited class list applied to the root tooltip panel.

### `AppTooltipPanelComponent` Outputs
- None.

## Data Flow
1. The host element binds `appTooltip` plus optional `placement`, `tooltipClass`, `openDelay`, and `tooltipDataCy`.
2. On `mouseenter` or `focusin`, the directive checks whether there is real content to show.
3. The directive creates a CDK overlay connected to the host element.
4. The directive attaches `AppTooltipPanelComponent` into that overlay.
5. The directive forwards the signal input values into the panel with `componentRef.setInput(...)`.
6. The panel renders either plain text or a `TemplateRef` via `ngTemplateOutlet`.
7. On `mouseleave`, `blur`, or `Escape`, the overlay is disposed.

## Standard Usage Pattern

### Plain Text Tooltip
```html
<i appTooltip="Remove project">info</i>
```

### Rich Tooltip Template
```html
<i [appTooltip]="detailsTooltip" tooltipClass="tooltip-xl">info</i>

<ng-template #detailsTooltip>
  <p>Targeted benefits/business value.</p>
  <p>Please provide a detailed description of the project.</p>
</ng-template>
```

## Why `ngTemplateOutlet` Is Required
- The tooltip API intentionally accepts `TemplateRef` content.
- Real callers already pass templates from forms and shared dropdown components.
- Removing `ngTemplateOutlet` would break every tooltip that relies on structured HTML content.
- The panel therefore must keep a template-only branch and a plain-text branch.

## Standard Pattern
- Use signal inputs for the directive and panel inputs.
- Keep the directive responsible for overlay lifecycle only.
- Keep the panel responsible for rendering only.
- Prefer plain strings when content is short.
- Use `TemplateRef` only when markup is actually needed.
- Keep extra panel styling in `tooltipClass` instead of branching the component logic.

## Known Legacy/Local Anti-Patterns
- Some call sites still mix `ngbTooltip` and `appTooltip` in the broader codebase.
- Some call sites pass attribute-like values such as `container="body"`; that setting is irrelevant for this directive because positioning is handled by CDK Overlay, not ng-bootstrap.
- The directive uses a timer for `openDelay`; keep that behavior localized here instead of duplicating timing logic in callers.

## Guidance For Future Changes
- Do not remove `TemplateRef` support unless every caller is migrated to plain strings.
- If new visual variants are needed, prefer CSS classes over new boolean inputs.
- If accessibility behavior changes, keep keyboard close support and host-focus support.
- If a future API needs events, add signal outputs deliberately and document the event contract here.

## Testing Strategy
- Verify that empty strings and nullish values do not open the overlay.
- Verify that string content renders as text.
- Verify that `TemplateRef` content renders through `ngTemplateOutlet`.
- Verify placement fallback for invalid values.
- Verify hide behavior on mouse leave, blur, and `Escape`.
- For form controls that depend on tooltip copy as user guidance, prefer mirroring the same meaning in nearby accessible inline text (`.visually-hidden`) so Cypress and assistive tech have a stable fallback when the visible popup is transient or rendered by a different tooltip implementation.
