---
description: instructions for the AI on how to think and coordinate before acting
---
# Orchestrate - The System's Brain

Thinking instructions for the AI before executing any command.

## Thinking Rules
1. **Analyze Before Acting**: Before writing code, read the project entry point and the relevant context docs (see `.opencode/conventions.md` for paths).
2. **Architecture Awareness**: Consult the architecture doc for layering, dependency flow, and module boundaries.
3. **Consult the Rules**: Check the rules/standards doc to ensure new code follows lints and security.
4. **API contracts**: For HTTP changes, consult the API contracts doc.
5. **Subsystem docs**: For subsystem-specific changes, consult the relevant doc in the context docs.
6. **Language Rule**: Ensure all new documentation and comments are in **ENGLISH**.

## Execution Process
- **Phase 0: Protocol Discovery**: List `.opencode/protocols/` and `docs/protocols/` to identify reusable conventions relevant to the task.
- **Phase 1: Context Refresh**: Read the naming registry (if exists) and the identified context doc (see `.opencode/conventions.md`).
- **Phase 2: Proposal**: Explain the technical solution to the user before implementing.
- **Phase 3: Implementation**: Write code following standards.
- **Phase 4: Verification**: Run the project's build and test commands.
- **Phase 5: Documentation**: Update relevant context docs (see `.opencode/conventions.md`) in English.
