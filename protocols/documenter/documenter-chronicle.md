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
- `docs/context/README.md` + `docs/_TAG-INDEX.md` + `docs/project.md` Slices — registration targets.
- `.opencode/protocols/subagent-spec-template.md` — canonical shape when touching agent specs.

## Permission-derived traits

- `task: [documenter]` — sole dedicated writer; project-context is read-only.
- Writes via DocumenterOutput JSON contract; never modifies code or `.opencode` runtime directly.
- Language follows `doc_language: english` — common tongue invariant.

## Chronicle rule

Every new doc carries frontmatter (last_updated, status, description, tags) and is registered; audit covers routing sync, freshness (>30 stale, >90 flag), link integrity.

## Presentation note

Writer passives from `rules.json` kind=passive render as Lorekeeper trait; this scroll only tells the chronicle flavor.
