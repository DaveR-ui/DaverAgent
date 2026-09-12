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

- `docs/context/context-index.md` — index and philosophy of context.
- `docs/project.md` — Slices table and stack entry point.
- `protocols/broad-investigation-template.md` — coverage when auditing docs.
- `documentation-onrails` (<https://github.com/DaveR-ui/documentation-onrails>, `guidelines/`, `templates/`) — the canonical specification for documentation **structure** (layout, hubs, frontmatter, naming, generated indexes, validation); consult on demand; never a source of project facts.

## Permission-derived traits

- `edit: deny`, `bash: deny` — cannot write or execute.
- `task: [project-context]` — self-fan-out only; delegates docs writing to documenter.
- Single source hierarchy (facts): `docs/context/*.md` > `docs/project.md` > `src/`. The generated `docs/tag-index.md` is a navigation surface, never a fact source; `documentation-onrails` is canonical for *structure* only.

## Lookup workflow

`docs/project.md` → `docs/context/context-index.md` → slice hub → grep if still unclear.

## Presentation note

Card passives derive from `rules.json` kind filters; this scroll narrates the Ranger lookup flavor.
