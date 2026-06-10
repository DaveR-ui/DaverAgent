# Model Routing Index

This file is the compatibility entry point for model-selection rules.

## Use These Sources

| Scope | Source of Truth |
| --- | --- |
| Opencode runtime agents (`opencode.json`, intake, orchestration, delivery flow) | `.opencode/llm-routing.md` |
| `.github` agent network (`.github/agents`, `.github/agent-workflows`) | `.github/agent-workflows/llm-routing.md` |

## Important Rule

- Do not maintain duplicated routing tables in multiple random files.
- Update the scope-specific table above, then update any references.
- For Opencode or VSCode documentation/data lookup, prefer the `librarian` route.
