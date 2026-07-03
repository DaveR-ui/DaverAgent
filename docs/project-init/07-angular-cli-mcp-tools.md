# 07 — Angular CLI MCP Tools

> Experiential annotations on when and how to use the Angular CLI MCP tools. These are RAG (Retrieval-Augmented Generation) sources — they provide ground-truth information, not web searches. For API reference docs, see `.opencode/docs/angular/`.

---

## Tool Overview

| Tool | When to use |
|---|---|
| `angular-cli_list_projects` | FIRST step for any project-specific action |
| `angular-cli_get_best_practices` | MANDATORY before writing/modifying any Angular code |
| `angular-cli_find_examples` | For MODERN / NEW / recently updated features |
| `angular-cli_search_documentation` | For established features and concept questions |
| `angular-cli_onpush_zoneless_migration` | Step-by-step OnPush migration (iterative) |

---

## angular-cli_list_projects

**Use first** for any project-specific action. Returns: project names, types, root, sourceRoot, unitTestFramework, styleLanguage, selectorPrefix, frameworkVersion, builder.

- Get the `workspacePath` (absolute path to `angular.json`) from here — every other tool needs it for version-specific results.
- If `unitTestFramework` is `"unknown"`, inspect `karma.conf.js` / `jest.config.js` / `angular.json` test target before generating tests.
- `frameworkVersion` gives the major version — use it for `search_documentation`.

---

## angular-cli_get_best_practices

**MANDATORY first step** before writing or modifying any Angular code. Returns the official best practices guide for the project's version.

Key rules it enforces (Angular 21):
- Standalone components — no `standalone: true` (it's the default in v20+).
- Signals for state; `OnPush` change detection.
- Native control flow: `@if` / `@for` / `@switch` — no `*ngIf` / `*ngFor`.
- `inject()` over constructor injection.
- `input()` / `output()` — no `@Input()` / `@Output()` decorators.
- `NgOptimizedImage` for images.
- No `ngClass` / `ngStyle` — use class/style bindings.
- No `@HostBinding` / `@HostListener` — use the `host` object.
- Reactive forms over template-driven.
- WCAG AA + AXE compliance.

**Provide `workspacePath`** for the version-specific guide. Returns the SAME content every time for a given version — cache it mentally, don't call repeatedly.

---

## angular-cli_find_examples

For **MODERN / NEW / recently updated** Angular features (e.g., signal inputs, deferrable views, functional guards).

- Uses **FTS5 full-text search**: AND is default, `OR` operator, `NOT`, phrase with `"quotes"`, prefix with `*`.
- **Provide `workspacePath`** for version-specific examples.
- The database is **curated for new features only** — for established features, use `search_documentation` instead.
- Set `includeExperimental=true` ONLY if the user asks for bleeding-edge OR no stable solution exists. If you do, **MUST warn the user** that the example uses experimental APIs not suitable for production.

---

## angular-cli_search_documentation

Searches **angular.dev** for concepts, APIs, and tutorials.

- Determine the version from `list_projects` (`frameworkVersion` field) or `ng version` (parse the "Angular:" line).
- The tool **clamps to v17 minimum** and **falls back to v20** if a newer version returns nothing.
- **ALWAYS check the `searchedVersion` field** in the output — it tells you the exact docs version queried.
- The top result includes a content snippet, but the top result is NOT always the most relevant — review other results' titles and breadcrumbs.

---

## angular-cli_onpush_zoneless_migration

Analyzes code and provides a **step-by-step migration plan** to `OnPush` (a prerequisite for zoneless).

- **Does NOT modify code** — it provides INSTRUCTIONS for a single action at a time.
- Call repeatedly, apply the suggested fix after each call, until the tool indicates no more actions are needed.
- This is the specialized starting point for zoneless/OnPush migration. For other migrations (e.g., signal inputs), use the `modernize` tool first.

---

## Gotchas

- `angular-cli_find_examples` may return **NO results** for common queries — the database is curated for new features only. Don't panic; use `angular-cli_search_documentation` instead.
- `angular-cli_search_documentation` may return **irrelevant top results** — always review other results' titles and breadcrumbs before trusting the first hit.
- The **Material theming docs** (material.angular.dev) are NOT in the `search_documentation` database — they're a separate site. Use `webfetch` with GitHub raw URLs for Material theming content.
- `angular-cli_get_best_practices` returns the **SAME content every time** for a given version — cache it mentally, don't call it repeatedly in the same session.
- On **Windows**, the `workspacePath` should be the absolute path to `angular.json`. Get it from `list_projects` — don't guess.
- These tools are **RAG sources**, not web searches. They return ground-truth information from the official docs/examples database. If they return nothing, the answer may not be in the curated set — fall back to `search_documentation` or `webfetch`.
- `onpush_zoneless_migration` is **iterative** — one call gives one step. Don't expect a full plan in a single response.

---

## Quick Reference

| Tool | workspacePath? | Version? |
|---|---|---|
| `angular-cli_list_projects` | No (returns it) | Returns `frameworkVersion` |
| `angular-cli_get_best_practices` | Yes (recommended) | Version-specific |
| `angular-cli_find_examples` | Yes (recommended) | Version-specific |
| `angular-cli_search_documentation` | No | Pass `version` (major) |
| `angular-cli_onpush_zoneless_migration` | No (takes file/dir path) | N/A |

**Version detection**: `list_projects` → `frameworkVersion` field, or `ng version` → parse "Angular:" line.

**workspacePath**: absolute path to `angular.json` on Windows. Get from `list_projects`.

**Mandatory order**: `list_projects` → `get_best_practices` → then code.

**Cross-reference**: `.opencode/docs/angular/` for API reference docs.