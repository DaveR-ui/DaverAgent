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
- Keep `sdd_agent` responsible for delegation and synthesis, not every worker.
- Treat LLMs as infrastructure, not domain logic.
- Validate critical decisions in deterministic code or documented rules, not in model output.

## Use In This Repo
- `sdd_agent` is the direct coordination layer and should delegate specialized work deliberately.
- Local agent docs are preferred over live web references for recurring orchestration rules.
- MCP-style integrations are useful when capabilities are reusable; direct logic is better for tight project-specific rules.

## Freshness And Consistency
- Keep one canonical cross-agent contract registry in `.github/agent-workflows/agent-contracts.md`.
- Update the registry before changing agent responsibilities, routing fast paths, or output sections.
- Treat repeated routing tables in multiple docs as drift unless one of them is explicitly declared canonical.

## See Also
- [agent-contracts.md](../../agent-workflows/agent-contracts.md)
- [project-rules.md](../project-rules.md)
- [AGENTS.md](../AGENTS.md)