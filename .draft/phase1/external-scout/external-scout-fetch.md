---
last_updated: 2026-08-24
description: Ranger fetch protocol for external-scout — one library/version/question live docs
tags: [protocol, external-scout, ranger, exploration, Branch-B]
---

# External-Scout Fetch — Ranger Protocol

Race: **Ranger** (exploration). Far scout who brings back knowledge of distant lands without settling them.

Presentation-only. Derived from shared protocols and permission.

## Purpose

Define single-question live docs fetching with source priority.

## Shared sources

- `.opencode/agents/subagents/external-scout.md` — one library + version + question contract.
- `.opencode/protocols/prompt-pipeline.md` — context budget awareness.

## Permission-derived traits

- `webfetch: allow` — only weapon equipped; `edit: deny`, `bash: deny`.
- No `task` beyond self — no fan-out.
- Compact answer; unreachable → one line and stop.

## Source priority

Official docs version-pinned → GitHub releases → npm/README. Structured signatures, breaking changes, usage patterns.

## Presentation note

Weapons display derives from permission `webfetch: allow`; passives from `rules.json` exploration group; scroll only narrates flavor.
