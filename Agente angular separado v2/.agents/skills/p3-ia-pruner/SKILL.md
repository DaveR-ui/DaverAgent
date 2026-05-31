---
name: ia-pruner
description: Maintenance skill for the Agent Knowledge Hub. Performs context pruning, archives old session memories, and consolidates lessons into the main standards.
last_updated: 2026-05-09
status: active
---

# ✂️ Skill: IA Pruner (Context Maintenance)

## Goal
Prevent "Context Drift" and "Instruction Bloat". This skill ensures that the `.agents/` directory remains lean, accurate, and relevant by archiving obsolete data and promoting useful patterns to the SSOT.

## Instructions

### 1. Session Cleanup
After a project milestone or every 10 sessions:
- **Archive**: Move contents of `.agents/cache-session/` (except the most recent 2) to a `archive/` folder or delete them if already summarized in `task-memory.md`.
- **Deduplicate**: If a lesson in `session-memory.md` is now a standard in `rules.md`, delete the session-specific memory file.

### 2. Instruction Consolidation
- **Scan**: Review `task-memory.md` for recurring themes.
- **Promote**: If a "Pattern" has been used successfully in 3 different tasks, move it from `task-memory.md` to `patterns-catalog.md`.
- **Refine**: Update `AGENTS.md` links if files were moved or renamed.

### 3. Stale Document Detection
- Identify files with `last_updated` older than 12 months.
- Flag them for "Manual Review" by the user or an auditor agent.

## Decision Rules
- **Safety First**: Never delete `rules.md`, `coding-conventions.md`, or `AGENTS.md`.
- **Summary Required**: Do not delete a session cache unless its "Solution Memory" has been integrated into the central memory logs.

## Output Format
Return a Maintenance Report:
- **Pruned Items**: List of files deleted or archived.
- **Promoted Patterns**: List of items moved to the Pattern Catalog.
- **Alerts**: List of stale documents requiring review.

## Constraints
- **PROHIBITED**: Deleting central standards files.
- **MANDATORY**: Summarizing any deleted data into the persistent memory before removal.
