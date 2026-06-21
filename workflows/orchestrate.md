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
5. **Permission system**: For auth changes, consult `docs/context/permission-architecture.md`.
6. **Language Rule**: Ensure all new documentation and comments are in **ENGLISH**.

## Execution Process
- **Phase 0: Protocol Discovery**: List `.opencode/protocols/` and `docs/protocols/` to identify reusable conventions relevant to the task (e.g., `api-endpoint-factory`). For the permission system, refer directly to `docs/context/permission-architecture.md`.
- **Phase 1: Context Refresh**: Read `docs/context/naming-registry.md` and the identified Protocol.
- **Phase 2: Proposal**: Explain the technical solution to the user before implementing.
- **Phase 3: Implementation**: Write code following standards.
- **Phase 4: Verification**: Run `go build` and `go test`.
- **Phase 5: Documentation**: Update relevant `docs/context/*.md` files in English.
