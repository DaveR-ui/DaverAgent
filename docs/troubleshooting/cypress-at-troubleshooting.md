---
last_updated: 2026-05-28
description: troubleshooting guide for recurring Cypress automated test failures in this repository, with fast triage checks and stable fix patterns
tags: [cypress, automated-tests, at, e2e, troubleshooting, tooltip, overlay, selectors, mocking, toast]
---

# Cypress / AT Troubleshooting

## Path & Overview
- Scope: recurring E2E / AT failures in this repository.
- Primary targets:
  - `cypress/support/step_definitions/**`
  - `cypress/support/utils/**`
  - component templates that expose stable `data-cy` or accessibility text
  - `mocks/mock-routes.json`, `mocks/middleware.js`, `mocks/data.json`
- Use this doc when tests fail only in Cypress, a tooltip is visible in screenshots but assertions fail, selectors drift after local UI changes, or mocked endpoints look correct but return empty data.

## Fast Commands

```powershell
npx cypress run --config-file cypress.config.ts --config video=false --spec "cypress/e2e/features/release5/990612-dsp-cloud-management-resouces-tooltips-addition.feature"
```

```powershell
npm run test:api
```

```powershell
npm run mock:local
```

## Fast Triage

| If you observe... | First suspicion | Cheapest check |
|---|---|---|
| Tooltip is visible in screenshot but Cypress says it does not exist | Tooltip content is rendered outside the host DOM or in a different implementation than the step assumes | Inspect screenshot + query the real overlay container or visible tooltip root |
| Step finds the icon but not the text | Selector points to the host icon `data-cy`, not the rendered panel text | Check whether `tooltipDataCy` is on the panel or only on the trigger |
| Some tooltips open and others do not | Same step is hitting multiple component implementations | Compare dropdown, typeahead, and plain field templates before changing the step |
| Assertion fails only because of spaces / line breaks | Tooltip/Toast content contains `&nbsp;`, line breaks, or template formatting | Normalize whitespace before comparing text |
| Toast shown but selector fails or returns multiple | Multiple toasts in DOM or different host (`router-events` vs `feature-inline`) | Use `.filter(':visible').last()` and check the specific feature toast host |
| Test fails after local markup changes with unchanged behavior | Cypress step relies on sibling/parent structure instead of ownership boundary | Move the query to the real container/trigger pair |
| Mocked endpoint returns empty array unexpectedly | json-server middleware is turning request body into query filtering | Check `mocks/middleware.js` and confirm `req.query = {}` for rewritten POST/PUT/DELETE |
| Route looks right but mock returns 404 | Wildcard depth in `mock-routes.json` is wrong | Match the full segment depth; `*` only matches one segment |

## Standard Debug Flow
1. Reproduce with the narrowest `--spec` possible.
2. Read the failing step definition before reading the whole feature.
3. Compare the queried selector against the current component template, not against historical assumptions.
4. Use the screenshot to answer one question: did the UI fail, or did the selector fail?
5. Prefer a small step-definition repair first when the UI is visibly correct.
6. If multiple implementations feed the same step, document the differences and give the step a stable fallback.

## Recurring Failure Patterns

### 1. Tooltip visible, Cypress says missing
- **Typical symptom**: screenshot clearly shows the tooltip, but Cypress fails on `.tooltip-inner`, `.app-tooltip-panel`, or a host `data-cy`.
- **Root cause**:
  - `AppTooltipDirective` mounts into CDK overlay, not under the host node.
  - Some screens still expose Bootstrap/ng-bootstrap tooltip markup.
  - Some steps accidentally assert the icon text (`info`) instead of the rendered tooltip text.
- **Standard pattern**:
  - Open the tooltip with `mouseenter` on the real trigger.
  - Query the visible tooltip content, not just the trigger.
  - If the popup is not queryable in Cypress, fall back to accessibility text already present in the label.
- **Good checks**:
  - `.cdk-overlay-container`
  - `.app-tooltip-panel`
  - `.tooltip-inner`
  - `.visually-hidden` text in the owning label

### 2. Host `data-cy` and panel `data-cy` are different elements
- **Typical symptom**: step queries `[data-cy="..."]` and gets the icon instead of the tooltip body.
- **Root cause**: `tooltipDataCy` belongs to the rendered panel, while another `data-cy` identifies the host or field label.
- **Standard pattern**:
  - Treat host and panel as separate contracts.
  - In steps, locate the visible host first, then find the real trigger inside that host before hovering or focusing.
  - Common wrappers in this repo are `legend`, `label`, and field containers that own an inner `<i>` tooltip trigger.
  - Use `.filter(':visible')` on the host query before traversing to the trigger when multiple matching sections can be rendered.
  - Do not assume the same selector identifies both.

### 3. One generic step serves multiple component families
- **Typical symptom**: dropdown tooltips pass, typeahead tooltips fail, or plain field tooltips behave differently.
- **Root cause**: the shared step assumes one DOM relationship like `siblings()` or one tooltip renderer.
- **Standard pattern**:
  - Split lookup strategy by ownership boundary:
    - plain field tooltip icon
    - dropdown tooltip trigger inside dropdown container
    - typeahead tooltip trigger inside typeahead label container
  - Keep one shared text-normalization helper if content comparison is the same.

### 4. Tooltip text mismatch caused by formatting only
- **Typical symptom**: expected text and visible text look identical to a person, but Cypress fails.
- **Root cause**: non-breaking spaces, line breaks, or HTML template formatting.
- **Standard pattern**:
  - Normalize text before comparing.

```typescript
const normalizeTooltipText = (value: string) =>
  value.replace(/\u00a0/g, ' ').replace(/\s+/g, ' ').trim();
```

### 5. UI behavior is correct, but popup is still unstable to query
- **Typical symptom**: screenshot proves correct behavior, but popup node is transient or browser-managed.
- **Root cause**: Cypress is racing the popup lifecycle or the rendered node is not stable enough for repeated queries.
- **Standard pattern**:
  - Mirror the tooltip text into accessible `.visually-hidden` label text.
  - Use popup assertion first when stable.
  - Fall back to the inline accessibility text when the popup itself is not queryable.
- **Why this is acceptable**:
  - It improves accessibility.
  - It keeps the semantic contract close to the owning field.
  - It avoids brittle timing-only fixes.

### 6. Toast visibility, multiple hosts, and whitespace
- **Typical symptom**: toast is visible in screenshot, but `[data-cy="app-router-events-toast-message"]` fails or returns multiple elements.
- **Root cause**:
  - **Shared Host Overlap**: `app-router-events-toast-message` can hold multiple nodes; assertions for "the current toast" should use `.filter(':visible').last()`.
  - **Host Divergence**: Some features (e.g., `demand-details`) use an inline host like `app-create-demand-page-toast` instead of the global router-events host.
  - **Triage Lesson**: If `PUT/GET` succeeded but no toast element appears, separate selector/host contract issues from runtime emission issues.
- **Standard pattern**:
  - Always use `visible-last` pattern: `cy.get('[data-cy="..."]').filter(':visible').last()`.
  - **Normalization**: Use `replace(/\u00a0/g, ' ').replace(/\s+/g, ' ').trim()` to handle NBSP and template breaks.
  - **Step Fallback**: Shared Cypress steps should prefer the global host but fall back to known feature-specific hosts if needed.
- **Validated Case**:
  - `demand-details.feature` passed after implementing host fallbacks and aligning assertion text with the runtime owner (`The demand <b>...</b> has been updated`).

## Validated Tooltip Pattern From This Repo

### What was validated
- Dynamic form tooltips can come from more than one implementation on the same screen.
- Access modal / cloud access tooltip assertions were stable when querying the current host trigger and normalizing text.
- Dynamic-form metadata tooltips became stable after exposing the same tooltip content in `.visually-hidden` label text and using that as a fallback.

### Stable rule set
- `AppTooltipDirective` overlays should be queried via overlay container when the panel exists there.
- If a host `data-cy` points to a wrapper instead of the icon, resolve the inner visible trigger before firing `mouseenter` or `focus`.
- Do not use `siblings()` unless the component template guarantees the relationship.
- For reusable form controls, keep tooltip meaning mirrored in label accessibility text.
- For Cypress text assertions, normalize whitespace before comparison.

## Mock / Route Failure Patterns

### Empty API data with apparently correct mocks
- **Likely cause**: middleware copied request body to `req.query`, causing json-server array filtering.
- **Fix**: clear query params in the rewrite path.
- **Reference**: `json-server-mocking.md`

### 404 on route that looks almost correct
- **Likely cause**: wildcard depth mismatch in `mock-routes.json`.
- **Fix**: match the full URL depth explicitly.
- **Reference**: `json-server-mocking.md`

## Known Anti-Patterns (AVOID)

| Anti-Pattern | Why it breaks |
|---|---|
| Querying tooltip text only under the host component tree | Overlay tooltips are rendered elsewhere |
| Asserting the icon `data-cy` as if it were the panel | Host and rendered panel are separate elements |
| Reusing one DOM traversal like `siblings('i[role="tooltip"]')` across all control types | Dropdown, field, and typeahead markup differ |
| Fixing tooltip flakes with waits only | Hides selector mistakes and keeps tests unstable |
| Comparing tooltip strings without whitespace normalization | Template formatting causes false negatives |
| Using screenshots as the only proof of selector correctness | Screenshot proves UI behavior, not DOM contract |

## Standard Pattern (USE)

### Step-definition strategy
- Find the smallest owning container for the trigger.
- Trigger hover/focus on the icon actually responsible for opening the tooltip.
- Assert text in the rendered panel if it is stable.
- Fall back to `.visually-hidden` accessibility text only when the popup itself is not queryable.

### Component-template strategy
- Keep stable `data-cy` contracts on host controls.
- When tooltip text is important to business behavior, mirror it in accessible inline text close to the label.
- Prefer improving accessibility and testability together instead of adding Cypress-only markup.

## Common Checks Before Editing
1. Is the failing selector targeting the trigger, the panel, or the field label?
2. Is the tooltip rendered by CDK overlay, Bootstrap/ng-bootstrap, or browser-native behavior?
3. Does the current component still match the DOM traversal used in the step?
4. Is the mismatch real behavior or only query behavior?
5. Can the same semantic text be exposed in accessible inline markup for a stable fallback?

## Common Documentation Lookups
- Tooltip implementation: `special-components/tooltip.md`
- Mock routing / json-server: `json-server-mocking.md`
- TestBed-only flakes: `troubleshooting/testbed-cross-suite-flaky-tests.md`
