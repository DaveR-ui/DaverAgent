---
description: instructions for the AI on how to think and coordinate before acting
---
# Orchestrate - The System's Brain

Thinking instructions for the AI before executing any command.

## Thinking Rules
1. **Analyze Before Acting**: Before writing code, read `docs/project.md` (entry point) and the relevant files in `docs/context/`.
2. **Architecture Awareness**: Consult `docs/context/architecture/architecture.md` for layering, dependency flow, and module boundaries.
3. **Consult the Rules**: Check `docs/context/conventions/project-rules.md` to ensure new code follows lints and security.
4. **Permission system**: For auth changes, consult `docs/context/auth-identity/security-permissions.md`.
5. **Language Rule**: Ensure all new documentation and comments are in **ENGLISH**.

## Execution Process
- **Phase 0: Protocol Discovery**: List `.opencode/protocols/` and `docs/protocols/` to identify reusable conventions relevant to the task (e.g., `api-endpoint-factory`). For the permission system, refer directly to `docs/context/auth-identity/security-permissions.md`.
- **Phase 1: Context Refresh**: Read the identified protocol and any relevant `docs/context/*.md` files.
- **Phase 2: Proposal**: Explain the technical solution to the user before implementing.
- **Phase 3: Implementation**: Write code following standards.
- **Phase 4: Verification**: Run `bun typecheck` and `bun test` from the affected package directory (e.g. `packages/opencode`, `packages/core`). **Never** from the repo root (guard `do-not-run-tests-from-root`).
- **Phase 5: Documentation**: Update relevant `docs/context/*.md` files in Spanish (for `docs/`) or English (for `.opencode/`).
