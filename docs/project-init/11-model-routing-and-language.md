# 11 — Model Routing and Language Protocol

> Experiential annotations on model routing, context budget discipline, and language protocol for the ab-ceramica agent system.

---

## Model routing

Source of truth: `.opencode/llm-routing.md`

| Importance / Intent | Task Type | Primary Model | Fallback |
|---|---|---|---|
| **Docs / Read-Only** | Documentation, prompt analysis, Q&A, repo navigation | Gemini 3.5 Flash | GPT-5.4 |
| **Exploration / Search** | Code search, file discovery, dependency tracing, scope discovery | GPT-5.3-Codex | GPT-5.4 |
| **Important / Execution** | Orchestration, implementation, validation, architecture, multi-step reasoning | GPT-5.4 | GPT-5.3-Codex |

### Agent defaults

| Agent | Default Route |
|---|---|
| `delivery` | Docs / Read-Only |
| `orchestrator` | Important / Execution |
| `coder`, `tester`, `reviewer`, `architect` | Important / Execution |
| `explorer` | Exploration / Search |
| `documenter` | Docs / Read-Only |

---

## Context budget policy

| Threshold | Action |
|---|---|
| ≤ 250K | Preferred GPT-5.4 band — use GPT-5.4 freely |
| Approaching 250K | Early compaction trigger — reduce context before continuing |
| After compaction | Cheap-band ceiling — aim for ≤ 272K |
| Redundant context | Remove repeated evidence, long excerpts, irrelevant files, stale plans, duplicate summaries |

### Context reduction moves

1. Keep only the bounded task slice, current plan, and smallest necessary evidence.
2. Replace large file dumps with targeted excerpts or summaries.
3. Split exploration into a separate `explorer` handoff instead of bloating the execution agent.
4. Route documentation lookup through expert subagents (`angular-expert`, `opencode-expert`, `vscode-expert`).
5. Split work into multiple bounded subagents rather than letting one context sprawl.

---

## Language protocol

| Channel | Language |
|---|---|
| Human ↔ Delivery | Human's language (Spanish rioplatense for david.romaniuk) |
| Delivery ↔ Subagents | English, full translation |

**Rules:**

- **NEVER** speak English with the human.
- **NEVER** pass the human's language to subagents — translate fully before delegating.
- The human's language is determined from `humano.md`. If `humano.md` doesn't specify, ask the human.

---

## Delivery delegation model

The `delivery` agent is the sole human interface. It **never implements directly** — all technical work is delegated.

| Path | When | Subagents |
|---|---|---|
| **Direct** (skip orchestrator) | Simple, well-defined, single-agent tasks | `coder`, `explorer`, `reviewer`, `tester`, `documenter` |
| **Via Orchestrator** | Multi-step, multi-agent, or unclear scope | `orchestrator` → coordinates downstream agents |

### Decision rules

1. Single action, clear target → release the appropriate subagent directly.
2. Multiple steps or agents needed → release `orchestrator`.
3. Exploration or Q&A → release `explorer` directly.
4. Parallel independent tasks → release multiple subagents concurrently.

---

## Flash discipline

When the route is **Docs / Read-Only**:

1. Return summary-first output.
2. Keep sections short.
3. Avoid repeated evidence and long quotations.
4. Do NOT include chain-of-thought.

---

## Documentation topic fast path

| Topic | Subagent | Constraint |
|---|---|---|
| Angular | `angular-expert` | Read-only, no web fallback, no training data |
| Opencode | `opencode-expert` | Read-only, no web fallback, no training data |
| VSCode | `vscode-expert` | Read-only, no web fallback, no training data |

If the expected docs folder is missing, the expert reports the exact path and **stops** — no guessing.

---

## Gotchas

- **The `delivery` agent is Docs/Read-Only route.** It should stay compact and delegate ALL technical work. Don't let it accumulate context by reading large files or doing exploration itself.
- **The `delivery` agent NEVER implements directly** — even "simple" documentation writing should be delegated to a `coder`. This task (writing these docs) is itself delegated.
- **Subagent prompts must be in English.** Translate the human's request fully before passing it to the orchestrator or any subagent.
- **Expert subagents are READ-ONLY.** They must not fall back to the web or training data. If the expected docs folder is missing, they report the exact path and stop.
- **Don't carry raw documentation into GPT-5.4 context.** Route it through the expert subagents instead — that's what they exist for.
- **The human's language comes from `humano.md`.** If it's not specified there, ask — don't assume.
- **Context budget is about active context, not file count.** A single large file can blow the budget faster than twenty small ones.

---

## Quick Reference

| Item | Value |
|---|---|
| Docs/Read-Only model | Gemini 3.5 Flash |
| Exploration/Search model | GPT-5.3-Codex |
| Important/Execution model | GPT-5.4 |
| Preferred GPT-5.4 band | ≤ 250K active context |
| Cheap-band ceiling (post-compaction) | ≤ 272K |
| Human ↔ Delivery language | Human's language (from `humano.md`) |
| Delivery ↔ Subagents language | English |
| Direct delegation | Single action, clear target |
| Orchestrator delegation | Multiple steps or unclear scope |
| Flash discipline | Summary-first, short sections, no chain-of-thought |

---

## Cross-references

- `.opencode/llm-routing.md` — canonical model routing source of truth.
- `.opencode/model-routing.md` — compatibility entry point for model selection.
- `02-session-bootstrap.md` — `humano.md` source and language determination.