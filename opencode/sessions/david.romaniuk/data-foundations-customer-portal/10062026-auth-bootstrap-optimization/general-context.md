# General Context

## Session Information
- **Session ID**: 10062026-auth-bootstrap-optimization
- **Created**: 2026-06-10
- **Project**: data-foundations-customer-portal (DFCustomerPortal)
- **Human**: David Romaniuk

## Original Prompt (es-AR)
> .github\agent-context\troubleshooting\startup-auth-bootstrap-analysis.md
> En ese archivo tengo una investigacion sobre como se hacia relogin. En teoria se implemento el plan ese. El bug se soluciono, pero ahora tarda demasiado. Se podra optimizar un poco mas el primer login?

## Prompt Classification
- **Type**: Performance Optimization
- **Priority**: High (user-facing slowness)
- **Complexity**: Medium-High (auth/bootstrap, multiple files, risk of regression)

## Context Summary
The previous auth bootstrap investigation (`startup-auth-bootstrap-analysis.md`) resulted in a fix for a relogin race condition. The fix introduced `AppStartupReadinessService` and gated the shell on `authResolved + permissionsResolved + launchDarklyResolved`. The bug is resolved, but the first login is now slow because the shell blocks until ALL readiness signals resolve sequentially.

## Optimization Plan

### Phase 1: Quick Wins (Low Risk)
1. **Move Datadog out of auth callback** — `app.component.ts` — defer with `requestIdleCallback`
2. **Fix `ProjectAiaCreationGuard`** — always returns `true` but waits for LD flags unnecessarily
3. **Remove unused LD dependency from `AdminAiaManagementGuard`** — subscribes to LD flags but never uses them

### Phase 2: High Impact (Medium-High Risk)
4. **Pre-warm LaunchDarkly during MSAL redirect** — parallelize LD init with auth resolution instead of sequential
5. **Defer non-critical dispatches** from `continueLoading()` — reduce HTTP contention

### Phase 3: Architectural (Future)
6. **Route-aware shell gate (progressive rendering)** — render shell with auth-only for unguarded routes
7. **Standardize all guards on `startupReady$`** — prerequisite for progressive rendering
8. **Collapse config loading** — single ownership in `AppConfigService`

## Key Files
- `src/app/app.component.ts` — Main component, auth callback, dispatch cascade
- `src/app/app.component.html` — Shell gate template
- `src/app/core/services/rebar/rebar.auth.service.ts` — Auth service with `tryResolveAuthentication()`
- `src/app/core/services/app-startup-readiness.service.ts` — Readiness signals
- `src/app/core/services/launchdarkly.service.ts` — LD SDK initialization
- `src/app/core/guards/administration.guard.ts` — Uses `startupReady$`
- `src/app/core/guards/admin-aia-management.guard.ts` — Unused LD dependency
- `src/app/core/guards/project-aia-creation.guard.ts` — No-op guard with LD wait
- `src/app/core/containers/app-shell/app-shell.component.ts` — Redundant subscriptions
- `src/main.ts` — Config pre-fetch

## Attachment Processing Log
- No attachments in this session
