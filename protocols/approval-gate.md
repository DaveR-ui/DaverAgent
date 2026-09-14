# Protocol: Approval Gate

The **propose → approve → execute** rule. Some actions are consequential enough that the agent system must present them, get an explicit approval, and only then execute. This protocol defines *when* the gate fires, *who* approves, and *how* the approval is represented. It is the human-decision layer that sits above the runtime permission layer.

## When to apply

The gate fires for any action that is one or more of:

- **Irreversible or destructive** — deleting files/branches/data, force-pushing, dropping schemas or tables, rewriting history.
- **Secret- or credential-bearing** — touching `.env`, `*.key`, `*.secret`, `*.pem`, tokens, or any credential file.
- **Outward-facing** — publishing, releasing, deploying, sending messages/emails, or any network side effect beyond read-only fetch.
- **Agent-system config mutation outside the review loop** — `agents/**`, `protocols/**`, `workflows/**`, `opencode.json` (the `delivery` agent's `## Agent-system changes require review` loop is the domain-specific instance of this gate).
- **Costly or broad blast radius** — bulk rewrites, mass renames, dependency upgrades across packages.

Ordinary reversible work (reading, drafting, local edits inside the project tree) does **not** fire the gate. When in doubt, fire it — a needless approval costs one round-trip; a missing one can be unrecoverable.

## The three states

| State | Meaning | Owner |
|---|---|---|
| **PROPOSED** | A concrete action + its blast radius is written down for the human | `delivery` |
| **APPROVED** / **REJECTED** | An explicit human decision on that proposal | Human |
| **EXECUTED** | The action ran, after APPROVED | `coder` / `orchestrator` / the receiving agent |

**Approval is explicit, never inferred.** Silence, "looks fine", or the absence of an objection is **not** approval. A proposal that is not approved stays PROPOSED.

## The proposal (PROPOSED)

A proposal MUST state, at minimum:

1. **Action** — the exact operation, in one sentence.
2. **Blast radius** — files/paths, branches, environments, or external systems affected; whether reversible and how.
3. **Secrets** — whether any secret-bearing path is touched.
4. **Alternatives** — 2–3 viable options with the recommendation first.
5. **Rollback** — how to undo it, or "irreversible".

`delivery` owns the proposal to the human (it is the sole human interface). For multi-step work, `orchestrator` produces the technical proposal and `delivery` relays it. The `question` tool — with all blocking questions batched, per `protocols/prompt-pipeline.md` — is the mechanism. These are **post-routing approval questions** owned by `delivery`/`orchestrator`; they are not Step 0 interpreter blockers.

## Relationship to the existing gates

These are **complementary, not redundant** — do not collapse them:

- **Interpreter-first gate** (`workflows/dispatch.md`, `protocols/prompt-pipeline.md`) — every turn *starts* by interpreting the prompt. Different axis (routing, not approval).
- **Agent-system review loop** (`agents/delivery.md` → `## Agent-system changes require review`) — the domain-specific instance of this gate for config edits (draft → review → apply → verify). For agent-system config edits, a **passing review** (`reviewer` / `analista`) satisfies the gate; `delivery` informs the human of the apply, and no separate human approval round-trip is required unless the edit is itself irreversible or secret-bearing.
- **Runtime permission rules** (`opencode.json` `permission` + agent frontmatter) — the *enforcement* layer (`allow`/`ask`/`deny`). `ask` is the runtime's built-in approval prompt; this protocol governs the **agent-level decision to propose at all**, including cases the runtime would silently `allow`.
- **Hard limits** (`agents/orchestrator.md` → `## Hard Limits`) — the never-list (secrets, force-push, empty commits, fabricated work). This protocol adds the *propose-first* behavior for the gray zone the never-list does not cover.

## Execution after APPROVED

- Execute exactly what was approved — no scope creep. If reality differs from the proposal, stop and re-propose.
- Record the approval (who, what, when) in the task/session context so downstream agents do not re-ask the same question.
- If the action is irreversible, state that it was executed unconditionally.

## Machine shape (optional)

When a plan spans multiple gated actions, carry the approvals as a compact envelope so each step's state is explicit:

```json
{
  "proposal_id": "approve-2026-09-13-secret-rotate",
  "action": "rotate the staging API key in .env.staging",
  "blast_radius": [".env.staging"],
  "secrets": true,
  "reversible": false,
  "state": "approved",
  "approved_by": "human",
  "approved_at": "2026-09-13T20:00:00Z"
}
```

`state` ∈ `proposed | approved | rejected | executed`.

## Rules

- **Single source of truth.** This protocol is the canonical statement of the propose → approve → execute rule. The `delivery` review loop and the `orchestrator` Hard Limits are **instances** that reference it — do not restate the rule elsewhere; point here.
- Fire the gate on irreversible, secret-bearing, outward-facing, config-mutating, or broad-blast-radius actions.
- Approval is explicit; silence is never consent.
- Proposals state action, blast radius, secrets, alternatives, and rollback.
- Execute only what was approved; re-propose on any deviation.
- Never bypass the gate to "save a round-trip".
