---
name: launchdarkly-flags
description: Guidelines for implementing, consuming, and testing LaunchDarkly feature flags.
---

# LaunchDarkly Flags Skill

> **Full reference**: [agent-context/launchdarkly-flags.md](../../agent-context/launchdarkly-flags.md)

## Checklist

1. Add constant to `src/app/core/constants/launchdarkly-flags-constants.ts` (suffix `_AIR226766` required).
2. Register in `initialFlags` and `errorFlags` in `launchdarkly-flags.reducer.ts`.
3. Consume via `selectLaunchdarklyFlags` selector.
4. In tests, use `mockStore.overrideSelector()` with `{ flags: { [FLAG]: value } }` structure.

See the reference doc for full code examples and anti-patterns.