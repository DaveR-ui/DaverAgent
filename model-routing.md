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
- For Opencode documentation/data lookup, prefer the `opencode-expert` subagent.
- For image inspection by a non-vision model, prefer the `vision-relay` subagent.

## Runtime Policy Summary

For opencode runtime delegation, `.opencode/llm-routing.md` now defines the canonical user-requested policy:

- **MiniMax M3** (`opencode-go/minimax-m3`) — cheap 1M-context generalist; used by `delivery` (intake/routing), `explorer`, `project-context`, `opencode-expert` (investigations/docs) and `vision-relay` (image inspection)
- **Kimi K2.7 Code** (`opencode-go/kimi-k2.7-code`) — code-specialized; used by `coder` and `tester`
- **Qwen 3.7 Plus** (`opencode-go/qwen3.7-plus`) — middle tier; used by `reviewer` for code review (different model family from the coder for perspective diversity)
- **GLM 5.2** (`opencode-go/glm-5.2`) — used only by `architect` for design-quality work
- **Qwen 3.7 Max** (`opencode-go/qwen3.7-max`) — used only by `orchestrator` for advanced multi-step reasoning
- **Gemini 3 Flash** (`opencode/gemini-3-flash`) — retained as runtime fallback for `vision-relay` if `minimax-m3` is unavailable

Cost discipline:

- Prefer the cheapest tier that can do the work.
- Do not escalate to `qwen3.7-max` unless the work is orchestration.
- Do not escalate to `glm-5.2` unless the work is design.
- **Trim/reduce context before continuing** when the working set approaches **250K**; aim to keep it **<= 272K** after compaction to stay in the cheaper band.

Do not restate that matrix elsewhere for the opencode runtime. Reference `.opencode/llm-routing.md` instead.
