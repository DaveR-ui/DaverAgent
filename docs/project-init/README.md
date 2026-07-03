# Project Init Annotations

> Experiential annotations from the **ab-ceramica** initialization process (Angular 21 SSR ceramics gallery, July 2026). These capture practical lessons, gotchas, and shortcuts — **NOT** reference documentation.

---

## What this folder is

This folder contains annotations written *after* completing a full opencode agent system initialization on a greenfield Angular 21 SSR project. The goal: make the next initialization smoother.

These are **experiential** docs — they describe what went wrong, what was confusing, what would have saved time. They do **not** duplicate the API reference docs that already exist in:

- `.opencode/docs/angular/` — Angular framework reference
- `.opencode/docs/opencode/` — Opencode runtime reference
- `.opencode/docs/vscode/` — VSCode reference

If you need the *spec*, read those. If you need the *practical shortcut*, read these.

---

## File index

| # | File | One-line description |
|---|------|---------------------|
| 01 | [`01-before-you-start.md`](./01-before-you-start.md) | Things to know before starting any initialization process |
| 02 | [`02-session-bootstrap.md`](./02-session-bootstrap.md) | Session manager, bootstrap, and sync gotchas |
| 03 | [`03-project-entry-point.md`](./03-project-entry-point.md) | `docs/project.md` as source of truth, `conventions.md`, Slices table |
| 04 | [`04-prompt-pipeline.md`](./04-prompt-pipeline.md) | canonical-prompter → context-reductor → slice-complexity-ladder pipeline |
| 05 | [`05-ladder-routing.md`](./05-ladder-routing.md) | Slice complexity ladder rung selection and routing |
| 06 | [`06-orchestrator-handoff.md`](./06-orchestrator-handoff.md) | How to structure the orchestrator handoff and what to expect back |
| 07 | [`07-angular-cli-mcp-tools.md`](./07-angular-cli-mcp-tools.md) | When and how to use the Angular CLI MCP tools |
| 08 | [`08-web-fetching-strategy.md`](./08-web-fetching-strategy.md) | `webfetch` limitations and workarounds for reference material |
| 09 | [`09-material-theming-gotchas.md`](./09-material-theming-gotchas.md) | Angular Material 21 theming pitfalls and customization |
| 10 | [`10-design-md-spec-quickref.md`](./10-design-md-spec-quickref.md) | `DESIGN.md` format spec quick reference |
| 11 | [`11-model-routing-and-language.md`](./11-model-routing-and-language.md) | Model routing, context budget, and language protocol |

---

## When to read these

- **Before starting a new project initialization** — read 01 and 02 first.
- **When onboarding a new agent** — read 01, 03, and 04.
- **When the process feels slow or confusing** — jump to the relevant file's `## Gotchas` section.
- **When a step fails unexpectedly** — check the `## Gotchas` section of the file covering that step.
- **When routing a prompt** — read 04 and 05 together.
- **When handing off to the orchestrator** — read 06.

---

## Scope note

These annotations were captured during the **ab-ceramica** init (July 2026) but apply generally to any opencode project initialization. Project-specific details (Angular 21, Material 21, SSR) are marked as such; the structural and process lessons are universal.

---

## Related documentation

| Path | What it covers |
|------|----------------|
| [`.opencode/protocols/README.md`](../../protocols/README.md) | Index of all agent protocols (canonical-prompter, context-reductor, interruption, etc.) |
| [`.opencode/docs/angular/`](../angular/) | Angular framework reference docs |
| [`.opencode/docs/opencode/`](../opencode/) | Opencode runtime reference docs |
| [`.opencode/docs/vscode/`](../vscode/) | VSCode reference docs |
| [`.opencode/conventions.md`](../../conventions.md) | Canonical project doc paths (project entry point, context dir, rules file) |
| [`.opencode/llm-routing.md`](../../llm-routing.md) | Model selection policy and context budget rules |
| [`.opencode/session-structure.md`](../../session-structure.md) | Opencode home layout (`~/.config/opencode/`) |