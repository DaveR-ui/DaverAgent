# Protocol: IA Learner

Orchestration and learning: convert ephemeral session data (fixes, pivots, errors) into persistent architectural rules and learning logs, with a strict relevance filter that discards noise.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-learner`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

Immediately after the [tester](../agents/subagents/tester.md) or [reviewer](../agents/subagents/reviewer.md) subagent confirms a success or after a failure has been recorded. The learner is responsible for the long-term intelligence of the ecosystem: it ensures the system evolves and avoids repeating past mistakes.

## Information capture

- **From successes** — extract the "Learning Point" from the Solution Memory.
- **From failures** — capture the "Intuitive Clue" provided by the user and the root cause of the failure.
- **From Hot Spots** — document the architectural pivot validated by the user in Phase 2 of [prompt-pipeline.md](./prompt-pipeline.md).

## Management of orchestrator rules

Update the central rule set to refine how the orchestrator routes tasks:

- **Rule compounding** — if a specific component pattern is repeatedly successful (or failing), codify it as a mandatory "pre-flight" check in the canonical rules doc (`docs/context/rules.md` or a slice-specific `task-memory.md`).
- **Inconsistency removal** — prune rules that have become redundant due to new architectural standards (e.g. removing legacy state-management rules once a feature is fully signal-based).

## Maintenance of the learning log

Maintain a chronological log (typically in the slice's `task-memory.md` or a centralized `docs/context/memory/task-memory.md`) that includes:

- **Decision records** — why a specific architectural choice was made (e.g. "chose `rxResource` over `linkedSignal` for AuthWizard due to X").
- **Pattern evolution** — tracks the migration from legacy to standard patterns.

## Synchronization with SSOT

- **Project metadata** — if a new library or version was identified, update the canonical entry point ([`docs/project.md`](../../docs/project.md) Slices / Stack).
- **Component map** — ensure `docs/context/README.md` reflects any new documentation created during the session.

## Relevance filter (noise reduction)

Before recording any learning, evaluate if it meets the **Worthy of Record** threshold. A learning is recorded only if it satisfies at least one of these:

- **Multi-attempt resolution** — resolved an error that required more than 2 attempts or iterations.
- **Cross-component impact** — involves an architectural decision that affects more than one component or service.
- **User-confirmed style preference** — represents a style or UX preference explicitly confirmed by the user that is not already documented in `docs/context/rules.md`.

If a learning meets none of these, classify it as **Noise** and discard it. Do not log trivial one-off fixes, typos, or obvious standard patterns.

## Rule reconciliation policy

Before adding a new rule:

1. Scan `docs/context/rules.md` (or the relevant slice doc) for existing rules that cover the same domain.
2. **Check for contradictions** — if the proposed rule contradicts or weakens an existing global rule, the **global rule takes precedence**.
3. **Override protocol** — if the user explicitly authorizes an override of a global rule, document it as:
   ```
   [OVERRIDE] Global rule: "{original rule}" → Session-specific override: "{new rule}" (Authorized by user on {date})
   ```
   Overrides must be flagged for review during the next pruning cycle.

## Pruning mechanism

Periodically scan the learning log and identify entries eligible for removal or archival:

- **Age threshold** — entries older than 10 sessions that have not been referenced or triggered in recent sessions are candidates for archival.
- **Framework supersession** — entries that have been rendered obsolete by a new framework version or completed migration (e.g. legacy patterns fully replaced by signals, deprecated APIs removed) must be flagged for deletion.
- **Override expiration** — user-authorized overrides that have not been re-confirmed in the last 5 sessions are candidates for reversion to the global rule.

When pruning, output a **Pruning Report** listing entries removed, the reason (age / supersession / override expiration), and the session in which they were originally recorded.

## Compact format enforcement

Every log entry follows the strict **"Problem → Pattern → Result"** format with a maximum of **3 lines per entry**. No exceptions. Prose, narratives, or multi-paragraph explanations are prohibited in the learning log.

## Output format

Return a Knowledge Update Summary:

- **New rules added** — list of updates to task memory and orchestrator rules.
- **Log entry** — a summary of the lesson learned for the learning log.
- **Precision impact** — estimated improvement for future tasks (e.g. "reduced ambiguity in signal-syncing for future wizards").
- **Pruning report** (if applicable) — entries removed or archived with reason.

## Constraints

- **PROHIBITED**: recording long prose without a structured "Problem → Pattern → Result" format.
- **PROHIBITED**: adding redundant rules that duplicate existing standards in `docs/context/rules.md`.
- **PROHIBITED**: recording learnings that do not pass the Relevance Filter.
- **PROHIBITED**: adding rules that contradict `docs/context/rules.md` without explicit user override authorization.
- **MANDATORY**: linking every log entry to a specific file or feature folder in `docs/context/`.
- **MANDATORY**: enforcing the 3-line maximum per log entry.
- **MANDATORY**: running the pruning scan before appending new entries to prevent token bloat.

## Integration

The learner is the most "maturity"-oriented protocol in this set. It complements [documenter](../agents/subagents/documenter.md) (which writes the docs) and the [tester](../agents/subagents/tester.md) / [reviewer](../agents/subagents/reviewer.md) subagents (which verify work). In the opencode runtime, the [orchestrator](../agents/subagents/orchestrator.md) decides when to invoke the learner (typically after a verified success or a Hot-Spot pivot), and periodic pruning (see the Pruning mechanism section above) handles the long-term memory maintenance. The relevance filter above is the durable value of this protocol — it should be applied even when the doc target is `docs/context/` rather than the original skill target.
