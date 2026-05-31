---
last_updated: 2026-05-09
status: ACTIVE
ai_optimized: yes
pillar: P3
purpose: Tag-based lookup for IA Orchestration & Logic (pipeline, agents, workflows, troubleshooting).
---

# Tag Dictionary — Pillar 3: IA Orchestration & Logic

> Use this file to locate docs and skills by keyword for P3 concerns.
> All doc paths are relative to `.agents/context/`.
> Skills reference `.agents/skills/SKILLS_INDEX.md` for full descriptions.

---

## agents / documentation / routing
**Docs:**
- [AGENTS.md](AGENTS.md) — Component-to-doc map (primary entry point)
- [CHEATSHEET.md](CHEATSHEET.md) — Day 1 onboarding guide
- [persona.md](persona.md) — IA mental model & communication style
- [flow.md](flow.md) — 5-phase pipeline diagram

**Skills:**
- `p3-ia-analyzer` — Initiation: metadata & clue extraction
- `p3-ia-dev` — Identity: persona management & guidelines

---

## errors / troubleshooting / common-errors
**Docs:**
- [troubleshooting/common-errors.md](../memory/troubleshooting/common-errors.md)
- [patterns-catalog.md](../memory/patterns-catalog.md)

**Skills:**
- `p3-ia-verifier` — Verification: test execution & solution memory
- `p3-ia-learner` — Learning: precision compounding & rule updates

---

## github / pr-fetch / pr-review
**Docs:**
- [github-pr-fetch.md](github-pr-fetch.md)

**Skills:**
- `p2-review-analysis` — Analyzing diffs and reviewing code
- `p3-ia-verifier` — Post-implementation verification

---

## memory / session / backlog / learning
**Docs:**
- [task-memory.md](../memory/task-memory.md) — Recent milestones
- [todo.md](../memory/todo.md) — Backlog
- [patterns-catalog.md](../memory/patterns-catalog.md) — Reusable recipes

**Skills:**
- `p3-ia-learner` — ORCHESTRATOR-RULES.md and learning log management
- `p3-ia-verifier` — Solution Memory generation

---

## orchestration / pipeline / workflow
**Docs:**
- [flow.md](flow.md) — 5-phase pipeline (Analyzer → Learner)
- [CHEATSHEET.md](CHEATSHEET.md) — Decision tree and fast paths
- [../../workflows/orchestrate.md](../../workflows/orchestrate.md) — Task routing reference
- [../../workflows/new-feature.md](../../workflows/new-feature.md) — Feature implementation steps

**Skills:**
- `p3-ia-analyzer` — Phase 1: Initiation
- `p3-ia-explorer` — Phase 2: Exploration
- `p3-ia-supplier` — Phase 3: Context Supply
- `p3-ia-proposer` — Phase 4: Proposal
- `p3-ia-verifier` — Phase 5: Verification
- `p3-ia-learner` — Learning & Memory

---

## search / web-research / external
**Docs:**
- *(no local doc — delegates to WebSearch agent)*

**Skills:**
- `p3-ia-search` — Standardized delegation for web searches

---

## skill-creation / meta / catalog
**Docs:**
- [../../skills/SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md) — Master skill registry
- [../../AGENT-GUIDE.md](../../AGENT-GUIDE.md) — Folder structure & index

**Skills:**
- `p3-ia-skill-creator` — Autonomous skill scaffolding
- `p3-ia-catalog-manager` — Unified CRUD for Agent Knowledge Hub
- `p3-ia-pruner` — Context pruning and consolidation
- `p3-ia-docs-gen` — Standards for creating documentation
