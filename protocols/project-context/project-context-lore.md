---
last_updated: 2026-08-24
description: Ranger lore protocol for project-context — doc lookup hierarchy and citation discipline
tags: [protocol, project-context, ranger, exploration, Branch-B]
---

# Project-Context Lore — Ranger Protocol

Race: **Ranger** (exploration). Lorekeeper's scout — knows where knowledge lives, carries none.

Presentation-only. Derived from shared protocols and permission.

## Purpose

Define read-only doc lookup that cites file path + line numbers for every fact.

## Shared sources

- `docs/context/README.md` — index and philosophy of context.
- `docs/project.md` — Slices table and stack entry point.
- `.opencode/protocols/broad-investigation-template.md` — coverage when auditing docs.

## Permission-derived traits

- `edit: deny`, `bash: deny` — cannot write or execute.
- `task: [project-context]` — self-fan-out only; delegates docs writing to documenter.
- Single source hierarchy: `docs/context/*.md` > `docs/project.md` > `_TAG-INDEX.md` > `src/`.

## Lookup workflow

`docs/project.md` → `docs/context/README.md` → slice README → grep if still unclear.

## Presentation note

Card passives derive from `rules.json` kind filters; this scroll narrates the Ranger lookup flavor.
