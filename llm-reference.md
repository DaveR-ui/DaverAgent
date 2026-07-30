# LLM Reference

Catalog of the 3 LLMs currently used by the agent system. Specs pulled from `https://models.dev/providers/opencode-go/`. Routing (which agent uses which model) lives in `opencode.json` — this file is the raw reference, not the policy.

> **Last updated**: 2026-07-30.

## Active Models

| Model | Route | Context | Output | Price (in / out per 1M) | Temperature | Used by |
|---|---|---|---|---|---|---|
| **MiniMax-M3** | `opencode-go/minimax-m3` | 1,000,000 | 131,072 | $0.30 / $1.20 | yes | `delivery`, `explorer`, `project-context`, `vision-relay`, `tester`, `external-scout` |
| **GLM-5.2** | `opencode-go/glm-5.2` | 1,000,000 | 131,072 | $1.40 / $4.40 | yes | `coder`, `architect`, `reviewer`, `analista` |
| **Kimi K3** | `opencode-go/kimi-k3` | 1,048,576 | 131,072 | $3.00 / $15.00 | ignored by API | `orchestrator` |

### Notes

- **MiniMax-M3** — cheapest model in the catalog, vision-capable. Default for read/inspect/dispatch work.
- **GLM-5.2** — long-horizon reasoning with a concrete, do-it-yourself execution profile (does not delegate easily). Used for implementation (`coder`), design and review (`architect`, `reviewer`), and second-opinion analysis (`analista`); cheaper than Kimi K3.
- **Kimi K3** — Most expensive tier; reserved for multi-agent coordination (`orchestrator`) only — implementation (`coder`) moved to GLM-5.2 on 2026-07-30.
- **No fallback models configured.** If a primary is unavailable, the runtime surfaces the error.

## How to update

1. When specs change (price, context window), update the table and bump the **Last updated** date.
2. When you add, remove, or reassign a model, update both this file and `opencode.json`.
