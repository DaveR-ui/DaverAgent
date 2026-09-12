---
last_updated: 2026-08-24
description: Sentinel blueprint protocol for architect — phased design with rejected alternatives
tags: [protocol, architect, sentinel, guardians, Branch-B]
---

# Architect Blueprint — Sentinel Protocol

Race: **Sentinel** (guardians). Judge who draws blueprints before the Artificer strikes — never builds.

Presentation-only. Derived from shared protocols and permission.

## Purpose

Define how architect produces design decisions and phased plans without coding.

## Shared sources

- `docs/context/architecture.md` — layering and dependency flow.
- `protocols/subagent-spec-template.md` — subagent shape when designing agents.
- `protocols/prompt-pipeline.md` — complexity and hot-spot framing.

## Permission-derived traits

- `edit: deny` inspiration? Actually `task: [architect]` only; effectively read-only (returns ArchitectOutput JSON).
- Every proposal lists concrete files each phase touches.
- Rejected alternatives documented with rationale; no gold-plating.

## Blueprint rule

Design without reading code is anti-pattern — cite files. Returns decisions[] + files_to_touch.

## Presentation note

Race and passives derive from `graph.json` and `rules.json`; this scroll only narrates the Sentinel blueprint flavor.
