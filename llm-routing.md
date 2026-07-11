# Opencode LLM Routing

**Scope**: runtime agents configured in `opencode.json` and any opencode-side intake/orchestration behavior.

## Canonical Importance Matrix

| Importance / Intent | Task Type | Primary Model | Fallback Model | Routing Rule |
| --- | --- | --- | --- | --- |
| **Intake / Routing** | Delivery intake, prompt analysis, routing decisions, policy application, human-facing translation | **`opencode-go/minimax-m3`** (MiniMax M3) | `opencode/gemini-3-flash` | Delivery uses the cheap 1M-context generalist; routing decisions are simple enough that the cheap model suffices, and the smart models are reserved for the specialist subagents (coder/tester/reviewer/architect/orchestrator). |
| **Docs / Read-Only** | Documentation reading, read-only investigation, explanatory Q&A, repo navigation for answers (explorer, project-context, opencode-expert) | **`opencode-go/minimax-m3`** (MiniMax M3) | `opencode/gemini-3-flash` | Use the cheapest fast model and force compact output. |
| **Exploration / Search** | Code search, file discovery, dependency tracing, scope discovery, architecture exploration | **`opencode-go/minimax-m3`** (MiniMax M3) | `opencode/gemini-3-flash` | Average-cost generalist is enough; fall back to the cheapest flash on capacity issues. |
| **Code** | Programming, bug fixes, feature implementation, refactoring, tests | **`opencode-go/kimi-k2.7-code`** (Kimi K2.7 Code) | `opencode-go/minimax-m3` | Code-specialized model with 262k context = 262k output. No `temperature` support. |
| **Code Review** | Code review, security audit, best-practices check, second-opinion on complex work | **`opencode-go/qwen3.7-plus`** (Qwen 3.7 Plus) | `opencode-go/minimax-m3` | Middle tier; intentionally a different model family from the coder (`kimi-k2.7-code`) for genuine perspective diversity. |
| **Design / Architecture** | System design, module boundaries, patterns, high-level architecture decisions, design reviews | **`opencode-go/glm-5.2`** (GLM 5.2) | `opencode-go/minimax-m3` | Use GLM 5.2 for design-quality work because its reasoning profile is stronger for long-horizon planning. |
| **Orchestration (advanced)** | Multi-step task decomposition, multi-agent coordination, planning, synthesis across heterogeneous sources | **`opencode-go/qwen3.7-max`** (Qwen 3.7 Max) | `opencode-go/minimax-m3` | Use the most capable reasoning model here; orchestrators carry the most cross-agent context and the highest cost-of-error. |
| **Vision Relay** | Single-purpose image inspection for non-vision models: OCR screenshots, UI mockups, diagrams, error dialogs | **`opencode-go/minimax-m3`** (MiniMax M3) | `opencode/gemini-3-flash` | Cheapest vision-capable model we use. `gemini-3-flash` retained as runtime fallback. |

### Why these specific models

- **MiniMax M3 (`opencode-go/minimax-m3`)** — $0.30 in / $1.20 out per 1M tokens, 0.06 cached. Strong generalist at a low price with 1M context. Used by `delivery`, `explorer`, `project-context`, `opencode-expert` (the "investigations" and docs-lookup agents) and `vision-relay`.
- **Kimi K2.7 Code (`opencode-go/kimi-k2.7-code`)** — $0.95 in / $4.00 out. Code-specialized model with 262k context = 262k output. Used by `coder` and `tester`. Does not support `temperature` customization — the field is ignored by the API.
- **Qwen 3.7 Plus (`opencode-go/qwen3.7-plus`)** — $0.40 in / $1.60 out. Middle tier. Used by `reviewer` so the review comes from a **different model family** than the one that wrote the code (`kimi-k2.7-code`), giving a genuinely different perspective without paying the full `qwen3.7-max` price.
- **GLM 5.2 (`opencode-go/glm-5.2`)** — $1.40 in / $4.40 out. Used only for `architect` and design-quality tasks where long-horizon reasoning and structured design output matter more than throughput. Kept as a **third distinct model** in the coder/reviewer/architect trio for maximum perspective diversity.
- **Qwen 3.7 Max (`opencode-go/qwen3.7-max`)** — $2.50 in / $7.50 out, plus prompt-caching savings. Reserved for `orchestrator` because it carries the cross-agent synthesis load and the highest cost-of-error.
- **Gemini 3 Flash (`opencode/gemini-3-flash`)** — $0.50 in / $3.00 out. No longer the primary for `vision-relay` (replaced by the cheaper `minimax-m3`), but retained as a runtime fallback if `minimax-m3` is unavailable.

## Agent Defaults

Each agent has a per-agent `model` field. The runtime rule is: **the agent's own `model` field wins over the global default**. If a per-agent model is missing, subagents inherit the primary agent's model.

| Agent | Default Model | Route Class | Notes |
| --- | --- | --- | --- |
| `delivery` | `opencode-go/minimax-m3` | Intake / Routing | Intake, translation, routing, and policy application. Uses the cheap 1M-context generalist; routing is simple enough that the smart models are reserved for the specialist subagents. Delegates all technical work. |
| `orchestrator` | `opencode-go/qwen3.7-max` | Orchestration (advanced) | Owns task decomposition, context trimming decisions, and downstream model choice. |
| `coder` | `opencode-go/kimi-k2.7-code` | Code (specialized) | Programming, bug fixes, feature implementation, refactoring. Code-specialized model; no `temperature` (unsupported by API). |
| `tester` | `opencode-go/kimi-k2.7-code` | Code (specialized) | Unit, integration, e2e tests. Same model as `coder` because tests are code; no `temperature`. |
| `reviewer` | `opencode-go/qwen3.7-plus` | Complex (different perspective) | Code review, security audit, best practices. Read-only by permission. Different model family from `coder` on purpose. |
| `architect` | `opencode-go/glm-5.2` | Design / Architecture | System design, module boundaries, patterns. Third distinct model in the coder/reviewer/architect trio. |
| `explorer` | `opencode-go/minimax-m3` | Exploration / Search | Code search, file discovery, dependency tracing. |
| `project-context` | `opencode-go/minimax-m3` | Docs / Read-Only | Reads and writes `docs/`. |
| `opencode-expert` | `opencode-go/minimax-m3` | Docs / Read-Only | Read-only opencode documentation lookup. |
| `vision-relay` | `opencode-go/minimax-m3` | Vision Relay | Image inspection only. Cheaper than the previous `gemini-3-flash`; `gemini-3-flash` retained as runtime fallback. |

## Context Budget Policy

The user-requested cost policy is:

1. **Preferred band per tier:** MiniMax M3 stays cheap; do not escalate to Qwen 3.7 Max unless the work is orchestration; do not escalate to GLM 5.2 unless the work is design.
2. **Early compaction trigger:** when the working set is getting close to **250K**, reduce context before releasing or continuing an important subagent.
3. **Cheap-band ceiling:** after compaction, aim to keep the working set **<= 272K** whenever feasible because that band is materially cheaper.
4. **Do not pay for redundant context:** remove repeated evidence, long pasted excerpts, irrelevant files, stale plans, and duplicate summaries before escalating.
5. **Escalation ladder (cheap → expensive):**
   - `minimax-m3` (cheapest, vision-capable) → used by `delivery`, `explorer`, `project-context`, `opencode-expert`, `vision-relay`.
   - `qwen3.7-plus` (middle tier, different perspective) → used by `reviewer` for code review.
   - `kimi-k2.7-code` (code-specialized) → used by `coder` and `tester`.
   - `glm-5.2` (design) → used by `architect` only.
   - `qwen3.7-max` (advanced orchestration) → used by `orchestrator` only.
   - `gemini-3-flash` (previous vision primary) → retained as runtime fallback for `vision-relay` if `minimax-m3` is unavailable.

### Required Context-Reduction Moves

When the context is trending toward the budget limit:

1. Keep only the bounded task slice, current plan, and the smallest necessary evidence.
2. Replace large file dumps with targeted excerpts or summaries.
3. Split exploration into a separate `explorer` handoff instead of bloating the execution agent.
4. Route documentation lookup through the dedicated expert subagents instead of carrying raw docs into the design or orchestration tier.
5. If a non-vision model needs to inspect an image, route the image through `vision-relay` instead of escalating the whole task to a vision-capable model.
6. If needed, split the work into multiple bounded subagents rather than letting one context sprawl.

## Documentation Topic Fast Path

When the user asks for **Opencode** documentation/data lookup:

1. Delegate to the dedicated read-only expert subagent:
   - `opencode-expert` — read-only lookup against `docs/project.md`, `AGENTS.md`, `CONTEXT.md`, and the slice READMEs under `docs/<slice>/<subslice>/README.md`.
2. These agents are **read-only** and **must not** fall back to the web or to training data. If the expected docs are missing, they report and stop.
3. Because this route is documentation/research, default to the **Docs / Read-Only** route and apply compact-output discipline. Keep the answer read-only unless the user explicitly asks for configuration changes.

## Exploration Fast Path

When the task is mainly code search, repo exploration, or scope discovery:

1. Route directly to **`explorer`** when possible.
2. Use **`opencode-go/minimax-m3`** as the first choice (average-cost generalist, no need to pay more for search).
3. Escalate to `qwen3.7-max` only if the orchestrator itself is doing the exploration and needs synthesis at the same time.

## Vision Relay Fast Path

When a subagent (or the orchestrator) needs to inspect an image but its own model does not have vision input:

1. The calling agent delegates the image to **`vision-relay`** with a specific question.
2. `vision-relay` uses `opencode-go/minimax-m3` to look at the image and returns a compact textual answer.
3. The calling agent continues its work with the textual answer — it does not need to receive the image itself.

This keeps image inspection costs on the cheapest vision-capable model we use instead of forcing the whole subagent to switch models. If `minimax-m3` is unavailable, the runtime falls back to `opencode/gemini-3-flash` (the previous primary).

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
2. If the task is delivery intake / routing / prompt analysis, use **`opencode-go/minimax-m3`** (the `delivery` agent — the cheap 1M-context generalist; smart models are reserved for specialist subagents).
3. If the task is documentation reading/synthesis or code search/exploration, use **`opencode-go/minimax-m3`** via `project-context` / `opencode-expert` / `explorer` (the cheap 1M-context "investigations" model).
4. If the task is code implementation, bug fixing, refactoring, or test writing, route to `coder` / `tester` (which use **`opencode-go/kimi-k2.7-code`**).
5. If the task is code review, security audit, or best-practices check, route to `reviewer` (which uses **`opencode-go/qwen3.7-plus`** — a different model family from the coder for genuine perspective diversity).
6. If the task is design or architecture, route to `architect` (which uses **`opencode-go/glm-5.2`** — a third distinct model in the coder/reviewer/architect trio).
7. If the task is multi-step orchestration, route to `orchestrator` (which uses **`opencode-go/qwen3.7-max`**).
8. If the task involves inspecting an image and the calling model is not vision-capable, route the image to `vision-relay` (which uses **`opencode-go/minimax-m3`**).
9. If the context is approaching **250K**, compact first and try to keep the resulting working set **<= 272K**.
10. If the primary model is unavailable, use the fallback listed in the matrix.
