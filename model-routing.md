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
- For image inspection by a non-vision model, prefer the `vision-relay` subagent.

## Runtime Policy Summary

For opencode runtime delegation, `.opencode/llm-routing.md` now defines the canonical user-requested policy:

- **MiniMax M3** (`opencode-go/minimax-m3`) — cheap 1M-context generalist; used by `delivery` (intake/routing), `explorer`, `project-context` (investigations/docs), `vision-relay` (image inspection) and `tester` (unit/e2e tests)
- **Kimi K3** (`opencode-go/kimi-k3`) — code + orchestration tier; used by `coder` (implementation) and `orchestrator` (advanced multi-step reasoning)
- **GLM 5.2** (`opencode-go/glm-5.2`) — used by `architect` (design-quality work) and `reviewer` (code review). Perspective diversity comes from the `coder`/`orchestrator` being in the Kimi family, not from splitting architect and reviewer across providers.

Cost discipline:

- Prefer the cheapest tier that can do the work.
- Do not escalate to `kimi-k3` unless the work is code or orchestration; the cheap routes (`delivery`, `explorer`, `project-context`, `vision-relay`, `tester`) must not escalate to K3.
- Do not escalate to `glm-5.2` unless the work is design or code review.
- **Trim/reduce context before continuing** when the working set approaches **250K**; aim to keep it **<= 272K** after compaction to stay in the cheaper band.

Do not restate that matrix elsewhere for the opencode runtime. Reference `.opencode/llm-routing.md` instead.
