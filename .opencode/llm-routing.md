# Opencode LLM Routing

**Scope**: runtime agents configured in `opencode.json` and any opencode-side intake/orchestration behavior.

## Canonical Matrix

| Difficulty | Task Type | Primary Model | Fallback Model | Routing Rule |
| --- | --- | --- | --- | --- |
| **Low / Docs & Research** | Prompt analysis, read-only investigation, documentation, repo navigation, explanatory Q&A | **Gemini 3.5 Flash** | **GPT-5.4** | Use the cheapest fast model and force compact output. |
| **Medium / Bounded Code** | Localized bug fix, single-component/service change, focused tests, routine refactor | **GPT-5.3-Codex** | **GPT-5.4** | Use when the blast radius is bounded and no architecture pivot is involved. |
| **High / Complex** | Auth/bootstrap, race conditions, multi-file logic pivots, shared state, architecture, risky review | **GPT-5.4** | **GPT-5.3-Codex** | Use for deep reasoning and high-regression-risk work. |

## Agent Defaults

| Agent | Default Difficulty | Notes |
| --- | --- | --- |
| `delivery` | Low by default | Intake, translation, session handling, and routing; escalate when the handoff target is code-heavy or high-risk. |
| `orchestrator` | High by default | Owns task decomposition and downstream model choice. |
| `coder`, `tester` | Medium by default | Escalate to High for auth/bootstrap/race-condition or multi-file logic work. |
| `reviewer`, `architect` | High by default | Reasoning-heavy validation and design work. |
| `documenter`, `explorer` | Low by default | Keep outputs terse and cheap. |

## Documentation Topic Fast Path

When the user asks for **Opencode**, **VSCode**, or **Angular** documentation/data lookup:

1. Use the **`librarian` skill** first.
2. Keep the answer read-only unless the user explicitly asks for configuration changes.
3. Because this route is documentation/research, default to the **Low** tier and apply compact-output discipline.

## Flash Discipline

When the selected difficulty is **Low**:

1. Return summary-first output.
2. Keep sections short.
3. Avoid repeated evidence and long quotations.
4. Do not include chain-of-thought.

## Delivery Delegation Model

The `delivery` agent is the sole human interface. It **never implements directly** — all technical work is delegated.

### Delegation Paths

| Path | When | Subagents |
| --- | --- | --- |
| **Direct** (skip orchestrator) | Simple, well-defined, single-agent tasks | `coder`, `explorer`, `reviewer`, `tester`, `documenter` |
| **Via Orchestrator** | Multi-step, multi-agent, or unclear scope | `orchestrator` → coordinates downstream agents |

### Decision Rules

1. **Single action, clear target** → Release the appropriate subagent directly.
2. **Multiple steps or agents needed** → Release `orchestrator`.
3. **Exploration or Q&A** → Release `explorer` directly.
4. **Parallel independent tasks** → Release multiple subagents concurrently.

### Session Storage

All session data lives at a hardcoded path: `~/.config/opencode/sessions/`.
See `.opencode/agents/delivery.md` for the full session structure and delegation matrix.

## Selection Procedure

1. Classify the task by difficulty.
2. Check the agent default.
3. Override upward when risk is higher than the default.
4. If the task is Opencode/VSCode/Angular documentation, use `librarian` first.
5. If the primary model is unavailable, use the fallback.
