---
description: instructions for the AI on how to think and coordinate before acting
---
# Orchestrate - The System's Brain

Thinking instructions for the AI before executing any command.

## Thinking Rules
1. **Analyze Before Acting**: Before writing code, read `context/blueprint.md` and `context/architecture.md`.
2. **Infrastructure Awareness**: Consult `context/docker-strategy.md` for deployment, pgAdmin, and container startup rules.
3. **Consult the Rules**: Check `context/rules.md` to ensure new code follows lints and security.
4. **Verify the Backlog**: Review `context/todo.md` to avoid duplicating efforts.
5. **Language Rule**: Ensure all new documentation and comments are in **ENGLISH**.

## Execution Process
- **Phase 0: Skill Discovery**: Use `list_dir` on `.agent/skills/` to identify specialized tools/instructions relevant to the task (e.g., `api-endpoint-factory`, `sql-master`).
- **Phase 1: Context Refresh**: Read `context/blueprint.md`, `context/naming-registry.md`, and the identified Skill's `SKILL.md`.
- **Phase 2: Proposal**: Explain the technical solution to the user before implementing.
- **Phase 3: Implementation**: Write code following standards.
- **Phase 4: Verification**: Run tests and validate contracts.
- **Phase 5: Documentation**: Update `task-memory.md` and `todo.md` in English.
