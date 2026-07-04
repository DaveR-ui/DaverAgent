# Model Routing Index

This file is the compatibility entry point for model-selection rules.

## Use These Sources

| Scope | Source of Truth |
| --- | --- |
| Opencode runtime agents (`opencode.json`, intake, orchestration, delivery flow) | `.opencode/llm-routing.md` |
| (legacy) `.github` agent network | not used in this repo — single source: `.opencode/llm-routing.md` |

## Important Rule

- Do not maintain duplicated routing tables in multiple random files.
- Update the scope-specific table above, then update any references.
- For Opencode, VSCode, or Angular documentation/data lookup, prefer the dedicated `*-expert` subagents.
- For image inspection by a non-vision model, prefer the `vision-relay` subagent.

## Runtime Policy Summary

For opencode runtime delegation, `.opencode/llm-routing.md` now defines the canonical user-requested policy:

- **MiniMax M3** (`opencode/minimax-m3`) — default for everything "average": docs, exploration, and important execution work
- **Qwen 3.7 Max** (`opencode/qwen3.7-max`) — used only by `orchestrator` for advanced multi-step reasoning
- **GLM 5.2** (`opencode/glm-5.2`) — used only by `architect` for design-quality work
- **Gemini 3 Flash** (`opencode/gemini-3-flash`) — used only by `vision-relay` for cheap image inspection

Cost discipline:

- Prefer the cheapest tier that can do the work.
- Do not escalate to `qwen3.7-max` unless the work is orchestration.
- Do not escalate to `glm-5.2` unless the work is design.
- **Trim/reduce context before continuing** when the working set approaches **250K**; aim to keep it **<= 272K** after compaction to stay in the cheaper band.

Do not restate that matrix elsewhere for the opencode runtime. Reference `.opencode/llm-routing.md` instead.
