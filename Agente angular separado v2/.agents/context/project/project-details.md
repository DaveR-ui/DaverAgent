---
last_updated: 2026-05-09
description: Technical stack, security guardrails, operational paths, and project metadata SSOT.
tags: [standards, project-rules, guardrails]
status: active
---

# Project Details

## Technical Stack
- **Framework**: Angular v21.2.8
- **Reactivity**: Signals-first (Mandatory)
- **Testing**: Vitest (Unit), Playwright (E2E)
- **Styling**: TailwindCSS v4.1.18 (SafeGuard Design System)
- **Design Spec**: `design/DESIGN.md` (Based on google-labs-code/design.md)
- **Tooling**: Biome (Linting/Formatting), Storybook v10.2.0

## Security & Guardrails
- **Commit Policy**: NO automatic commits allowed.
- **Branch Protection**: Standards for PR reviews.
- **Prohibited Patterns**: Strict ban on `setTimeout` and massive library imports.

## Operational Paths
- **Context Hub**: `.agents/context/`
- **Skills Index**: `.agents/skills/SKILLS_INDEX.md`
- **Orchestrator**: `.agents/workflows/orchestrate.md`
- **Design Tokens**: `src/styles.scss` (@theme block)
- **Documentation**: `.agents/context/orchestration/AGENTS.md`

## Project Context
- **Name**: spa-matafuegos
- **Type**: Single Page Application
- **Owner**: Dacar-Enterprice-Software
