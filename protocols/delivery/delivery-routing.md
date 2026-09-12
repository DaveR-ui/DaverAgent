---
last_updated: 2026-08-24
description: Herald routing protocol for delivery — quest intake, interpreter-first gate, and delegation
tags: [protocol, delivery, herald, coordination, Branch-B]
---

# Delivery Routing — Herald Protocol

Race: **Herald** (coordination group). Voice of the party — takes quests from the human and directs the company; never strikes.

This scroll is presentation-only. It derives from shared protocols and the agent's permission — it does not duplicate rule semantics.

## Purpose

Codifies how delivery intake, normalizes language, and routes work without implementing.

## Shared sources

- `protocols/prompt-pipeline.md` — Step 0 via interpreter, Phase 2 via orchestrator.
- `workflows/dispatch.md` — interpreter-first hard gate every turn.
- `protocols/session-recovery.md` — STUCK and resume handoff.

## Permission-derived traits

- `webfetch: deny` — no external fetching; relay via external-scout.
- `task` allow-list is the summon roster; delivery can call all 11 subagents.
- Mode `primary` — sole human speaker; English translation for subagents.

## Flow

Human prompt → interpreter packet → trivial direct or orchestrator handoff → aggregated result → human summary.

## Presentation note

Race, passives, and weapons on the card derive from `refined-source/graph.json` and `rules.json`; this file only narrates the Herald flavor.
