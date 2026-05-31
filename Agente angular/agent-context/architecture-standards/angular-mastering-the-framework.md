---
last_updated: 2026-04-27
description: minimal Angular architecture rules for signals-first, standalone, OnPush-aligned, typed implementations
tags: [architecture, angular, signals, standalone, onpush, standards]
status: ACTIVE
ai_optimized: yes
---

# Angular: Mastering the Framework

## Core Rules
- Prefer standalone components and modern Angular primitives.
- Use signals-first state and derived values.
- Keep change detection explicit and OnPush-aligned.
- Use `inject()` over constructor injection in new or updated code.
- Favor strict typing and modern control flow.

## Repo Overrides
- This repository uses local standards as the final authority.
- Ignore older examples that rely on `setTimeout`, manual subscriptions, or obsolete Angular patterns.
- For async component data, prefer the repo's `rxResource` guidance over generic course examples.

## See Also
- [architecture.md](../architecture.md)
- [coding-conventions.md](../coding-conventions.md)
- [project-rules.md](../project-rules.md)
- [angular-reactivity/resource-api.md](../angular-reactivity/resource-api.md)