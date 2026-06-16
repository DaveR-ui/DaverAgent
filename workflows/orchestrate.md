---
description: instructions for the AI on how to think and coordinate before acting
---
# Orchestrate - The System's Brain

Thinking instructions for the AI before executing any command.

## Thinking Rules
1. **Analyze Before Acting**: Before writing code, read `context/architecture.md` and `context/rules.md`.
2. **Infrastructure Awareness**: Consult `context/docker-strategy.md` for deployment, pgAdmin, and container startup rules.
3. **Consult the Rules**: Check `context/rules.md` to ensure new code follows lints and security.
4. **Language Rule**: Ensure all new documentation and comments are in **ENGLISH**.

## Execution Process
- **Phase 0: Skill Discovery**: Use `list_dir` on `.opencode/skills/` to identify specialized tools/instructions relevant to the task (e.g., `api-endpoint-factory`, `permission-system`).
- **Phase 1: Context Refresh**: Read `context/naming-registry.md` and the identified Skill's `SKILL.md`.
- **Phase 2: Proposal**: Explain the technical solution to the user before implementing.
- **Phase 3: Implementation**: Write code following standards.
- **Phase 4: Verification**: Run tests and validate contracts.
- **Phase 5: Documentation**: Update relevant context files in English.
