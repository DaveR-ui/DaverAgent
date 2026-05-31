---
last_updated: 2026-04-27
description: minimal frontend clean architecture rules for separating UI, orchestration, and external communication
tags: [architecture, frontend, containers, presentation, standards]
status: ACTIVE
ai_optimized: yes
---

# Clean Architecture in the Front End

## Core Rules
- Treat UI as an outer layer.
- Organize by business capability, not only by technical artifact type.
- Containers own orchestration and state wiring.
- Presentational components stay focused on UI and explicit inputs.
- Services and adapters isolate external communication.

## Use In This Repo
- Prefer feature-scoped organization when introducing or documenting behavior.
- Keep templates and presentational components light; move derived logic to TypeScript signals or computeds.
- Reuse shared services only when behavior is truly cross-feature.

## See Also
- [architecture.md](../architecture.md)
- [coding-conventions.md](../../standards/coding-conventions.md)
- [api-strategy.md](../api-strategy.md)
