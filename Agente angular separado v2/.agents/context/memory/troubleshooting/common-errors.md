---
last_updated: 2026-04-23
description: quick reference for recurring Angular runtime and test errors with root cause and fixes
tags: [errors, troubleshooting, angular, signals, linksignal, ng0103, ng0600, ngmodule, ɵcmp]
---

# Common Errors & Solutions

## [NG0103] Input/Signal Modification During Template Execution
- **Issue**: Modifying a signal value inside a `computed()` or template.
- **Solution**: Use `linkedSignal()` or ensure data flows in one direction.

## [NG0600] Circular Dependency
- **Issue**: Cyclic imports between services/components.
- **Solution**: Decouple logic into Injection Tokens or shared utility files.

## [NG0506] Resource in Error State
- **Context**: Accessing `.value()` of a resource that failed (`rxResource` or legacy `httpResource`).
- **Fix**: Check `resource.hasValue()` first, then `resource.error()`, then `resource.isLoading()` — in that exact order. Never access `.value()` without a `hasValue()` guard.
- **See also**: [resource-api.md](../../standards/angular-reactivity/resource-api.md#resource-template-structure-required)

## [NG01353] ngModelGroup Error
- **Context**: Missing `ControlContainer` in component for `ngModelGroup`.
- **Fix**: Provide `ControlContainer` in `providers: [viewParentControlContainerProvider]`.

## TypeError: Cannot read properties of undefined (reading 'ɵcmp')
- **Context**: TestBed compiles a broken standalone import graph after `resetTestingModule()`. Logic-only specs still trigger template compilation.
- **Fix**: Use `runInInjectionContext()` with a provider-only TestBed for logic-only tests. Do not import components with templates when only testing service logic.
- **See also**: [testing.md](../../standards/angular-reactivity/testing.md#provider-only-testbed-for-logic-only-specs)
