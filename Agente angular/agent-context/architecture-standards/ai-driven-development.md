---
last_updated: 2026-04-27
description: minimal AI-assisted development rules for keeping humans in control and context concise
tags: [architecture, ai, workflow, standards, agents]
status: ACTIVE
ai_optimized: yes
---

# AI-Driven Development

## Core Rules
- The developer remains responsible for decisions.
- Prefer concise reusable context over repeated prompt prose.
- Keep requirements, success criteria, and architecture visible before execution.
- Use specialized agents for distinct responsibilities.
- Let durable docs carry recurring context instead of conversation history.

## Use In This Repo
- Store reusable rules in `.github/agent-context/`.
- Plans, handoffs, and verification should be explicit rather than implied.
- Use small, purpose-specific context packages instead of loading unrelated documentation.

## See Also
- [AGENTS.md](../AGENTS.md)
- [project-rules.md](../project-rules.md)