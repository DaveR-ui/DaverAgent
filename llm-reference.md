# LLM Reference

Reference catalog of the LLMs used by the agent system. This is the **raw specs** of each model — see `.opencode/llm-routing.md` for the **routing policy** (which model is used for which task and why).

> **Source**: specs pulled from `https://models.dev/providers/opencode-go/` on 2026-07-05.
> **Last updated**: 2026-07-17.

## Model Catalog

| Model | Route | Context | Output | Price (in/out per 1M) | Reasoning | Tool Call | Structured | Temperature |
|---|---|---|---|---|---|---|---|---|
| **GLM-5.2** | `opencode-go/glm-5.2` | 1,000,000 | 131,072 | $1.40 / $4.40 | Yes | Yes | Yes | Yes |
| **Kimi K2.7 Code** | `opencode-go/kimi-k2.7-code` | 262,144 | 262,144 | $0.95 / $4.00 | Yes | Yes | Yes | **No** |
| **Kimi K3** | `opencode-go/kimi-k3` | 1,048,576 | 131,072 | $3.00 / $15.00 | Yes | Yes | Yes | Yes |
| **MiniMax-M3** | `opencode-go/minimax-m3` | 1,000,000 | 131,072 | $0.30 / $1.20 | Yes | Yes | — | Yes |

### Notes on the table

- **Price**: `input / output` per million tokens. Cached input is cheaper (e.g. MiniMax-M3 cached = $0.06/M, Kimi K3 cached read = $0.30/M).
- **Structured**: `—` means the column was not listed for that model on models.dev (not necessarily "unsupported").
- **Temperature**: the Kimi family (`kimi-k2.7-code`, `kimi-k3`) does **not** support `temperature` customization — the field is ignored by the API. All other models in the catalog do.
- **Context = Output**: Kimi K2.7 Code has equal context and output (262k = 262k), which is unusual and useful for whole-file generation.

---

## Per-Model Notes

Use the sections below to capture observations, gotchas, benchmarks, and any other info you gather about each model as you use it.

### `opencode-go/glm-5.2`

- **Role in this project**: `architect` (design-quality work, system design, module boundaries); `reviewer` (code review, security audit, best practices).
- **Provider**: opencode-go
- **Price tier**: high ($1.40 / $4.40)
- **Standout feature**: 1M context window, supports structured output.
- **Notes**:
  - Used by both `architect` and `reviewer`; perspective diversity is no longer achieved by changing model family between these two roles, but by the `coder` (`kimi-k2.7-code`) being in a different family from both.

### `opencode-go/kimi-k2.7-code`

- **Role in this project**: `coder`, `tester` (code-specialized).
- **Provider**: opencode-go
- **Price tier**: mid ($0.95 / $4.00)
- **Standout feature**: code-specialized, 262k context = 262k output (huge output capacity).
- **Limitations**: does **not** support `temperature` customization.
- **Notes**:
  - _(add your observations here)_

### `opencode-go/kimi-k3`

- **Role in this project**: `orchestrator` (advanced multi-step reasoning, multi-agent coordination).
- **Provider**: opencode-go
- **Price tier**: highest ($3.00 / $15.00, $0.30 cached read, $15 cached write)
- **Standout feature**: 1M context window, large output capacity (131k), carries the cross-agent synthesis load.
- **Limitations**: highest cost.
- **Notes**:
  - Replaces `qwen3.7-max` for orchestration. Same model family as the `coder` (`kimi-k2.7-code`), so perspective diversity for the orchestrator now depends on the prompt and tools, not the model family.

### `opencode-go/minimax-m3`

- **Role in this project**: `delivery`, `explorer`, `project-context`, `vision-relay` — the cheap 1M-context generalist for intake, investigations, docs-lookup, and image inspection.
- **Provider**: opencode-go
- **Price tier**: cheap ($0.30 / $1.20, $0.06 cached)
- **Standout feature**: cheapest vision-capable model we use.
- **Notes**:
  - _(add your observations here)_


## Fallback Models

No fallback models are currently configured (as of 2026-07-12). If a primary is unavailable, the runtime surfaces the error. To add a fallback for a specific route, edit the importance matrix in `.opencode/llm-routing.md` and add a row to this section.

---

## How to update this file

1. When you learn something new about a model, add it under the **Notes** section of that model.
2. When specs change (price, context window, new features), update the **Model Catalog** table and bump the **Last updated** date at the top.
3. When you add or remove a model from the routing, update both this file and `.opencode/llm-routing.md`.
