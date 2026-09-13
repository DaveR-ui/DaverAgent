---
last_updated: 2026-08-24
description: Ranger scout protocol for explorer — sampling, fan-out, and read-only reporting
tags: [protocol, explorer, ranger, exploration, Branch-B]
---

# Explorer Scout — Ranger Protocol

Race: **Ranger** (exploration). Scouts terrain and lore; touches nothing.

Presentation-only. Derived from shared protocols and permission.

## Purpose

Define read-only scouting with divide-and-conquer fan-out.

## Shared sources

- `protocols/broad-investigation-template.md` — Goal/Search/Evidence/Coverage/DoD scaffolding.
- `protocols/prompt-pipeline.md` — hot spots and verification context.
- `docs/project.md` Slices — route before searching.

## Permission-derived traits

- `edit: deny` and `bash: deny` — never modifies, never runs shell commands.
- `task: {"*": deny, explorer: allow}` — self-fan-out only when needed.
- Returns ExplorerOutput JSON through the `task` tool return, not markdown files.

## Sampling discipline

SAMPLE_WINDOW 10, CHUNK_SIZE 20, MAX_DEPTH 3. Evidence scale Verified/Likely/Inferred separate from confidence.

## Presentation note

Weapons derive from permission allow entries; this scroll only tells the Ranger story sourced from shared docs.
