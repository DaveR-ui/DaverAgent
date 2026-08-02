# LLM Reference

Catalog of the 2 LLMs currently used by the agent system. Specs pulled from `https://models.dev/providers/opencode-go/`. Routing (which agent uses which model) lives in `opencode.json` — this file is the raw reference, not the policy.

> **Last updated**: 2026-07-31.

## Active Models

| Model | Route | Context | Output | Price (in / out per 1M) | Temperature | Used by |
|---|---|---|---|---|---|---|
| **MiniMax-M3** | `opencode-go/minimax-m3` | 1,000,000 | 131,072 | $0.30 / $1.20 | yes | `delivery`, `explorer`, `project-context`, `vision-relay`, `tester`, `external-scout` |
| **Kimi K3** | `opencode-go/kimi-k3` | 1,048,576 | 131,072 | $3.00 / $15.00 | ignored by API | `coder`, `architect`, `reviewer`, `analista`, `orchestrator` |

### Notes

- **MiniMax-M3** — cheapest model in the catalog, vision-capable. Default for read/inspect/dispatch work.
- **Kimi K3** — Most expensive tier; used for all heavy work: implementation (`coder`), design (`architect`), review (`reviewer`), second-opinion analysis (`analista`), and multi-agent coordination (`orchestrator`).
- **No fallback models configured.** If a primary is unavailable, the runtime surfaces the error.

## How to update

1. When specs change (price, context window), update the table and bump the **Last updated** date.
2. When you add, remove, or reassign a model, update both this file and `opencode.json`.
