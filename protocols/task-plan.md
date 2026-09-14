# Protocol: Task Plan

A **machine-checkable JSON task plan**: the executable decomposition an `orchestrator` emits after Phase 2 (Reduce), before it releases subagents. It makes dependencies, parallelism, and the two file vocabularies explicit so a plan can be validated by a script instead of read by eye.

This protocol is the machine representation. `protocols/prompt-pipeline.md` remains the **thinking** convention (Step 0 Interpret → Phase 2 Reduce); this plan is the executable form of the Reduce output. It does not replace the routing packet (Step 0) or the Reduce scope — it encodes the Reduce decomposition in a checkable shape.

## When to use

Emit a task plan when:

- The work decomposes into **2+ subtasks** with dependencies or parallelism, or
- The work touches **5+ files** / spans **2+ subagents**, or
- The human or a downstream agent needs a reviewable, checkable decomposition.

Do **not** emit one for a single atomic task — a one-subtask plan is noise. A single-liner, a lookup, or a mechanical one-file edit goes straight to the owning subagent.

## The plan schema

JSON Schema (draft 2020-12) for the envelope. The structural invariants a schema cannot express (DAG acyclicity, executability, the `parallel` barrier) are in `## Validation invariants` below.

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "TaskPlan",
  "type": "object",
  "required": ["plan_id", "goal", "subtasks"],
  "additionalProperties": false,
  "properties": {
    "plan_id": { "type": "string", "minLength": 1 },
    "goal": { "type": "string", "minLength": 1 },
    "acceptance": { "type": "array", "items": { "type": "string" } },
    "subtasks": {
      "type": "array",
      "minItems": 1,
      "items": {
        "type": "object",
        "required": [
          "id", "title", "suggested_agent", "agent_id",
          "depends_on", "parallel", "context_files", "reference_files", "status"
        ],
        "additionalProperties": false,
        "properties": {
          "id": { "type": "string", "pattern": "^[A-Za-z0-9_-]+$" },
          "title": { "type": "string", "minLength": 1 },
          "suggested_agent": { "type": "string", "minLength": 1 },
          "agent_id": { "type": ["string", "null"] },
          "depends_on": { "type": "array", "items": { "type": "string" } },
          "parallel": { "type": "boolean" },
          "context_files": { "type": "array", "items": { "type": "string" } },
          "reference_files": { "type": "array", "items": { "type": "string" } },
          "acceptance": { "type": "array", "items": { "type": "string" } },
          "status": { "type": "string", "enum": ["pending", "in_progress", "done", "blocked", "skipped"] }
        }
      }
    }
  }
}
```

## Example plan

```json
{
  "plan_id": "task-plan-2026-09-13-add-standards-scout",
  "goal": "Adopt the OAC standards-scout pattern into the global agent system",
  "acceptance": ["drafts exist under /tmp/...", "tests stay green after apply"],
  "subtasks": [
    {
      "id": "T1",
      "title": "Draft agents/standards-scout.md",
      "suggested_agent": "coder",
      "agent_id": "coder",
      "depends_on": [],
      "parallel": true,
      "context_files": ["protocols/subagent-spec-template.md", "agents/external-scout.md"],
      "reference_files": ["tests/test-agent-hardening.py"],
      "acceptance": ["3-section shell with ordered anchors", "mode: subagent"],
      "status": "pending"
    },
    {
      "id": "T2",
      "title": "Add standards-scout: allow to delivery task map",
      "suggested_agent": "coder",
      "agent_id": "coder",
      "depends_on": ["T1"],
      "parallel": false,
      "context_files": ["agents/delivery.md"],
      "reference_files": [],
      "acceptance": ["entry at 4-space indent", "test-agent-hardening reachability passes"],
      "status": "pending"
    }
  ]
}
```

The example above is **executable** (every `agent_id` resolved, so invariant 4 holds). A plan that still ties any routing decision is **PROPOSED**, not executable: leave that subtask's `agent_id` as `null` and do not release it until the orchestrator resolves it.

## Field contract

| Field | Type | Required | Meaning |
|---|---|---|---|
| `plan_id` | string | yes | Stable id; `<slug>` or `task-plan-<date>-<slug>`. Unique per plan. |
| `goal` | string | yes | One-line objective. |
| `acceptance` | string[] | no | Plan-level done criteria. |
| `subtasks` | object[] | yes | Non-empty list of atomic subtasks. |
| `subtasks[].id` | string | yes | Unique within the plan (`^[A-Za-z0-9_-]+$`). |
| `subtasks[].title` | string | yes | One-line imperative. |
| `subtasks[].suggested_agent` | string | yes | **Hint** — the discipline this subtask looks like (e.g. `coder`). May be an agent id or a capability. |
| `subtasks[].agent_id` | string \| null | yes | **Resolved** concrete agent id the orchestrator will actually call (e.g. `coder`, `tester`); `null` until routed. |
| `subtasks[].depends_on` | string[] | yes | Ids of subtasks that MUST finish first. `[]` = no dependency. |
| `subtasks[].parallel` | boolean | yes | Scheduling hint, **independent of `depends_on`**. `true` = may be released concurrently with any other subtask whose dependencies are already met. `false` = **serialize** — run alone, even if it has no unmet dependencies (shared resource, ordering-sensitive, or must be observed in isolation). |
| `subtasks[].context_files` | string[] | yes | **Standards** the agent must obey before acting (docs, protocols, rules) — passed to the agent, not modified. |
| `subtasks[].reference_files` | string[] | yes | **Source/evidence** to read for the task itself (code, tests, fixtures). |
| `subtasks[].acceptance` | string[] | no | Per-subtask done criteria. |
| `subtasks[].status` | string | yes | `pending \| in_progress \| done \| blocked \| skipped`. |

### `suggested_agent` vs. `agent_id`

- `suggested_agent` is written **during decomposition** and is a hint — it says what kind of work this is, before the orchestrator commits.
- `agent_id` is the **routing decision** — the exact agent the orchestrator releases, including any `language=` / `framework=` param carried in the task payload convention. It is `null` until the orchestrator resolves it.
- A plan whose `agent_id` is `null` everywhere is still PROPOSED, not executable.
- The split is intentional even though one seat (`orchestrator`) usually authors both: it makes the PROPOSED → executable transition explicit (invariant 4), and survives intact if planning and routing are ever separated.

### `context_files` vs. `reference_files`

Two deliberately different vocabularies (do not merge them):

- `context_files` = **standards** — what the agent must *conform to* (`docs/context/*.md`, `docs/protocols/*.md`, `protocols/*.md`, `agents/<id>.md`). Read before acting; never written.
- `reference_files` = **source** — what the agent *reads to do the work* (application code, tests, fixtures, diffs). Evidence for the change.

Both lists are **advisory routing hints**, not controls: no invariant checks path existence, and the plan deliberately does **not** encode the read/modify/create distinction that Phase 2's Key-files list carries — that detail belongs to the subtask's implementation and its `acceptance`, not to the plan envelope.

## Validation invariants (machine-checkable)

A plan is **valid** iff all hold. The embedded schema already enforces field types, `required`, `status` enum, and the `id` pattern; these invariants are the rules a schema cannot express and that a validator script (follow-up) would enforce:

1. `subtasks` is non-empty; every `id` is **unique** within the plan (the pattern is schema-enforced; uniqueness is not).
2. Every `depends_on` id **resolves** to another subtask `id` in the same plan.
3. The dependency graph is a **DAG** — no cycles (a topological sort exists).
4. Every `agent_id` is **non-null** (executability) and names an agent reachable from the caller's `permission.task` map.
5. `parallel: false` subtasks are **serialized** relative to all others; `parallel` is independent of `depends_on` (a subtask may have dependencies and still be `parallel: true`).

Failed invariant ⇒ the plan is **invalid**; the orchestrator must fix it before releasing work.

## Status semantics and lifecycle

`pending → in_progress → done`, or `blocked` (a `depends_on` failed) or `skipped` (superseded by a plan revision). A `blocked` subtask stops its dependents; the orchestrator re-plans rather than forcing it.

## Relationship to other protocols

- `protocols/prompt-pipeline.md` — Step 0 (interpreter → routing packet) and Phase 2 (Reduce → scope) **feed** this plan. The plan is the Reduce output made executable.
- `protocols/approval-gate.md` — if any subtask fires the approval gate (irreversible, secret-bearing, config mutation), the plan is PROPOSED and must be APPROVED before execution.
- `protocols/broad-investigation-template.md` — a broad-investigation subtask's Search Strategy / Coverage / DoD populate that subtask's `reference_files` and `acceptance`.
- `agents/orchestrator.md` — the orchestrator owns emission, validation, and revision of the plan.

## Follow-up (deferred, out of scope here)

A CLI validator (`scripts/task-plan-validate.*`) implementing the invariants in `## Validation invariants` is **deferred**: it needs its own design, lives in `scripts/` (outside the `delivery` agent's edit scope), and must ship with tests. Until then, the embedded schema is checked only by a manual parse (no test validates `protocols/*.md`), and invariant enforcement is manual (orchestrator) plus reviewed (`reviewer`).

## Rules

- Emit a plan only for 2+ subtasks / 5+ files / multi-subagent work.
- Keep subtasks atomic; one acceptance contract each.
- Never merge `context_files` (standards) and `reference_files` (source).
- `parallel` is a scheduling hint independent of `depends_on`; `parallel: false` serializes the subtask.
- A plan is executable only when every `agent_id` is resolved and all invariants pass.
- All plan content in ENGLISH.
