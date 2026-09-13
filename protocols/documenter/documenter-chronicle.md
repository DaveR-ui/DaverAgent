---
last_updated: 2026-08-24
description: Lorekeeper chronicle protocol for documenter — sole writer for docs with registration and audit
tags: [protocol, documenter, lorekeeper, writers, Branch-B]
---

# Documenter Chronicle — Lorekeeper Protocol

Race: **Lorekeeper** (writers). Chronicler of the party — writes only in the common tongue (English).

Presentation-only. Derived from shared protocols and permission.

## Purpose

Define how documenter maintains `docs/` with frontmatter, registration, and post-change audit.

## Shared sources

- `docs/context/doc-conventions.md` — frontmatter, component format, one topic per file.
- `docs/context/context-index.md` + `docs/index.md` + `docs/tag-index.md` + `docs/project.md` Slices — registration targets.
- `protocols/subagent-spec-template.md` — canonical shape when touching agent specs.
- `documentation-onrails (version 1.4, snapshot 2026-09-12)` (<https://github.com/DaveR-ui/documentation-onrails>, `guidelines/`, `templates/`, `protocols/`, `validate.js`) — the **canonical specification for documentation STRUCTURE** (layout, hubs, frontmatter, naming, generated indexes, lifecycle, validation); consult on demand; supersedes the structural conventions previously in this scroll; never a source of project facts.

## Permission-derived traits

- `task: [documenter]` — sole dedicated writer; project-context is read-only.
- Writes via DocumenterOutput JSON contract; never modifies code or the global agent-system config directly.
- Language follows `doc_language: english` — common tongue invariant.

## Chronicle rule

Every new doc carries the frontmatter contract (context-doc: last_updated, status, description, tags, version; note: id, category, tags, aliases, related, version, status) and is registered; audit covers routing sync, freshness (>30 stale, >90 flag), link integrity, structure validation.

## Presentation note

Writer passives from `rules.json` kind=passive render as Lorekeeper trait; this scroll only tells the chronicle flavor.
