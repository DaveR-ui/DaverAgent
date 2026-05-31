---
last_updated: 2026-05-09
status: ACTIVE
ai_optimized: yes
pillar: Q0
purpose: Tag-based lookup for Multistage skills used across any SDD pipeline stage.
---

# Tag Dictionary — Q0: Multistage Skills

> Use this file to locate docs and skills by keyword for Q0 concerns.
> These skills are not bound to a single SDD stage — they apply across preparation, action, and closure.
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
- `p3-ia-dev` — Identity: persona management & guidelines (any stage)

---

## orchestration / pipeline / workflow
**Docs:**
- [flow.md](flow.md) — 5-phase pipeline (Analyzer → Learner)
- [CHEATSHEET.md](CHEATSHEET.md) — Decision tree and fast paths
- [../../workflows/orchestrate.md](../../workflows/orchestrate.md) — Task routing reference
- [../../workflows/new-feature.md](../../workflows/new-feature.md) — Feature implementation steps

**Skills:**
- `p3-ia-dev` — Identity and persona guidelines applied throughout the pipeline

---

## skill-creation / meta / catalog
**Docs:**
- [../../skills/SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md) — Master skill registry
- [../../AGENT-GUIDE.md](../../AGENT-GUIDE.md) — Folder structure & index

**Skills:**
- `p3-ia-skill-creator` — Autonomous skill scaffolding (any stage)
- `p3-ia-catalog-manager` — Unified CRUD for Agent Knowledge Hub (any stage)
- `p3-ia-pruner` — Context pruning and consolidation (any stage)
- `p3-ia-docs-gen` — Standards for creating documentation (any stage)

---

## documentation / writing / standards
**Docs:**
- [AGENTS.md](AGENTS.md) — Entry point for all agent documentation
- [../../skills/p3-ia-docs-gen/SKILL.md](../../skills/p3-ia-docs-gen/SKILL.md) — Documentation generation skill

**Skills:**
- `p3-ia-docs-gen` — Standards for AI-optimized documentation (any stage)

---

## evolution / learning / pruning
**Docs:**
- [task-memory.md](../memory/task-memory.md) — Distillation source
- [rules.md](../project/rules.md) — Antipattern flagging

**Skills:**
- `p3-ia-learner` — Precision compounding and rule updates
- `p3-ia-pruner` — Context cleanup and consolidation
- `p3-ia-catalog-manager` — Automatic index synchronization
