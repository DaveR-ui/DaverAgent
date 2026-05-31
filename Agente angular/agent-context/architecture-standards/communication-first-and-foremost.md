---
last_updated: 2026-04-27
description: minimal communication rules for distributed execution, decisions, and sources of truth
tags: [architecture, communication, standards, workflow]
status: ACTIVE
ai_optimized: yes
---

# Communication First and Foremost

## Core Rules
- Clarity beats cleverness.
- Keep two sources of truth: one for durable context and one for agreed execution work.
- Move important decisions back into documented sources of truth.
- Use chat for simple questions only; escalate ambiguous threads into explicit alignment.
- Define success criteria and definition of done before execution.

## Use In This Repo
- Plans belong in agent and memory workflows, not in scattered chat-only context.
- Feature rules should live in `.github/agent-context/` so later tasks can reuse them.
- When a conversation changes scope, update the durable documentation instead of relying on message history.

## See Also
- [AGENTS.md](../AGENTS.md)
- [project-rules.md](../project-rules.md)