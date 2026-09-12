---
last_updated: 2026-08-24
description: Inquisitor trials protocol for tester — canonical runners and behavior assertions
tags: [protocol, tester, inquisitor, quality, Branch-B]
---

# Tester Trials — Inquisitor Protocol

Race: **Inquisitor** (quality). Trials every artifact under controlled combat until it breaks.

Presentation-only. Derived from shared protocols and permission.

## Purpose

Define how tester authors and runs tests from package dir, quarantining flaky trials.

## Shared sources

- `docs/project.md` Common Commands — canonical runners.
- `protocols/prompt-pipeline.md` — verification path definition.
- `docs/context/project-rules.md` — testing conventions.

## Permission-derived traits

- `task: [tester]` — self-contained; no edit restrictions beyond schema validation.
- Returns TesterOutput JSON; never writes summary.md per rule 0007.
- Stack: Vitest 4 (unit), Playwright 1.58 (e2e) for frontend; Go tests when configured.

## Trials rule

Assert observable outcomes (DOM, emitted values, state), not private calls or mocks alone. Don't duplicate logic into tests.

## Presentation note

Quality passives from `rules.json` group quality (kind=passive) render as Inquisitor trait; this scroll narrates trials flavor.
