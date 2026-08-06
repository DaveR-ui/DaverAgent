# Protocol: IA Pruner

Maintenance: prevent context drift and instruction bloat by archiving obsolete data and promoting useful patterns into the canonical standards.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-pruner`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

Periodic maintenance, after a project milestone, or every 10 sessions. The pruner ensures `docs/` and `.opencode/protocols/` remain lean, accurate, and relevant. It is the only role authorized to bulk-archive assets.

## Session cleanup

- **Archive** — move the contents of any session cache (except the most recent 2) to an `archive/` folder, or delete them if already summarized in `task-memory.md`.
- **Deduplicate** — if a lesson in `session-memory.md` is now a standard in `docs/context/rules.md`, delete the session-specific memory file.

## Instruction consolidation

- **Scan** — review `task-memory.md` and the per-slice learning logs for recurring themes.
- **Promote** — if a "Pattern" has been used successfully in 3 different tasks, move it from the learning log to the relevant standards doc (`docs/context/rules.md` or a slice-specific standards doc).
- **Refine** — update `docs/context/README.md` and `docs/_TAG-INDEX.md` links if files were moved or renamed.

## Stale document detection

- Identify files with `last_updated` older than 12 months.
- Flag them for manual review by the user or an auditor agent.

## Decision rules

- **Safety first** — never delete `docs/project.md`, `docs/context/rules.md`, `docs/context/architecture.md`, or any file under `.opencode/`.
- **Summary required** — do not delete a session cache unless its "Solution Memory" has been integrated into the persistent memory logs.

## Output format

Return a Maintenance Report:

- **Pruned items** — list of files deleted or archived.
- **Promoted patterns** — list of items moved to the standards docs.
- **Alerts** — list of stale documents requiring review.

## Constraints

- **PROHIBITED**: deleting central standards files.
- **MANDATORY**: summarizing any deleted data into the persistent memory before removal.

## Integration

This protocol is the bulk-prune complement of [ia-catalog-manager](./ia-catalog-manager.md) (single-asset CRUD) and [ia-learner](./ia-learner.md) (the per-session learning cycle). The [sync-checker](./ia-sync-checker.md) protocol identifies stale entries; the pruner then performs the actual removal. In the opencode runtime, the pruner is invoked by the [orchestrator](../agents/subagents/orchestrator.md) at the end of a project milestone or when the session count crosses a threshold.
