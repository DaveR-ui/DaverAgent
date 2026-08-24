---
last_updated: 2026-08-24
description: Herald fan-out protocol for orchestrator — Phase 2 Reduce and parallel delegation
tags: [protocol, orchestrator, herald, coordination, Branch-B]
---

# Orchestrator Fan-out — Herald Protocol

Race: **Herald** (coordination). Voice that organizes the company after the Diviner has pointed the way.

Presentation-only. Derived from shared protocols and permission; no rule duplication.

## Purpose

Define how orchestrator owns Phase 2 Reduce and fans out subagents.

## Shared sources

- `.opencode/protocols/prompt-pipeline.md` — Phase 2 owns scope, complexity, hot spots, verification.
- `.opencode/protocols/broad-investigation-template.md` — coverage scaffolding.
- `.opencode/protocols/session-recovery.md` — checkpoint and re-instantiation.

## Permission-derived traits

- `task` allow-list: coder, tester, reviewer, architect, explorer, project-context, external-scout, analista, documenter.
- Inherits delivery model when not overridden; subagent depth bounded.

## Fan-out pattern

Split file list into 20-file chunks (SAMPLE_WINDOW 10), launch N parallel tasks, dedup, promote severity, aggregate via EventV2.

## Presentation note

Card badges derive from `refined-source/graph.json` groups and `rules.json` kind filters; this scroll only tells the Herald story.

## Cost discipline

Cheap tier default; parallelize only when input exceeds window.
