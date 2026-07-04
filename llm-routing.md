# Opencode LLM Routing

**Scope**: runtime agents configured in `opencode.json` and any opencode-side intake/orchestration behavior.

## Canonical Importance Matrix

| Importance / Intent | Task Type | Primary Model | Fallback Model | Routing Rule |
| --- | --- | --- | --- | --- |
| **Docs / Read-Only** | Documentation reading, prompt analysis, read-only investigation, explanatory Q&A, repo navigation for answers | **`opencode/minimax-m3`** (MiniMax M3) | `opencode/gemini-3-flash` | Use the cheapest fast model and force compact output. |
| **Exploration / Search** | Code search, file discovery, dependency tracing, scope discovery, architecture exploration | **`opencode/minimax-m3`** (MiniMax M3) | `opencode/gemini-3-flash` | Average-cost generalist is enough; fall back to the cheapest flash on capacity issues. |
| **Important / Execution** | Programming, bug fixes, feature implementation, refactoring, tests, code review, business logic | **`opencode/minimax-m3`** (MiniMax M3) | `opencode/gemini-3-flash` | Default all "average" execution subagents to MiniMax M3 while the active context stays inside the cost budget below. |
| **Design / Architecture** | System design, module boundaries, patterns, high-level architecture decisions, design reviews | **`opencode/glm-5.2`** (GLM 5.2) | `opencode/minimax-m3` | Use GLM 5.2 for design-quality work because its reasoning profile is stronger for long-horizon planning. |
| **Orchestration (advanced)** | Multi-step task decomposition, multi-agent coordination, planning, synthesis across heterogeneous sources | **`opencode/qwen3.7-max`** (Qwen 3.7 Max) | `opencode/minimax-m3` | Use the most capable reasoning model here; orchestrators carry the most cross-agent context and the highest cost-of-error. |
| **Vision Relay** | Single-purpose image inspection for non-vision models: OCR screenshots, UI mockups, diagrams, error dialogs | **`opencode/gemini-3-flash`** (Gemini 3 Flash) | `opencode/gpt-5.4-nano` | Cheapest model in the catalog with confirmed vision input. Used as a relay by other agents, not as a primary reasoner. |

### Why these specific models

- **MiniMax M3 (`opencode/minimax-m3`)** — $0.30 in / $1.20 out per 1M tokens, 0.06 cached. Strong generalist at a low price; good enough for the bulk of "average" work (code, review, tests, exploration, doc reading, prompt analysis). The model id is `minimax-m3` (MiniMax is the provider, M3 is the model).
- **GLM 5.2 (`opencode/glm-5.2`)** — $1.40 in / $4.40 out. Used only for `architect` and design-quality tasks where long-horizon reasoning and structured design output matter more than throughput.
- **Qwen 3.7 Max (`opencode/qwen3.7-max`)** — $2.50 in / $7.50 out, plus prompt-caching savings. Reserved for `orchestrator` because it carries the cross-agent synthesis load and the cost of an orchestration mistake is the highest in the system.
- **Gemini 3 Flash (`opencode/gemini-3-flash`)** — $0.50 in / $3.00 out, the cheapest model in the OpenCode Zen catalog with vision input. Used by the `vision-relay` subagent.

## Agent Defaults

Each agent has a per-agent `model` field. The runtime rule is: **the agent's own `model` field wins over the global default**. If a per-agent model is missing, subagents inherit the primary agent's model.

| Agent | Default Model | Route Class | Notes |
| --- | --- | --- | --- |
| `delivery` | `opencode/minimax-m3` | Docs / Read-Only | Intake, translation, routing, and policy application. Stays compact and delegates all technical work. |
| `orchestrator` | `opencode/qwen3.7-max` | Orchestration (advanced) | Owns task decomposition, context trimming decisions, and downstream model choice. |
| `coder` | `opencode/minimax-m3` | Important / Execution | Programming, bug fixes, feature implementation, refactoring. |
| `tester` | `opencode/minimax-m3` | Important / Execution | Unit, integration, e2e tests. |
| `reviewer` | `opencode/minimax-m3` | Important / Execution | Code review, security audit, best practices. Read-only by permission, not by model. |
| `architect` | `opencode/glm-5.2` | Design / Architecture | System design, module boundaries, patterns. The only agent that uses the design-tier model. |
| `explorer` | `opencode/minimax-m3` | Exploration / Search | Code search, file discovery, dependency tracing. |
| `project-context` | `opencode/minimax-m3` | Docs / Read-Only | Reads and writes `docs/`. |
| `angular-expert` | `opencode/minimax-m3` | Docs / Read-Only | Read-only Angular + AG Grid documentation lookup. |
| `opencode-expert` | `opencode/minimax-m3` | Docs / Read-Only | Read-only opencode documentation lookup. |
| `vscode-expert` | `opencode/minimax-m3` | Docs / Read-Only | Read-only VSCode documentation lookup. |
| `vision-relay` | `opencode/gemini-3-flash` | Vision Relay | Image inspection only. Used by other agents when they need to "see" an image but their own model cannot. |

## Context Budget Policy

The user-requested cost policy is:

1. **Preferred band per tier:** MiniMax M3 stays cheap; do not escalate to Qwen 3.7 Max unless the work is orchestration; do not escalate to GLM 5.2 unless the work is design.
2. **Early compaction trigger:** when the working set is getting close to **250K**, reduce context before releasing or continuing an important subagent.
3. **Cheap-band ceiling:** after compaction, aim to keep the working set **<= 272K** whenever feasible because that band is materially cheaper.
4. **Do not pay for redundant context:** remove repeated evidence, long pasted excerpts, irrelevant files, stale plans, and duplicate summaries before escalating.
5. **Escalation ladder (cheap → expensive):**
   - `gemini-3-flash` (cheapest, vision-capable) → used only by `vision-relay` and as a fallback.
   - `minimax-m3` (default for everything "average") → used for the majority of work.
   - `glm-5.2` (design) → used by `architect` only.
   - `qwen3.7-max` (advanced orchestration) → used by `orchestrator` only.

### Required Context-Reduction Moves

When the context is trending toward the budget limit:

1. Keep only the bounded task slice, current plan, and the smallest necessary evidence.
2. Replace large file dumps with targeted excerpts or summaries.
3. Split exploration into a separate `explorer` handoff instead of bloating the execution agent.
4. Route documentation lookup through the dedicated expert subagents instead of carrying raw docs into the design or orchestration tier.
5. If a non-vision model needs to inspect an image, route the image through `vision-relay` instead of escalating the whole task to a vision-capable model.
6. If needed, split the work into multiple bounded subagents rather than letting one context sprawl.

## Documentation Topic Fast Path

When the user asks for **Angular**, **Opencode**, or **VSCode** documentation/data lookup:

1. Delegate to the dedicated read-only expert subagent:
   - `angular-expert` — consults `.opencode/docs/angular/` and Angular CLI / AG Grid MCP tools.
   - `opencode-expert` — consults `.opencode/docs/opencode/`.
   - `vscode-expert` — consults `.opencode/docs/vscode/`.
2. These agents are **read-only** and **must not** fall back to the web or to training data. If the expected docs folder is missing, they report the exact path and stop.
3. Because this route is documentation/research, default to the **Docs / Read-Only** route and apply compact-output discipline. Keep the answer read-only unless the user explicitly asks for configuration changes.

## Exploration Fast Path

When the task is mainly code search, repo exploration, or scope discovery:

1. Route directly to **`explorer`** when possible.
2. Use **`opencode/minimax-m3`** as the first choice (average-cost generalist, no need to pay more for search).
3. Escalate to `qwen3.7-max` only if the orchestrator itself is doing the exploration and needs synthesis at the same time.

## Vision Relay Fast Path

When a subagent (or the orchestrator) needs to inspect an image but its own model does not have vision input:

1. The calling agent delegates the image to **`vision-relay`** with a specific question.
2. `vision-relay` uses `opencode/gemini-3-flash` to look at the image and returns a compact textual answer.
3. The calling agent continues its work with the textual answer — it does not need to receive the image itself.

This keeps image inspection costs on the cheapest vision-capable model instead of forcing the whole subagent to switch models.

### Example delegation

```
@vision-relay inspect the screenshot at .opencode/sessions/.../assets/error.png
and tell me: which HTTP status code and which Go function is on the error page?
```

The vision-relay contract is: one image, one focused question, one compact textual answer. No chain of thought, no exploration, no side effects.

## Flash Discipline

When the selected route is **`gemini-3-flash`** (vision relay) or any cheap-flash fallback:

1. Return summary-first output.
2. Keep sections short.
3. Avoid repeated evidence and long quotations.
4. Do not include chain-of-thought.

## Delivery Delegation Model

The `delivery` agent is the sole human interface. It **never implements directly** — all technical work is delegated.

### Delegation Paths

| Path | When | Subagents |
| --- | --- | --- |
| **Direct** (skip orchestrator) | Simple, well-defined, single-agent tasks | `coder`, `explorer`, `reviewer`, `tester`, `documenter`, `vision-relay` |
| **Via Orchestrator** | Multi-step, multi-agent, or unclear scope | `orchestrator` → coordinates downstream agents |

### Decision Rules

1. **Single action, clear target** → Release the appropriate subagent directly.
2. **Multiple steps or agents needed** → Release `orchestrator`.
3. **Exploration or Q&A** → Release `explorer` directly.
4. **Parallel independent tasks** → Release multiple subagents concurrently.
5. **Image inspection by a non-vision model** → Release `vision-relay` with one focused question; do not switch the calling agent's model.

### Session Storage

All session data lives at a hardcoded path: `~/.config/opencode/sessions/`.
See `.opencode/agents/delivery.md` for the full session structure and delegation matrix.

## Selection Procedure

1. Classify the task by **importance / intent** first, not by file count alone.
2. If the task is documentation reading or synthesis, use **`opencode/minimax-m3`** (the default).
3. If the task is code search/exploration, use **`opencode/minimax-m3`** via the `explorer` agent.
4. If the task is design or architecture, route to `architect` (which uses **`opencode/glm-5.2`**).
5. If the task is multi-step orchestration, route to `orchestrator` (which uses **`opencode/qwen3.7-max`**).
6. If the task involves inspecting an image and the calling model is not vision-capable, route the image to `vision-relay` (which uses **`opencode/gemini-3-flash`**).
7. If the context is approaching **250K**, compact first and try to keep the resulting working set **<= 272K**.
8. If the primary model is unavailable, use the fallback listed in the matrix.
