---
last_updated: 2026-05-09
description: entry point for agent documentation, including component lookup and troubleshooting references
tags: [agents, documentation, angular, testing, troubleshooting]
status: ACTIVE
---

# Agent Documentation System

> 🚨 **CRITICAL ADVISORY** 🚨
> **Rule 1:** Language Standards (Angular v21+) always override existing `src/` code.
> **Rule 2:** Project Rules (SafeGuard) always override generic UI implementations.
> **Rule 3:** The IA Orchestration Flow is the only valid way to implement non-trivial tasks.

> 💡 **Limited context?** Start with the [Day 1 Onboarding Guide](CHEATSHEET.md).

## 📑 Quick Index

| Section | Anchor | Purpose |
|---|---|---|
| Knowledge Pillars | [🏛️](#-knowledge-pillars) | P1/P2/P3 domain map + tag dictionaries |
| SDD Stage Dimension | [🔄](#-sdd-stage-dimension-orthogonal-to-pillars) | Q0–Q3 pipeline stage tags |
| Component-to-Doc Map | [📋](#-component-to-documentation-map-lvl-2-proyecto) | UI components → their docs |
| Orchestration & Pipeline | [🌀](#-orchestration--pipeline-lvl-3-programador) | 5-phase flow, persona, routing |
| Maintenance & Evolution | [🛠️](#-maintenance--evolution) | Debt, learning, SSOT, auto-sync |
| Situational Shortcuts | [🚀](#-situational-shortcuts-ia-to-ia) | Fast lookups by scenario |
| Common Lookups | [🆘](#-common-lookups) | Keyword → doc direct links |

## 🏛️ Knowledge Pillars

| Level | Pillar | Focus | Index |
| :--- | :--- | :--- | :--- |
| **Lvl 1** | Language / Standards | Angular v21+, Signals, TS | [tags-p1.md](tags-p1.md) · [SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md) |
| **Lvl 2** | Project / SafeGuard | Identity, Design, Architecture, Business Rules | [tags-p2.md](tags-p2.md) · [SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md) |
| **Lvl 3** | Programmer / IA | Orchestration Flow, Mental Model | [tags-p3.md](tags-p3.md) · [SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md) |

Full pillar details: [SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md)

## 🔄 SDD Stage Dimension (Orthogonal to Pillars)

Skills are also tagged by the SDD pipeline stage they operate in, independent of their pillar level:

| Stage | Name | Description | Tag Dictionary |
| :--- | :--- | :--- | :--- |
| **q0** | Multietapa | Skills used across any stage (identity, meta, catalog) | [tags-q0.md](tags-q0.md) |
| **q1** | Preparación | Initiation + Exploration (analyzer, explorer, search) | [tags-q1.md](tags-q1.md) |
| **q2** | Acción | Context Supply + Proposal + Implementation (all p1/p2 framework skills) | [tags-q2.md](tags-q2.md) |
| **q3** | Cierre | Verification + Testing + Learning (verifier, learner, testing skills) | [tags-q3.md](tags-q3.md) |

---

## 📋 Component-to-Documentation Map (Lvl 2: Proyecto)

| Component | Primary Doc | Key Standards |
| :--- | :--- | :--- |
| **UI Design System** | [Unified Design Rules](../project/design/unified-design-rules.md) | Containers, Buttons, Inputs, Empty States. |
| **Identity & Tokens** | [SafeGuard Identity](../project/design/identity.md) | Colors, Typography, Spacing ([Tokens](../project/design/tokens.md), [YAML SSOT](../project/design/DESIGN.md)). |
| **Architecture** | [Architecture Standards](../project/architecture-standards/index.md) | Clean Architecture, Hexagonal, SDD Standards. |
| **Modal Service** | [Modal Creation](../project/modal-creation.md) | Signal-based service, direct vs effect. |
| **HTTP Reactivity** | [Resource API](../standards/angular-reactivity/resource-api.md) | `rxResource` standard, error handling. |
| **Domain Knowledge** | [Domain Encyclopedia](../project/domain-logic.md) | Business terms (PH, ABC), Extinguisher types. |
| **Pattern Library** | [Pattern Catalog](../memory/patterns-catalog.md) | Reusable recipes (rxResource, Modals). |
| **Special UI** | [Dropdowns](../project/special-components/dropdown-components.md) | 6 variants, selection guide. |
| **Tooltips** | [Tooltips](../project/special-components/tooltip.md) | CDK overlay, plain text & TemplateRef content. |

---

## 🌀 Orchestration & Pipeline (Lvl 3: Programador)

The system operates through a structured pipeline:

1. **[Orchestration Flow](flow.md)**: The 5-phase pipeline (Analyzer ➔ Learner).
2. **[IA Persona](persona.md)**: The mental model (Clue Inventory, Hot Spots).
3. **[Workflows](../../workflows/orchestrate.md)**: Task routing and specific execution guides.

Full pipeline diagram: [flow.md](flow.md)
Routing reference: [orchestrate.md](../../workflows/orchestrate.md)

---

## 🛠️ Maintenance & Evolution

- **Technical Debt**: All antipatterns found during tasks are flagged in [rules.md](../project/rules.md).
- **Learning**: Post-implementation lessons are stored in [task-memory.md](../memory/task-memory.md) and [memory-learner](../../skills/p3-ia-learner/SKILL.md).
- **SSOT**: Session-specific context should be stored in `.agents/cache-session/<session-id>/session-plan.md` and `session-memory.md`.

Tag dictionaries auto-sync via `p3-ia-catalog-manager` on doc create/rename/delete.

---

## 🚀 Situational Shortcuts (IA-to-IA)

| If you are... | Use this... | Why? |
| :--- | :--- | :--- |
| **Stuck / Debugging** | [Common Errors](../memory/troubleshooting/common-errors.md) | Resolve known antipatterns and environment issues. |
| **Planning a Task** | [Orchestration Flow](flow.md) | Ensure compliance with the 5-phase pipeline. |
| **Designing UI** | [Design Implementation](../project/design/implementation.md) | Use the specific SafeGuard design tokens, not generic ones. |
| **Onboarding** | [Cheatsheet](CHEATSHEET.md) | Fast path for new agents or fresh sessions. |
| **Finalizing** | [Solution Verifier](../../skills/p3-ia-verifier/SKILL.md) | Generate memory and verify tests before closing. |

---

## 🆘 Common Lookups

For keyword-based lookup, use the pillar tag dictionaries:

| Need | Go to |
| :--- | :--- |
| Angular, signals, rxResource, testing | [tags-p1.md](tags-p1.md) |
| Modal, dropdown, API, design, rules | [tags-p2.md](tags-p2.md) |
| Orchestration, troubleshooting, memory | [tags-p3.md](tags-p3.md) |
| All skills by pillar | [SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md) |

Direct links:
- Testing rxResource: [testing.md](../standards/angular-reactivity/testing.md)
- Common Errors: [troubleshooting/common-errors.md](../memory/troubleshooting/common-errors.md)
- Design Implementation: [design/implementation.md](../project/design/implementation.md)
- API Strategy: [api-strategy.md](../project/api-strategy.md)
