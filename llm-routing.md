# Opencode LLM Routing

**Scope**: runtime agents configured in `opencode.json` and any opencode-side intake/orchestration behavior.

## Canonical Importance Matrix

| Importance / Intent | Task Type | Primary Model | Fallback Model | Routing Rule |
| --- | --- | --- | --- | --- |
| **Intake / Routing** | Delivery intake, prompt analysis, routing decisions, policy application, human-facing translation | **`opencode-go/minimax-m3`** (MiniMax M3) | — | Delivery uses the cheap 1M-context generalist; routing decisions are simple enough that the cheap model suffices, and the smart models are reserved for the specialist subagents (coder/reviewer/architect/orchestrator). |
| **Docs / Read-Only** | Documentation reading, read-only investigation, explanatory Q&A, repo navigation for answers (explorer, project-context) | **`opencode-go/minimax-m3`** (MiniMax M3) | — | Use the cheapest fast model and force compact output. |
| **Exploration / Search** | Code search, file discovery, dependency tracing, scope discovery, architecture exploration | **`opencode-go/minimax-m3`** (MiniMax M3) | — | Average-cost generalist is enough. |
| **Code** | Programming, bug fixes, feature implementation, refactoring | **`opencode-go/kimi-k3`** (Kimi K3) | `opencode-go/minimax-m3` | Kimi K3 is the code + orchestration tier; used by `coder`. The Kimi family ignores `temperature` — the field is harmless if present. |
| **Tests** | Unit tests, integration tests, test coverage, e2e | **`opencode-go/minimax-m3`** (MiniMax M3) | — | The `tester` agent runs on the cheap 1M-context generalist; tests follow documented patterns and do not need a code-specialized tier. |
| **Code Review** | Code review, security audit, best-practices check, second-opinion on complex work | **`opencode-go/glm-5.2`** (GLM 5.2) | `opencode-go/minimax-m3` | Same model as `architect`; perspective diversity is framed as Kimi (`coder`/`orchestrator`) vs GLM (`architect`/`reviewer`). |
| **Design / Architecture** | System design, module boundaries, patterns, high-level architecture decisions, design reviews | **`opencode-go/glm-5.2`** (GLM 5.2) | `opencode-go/minimax-m3` | Use GLM 5.2 for design-quality work because its reasoning profile is stronger for long-horizon planning. |
| **Orchestration (advanced)** | Multi-step task decomposition, multi-agent coordination, planning, synthesis across heterogeneous sources | **`opencode-go/kimi-k3`** (Kimi K3) | `opencode-go/minimax-m3` | Use the most capable reasoning model here; orchestrators carry the most cross-agent context and the highest cost-of-error. |
| **Vision Relay** | Single-purpose image inspection for non-vision models: OCR screenshots, UI mockups, diagrams, error dialogs | **`opencode-go/minimax-m3`** (MiniMax M3) | — | Cheapest vision-capable model we use. No fallback configured. |

> **Fallback policy (2026-07-12)**: As of this revision, no `gemini-*` models are used in the routing matrix. Routes whose primary is `minimax-m3` (Intake, Docs, Exploration, Vision Relay) have **no fallback** — if `minimax-m3` is unavailable, the runtime surfaces the error. Routes whose primary is a specialized model (Code, Code Review, Design, Orchestration) fall back to `minimax-m3` as a safety net, but this should be a rare event — investigate the underlying capacity issue instead of relying on the fallback.

### Why these specific models

- **MiniMax M3 (`opencode-go/minimax-m3`)** — $0.30 in / $1.20 out per 1M tokens, 0.06 cached. Strong generalist at a low price with 1M context. Used by `delivery`, `explorer`, `project-context` (the "investigations" and docs-lookup agents) and `vision-relay`.
- **GLM 5.2 (`opencode-go/glm-5.2`)** — $1.40 in / $4.40 out. Used for `architect` and `reviewer` — design-quality work and code review both need long-horizon reasoning and structured output. The perspective-diversity rationale is carried by the family split: Kimi (`coder`/`orchestrator`) vs GLM (`architect`/`reviewer`).
- **Kimi K3 (`opencode-go/kimi-k3`)** — $3.00 in / $15.00 out per 1M tokens; cached read $0.30, cached write $15. 1M context, 131k output. The code + orchestration tier: used by `coder` (implementation) and `orchestrator` (cross-agent synthesis, highest cost-of-error). The Kimi family ignores `temperature` — the field is harmless if present.

## Agent Defaults

Each agent has a per-agent `model` field. The runtime rule is: **the agent's own `model` field wins over the global default**. If a per-agent model is missing, subagents inherit the primary agent's model.

| Agent | Default Model | Route Class | Notes |
| --- | --- | --- | --- |
| `delivery` | `opencode-go/minimax-m3` | Intake / Routing | Intake, translation, routing, and policy application. Uses the cheap 1M-context generalist; routing is simple enough that the smart models are reserved for the specialist subagents. Delegates all technical work. |
| `orchestrator` | `opencode-go/kimi-k3` | Orchestration (advanced) | Owns task decomposition, context trimming decisions, and downstream model choice. |
| `coder` | `opencode-go/kimi-k3` | Code + Orchestration | Programming, bug fixes, feature implementation, refactoring. Same tier as the orchestrator; `temperature` field ignored by the Kimi API but harmless. |
| `tester` | `opencode-go/minimax-m3` | Cheap (generalist) | Unit, integration, e2e tests. Runs on the cheap 1M-context generalist. |
| `reviewer` | `opencode-go/glm-5.2` | Complex (long-horizon reasoning) | Code review, security audit, best practices. Read-only by permission. Same model as `architect`; the diversity for review comes from `coder`/`orchestrator` being in a different family (Kimi). |
| `architect` | `opencode-go/glm-5.2` | Design / Architecture | System design, module boundaries, patterns. Same model as `reviewer`; the split is now `kimi-k3` (coder/orchestrator) + `glm-5.2` (architect/reviewer), with `minimax-m3` covering the cheap routes (delivery/explorer/project-context/vision-relay/tester). |
| `explorer` | `opencode-go/minimax-m3` | Exploration / Search | Code search, file discovery, dependency tracing. |
| `project-context` | `opencode-go/minimax-m3` | Docs / Read-Only | Reads and writes `docs/`. |
| `vision-relay` | `opencode-go/minimax-m3` | Vision Relay | Image inspection only. No fallback configured. |

## Context Budget Policy

The user-requested cost policy is:

1. **Preferred band per tier:** MiniMax M3 stays cheap; do not escalate to Kimi K3 unless the work is code or orchestration; do not escalate to GLM 5.2 unless the work is design or review.
2. **Early compaction trigger:** when the working set is getting close to **250K**, reduce context before releasing or continuing an important subagent.
3. **Cheap-band ceiling:** after compaction, aim to keep the working set **<= 272K** whenever feasible because that band is materially cheaper.
4. **Do not pay for redundant context:** remove repeated evidence, long pasted excerpts, irrelevant files, stale plans, and duplicate summaries before escalating.
5. **Escalation ladder (cheap → expensive):**
   - `minimax-m3` (cheapest, vision-capable) → used by `delivery`, `explorer`, `project-context`, `vision-relay`, `tester`.
   - `glm-5.2` (design and review) → used by `architect` and `reviewer`.
   - `kimi-k3` (code + orchestration) → used by `coder` and `orchestrator`. The cheap routes above must not escalate to K3; it is reserved for implementation and coordination work.

> **Runtime note (2026-07-19) — compaction is config-enforced, not prompt-enforced:** the project `opencode.json` sets `"compaction": { "auto": true, "prune": true, "reserved": 10000 }`. `prune: true` makes the runtime delete old tool outputs to save tokens, which is the mechanism that actually keeps sessions inside the cheap band; the 250K trigger / 272K ceiling above is the agent-side discipline layered on top. If compaction misbehaves (context lost mid-task, premature pruning, overflow during compaction) or the targets need tuning, adjust that `opencode.json` block and **restart opencode** — do not work around it by editing agent prompts. `small_model` is also pinned to `opencode-go/minimax-m3` in the same file so title/summary generation never escalates tier.

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

1. Delegate to `project-context` for read-only lookup against `docs/project.md`, `AGENTS.md`, `CONTEXT.md`, and the slice READMEs under `docs/<slice>/<subslice>/README.md`.
2. Keep the answer read-only unless the user explicitly asks for configuration changes.
3. Because this route is documentation/research, default to the **Docs / Read-Only** route and apply compact-output discipline.

## Exploration Fast Path

When the task is mainly code search, repo exploration, or scope discovery:

1. Route directly to **`explorer`** when possible.
2. Use **`opencode-go/minimax-m3`** as the first choice (average-cost generalist, no need to pay more for search).
3. Escalate to `kimi-k3` only if the orchestrator itself is doing the exploration and needs synthesis at the same time.

## Vision Relay Fast Path

When a subagent (or the orchestrator) needs to inspect an image but its own model does not have vision input:

1. The calling agent delegates the image to **`vision-relay`** with a specific question.
2. `vision-relay` uses `opencode-go/minimax-m3` to look at the image and returns a compact textual answer.
3. The calling agent continues its work with the textual answer — it does not need to receive the image itself.

This keeps image inspection costs on the cheapest vision-capable model we use instead of forcing the whole subagent to switch models.

### Example delegation

```
@vision-relay inspect the screenshot at .opencode/sessions/.../assets/error.png
and tell me: which HTTP status code and which Go function is on the error page?
```

The vision-relay contract is: one image, one focused question, one compact textual answer. No chain of thought, no exploration, no side effects.

## Cheap Model Discipline

When the selected route is `minimax-m3` or any other cheap-tier model:

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
3. If the task is documentation reading/synthesis or code search/exploration, use **`opencode-go/minimax-m3`** via `project-context` / `explorer` (the cheap 1M-context "investigations" model).
4. If the task is code implementation, bug fixing, refactoring, or test writing, route to `coder` / `tester` (which use **`opencode-go/kimi-k3`** and **`opencode-go/minimax-m3`** respectively).
5. If the task is code review, security audit, or best-practices check, route to `reviewer` (which uses **`opencode-go/glm-5.2`** — same model as `architect`; the diversity for review now comes from the `coder` being in a different model family).
6. If the task is design or architecture, route to `architect` (which uses **`opencode-go/glm-5.2`**).
7. If the task is multi-step orchestration, route to `orchestrator` (which uses **`opencode-go/kimi-k3`**).
8. If the task involves inspecting an image and the calling model is not vision-capable, route the image to `vision-relay` (which uses **`opencode-go/minimax-m3`**).
9. If the context is approaching **250K**, compact first and try to keep the resulting working set **<= 272K**.
10. If the primary model is unavailable, use the fallback listed in the matrix.
