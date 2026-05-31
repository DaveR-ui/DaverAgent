---
last_updated: 2026-05-09
status: ACTIVE
ai_optimized: yes
pillar: Q1
purpose: Tag-based lookup for SDD Stage 1 — Preparación (Initiation + Exploration).
---

# Tag Dictionary — Q1: Preparación (Initiation + Exploration)

> Use this file to locate docs and skills by keyword for Q1 concerns.
> This stage covers task analysis, metadata extraction, asset discovery, and scope exploration.
> All doc paths are relative to `.agents/context/`.
> Skills reference `.agents/skills/SKILLS_INDEX.md` for full descriptions.

---

## analysis / metadata / initiation
**Docs:**
- [flow.md](flow.md) — 5-phase pipeline diagram (Phase 1: Analyzer)
- [persona.md](persona.md) — IA mental model & clue inventory
- [CHEATSHEET.md](CHEATSHEET.md) — Day 1 onboarding guide & decision tree
- [AGENTS.md](AGENTS.md) — Component-to-doc map for scope identification

**Skills:**
- `p3-ia-analyzer` — First filter: metadata & clue extraction

---

## exploration / scope / discovery / blast-radius
**Docs:**
- [flow.md](flow.md) — 5-phase pipeline diagram (Phase 2: Explorer)
- [CHEATSHEET.md](CHEATSHEET.md) — Decision tree for scope discovery
- [AGENTS.md](AGENTS.md) — Component-to-doc map for asset lookup
- [../../skills/p3-ia-explorer/SKILL.md](../../skills/p3-ia-explorer/SKILL.md) — Explorer skill details

**Skills:**
- `p3-ia-explorer` — Asset discovery & logic density check

---

## search / web-research / external
**Docs:**
- [AGENTS.md](AGENTS.md) — Entry point for routing decisions
- [../../workflows/orchestrate.md](../../workflows/orchestrate.md) — External Web Research routing notes

**Skills:**
- `p3-ia-search` — Standardized delegation for web searches

---

## routing / pre-flight / task-clarity
**Docs:**
- [CHEATSHEET.md](CHEATSHEET.md) — Fast paths and intent routing
- [../../workflows/orchestrate.md](../../workflows/orchestrate.md) — Pre-flight checklist
- [flow.md](flow.md) — Pipeline entry point

**Skills:**
- `p3-ia-analyzer` — Confirm prompt clarity before routing
- `p3-ia-explorer` — Scope discovery when blast-radius is unknown
- `p3-ia-search` — External lookup when local docs cannot fill gaps
