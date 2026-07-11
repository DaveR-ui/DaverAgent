---
description: instructions for the AI on how to think and coordinate before acting
---
# Orchestrate - The System's Brain

Thinking instructions for the AI before executing any command.

## Thinking Rules
1. **Analyze Before Acting**: Before writing code, read `docs/project.md` (entry point) and the relevant files in `docs/context/`.
2. **Architecture Awareness**: Consult `docs/context/architecture.md` for layering, dependency flow, and module boundaries.
3. **Consult the Rules**: Check `docs/context/rules.md` to ensure new code follows lints and security.
4. **API contracts**: For HTTP changes, consult `docs/context/api-contracts.md`.
5. **Permission system**: For auth changes, consult `packages/core/src/permission/` (the design lives next to the code; there is no `docs/context/permission-architecture.md`).
6. **V2 Session Core**: For session, prompt, or tool output work, follow `CONTEXT.md` (V2 session terminology) and `AGENTS.md` (V2 Session Core section).
7. **Language Rule**: Ensure all new documentation and comments are in **ENGLISH** (for `.opencode/`, code comments, and code-fenced docstrings); the human-facing `docs/` directory is in **Spanish** per `docs/README.md`.

## Execution Process
- **Phase 0: Protocol Discovery**: List `.opencode/protocols/` and `docs/protocols/` to identify reusable conventions relevant to the task (e.g., `api-endpoint-factory`).
- **Phase 1: Context Refresh**: Read `docs/context/naming-registry.md` and the identified Protocol.
- **Phase 2: Proposal**: Explain the technical solution to the user before implementing.
- **Phase 3: Implementation**: Write code following standards.
- **Phase 4: Verification**: Run `bun typecheck` and `bun test` from the affected package directory (e.g. `packages/opencode`, `packages/core`). **Never** from the repo root (guard `do-not-run-tests-from-root`).
- **Phase 5: Documentation**: Update relevant `docs/context/*.md` files in Spanish (for `docs/`) or English (for `.opencode/`).
