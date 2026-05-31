---
last_updated: 2026-04-27
description: minimal clean architecture rules about layers, dependency direction, and replaceable outer details
tags: [architecture, clean-architecture, layers, dependency-rule, standards]
status: ACTIVE
ai_optimized: yes
---

# Clean Architecture

## Core Rules
- Distinguish entities, use cases, interface adapters, and framework details.
- Dependencies point inward.
- The domain must not know UI, framework, or storage details.
- Separation of concerns is the main maintainability tool.
- Replace outer technology without rewriting inner rules.

## Use In This Repo
- Local architecture docs define the approved layering, even if legacy files violate it.
- When modifying a feature, prefer the smallest move that restores dependency direction.
- Do not let Angular-specific implementation details leak into core decision rules.

## See Also
- [architecture.md](../architecture.md)
- [coding-conventions.md](../coding-conventions.md)