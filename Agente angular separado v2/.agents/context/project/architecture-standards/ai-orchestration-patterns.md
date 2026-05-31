---
last_updated: 2026-04-27
description: minimal orchestration rules for supervisor workflows, plan-and-execute, and clean AI boundaries
tags: [architecture, ai, orchestration, mcp, standards]
status: ACTIVE
ai_optimized: yes
---

# AI Orchestration Patterns

## Core Rules
- Choose orchestration patterns deliberately; do not mix them accidentally.
- Prefer plan-and-execute for complex multi-step work.
- Keep the orchestrator responsible for delegation and synthesis, not every worker.
- Treat LLMs as infrastructure, not domain logic.
- Validate critical decisions in deterministic code or documented rules, not in model output.

## Use In This Repo
- The SDD agent acts as an orchestrator and should delegate specialized work deliberately.
- Local agent docs are preferred over live web references for recurring orchestration rules.
- MCP-style integrations are useful when capabilities are reusable; direct logic is better for tight project-specific rules.

## See Also
- [rules.md](../rules.md)
- [AGENTS.md](../../orchestration/AGENTS.md)
