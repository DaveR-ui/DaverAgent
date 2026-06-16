# Opencode LLM Routing

**Scope**: runtime agents configured in `opencode.json` and any opencode-side intake/orchestration behavior.

## Canonical Importance Matrix

| Importance / Intent | Task Type | Primary Model | Fallback Model | Routing Rule |
| --- | --- | --- | --- | --- |
| **Docs / Read-Only** | Documentation reading, prompt analysis, read-only investigation, explanatory Q&A, repo navigation for answers | **Gemini 3.5 Flash** | **GPT-5.4** | Use the cheapest fast model and force compact output. |
| **Exploration / Search** | Code search, file discovery, dependency tracing, scope discovery, architecture exploration | **GPT-5.3-Codex** | **GPT-5.4** | Prefer Codex for exploration-heavy work instead of spending GPT-5.4 on search. |
| **Important / Execution** | Orchestration, implementation, validation, architecture, risky review, multi-step reasoning | **GPT-5.4** | **GPT-5.3-Codex** | Default all important technical subagents to GPT-5.4 while the active context stays inside the cost budget below. |

## Agent Defaults

| Agent | Default Route | Notes |
| --- | --- | --- |
| `delivery` | **Docs / Read-Only** | Intake, translation, routing, and policy application. Stay compact and delegate actual technical work. |
| `orchestrator` | **Important / Execution** | Owns task decomposition, context trimming decisions, and downstream model choice. |
| `coder`, `tester`, `reviewer`, `architect` | **Important / Execution** | Use GPT-5.4 by default for important execution and reasoning work, subject to the context budget policy. |
| `explorer` | **Exploration / Search** | Use GPT-5.3-Codex for code search, discovery, and scope mapping. |
| `documenter` | **Docs / Read-Only** | Keep outputs terse and cheap; use Gemini 3.5 Flash for documentation reading or synthesis. |

## Context Budget Policy

The user-requested cost policy is:

1. **Preferred GPT-5.4 band:** use GPT-5.4 when the active context is **<= 250K**.
2. **Early compaction trigger:** when the working set is getting close to **250K**, reduce context before releasing or continuing an important subagent.
3. **Cheap-band ceiling:** after compaction, aim to keep the working set **<= 272K** whenever feasible because that band is materially cheaper.
4. **Do not pay for redundant context:** remove repeated evidence, long pasted excerpts, irrelevant files, stale plans, and duplicate summaries before escalating.

### Required Context-Reduction Moves

When the context is trending toward the budget limit:

1. Keep only the bounded task slice, current plan, and the smallest necessary evidence.
2. Replace large file dumps with targeted excerpts or summaries.
3. Split exploration into a separate `explorer` handoff instead of bloating the execution agent.
4. Route documentation lookup through `librarian` / Gemini instead of carrying raw docs into GPT-5.4.
5. If needed, split the work into multiple bounded subagents rather than letting one context sprawl.

## Documentation Topic Fast Path

When the user asks for **Opencode**, **VSCode**, or **Angular** documentation/data lookup:

1. Use the **`librarian` skill** first.
2. Keep the answer read-only unless the user explicitly asks for configuration changes.
3. Because this route is documentation/research, default to the **Docs / Read-Only** route and apply compact-output discipline.

## Exploration Fast Path

When the task is mainly code search, repo exploration, or scope discovery:

1. Route directly to **`explorer`** when possible.
2. Use **GPT-5.3-Codex** as the first choice.
3. Escalate to GPT-5.4 only if the exploration turns into high-risk reasoning or architecture decisions.

## Flash Discipline

When the selected route is **Docs / Read-Only**:

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

1. Classify the task by **importance / intent** first, not by file count alone.
2. If the task is documentation reading or synthesis, use **Gemini 3.5 Flash**.
3. If the task is code search/exploration, use **GPT-5.3-Codex**.
4. Otherwise, treat the subagent as **Important / Execution** and use **GPT-5.4** when the active context is **<= 250K**.
5. If the context is approaching **250K**, compact first and try to keep the resulting working set **<= 272K**.
6. If the primary model is unavailable, use the fallback.
