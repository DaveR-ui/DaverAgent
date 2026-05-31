---
last_updated: 2026-02-18
tags: [launchdarkly, flag]
---

# Adding and Managing LaunchDarkly Flags

This guide provides the steps required to implement, consume, and test new feature flags using LaunchDarkly.

## 1. Define the Constant
Add the new flag key as a constant in [src/app/core/constants/launchdarkly-flags-constants.ts](../../src/app/core/constants/launchdarkly-flags-constants.ts).
**Rule**: The value must include the `_AIR226766` suffix.

```typescript
export const LD_FLAG_MY_NEW_FEATURE = 'my_new_feature_AIR226766';
```

## 2. Configure Default Values
Update [src/app/state/launchdarkly-flags/launchdarkly-flags.reducer.ts](../../src/app/state/launchdarkly-flags/launchdarkly-flags.reducer.ts):
1. Import the new constant.
2. Add it to `initialFlags` (fallback for local development).
3. Add it to `errorFlags` (fallback for service failures, typically set to `false` or `true` based on safe default).

## 3. Consume the Flag
Use the `selectLaunchdarklyFlags` selector in your component or service.

```typescript
import { selectLaunchdarklyFlags } from '@state/index';
// ...
this.store.select(selectLaunchdarklyFlags)
  .pipe(untilDestroyed(this))
  .subscribe((ldFlags) => {
    this.isFeatureEnabled = !!ldFlags['flags'][LD_FLAG_MY_NEW_FEATURE];
  });
```

## 4. Unit Testing

### Required Mock Structure
The mock **MUST** match the selector's return structure:
```typescript
const mockLaunchdarklyFlags = {
  flags: {
    [LD_FLAG_MY_NEW_FEATURE]: false  // or true
  }
};
```

### Pattern A: overrideSelector (Recommended for existing tests)
Use this when `provideMockStore()` is already configured without selectors:

```typescript
import { selectLaunchdarklyFlags } from '@state/launchdarkly-flags/launchdarkly-flags.selector';
import { LD_FLAG_MY_NEW_FEATURE } from '@core/constants/launchdarkly-flags-constants';

const mockLaunchdarklyFlags = {
  flags: {
    [LD_FLAG_MY_NEW_FEATURE]: false
  }
};

beforeEach(() => {
  // ... TestBed setup with provideMockStore() ...
  mockStore = TestBed.inject(MockStore);
  mockStore.overrideSelector(selectLaunchdarklyFlags, mockLaunchdarklyFlags as any);
  // ... rest of setup
});
```

### Pattern B: provideMockStore with selectors (For new tests)
```typescript
import { provideMockStore, MockStore } from '@ngrx/store/testing';
import { selectLaunchdarklyFlags } from '@state/launchdarkly-flags/launchdarkly-flags.selector';
import { LD_FLAG_MY_NEW_FEATURE } from '@core/constants/launchdarkly-flags-constants';

providers: [
  provideMockStore({
    selectors: [
      {
        selector: selectLaunchdarklyFlags,
        value: {
          flags: {
            [LD_FLAG_MY_NEW_FEATURE]: true
          }
        }
      }
    ]
  })
]
```

### Dynamic updates in tests
```typescript
mockStore.overrideSelector(selectLaunchdarklyFlags, {
  flags: { [LD_FLAG_MY_NEW_FEATURE]: false }
});
mockStore.refreshState();
fixture.detectChanges();
```

### Common Pitfalls

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| `spyOn(mockStore, 'select')` | Overrides ALL selectors, breaks other `store.select()` calls | Use `mockStore.overrideSelector()` |
| Missing `flags` wrapper | `TypeError: Cannot read properties of undefined (reading 'flags')` | Ensure mock is `{ flags: { ... } }` |
| Empty mock `{}` | Crashes in `afterAll` phase when component accesses `ldFlags['flags']` | Always provide full mock structure |

#### Error Example
```
ERROR: An error was thrown in afterAll
TypeError: Cannot read properties of undefined (reading 'admin_resource_masscopy_AIR226766')
```
**Cause:** Test used `mockState = {}` but component accesses `ldFlags['flags'][FLAG_NAME]`
**Fix:** Add `mockStore.overrideSelector(selectLaunchdarklyFlags, mockLaunchdarklyFlags)`

