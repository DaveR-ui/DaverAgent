# 03 — Project Entry Point

> `docs/project.md` as the source of truth, `conventions.md`, and the Slices table. Read this before routing any prompt.

---

## docs/project.md is the hub

`docs/project.md` is the project entry point. **ALL other docs reference it.** It is the first file any agent should read when entering the project.

It contains:

- **Project metadata** — name, version, description, status, package manager
- **Technology stack** — runtime and dev dependencies with versions and roles
- **Commands** — install, start, build, test, serve
- **Domain entities** — the core data model (e.g., Piece, Collection, Course, Session, Enrollment)
- **Slices table** — the fast-routing mechanism (see below)
- **Project structure** — current directory layout
- **Key configuration** — angular.json, tsconfig.json, budgets, compiler options

If `docs/project.md` doesn't exist, **everything downstream breaks**: sync, project slang, slice matching, context doc discovery. Creating it is usually the first real task in a greenfield project.

---

## The Slices table

The Slices table enables **fast prompt routing without full codebase exploration**. Instead of scanning the entire repo to figure out which area a prompt touches, the delivery agent matches prompt keywords against the Slices table.

### Columns

| Column | Purpose |
|--------|---------|
| **Slice** | Agnostic domain name (e.g., "gallery", "courses") — NOT a file name |
| **Description** | One-line summary of what the slice covers |
| **Keywords** | Primary matching mechanism — comprehensive, with synonyms and abbreviations |
| **Entry points** | File paths that exist (or "TBD" for new slices) |
| **Primary agents** | Which agents typically handle this slice (usually starts with "coder, reviewer") |

### When adding a new slice

1. **Propose to the human** — don't add slices unilaterally.
2. Use an **agnostic domain name**, not a file name (e.g., "gallery", not "gallery-component").
3. Make **keywords comprehensive** — include synonyms, abbreviations, and common misspellings. This is the primary matching mechanism.
4. **Entry points must exist** — only list files that actually exist. Use "TBD" for new slices.
5. Assign **appropriate agents** — start with "coder, reviewer". Add "tester" if the slice has tests, "architect" if complex.

### Matching rules

- A prompt can match **multiple slices**. List all matching slices — don't force a single match.
- Don't create a new slice just because a task touches multiple existing slices. List all matching slices instead.
- The Slices table is **per-project, not per-session**. It persists across sessions.

---

## conventions.md

`.opencode/conventions.md` defines canonical paths. All agents reference it instead of hardcoding paths.

If paths change (e.g., context docs move from `docs/context/` to `docs/architecture/`), **update `conventions.md`** — not individual agents. Agents that hardcode paths will break silently.

---

## Context docs

Context docs live in `docs/context/`. They provide deep dives on specific areas:

| File | Covers |
|------|--------|
| `architecture.md` | SSR, standalone components, signals, change detection, routing, hydration, DI |
| `rules.md` | TypeScript, components, templates, state management, accessibility, SSR safety, forms, testing, naming |
| `design-system.md` | Mapping DESIGN.md tokens to Angular Material 21 theming |
| `gallery.md` | Gallery feature: pieces, collections, lightbox, grid layout |
| `courses.md` | Courses feature: listing, calendar, enrollment |
| `content-model.md` | Data strategy without backend: static files, TypeScript interfaces, future CMS |
| `seo.md` | SSR-based SEO: meta tags, JSON-LD, sitemap, prerendering |
| `ecommerce-roadmap.md` | Roadmap from gallery to shop: cart, checkout, payment |

The **context index** (`docs/context/README.md`) lists all context docs with a recommended reading order. Read it when you need to discover which context docs are relevant.

---

## Protocols: two locations

| Location | What it holds |
|---------|---------------|
| `docs/protocols/` | **Project-specific** conventions (query patterns, error catalogs, subsystem rules) |
| `.opencode/protocols/` | **Agent system** behavior (how the agent system coordinates, persists state) |

They live in different roots for a reason. Don't mix them up.

---

## Gotchas

- **If `docs/project.md` doesn't exist, everything downstream breaks.** Sync fails, project slang is empty, slice matching returns nothing. Creating `docs/project.md` is usually the first real task.
- **The Slices table is per-project, not per-session.** It persists across sessions. Don't recreate it each time.
- **Don't create a new slice just because a task touches multiple existing slices.** List all matching slices instead. Creating overlapping slices causes routing ambiguity.
- **The "Primary agents" column usually starts with "coder, reviewer".** Add "tester" if the slice has tests, "architect" if the slice involves complex design decisions. Don't list every agent — list the ones that are *primary*.
- **Keywords are the primary matching mechanism.** If keywords are sparse, routing will miss valid matches. Include synonyms, abbreviations, and common alternative spellings.
- **Entry points must exist.** Listing a path that doesn't exist causes agents to fail when they try to read it. Use "TBD" for slices that haven't been scaffolded yet.
- **Slice names should be agnostic domain names**, not file names or component names. "gallery" not "GalleryComponent".

---

## Quick Reference

| What | Where / Rule |
|------|--------------|
| Project entry point | `docs/project.md` |
| Canonical paths | `.opencode/conventions.md` |
| Context docs | `docs/context/` |
| Context index | `docs/context/README.md` |
| Project protocols | `docs/protocols/` |
| Agent protocols | `.opencode/protocols/` |
| Slices table columns | Slice, Description, Keywords, Entry points, Primary agents |
| Slice naming | Agnostic domain names, not file names |
| Keywords rule | Comprehensive — synonyms, abbreviations, alternative spellings |
| Entry points rule | Must exist, or use "TBD" |
| Primary agents default | "coder, reviewer" — add "tester" / "architect" as needed |