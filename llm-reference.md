# LLM Reference

Reference catalog of the LLMs used by the agent system. This is the **raw specs** of each model — see `.opencode/llm-routing.md` for the **routing policy** (which model is used for which task and why).

> **Source**: specs pulled from `https://models.dev/providers/opencode-go/` on 2026-07-05.
> **Last updated**: 2026-07-05.

## Model Catalog

| Model | Route | Context | Output | Price (in/out per 1M) | Reasoning | Tool Call | Structured | Temperature |
|---|---|---|---|---|---|---|---|---|
| **GLM-5.2** | `opencode-go/glm-5.2` | 1,000,000 | 131,072 | $1.40 / $4.40 | Yes | Yes | Yes | Yes |
| **Kimi K2.7 Code** | `opencode-go/kimi-k2.7-code` | 262,144 | 262,144 | $0.95 / $4.00 | Yes | Yes | Yes | **No** |
| **MiniMax-M3** | `opencode-go/minimax-m3` | 1,000,000 | 131,072 | $0.30 / $1.20 | Yes | Yes | — | Yes |
| **Qwen3.7 Max** | `opencode-go/qwen3.7-max` | 1,000,000 | 65,536 | $2.50 / $7.50 | Yes | Yes | — | Yes |
| **Qwen3.7 Plus** | `opencode-go/qwen3.7-plus` | 1,000,000 | 65,536 | $0.40 / $1.60 | Yes | Yes | — | Yes |

### Notes on the table

- **Price**: `input / output` per million tokens. Cached input is cheaper (e.g. MiniMax-M3 cached = $0.06/M).
- **Structured**: `—` means the column was not listed for that model on models.dev (not necessarily "unsupported").
- **Temperature**: Kimi K2.7 Code is the only model in the catalog that does **not** support `temperature` customization — the field is ignored by the API.
- **Context = Output**: Kimi K2.7 Code has equal context and output (262k = 262k), which is unusual and useful for whole-file generation.

---

## Per-Model Notes

Use the sections below to capture observations, gotchas, benchmarks, and any other info you gather about each model as you use it.

### `opencode-go/glm-5.2`

- **Role in this project**: `architect` (design-quality work, system design, module boundaries).
- **Provider**: opencode-go
- **Price tier**: high ($1.40 / $4.40)
- **Standout feature**: 1M context window, supports structured output.
- **Notes**:
  - _(add your observations here)_

### `opencode-go/kimi-k2.7-code`

- **Role in this project**: `coder`, `tester` (code-specialized).
- **Provider**: opencode-go
- **Price tier**: mid ($0.95 / $4.00)
- **Standout feature**: code-specialized, 262k context = 262k output (huge output capacity).
- **Limitations**: does **not** support `temperature` customization.
- **Notes**:
  - _(add your observations here)_

### `opencode-go/minimax-m3`

- **Role in this project**: `delivery`, `explorer`, `project-context`, `vision-relay` — the cheap 1M-context generalist for intake, investigations, docs-lookup, and image inspection.
- **Provider**: opencode-go
- **Price tier**: cheap ($0.30 / $1.20, $0.06 cached)
- **Standout feature**: cheapest vision-capable model we use; cheaper than the previous `gemini-3-flash` fallback.
- **Notes**:
  - _(add your observations here)_

### `opencode-go/qwen3.7-max`

- **Role in this project**: `orchestrator` (advanced multi-step reasoning, multi-agent coordination).
- **Provider**: opencode-go
- **Price tier**: highest ($2.50 / $7.50)
- **Standout feature**: most capable reasoning model in the catalog; carries the cross-agent synthesis load.
- **Notes**:
  - _(add your observations here)_

### `opencode-go/qwen3.7-plus`

- **Role in this project**: `reviewer` (code review, security audit, best practices).
- **Role in this project**: `reviewer` (code review, security audit, best practices).
- **Provider**: opencode-go
- **Price tier**: mid ($0.40 / $1.60)
- **Standout feature**: middle tier between MiniMax-M3 and Qwen3.7 Max; intentionally a different model family from the coder (`kimi-k2.7-code`) for genuine perspective diversity.
- **Standout feature**: middle tier between MiniMax-M3 and Qwen3.7 Max; intentionally a different model family from the coder (`kimi-k2.7-code`) for genuine perspective diversity.
- **Notes**:
  - _(add your observations here)_

---

## Fallback Models (not in the opencode-go catalog)

These are retained as runtime fallbacks for `vision-relay` if the primary is unavailable. They live under different providers.

| Model | Route | Price (in/out per 1M) | Notes |
|---|---|---|---|
| Gemini 3 Flash | `opencode/gemini-3-flash` | $0.50 / $3.00 | Previous primary for vision-relay. Retained as fallback. |
| GPT-5.4 Nano | `opencode/gpt-5.4-nano` | _(check models.dev)_ | Last-resort fallback. |

---

## How to update this file

1. When you learn something new about a model, add it under the **Notes** section of that model.
2. When specs change (price, context window, new features), update the **Model Catalog** table and bump the **Last updated** date at the top.
3. When you add or remove a model from the routing, update both this file and `.opencode/llm-routing.md`.
