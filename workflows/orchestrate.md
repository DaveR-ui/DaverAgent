---
description: instructions for the AI on how to think and coordinate before acting
---
# Orchestrate - The System's Brain

Thinking instructions for the AI before executing any command.

## Thinking Rules
1. **Analyze Before Acting**: Before writing code, read `docs/project.md` (entry point) and the relevant files in `docs/context/`.
2. **Architecture Awareness**: Consult `docs/context/architecture.md` for layering, dependency flow, and module boundaries.
3. **Consult the Rules**: Check `docs/context/project-rules.md` to ensure new code follows lints and security.
4. **Permission system**: For auth changes, consult the project's permission doc under `docs/context/` (per the Slices table).
5. **Language Rule**: Ensure all new documentation and comments are in **ENGLISH**.

## Execution Process
- **Phase 0: Protocol Discovery**: List `protocols/` to identify reusable conventions relevant to the task. For the permission system, refer directly to the project's permission doc under `docs/context/`.
- **Phase 1: Context Refresh**: Read the identified protocol and any relevant `docs/context/*.md` files.
- **Phase 2: Proposal**: Explain the technical solution to the user before implementing.
- **Phase 3: Implementation**: Write code following standards.
- **Phase 4: Verification**: Run the canonical test/typecheck/lint commands from `docs/project.md` (Common Commands) for the affected package directory. **Never** from the repo root (guard `do-not-run-tests-from-root`).
- **Phase 5: Documentation**: Update relevant docs in the project's `doc_language` (see `docs/project.md`) or English (for agent-system files).
