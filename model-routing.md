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

## Runtime Policy Summary

For opencode runtime delegation, `.opencode/llm-routing.md` now defines the canonical user-requested policy:

- **GPT-5.4** for important execution subagents when active context is **<= 250K**
- **Trim/reduce context before continuing** when the working set approaches that threshold
- **Target <= 272K after compaction** to stay in the cheaper band whenever feasible
- **GPT-5.3-Codex** for code search and exploration
- **Gemini 3.5 Flash** for documentation reading and read-only synthesis

Do not restate that matrix elsewhere for the opencode runtime. Reference `.opencode/llm-routing.md` instead.
