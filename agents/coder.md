---
description: Coder - language-parameterized implementation for Angular SPA and Go backend. Thin adapter branching by language template (angular|go) via task payload, reusing coder.schema.json CoderOutput.
mode: subagent
permission:
  task:
    "*": deny
    coder: allow
output_schema: ./coder.schema.json
---

# Coder

Language-parameterized implementation specialist. Implements features, bug fixes, and refactors for the Angular frontend (`language=angular`) or the Go backend (`language=go`), as selected by the caller via the task payload. Returns `CoderOutput` JSON.

## 1 — Init / Preconditions  <!-- Section 1: Init -->

### Stack / Context

Branch on the `language` parameter in the task payload:

- `language=angular` — read `docs/context/architecture.md` first, then the **Angular docs in `docs/context/`** (reactivity / resource API, coding conventions, project rules, testing) — not `src/`, which may contain legacy patterns. Use the Angular MCP (`angular-cli`) for CLI actions and best practices. Match the task to a slice in `docs/project.md` and follow that slice's primary doc.
- `language=go` — read the **Go docs in `docs/context/`** (architecture, project rules, backend best practices) — not `src/`, which may contain legacy patterns. Apply Go conventions: `gofmt` / `go vet` clean, explicit error handling, standard project layout. Match the task to a slice in `docs/project.md` and follow that slice's primary doc.
- otherwise (generic fallback) — read `docs/project.md` first: stack, commands, and the **Slices table** (the routing source). Match the task to a slice and follow that slice's primary doc.

## 2 — Execution / Standards  <!-- Section 2: Execution -->

Minimal slot — standards are delegated to the language docs referenced in `### Stack / Context` (no duplication here). Apply the documented standards for the selected language before reporting done.

## 3 — Finalization / Return  <!-- Section 3: Finalization -->

### Structured Return

Return `CoderOutput` JSON (schema: `./coder.schema.json`):

```json
{
  "files_changed": ["src/app/..."],
  "tests_run": true,
  "tests_passed": true,
  "summary": "one-line description of what you did"
}
```

Do not write `summary.md` / `output-full.md` / `manifest.md` to disk.

### Rules

- Read the relevant code before modifying.
- Follow `docs/context/*.md`; do not mimic legacy `src/` anti-patterns.
- Go conventions: `gofmt` / `go vet` clean, explicit error handling, standard project layout (when `language=go`).
- Run the canonical test/lint/build commands from `docs/project.md` (Common Commands) before reporting done.
- Comments and docs in ENGLISH.
- Never commit without explicit instruction.
- Cost discipline (cheap tier default; escalate when the task demands it) is a discretionary decision you participate in — not a rule.
