# Protocol: Go Standards

On-demand, agent-owned language baseline for `coder` with `language=go`.
Resolve this file against the injected `agent-system` reference, not the project.
Read `docs/project.md`, the matched slice's primary doc, and relevant Go architecture,
project-rules, and backend docs in `docs/context/` first. Project versions, layout,
contracts, and canonical commands take precedence over baseline suggestions here.

- Format changed Go files with `gofmt`; run the project's canonical tests and
  `go vet` in the affected module/package scope. Report actual commands and results.
- Handle errors explicitly; wrap with useful context and `%w` when callers need
  `errors.Is`/`errors.As`. Do not swallow errors or panic for ordinary failures.
- Respect the existing documented package boundaries and module layout. Keep
  packages cohesive, names idiomatic, and interfaces small and consumer-driven.
  Do not impose `cmd/`, `internal/`, or any other layout without project evidence.
- Pass cancellation/deadlines through `context.Context` where appropriate; close
  owned resources and bound goroutine lifetimes. Avoid unguarded shared mutable state.
- Validate boundary inputs and preserve API/error contracts. Add focused tests,
  including failure paths; use table-driven tests when they clarify cases.
- Do not copy legacy source patterns against the docs, introduce dependencies,
  restructure modules, or assume a Go version without explicit task/project support.
