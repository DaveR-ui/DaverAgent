---
last_updated: 2026-05-27
description: entry point for agent documentation, including component lookup and troubleshooting references
tags: [agents, documentation, angular, testing, troubleshooting]
status: ACTIVE
---

# Agent Documentation System

> 🚨 **CRITICAL ADVISORY** 🚨
> **DO NOT mimic existing `src/` patterns.** The codebase has legacy anti-patterns being refactored.
> **Rule 1:** Documentation in `.github/` always overrides what exists in `src/`. Follow docs, not code.
> **Rule 2:** Only code examples found in `.github/` documentation are valid implementation references. Never copy patterns from `src/`.

## 🚀 CRITICAL WORKFLOW

Before any change:

1. Find the component in the **Component Map** below → read its Primary Doc
2. Check for `(CRITICAL)` sections in that doc
3. Implement using documented patterns

## 📋 Component-to-Documentation Map

| Component                           | Primary Doc                                      | Secondary Docs                                                                               | Key Issues Fixed                               |
| ----------------------------------- | ------------------------------------------------ | -------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| `access-modal.component.ts/html`    | `simple-features/access-modal.md`                | `angular-reactivity/resource-api.md`, `workflows/access-modal-cross-env-spec.md` (PROPOSED), `simple-features/cloud-resource-manage-access.md` | Resource error state and project refresh rules |
| `access-selector.component.ts/html` | `simple-features/access-modal.md`                | `angular-reactivity/resource-api.md`, `special-components/dropdown-components.md`, `simple-features/cloud-resource-manage-access.md` | Signals migration and role filtering rules |
| Cloud Resource Manage Access        | `simple-features/cloud-resource-manage-access.md`| `simple-features/access-modal.md`, `../agent-workflows/removing-ngrx-store.md`             | Role filtering (8, 22, 23, 35) and NgRx cleanup |
| `access-confirm-modal.ts/html`      | `special-components/confirmation-modal.md`       | `simple-features/access-modal.md`                                                            | Shared requestor/comment approval step         |
| Modal Service + Component (generic) | `modal-creation.md`                              | -                                                                                            | Signal-based service, direct vs effect         |
| AG Grid Implementation              | `aggrid/ag-grid-implementation.md` | `../skills/ag-grid-standard/SKILL.md`, `aggrid/troubleshooting/ag-grid-errors.md` | Standard grid patterns & sub-tables            |
| Global style tokens / CSS variables | `style-tokens.md`                                | `coding-conventions.md`                                                                     | Central token index and runtime CSS variable map |
| Cross-environment access modal      | `workflows/access-modal-cross-env-spec.md`       | `simple-features/access-modal.md`, `angular-reactivity/index.md`                             | Future: Cross-project blocking (PROPOSED)      |
| Reactive HTTP data loading          | `angular-reactivity/resource-api.md`             | `angular-reactivity/testing.md`, `project-rules.md`                                               | `rxResource` standard, resource error handling |
| Security permissions / role gates  | `security-permissions.md`                        | `launchdarkly-flags.md`, `simple-features/access-modal.md`                                        | Raw selector contract, `Access_AdminAdministration`, `Role_Support` |
| User identity / profile data       | `identity-user-data.md`                          | `security-permissions.md`, `troubleshooting/auth-relogin-race-condition.md`                      | Logged-in user claims, store, profile API, photo sources |
| Dropdown components (all 6)         | `special-components/dropdown-components.md`      | `angular-reactivity/resource-api.md`                                                         | 6 variants, selection guide (Feb 3)            |
| Dropdown single-select              | `special-components/dropdown-components.md`      | `dropdown-select-remaster`, `dropdown-select-autocomplete` components                        | Modern signals-based single-select             |
| Dropdown multi-select               | `special-components/dropdown-components.md`      | `dropdown-multi-select`, `input-search-dropdown-multi-select` components                     | Legacy multi-select (no modern alt)            |
| Dropdown autocomplete/search        | `special-components/dropdown-components.md`      | `dropdown-select-autocomplete` component                                                     | Custom HTML (NOT Material)                     |
| Tooltip directive + panel           | `special-components/tooltip.md`                  | `angular-reactivity/index.md`, `project-rules.md`                                            | Signal inputs, string vs template content      |
| Dropdown with async data            | `simple-features/access-modal.md`                | `angular-reactivity/resource-api.md`, `special-components/dropdown-components.md`            | Value binding & protection                     |
| Signal computeds                    | `angular-reactivity/resource-api.md`             | Component-specific file                                                                      | Error state handling                           |
| Feature flags                       | `launchdarkly-flags.md`                          | `project-rules.md`                                                                                | Flag naming conventions                        |
| Vitest Tests                        | `vitest.md`                                      | -                                                                                            | Path aliases, Jasmine vs Vitest                |
| Jasmine rxResource Tests            | `angular-reactivity/testing.md`                  | `../skills/angular-testing/references/testing-patterns.md`, `../skills/jasmine-test-standard/SKILL.md` | TestBed.flushEffects timing (Jan 27)           |
| Jasmine/Karma TestBed flakiness     | `troubleshooting/testbed-cross-suite-flaky-tests.md` | `../skills/jasmine-test-standard/SKILL.md`                             | Combined-run `ngModule/ɵcmp` flaky failures, inject() override, ViewChild modal mocking, logic-only `runInInjectionContext()` specs, provider-only teardown order for `afterAll`/disconnect issues |
| Circular dependency CoreModule ↔ ProjectDetailsPage | `troubleshooting/circular-dependency-core-module.md` | `troubleshooting/common-errors.md`, `troubleshooting/testbed-cross-suite-flaky-tests.md` | Module initialization order, shared interfaces in domain files, 50+ spec failures fixed (2026-05-30) |
| Cypress / AT troubleshooting        | `troubleshooting/cypress-at-troubleshooting.md` | `special-components/tooltip.md`, `json-server-mocking.md` | Overlay tooltip assertions, selector drift, whitespace normalization, mock-route triage |
| admin-resources-cell-render spec   | `troubleshooting/testbed-cross-suite-flaky-tests.md` | `aggrid/ag-grid-implementation.md`                                                            | ViewChild modal mocking + TestBed reset ordering |
| documentation-list / cloud-resources specs | `troubleshooting/testbed-cross-suite-flaky-tests.md` | `../skills/angular-testing/references/testing-patterns.md`                                      | Provider-only TestBed + `runInInjectionContext()` when `ɵcmp` persists after template isolation |
| ngModelGroup Components             | `angular-reactivity/testing.md`                  | `../skills/angular-testing/references/testing-patterns.md`                                      | ControlContainer mocking to avoid NG01353      |
| Form Validators                     | `project-rules.md#validations`                        | -                                                                                            | Manual error feedback in HTML                  |
| Authview Wizard                     | `authviews/wizard-logic.md`                      | `authviews/improvements.md`, `authviews/api-endpoints.md`                                    | Edit vs Create flow, State leaks               |
| Component-Scoped Services           | `service-management.md`                          | -                                                                                            | Dependencies missing providers                 |
| Mocking (json-server, mock-routes)  | `json-server-mocking.md`                         | -                                                                                            | Empty mocking arrays, missing routes           |
| SDD Architecture Standards          | `architecture-standards/index.md`                | `architecture.md`, `coding-conventions.md`, `project-rules.md`                               | Offline standard summaries and local architecture guidance |


## 🚫 Standards & Anti-Patterns

See [project-rules.md](project-rules.md) for the full anti-patterns table, operational guardrails, and coding standards.

For the SDD agent's local architecture rules, see [architecture-standards/index.md](architecture-standards/index.md).

## 📝 Undocumented Components

If a component is not in the Component Map:

1. Search this folder for applicable docs
2. If none found, create a new doc following [project-rules.md](project-rules.md) standards (component path, purpose, data flow, known anti-patterns, standard pattern)
3. Add an entry to the Component Map above

## 🆘 Common Documentation Lookups

**"I'm getting 'Resource is currently in an error state'"**
→ See: [testing.md](angular-reactivity/testing.md#critical-error-state-handling-in-effects)

**"How do I handle resource errors in templates?"**
→ See: [resource-api.md](angular-reactivity/resource-api.md#resource-template-structure-required)

**"How do I test rxResource in Jasmine/Karma?"**
→ See: [testing.md](angular-reactivity/testing.md) + [testing-patterns.md](../skills/angular-testing/references/testing-patterns.md#testing-rxresource-and-signals)

**"How do I sync a dropdown with async data?"**
→ See: [access-modal.md](simple-features/access-modal.md) + [resource-api.md](angular-reactivity/resource-api.md#linkedsignal--selection-synchronization)

**"What's the correct pattern for computed() with rxResource?"**
→ See: [resource-api.md](angular-reactivity/resource-api.md#computed--derived-state)

**"How do I consume security permissions without hardcoding pipes into the selector docs?"**
→ See: [security-permissions.md](security-permissions.md)

**"How do I get the logged-in user's name, EID, UPN, or photo?"**
→ See: [identity-user-data.md](identity-user-data.md)

**"My rxResource test is failing with timing issues"**
→ See: [testing.md](angular-reactivity/testing.md#critical-testbedflusheffects-timing) + [testing-patterns.md](../skills/angular-testing/references/testing-patterns.md#testing-rxresource-with-jasmine)

**"Where is the Model Selection Policy?"**
→ See: [agent-contracts.md](../agent-workflows/agent-contracts.md#model-selection-policy)

**"Getting NG01353 error with ngModelGroup"**
→ See: [testing-patterns.md](../skills/angular-testing/references/testing-patterns.md#controlcontainer-mocking-for-ngmodelgroup)

**"TypeError: Cannot read properties of undefined (reading 'ɵcmp')"**
→ See: [common-errors.md](troubleshooting/common-errors.md#typeerror-cannot-read-properties-of-undefined-reading-ɵcmp)

**"TypeError: Cannot read properties of undefined (reading 'ngModule')"**
→ See: [circular-dependency-core-module.md](troubleshooting/circular-dependency-core-module.md) (NEW - 2026-05-30)

**"Multiple specs fail with 'Error loading' in Karma but pass individually"**
→ See: [circular-dependency-core-module.md](troubleshooting/circular-dependency-core-module.md) (NEW - 2026-05-30)

**"My spec still throws `ɵcmp` after `resetTestingModule()` and `overrideComponent(...)`"**
→ See: [testbed-cross-suite-flaky-tests.md](troubleshooting/testbed-cross-suite-flaky-tests.md#root-cause-7-logic-only-spec-still-compiles-a-broken-standalone-import-graph)

**"The tooltip is visible in the screenshot, but Cypress says it cannot find it"**
→ See: [cypress-at-troubleshooting.md](troubleshooting/cypress-at-troubleshooting.md#1-tooltip-visible-cypress-says-missing)

**"My AT fails after local selector/markup changes"**
→ See: [cypress-at-troubleshooting.md](troubleshooting/cypress-at-troubleshooting.md)