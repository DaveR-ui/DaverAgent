---
description: instructions for the AI on how to think and coordinate before acting
---
# Orchestrate - The System's Brain

Thinking instructions for the AI before executing any command.

## Thinking Rules
1. **Analyze Before Acting**: Before writing code, read `docs/project.md` (entry point) and the relevant files in `docs/context/`.
2. **Architecture Awareness**: Consult the architecture doc in `docs/context/` for layering, dependency flow, and module boundaries.
3. **Consult the Rules**: Check the rules/standards doc in `docs/context/` to ensure new code follows lints and security.
4. **API contracts**: For HTTP changes, consult the API contracts doc in `docs/context/`.
5. **Subsystem docs**: For subsystem-specific changes, consult the relevant doc in `docs/context/`.
6. **Language Rule**: Ensure all new documentation and comments are in **ENGLISH**.

## Execution Process
- **Phase 0: Protocol Discovery**: List `.opencode/protocols/` and `docs/protocols/` to identify reusable conventions relevant to the task.
- **Phase 1: Context Refresh**: Read the naming registry (if exists) and the identified Protocol from `docs/context/`.
- **Phase 2: Proposal**: Explain the technical solution to the user before implementing.
- **Phase 3: Implementation**: Write code following standards.
- **Phase 4: Verification**: Run the project's build and test commands.
- **Phase 5: Documentation**: Update relevant `docs/context/*.md` files in English.
