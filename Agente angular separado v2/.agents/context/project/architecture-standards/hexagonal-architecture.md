---
last_updated: 2026-04-27
description: minimal hexagonal architecture rules focused on ports, adapters, and isolating business logic
tags: [architecture, hexagonal, ports, adapters, standards]
status: ACTIVE
ai_optimized: yes
---

# Hexagonal Architecture

## Core Rules
- Identify business logic before choosing frameworks or tools.
- Define ports around required behavior, not around vendor APIs.
- Keep adapters responsible for translation at the boundaries.
- Test the core logic with stubs or mocks before wiring external integrations.
- Treat infrastructure as replaceable.

## Use In This Repo
- Angular services and UI components must not become the business core by accident.
- Mapping to backend payloads belongs in adapters or service boundaries, not in reusable domain rules.
- Existing `.agents/context/` docs override legacy patterns in `src/`.

## See Also
- [architecture.md](../architecture.md)
- [rules.md](../rules.md)
