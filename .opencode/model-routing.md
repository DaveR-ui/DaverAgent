# Model Routing Table

**Single source of truth for all subagent model selection.**

Every subagent MUST reference this file for model selection. No hardcoded fallbacks allowed.

## Routing Rules

| Category | Subagent | Description | Default Model | Fallback Model |
|----------|----------|-------------|---------------|----------------|
| `coder` | coder | Programming, bug fixes, features, refactoring | qwen/qwen3.6-plus | zai/glm-5.1 |
| `documenter` | documenter | Documentation, README, API docs, guides | qwen/qwen3.6-plus | google/gemini-2.5-flash |
| `reviewer` | reviewer | Code review, security audit, best practices | qwen/qwen3.6-plus | zai/glm-5.1 |
| `tester` | tester | Unit tests, integration tests, coverage, e2e | qwen/qwen3.6-plus | zai/glm-5.1 |
| `architect` | architect | System design, architecture, module boundaries | qwen/qwen3.6-plus | google/gemini-2.5-flash |
| `explorer` | explorer | Codebase exploration, file search, dependencies | qwen/qwen3.6-plus | zai/glm-5.1 |
| `opencode-expert` | opencode-expert | OpenCode config, agents, skills, tools, MCP | qwen/qwen3.6-plus | zai/glm-5.1 |

## Model Selection Logic

1. **Always try the Default Model first**
2. **If Default is unavailable or fails**, use the Fallback Model
3. **If both fail**, report the error and ask the user to specify a model

## Model Aliases

| Alias | Provider/Model ID | Use Case |
|-------|-------------------|----------|
| `qwen/qwen3.6-plus` | Qwen 3.6 Plus | Default for all categories - balanced speed/capability |
| `zai/glm-5.1` | GLM 5.1 | Fallback for code-heavy tasks |
| `google/gemini-2.5-flash` | Gemini 2.5 Flash | Fallback for document/design tasks - fast and cost-effective |

## Usage for Subagents

When spawning or selecting a model:

1. Identify your **category** from the table above
2. Use the **default model** for that category
3. If unavailable, switch to the **fallback model**
4. Never hardcode a model - always reference this table

## Adding New Categories

To add a new subagent category:

1. Add a row to the Routing Rules table
2. Define default and fallback models
3. Create the subagent file in `.opencode/agents/subagents/`
4. Reference this file in the subagent's Model section
5. Register the subagent in `opencode.json`
