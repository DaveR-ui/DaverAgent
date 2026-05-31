---
last_updated: 2026-05-09
status: ACTIVE
ai_optimized: yes
purpose: Entry point for tag-based lookup. Routes to pillar-specific tag dictionaries.
---

# Agent Context — Tag Index

> This file routes to pillar-specific tag dictionaries. Each dictionary maps keywords to docs and skills within that pillar.

## ⚠️ P vs Q: Understanding the Two Axes

This system uses **two orthogonal dimensions** for lookup. Both are valid — pick the one that matches your question:

| Dimension | Answers the question... | Dictionaries | Example |
|---|---|---|---|
| **P (Pillar)** | *"What domain does this belong to?"* | `tags-p1.md`, `tags-p2.md`, `tags-p3.md` | "I need info about modals" → P2 |
| **Q (Stage)** | *"When in the pipeline do I need this?"* | `tags-q0.md`–`tags-q3.md` | "I'm in the verification stage" → Q3 |

**Duplication is intentional.** A keyword like `orchestration` appears in both `tags-p3.md` (it's a P3 domain concept) and `tags-q0.md`/`tags-q1.md` (it's relevant across pipeline stages). This is not a bug — it enables lookup from either axis.

**Rule of thumb**: Start with **P** if you know the topic. Start with **Q** if you know your current pipeline stage.

## Pillar Dictionaries

| Pillar | Focus | File |
| :--- | :--- | :--- |
| **P1** | Language & Framework Standards (Angular, TypeScript, testing) | [tags-p1.md](tags-p1.md) |
| **P2** | Project & SafeGuard Standards (design, API, UI components) | [tags-p2.md](tags-p2.md) |
| **P3** | IA Orchestration & Logic (pipeline, agents, workflows) | [tags-p3.md](tags-p3.md) |

## Quick Cross-Pillar Lookup

| Keyword | Go to |
| :--- | :--- |
| angular, signals, rxResource, testing, typescript | [tags-p1.md](tags-p1.md) |
| modal, dropdown, tooltip, api, design, rules, domain | [tags-p2.md](tags-p2.md) |
| orchestration, pipeline, agents, troubleshooting, memory, skills | [tags-p3.md](tags-p3.md) |

## Skills Index

All skills registered and categorized by pillar: [SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md)

## ⚡ Fast Paths (Vías Rápidas)

| Situation / Intent | Recommended Resource |
| :--- | :--- |
| **"Something failed"** / Debugging | [troubleshooting/common-errors.md](../memory/troubleshooting/common-errors.md) |
| **"Starting a new feature"** | [new-feature.md](../../workflows/new-feature.md) |
| **"UI looks basic/wrong"** | [unified-design-rules.md](../project/design/unified-design-rules.md) |
| **"Unknown business term"** | [domain-logic.md](../project/domain-logic.md) |
| **"Need a reusable pattern"** | [patterns-catalog.md](../memory/patterns-catalog.md) |
| **"Reviewing a PR"** | [github-pr-fetch.md](github-pr-fetch.md) |
