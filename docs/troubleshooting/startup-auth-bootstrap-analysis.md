---
last_updated: 2026-06-03
description: map of the current application bootstrap, authentication startup, authorization timing, shell rendering, guard analysis, NgRx timeline, and bounded improvement slices
tags: [startup, bootstrap, auth, msal, routing, guards, ngrx, analysis, shell, app-component, rebar-auth, loading-spinner, datadog, launchdarkly]
status: ACTIVE
---

# Startup + Auth Bootstrap Analysis

> [!TIP]
> Use this document when a task mentions first login, shell flicker, unauthorized flashes after redirect, or the need to split the startup flow into smaller refactor slices.

## Purpose

- Document how the application boots today, from browser load to route authorization.
- Make the current coordination gaps explicit before attempting a fix.
- Propose bounded slices so auth startup can be improved without taking a large refactor in one step.

## Current Bootstrap Sequence

### 1. Browser bootstrap

**Files**
- `src/main.ts`
- `src/app/app.config.ts`
- `src/app/core/services/app-config.service.ts`

**What happens**
1. `DOMContentLoaded` triggers in `main.ts`.
2. `main.ts` fetches `config/config.json` manually and stores it in `sessionStorage`.
3. `bootstrapApplication(AppComponent, appConfig)` runs.
4. `app.config.ts` runs `provideAppInitializer(() => config.load())`.
5. `AppConfigService.load()` reads the same config from `sessionStorage` if present, otherwise performs another HTTP fetch.

**Observations**
- Config is preloaded twice conceptually: once in `main.ts`, once again via `AppConfigService.load()`.
- The second step is usually fast because of `sessionStorage`, but the ownership is split between two bootstrap layers.
- This does not directly explain the auth bug, but it increases startup complexity.

## 2. Auth bootstrap inside the shell

**Files**
- `src/app/app.component.ts`
- `src/app/core/rebarauth/rebar.auth.service.ts`
- `src/app/core/rebarauth/rebar.auth.module.ts`

**What happens**
1. `AppComponent.ngOnInit()` calls `msalService.handleRedirectObservable().subscribe()`.
2. The subscription discards the redirect result and does not gate any later startup work.
3. `RebarAuthService` is instantiated as part of app startup.
4. In its constructor, `RebarAuthService` subscribes to `msalBroadcastService.inProgress$`.
5. Every time the status becomes `InteractionStatus.None`, it calls:
   - `checkAndSetActiveAccount()`
   - `isUserAuthenticated()`
   - `login()` when no account is visible yet
6. `authObserver$` emits `true` whenever MSAL reports `InteractionStatus.None`.
7. `AppComponent` subscribes to `authObserver$` and treats that emission as the signal to continue startup.

**Important detail**
- In the current code, `InteractionStatus.None` is treated as if it meant auth is fully resolved.
- In practice it only means MSAL is idle, not that redirect hydration, account selection, and user permissions are all ready.

## 3. Post-auth app initialization

**Files**
- `src/app/app.component.ts`
- `src/app/state/user-info/user-info.effects.ts`

**What happens after `authObserver$` emits `true`**
1. `AppComponent` reads claims through `RebarAuthService.getUserClaims()`.
2. It constructs `UserClaims`.
3. It dispatches `setUserASGGroupInfo(...)`.
4. If the user is not ASG, it calls `continueLoading(...)`.
5. `continueLoading(...)` dispatches:
   - `loadLaunchdarklyFlags`
   - `setInitialUserInfo`
   - `getDropdownValues`
   - `getSecurityRoles`
   - `getNotificationList`
6. `UserInfoEffects` reacts to `setInitialUserInfo` and dispatches additional user-related actions.

**Observations**
- The shell starts loading role-dependent and flag-dependent state only after the auth service emits an idle status.
- There is no explicit state such as `authPending`, `authResolved`, or `permissionsResolved` coordinating the router with the shell.

## 4. Route authorization

**Files**
- `src/app/app-routing.module.ts`
- `src/app/core/guards/administration.guard.ts`
- `src/app/core/guards/admin-aia-management.guard.ts`

**What happens**
- Route access is mixed:
  - MSAL guard wiring exists in `RebarAuthModule` via `REBAR_AUTH_GUARD`.
  - The generic guarded route example at the bottom of `app-routing.module.ts` is commented out.
  - Sensitive routes like `administration/:environment` and `admin-aia-management` rely on custom authorization guards.
- These custom guards wait for store slices to load and then decide whether to allow the route.

**Guard behavior today**
- `AdministrationGuard` waits for both security permissions and LaunchDarkly flags.
- `AdminAiaManagementGuard` waits for security permissions and LaunchDarkly flags, even though it only uses permissions in its final decision.
- If permissions resolve to a deny state, the guard redirects to `/unauthorized`.

## Why the first-login flicker is plausible

This matches the reported symptom:

1. User deep-links into a protected page such as administration.
2. Redirect login completes.
3. The app shell renders and starts route evaluation before the full auth-derived state is ready.
4. `authObserver$` can report readiness too early because it is keyed only to `InteractionStatus.None`.
5. Guards depend on store-backed permissions and flags that are still being populated by `AppComponent.continueLoading(...)`.
6. The page can appear briefly, then a later authorization decision redirects to unauthorized.

The existing annex already documents the relogin race. The broader startup issue is that there is no single authority that says: auth redirect is resolved, active account is stable, claims were normalized, permissions were loaded, and route evaluation can now proceed.

## Complex Or Fragile Areas

### A. `AppComponent` is doing orchestration work

`AppComponent` currently owns several unrelated startup responsibilities:
- redirect handling
- auth readiness reaction
- user-claims normalization
- store bootstrap dispatches
- LaunchDarkly timing
- Datadog initialization
- inactivity modal timers
- router event tracking

This makes the true startup contract hard to reason about.

### B. `RebarAuthService` mixes observation and command

The service currently:
- listens to MSAL lifecycle
- decides whether auth is ready
- mutates active account
- triggers login redirects

That creates a feedback loop where an observer of auth lifecycle can also trigger a new auth transition.

### C. Guards are deciding with asynchronously populated state

The authorization guards are not wrong in isolation, but they are tightly coupled to the timing of `AppComponent.continueLoading(...)`.

Consequence:
- route authorization is effectively dependent on shell side effects having completed first.

### D. Mixed startup ownership

Bootstrap work is currently spread across:
- `main.ts`
- `app.config.ts`
- `AppComponent`
- `RebarAuthService`
- route guards

That distribution makes it harder to define one reliable startup boundary.

## Best Approach

The best approach is not to patch the symptom in the guard first. The cleaner direction is to establish an explicit startup state machine and then let the router depend on that boundary.

### Recommended target shape

Use distinct phases instead of a single implicit readiness signal:

1. `configReady`
2. `redirectHandled`
3. `accountResolved`
4. `identityReady`
5. `permissionsReady`
6. `appReady`

The router should not evaluate sensitive authorization decisions as if the app were fully initialized before at least `permissionsReady`.

### Why this is the better direction

- It addresses the root coordination problem, not only one unauthorized redirect.
- It reduces coupling between `AppComponent` and route guards.
- It gives testable checkpoints instead of relying on incidental timing.
- It supports smaller slices with visible intermediate wins.

## Suggested Improvement Slices

### Slice 1. Separate redirect completion from generic idle state

**Goal**
- Stop using `InteractionStatus.None` as the only definition of auth readiness.

**Change direction**
- Capture the result of `handleRedirectObservable()` explicitly.
- Introduce a dedicated resolved signal/observable for redirect completion plus account selection.
- Keep `loginRedirect()` decisions out of a generic idle subscription.

**Expected gain**
- Reduces false positives where the app thinks auth is resolved only because MSAL is idle.

### Slice 2. Extract startup orchestration out of `AppComponent` ✅ DONE (2026-06-17)

**Goal**
- Move auth/bootstrap sequencing into a dedicated startup facade or initializer service.

**Change direction**
- Keep `AppComponent` focused on shell rendering and shell-only concerns.
- Move user bootstrap dispatches and Datadog gating into one startup coordinator.

**Expected gain**
- Cleaner ownership and easier tests.

**Implementation (2026-06-17)**

New file: `src/app/core/services/app-startup-orchestrator.service.ts` — `providedIn: 'root'`, single public `run()` method.

| Moved into orchestrator | Stayed in AppComponent |
|---|---|
| MSAL `handleRedirectObservable` + LD pre-warm | Router event tracking (constructor) |
| Permissions readiness watching | `@ViewChild` inactivity modal |
| Auth observer → claims normalization + store dispatches | Inactivity timer logic |
| Auth observer → Datadog initialization | LD flags → inactivity timer management |
| LD flags → `markLaunchDarklyResolved()` | `rebarAuthService.logout()` (for inactivity) |
| `continueLoading()` (5 store dispatches) | `startupReadiness` (template binding) |

`AppComponent` reduced from **264 → 141 lines** (−123 lines). Build passes with zero errors.

### Slice 3. Introduce explicit readiness for permissions ✅ DONE (2026-06-17)

**Goal**
- Make guards depend on explicit authorization readiness, not implicit store timing.

**Change direction**
- Add a small selector/facade that exposes when permissions and required flags are loaded.
- Evaluate access only after that readiness emits.

**Expected gain**
- Eliminates the "page renders, then unauthorized" class of issues.

**Implementation (2026-06-17)**

All 5 guards updated to gate on `AppStartupReadinessService.startupReady$` before evaluating permissions:

| Guard | Changes |
|---|---|
| `administration.guard.ts` | Removed `@UntilDestroy()`/`untilDestroyed` — startup gate already existed |
| `admin-aia-management.guard.ts` | Added startup gate via `combineLatest + skipWhile`, `createUrlTree`, removed `@UntilDestroy()` |
| `data-security.guard.ts` | Added startup gate, `take(1)`, replaced all `router.navigate` with `createUrlTree`, removed `@UntilDestroy()` |
| `historical-demand-migration.guard.ts` | Added startup gate, `take(1)`, `createUrlTree`, removed `@UntilDestroy()` |
| `workflow-management.guard.ts` | Added startup gate via `combineLatest`, replaced `skipWhile(isNil)` with startup gate |

Pattern applied uniformly:
```typescript
combineLatest([this.startupReadiness.startupReady$, this.permissions$, ...])
  .pipe(
    skipWhile(([startupReady]) => !startupReady),
    take(1),
    map(([, permissionsEntity, ...]) => { ... })
  )
```

All 4 spec files updated with `AppStartupReadinessService` mock (`startupReady$: of(true)`). **29/29 guard tests pass.**

### Slice 4. Simplify guard dependencies ✅ DONE (2026-06-17)

**Goal**
- Remove unnecessary waiting and reduce guard blast radius.

**Change direction**
- `HistoricalDemandMigrationGuard` combined LaunchDarkly flags (`_launchdarklyFlags`) but never used them in the final decision.
- Narrowed to minimum required state.

**Expected gain**
- Faster, more understandable route decisions.

**Implementation (2026-06-17)**

`historical-demand-migration.guard.ts`: Removed `launchdarklyFlags$` property, the store.select constructor block, and the LD source from `combineLatest`. `canActivate` now uses only `[startupReady$, permissions$]`. Matching spec cleanup: removed `selectLaunchdarklyFlags` mock, `LDFlagSet` import, and unused `withArgs` chains.

Note: `AdminAiaManagementGuard` had no unused LD dependency — no change needed there.

### Slice 5. Collapse config bootstrap ownership ✅ DONE (2026-06-17) → PATCHED (2026-06-17)

**Goal**
- Keep config loading in one place.

**Change direction**
- Chose `AppConfigService` (app initializer) as the single owner. Removed the pre-fetch from `main.ts`.

**Expected gain**
- Smaller startup surface and less duplicate reasoning.

**Implementation (2026-06-17)**

- `src/main.ts`: Removed `fetch('config/config.json')` + `sessionStorage.setItem` + `DOMContentLoaded` wrapper. File is now a simple `bootstrapApplication(AppComponent, appConfig).catch(console.error)`.
- `src/app/core/services/app-config.service.ts`: Removed `sessionStorage` fast-path read (was the handshake with `main.ts`) and the corresponding `sessionStorage.setItem` write after HTTP fetch. HTTP fetch is now the single, unconditional load path.
- `src/app/core/services/app-config.service.spec.ts`: Removed `'should return session cached values if available'` test (mechanism no longer exists); renamed remaining HTTP test to `'should make http request to load config'`.

> ⚠️ **MSAL factory crash — PATCHED (2026-06-17)**
>
> **Root cause**: Removing the pre-fetch from `main.ts` broke MSAL initialization. `RebarAuthModule.forRoot()` registers DI factories (`MSALInstanceFactory`, `MSALInterceptorConfigFactory`) that Angular evaluates during injector construction — **before** any `APP_INITIALIZER` runs. When `bootstrapApplication` was called immediately, `AppConfigService.config` was still `{}`, so `config.config['msal']` was `undefined` and threw `TypeError: Cannot read properties of undefined (reading 'auth')`.
>
> **Fix**: `main.ts` now fetches `config/config.json` again before calling `bootstrapApplication`, but instead of writing to `sessionStorage` it sets `AppConfigService.preloadedConfig` (a new static property). `AppConfigService.load()` checks that property first — if set, it populates `this.config` synchronously and returns `Promise.resolve(true)`, skipping the HTTP fetch. The net result is still **one** HTTP request total, with single ownership of config parsing.
>
> **Files changed**:
> - `src/main.ts`: added pre-fetch → `AppConfigService.preloadedConfig = jsonData` → `bootstrapApplication()`
> - `src/app/core/services/app-config.service.ts`: added `static preloadedConfig`, fast-path in `load()`
> - `src/app/core/services/app-config.service.spec.ts`: added `preloadedConfig = null` reset in `beforeEach`; added `'should use preloaded config when available and skip HTTP request'` test

## Concrete Review Notes By File

| File | Current role | Improvement note |
| --- | --- | --- |
| `src/main.ts` | Browser bootstrap + config prefetch | Duplicates config ownership with `AppConfigService.load()` |
| `src/app/app.config.ts` | Angular providers + app initializer | Good bootstrap boundary, but currently shares responsibility with `main.ts` |
| `src/app/app.component.ts` | Shell + startup orchestrator | Too many startup responsibilities mixed into the root component |
| `src/app/core/rebarauth/rebar.auth.service.ts` | Auth lifecycle watcher + login trigger | `InteractionStatus.None` is an insufficient readiness contract |
| `src/app/core/rebarauth/rebar.auth.module.ts` | MSAL provider setup | Guard wiring exists, but route usage is inconsistent |
| `src/app/core/guards/administration.guard.ts` | Role/flag-based route gate | Depends on async state populated after auth startup |
| `src/app/core/guards/admin-aia-management.guard.ts` | Admin AIA route gate | Waits on LaunchDarkly without using it in the final decision |

## Recommended Investigation Order

If this moves from documentation to implementation, the least risky order is:

1. Instrument and verify the exact order of `handleRedirectObservable`, `inProgress$`, `getAllAccounts()`, and `continueLoading(...)`.
2. Introduce a dedicated auth-startup readiness signal without changing route behavior yet.
3. Refactor one protected route to wait on explicit readiness.
4. Only then remove the old implicit timing assumptions.

## Boot Sequence Diagram

Visual reference for the full startup chain, from browser load to route authorization.

```
┌─────────────────────────────────────────────────────────────────┐
│  BROWSER                                                        │
│  ┌──────────┐    DOMContentLoaded    ┌──────────────────────┐   │
│  │ main.ts  │ ──────────────────────→ │ fetch(config.json)  │   │
│  └──────────┘                        └──────────┬───────────┘   │
│                                                  │              │
│                                       ┌──────────▼───────────┐  │
│                                       │ bootstrapApplication │  │
│                                       │ (AppComponent,       │  │
│                                       │  appConfig)          │  │
│                                       └──────────┬───────────┘  │
└──────────────────────────────────────────────────┼──────────────┘
                                                   │
         ┌─────────────────────────────────────────▼──────────────┐
         │  app.config.ts - ApplicationConfig                     │
         │                                                        │
         │  1. provideAppInitializer → AppConfigService.load()    │
         │  2. StoreModule.forRoot(reducers)                      │
         │  3. EffectsModule.forRoot(50+ effects)                 │
         │  4. RebarAuthModule.forRoot() ← MSAL/Azure AD          │
         │  5. AppRoutingModule                                   │
         │  6. HTTP Interceptors (AppInterceptor + MsalInterceptor│
         └─────────────────────────────────────────┬──────────────┘
                                                   │
         ┌─────────────────────────────────────────▼──────────────┐
         │  AppComponent.ngOnInit()                               │
         │                                                        │
         │  1. msalService.handleRedirectObservable().subscribe() │
         │  2. Suscribirse a rebarAuthService.authObserver$       │
         │     └─→ Cuando auth=true:                              │
         │         ├─ initializeDatadog()                         │
         │         ├─ dispatch(setUserASGGroupInfo)               │
         │         ├─ Si NO es ASG → continueLoading()            │
         │         │   ├─ dispatch(loadLaunchdarklyFlags)         │
         │         │   ├─ dispatch(setInitialUserInfo)            │
         │         │   ├─ dispatch(getDropdownValues)             │
         │         │   ├─ dispatch(getSecurityRoles)              │
         │         │   └─ dispatch(getNotificationList)           │
         │         └─ Si es ASG → dispatch(setInitialUserInfo{})  │
         │  3. Suscribirse a launchdarklyFlags$ (inactivity)      │
         └────────────────────────────────────────────────────────┘
```

## Shell Rendering Analysis

### The unconditional shell problem

**File**: `src/app/app.component.html`

```html
@if (userInfoLoading$ | async; as userInfoLoading) {
  @if (userInfoLoading.loading) {
    <app-loading-spinner [isFull]="true"></app-loading-spinner>
  }
}

<!-- notifications ... -->

<app-shell class="d-flex flex-column w-100 h-100"></app-shell>
```

**Problem**: `<app-shell>` renders **unconditionally**. The spinner overlays on top, but the shell is already in the DOM, including `<router-outlet>`.

**Consequence**: Angular Router attempts to resolve the current route (e.g. `/administration/npd`) immediately. Guards activate, but they depend on data that has not arrived yet.

**File**: `src/app/core/containers/app-shell/app-shell.component.html`

```html
@if (!enableGoneFishingLD) {
  @if (!ASG_unauthorized_user) {
    <app-header></app-header>
    <main><router-outlet></router-outlet></main>
    <app-footer></app-footer>
  } @else {
    <app-asg-unauthorized-user></app-asg-unauthorized-user>
  }
} @else {
  <app-gone-fishing></app-gone-fishing>
}
```

The shell has 3 visual states (normal, ASG unauthorized, gone fishing) but **none** of them account for "auth not resolved yet".

**File**: `src/app/core/containers/app-shell/app-shell.component.ts`

The shell also performs navigation side effects:
- `router.navigate(['/maintenance'])` when `enableGoneFishingLD` is true
- `router.navigate(['/unauthorized-user'])` when `isASGUser` is true

This mixes layout rendering with navigation decisions, creating a diffuse responsibility boundary.

## Complete Guard Analysis

### Guard comparison table

| Guard | File | Dependencies | Complexity | Pattern Issues |
|-------|------|-------------|------------|----------------|
| `AdministrationGuard` | `administration.guard.ts` | securityRoles + LD flags | Media | No `take(1)`, observable stays open |
| `DataSecurityGuard` | `data-security.guard.ts` | securityRoles + LD flags + URL parsing | **Alta** | 107 lines, 3 nested if/else levels, ReplaySubject, `indexOf` URL parsing |
| `WorkflowManagementGuard` | `workflow-management.guard.ts` | securityRoles only | Baja | Uses `take(1)` correctly - cleanest guard |
| `AdminAiaManagementGuard` | `admin-aia-management.guard.ts` | securityRoles + LD flags | Media | Waits on LD flags but ignores them in final decision |
| `ProjectAiaCreationGuard` | `project-aia-creation.guard.ts` | securityRoles + LD flags | Media | Similar to Administration |
| `HistoricalDemandMigrationGuard` | `historical-demand-migration.guard.ts` | ? | ? | Not analyzed |

### Common guard pattern

```
combineLatest([
  permissions$  ← store.select(securityRoles)
                  .pipe(skipWhile(!loaded))  ← WAITS
  launchdarklyFlags$ ← store.select(ldFlags)
                  .pipe(skipWhile(isNil))    ← WAITS
])
.pipe(map(([perms, flags]) => {
  const hasAccess = perms.includes(...) && flags['flags']
  return hasAccess ? true : router.navigate(['/unauthorized'])
}))
```

### Guard-specific issues

**DataSecurityGuard** (highest complexity):
- Uses `ReplaySubject` to bridge store subscription into `canActivate` — unnecessary indirection
- URL parsing via `indexOf('data-security-create')`, `indexOf('data-security-details')`, `indexOf('data-security')` — fragile ordering dependency (the `data-security` catch-all must be last)
- 3 levels of nested if/else for each URL branch × LD flag check
- Routes to `/unauthorized-user` (not `/unauthorized` like other guards)

**WorkflowManagementGuard** (cleanest):
- Uses `take(1)` — properly unsubscribes after first resolution
- Single dependency (securityRoles only)
- Returns `UrlTree` instead of calling `router.navigate()` — the Angular-preferred pattern

**Inconsistent error routes**:
- `/unauthorized` — used by AdministrationGuard, AdminAiaManagementGuard
- `/unauthorized-user` — used by DataSecurityGuard, AppShellComponent
- These resolve to different components/pages

## NgRx Initialization Timeline

```
┌─────────────────────────────────────────────────────────────────────┐
│  TIMELINE DE INICIALIZACIÓN                                         │
│                                                                     │
│  t0: App boot → Store inicializado                                  │
│      user-info: { loading: true, loaded: false }                    │
│      security-roles: { loaded: false }                              │
│      launchdarkly-flags: null                                       │
│                                                                     │
│  t1: MSAL resuelve → authObserver$ emite true                       │
│      → dispatch(setUserASGGroupInfo)                                │
│      → dispatch(setInitialUserInfo) → loading: false ← ⚠️           │
│      → dispatch(loadLaunchdarklyFlags)                              │
│      → dispatch(getSecurityRoles)                                   │
│      → dispatch(getDropdownValues)                                  │
│      → dispatch(getNotificationList)                                │
│                                                                     │
│  t2: user-info.loading = false                                      │
│      → El spinner desaparece                                        │
│      → El shell ya estaba renderizado                               │
│      → Router ya intentó navegar                                    │
│      → Guards esperando securityRoles + LD flags                    │
│                                                                     │
│  t3: securityRoles loaded = true                                    │
│      launchdarklyFlags != null                                      │
│      → Guards pueden resolver                                       │
│      → Si no tiene permiso → redirect a /unauthorized               │
│      → FLASH: el usuario vio la pantalla antes del redirect         │
└─────────────────────────────────────────────────────────────────────┘
```

**Key gap**: `user-info.loading` becomes `false` at `t2` (when eId/name are set), but `security-roles` and `launchdarkly-flags` have not loaded yet. The spinner disappears, the shell is visible, but guards cannot resolve yet.

## Extended Improvement Slices

| # | Slice | File | Problem | Severity |
|---|-------|------|---------|----------|
| 1 | **Shell sin gate de auth** | `app.component.html` | `<app-shell>` renders unconditionally, without waiting for auth or permissions | **Alta** — causes the flash |
| 2 | **Loading state prematuro** | `user-info.reducer.ts` | `loading: false` is set when eId/name arrive, not when everything is ready | **Media** — spinner disappears too early |
| 3 | **Guards sin `take(1)`** | `administration.guard.ts`, `data-security.guard.ts` | Observables stay open, may re-evaluate unnecessarily | **Media** — potential memory leak |
| 4 | **DataSecurityGuard complejo** | `data-security.guard.ts` | 107 lines, 3 nested if/else levels, unnecessary ReplaySubject, URL parsing with indexOf | **Alta** — hard to maintain |
| 5 | **Rutas de error inconsistentes** | Various guards | `/unauthorized` vs `/unauthorized-user` — no convention | **Baja** — confusion |
| 6 | **authObserver$ semántica** | `rebar.auth.service.ts` | Emits `true` when MSAL is idle, not when authenticated. If login fails, it also emits `true` | **Media** — silent bug |
| 7 | **Cascada de dispatches** | `app.component.ts` L142-152 | `continueLoading()` fires 5 dispatches in series without orchestration | **Media** — no order guarantee |
| 8 | **AppShellComponent con lógica de routing** | `app-shell.component.ts` | Shell does `router.navigate()` based on flags. Mixes layout with navigation | **Media** — diffuse responsibility |
| 9 | **Console.logs en producción** | `app.component.ts`, `rebar.auth.service.ts` | Multiple `console.log` with user data and claims | **Baja** — info leak |
| 10 | **Datadog inline en AppComponent** | `app.component.ts` L158-193 | 35 lines of Datadog RUM initialization inline, with `declare let` and script injection | **Baja** — should be a service |

## Alternative Approaches

### Approach A: Gate in template (minimal change)

```html
<!-- app.component.html -->
@if (authResolved$ | async) {
  <app-shell></app-shell>
} @else {
  <app-loading-spinner [isFull]="true"></app-loading-spinner>
}
```

- **Pros**: 1 file, minimal change
- **Cons**: Does not fix the dispatch cascade or guard timing

### Approach B: APP_INITIALIZER with auth blocking

```typescript
// app.config.ts
provideAppInitializer(() => authService.waitForAuth())
```

- **Pros**: App does not start until auth is resolved
- **Cons**: Can block indefinitely if MSAL has issues. Requires timeout handling.

### Approach C: Unified initialization state

```typescript
// New selector: selectAppReady
combineLatest([userInfo$, securityRoles$, ldFlags$]).pipe(
  map(([u, s, l]) => u.loaded && s.loaded && !isNil(l))
)
```

- **Pros**: Single source of truth for "app is ready"
- **Cons**: Requires state management refactor

### Recommendation

The existing "Best Approach" section (phased startup state machine) is the correct long-term direction. For an immediate quick win, **Approach A** (template gate) eliminates the visible flash with minimal risk. **Slice 1** (separate redirect completion from idle state) is the highest-value structural improvement that does not require a large refactor.

## Hidden Assumption

> This analysis assumes there is no additional auth logic in HTTP interceptors (`AppInterceptor`, `MsalInterceptor`) or in `AppConfigService` that could affect the startup flow. If either interceptor has redirect/retry logic that interacts with guards, the diagnosis may be incomplete.

## Firefox Log Analysis (2026-06-18)

Log file: `log-startup.txt` (Firefox, first login after redirect, dev environment).

### ✅ Startup sequence is healthy

| Timestamp | Event |
|---|---|
| 13:41:51 | `msal:initializeEnd` + `msal:handleRedirectStart` — bootstrap OK |
| 13:41:55 | Second `msal:initializeEnd` — normal redirect round-trip (first cycle detects no session, redirects to AAD; second cycle completes after return) |
| 13:41:56 | `msal:loginSuccess` + `msal:handleRedirectEnd` |
| 13:41:56 | User claims resolved, LD pre-warm triggered |
| 13:41:56 | `LaunchDarkly client initialized` — < 1 s after auth |
| 13:41:56 | `Initializing Datadog` |

No `TypeError reading 'auth'` — the `preloadedConfig` fix from 2026-06-18 is working.

### 🐛 Issue found: Datadog script URL `undefined` (fixed 2026-06-18)

**Symptom** (line 103–104 of log):
```
"https://dataservicesportal-dev.ciodev.accenture.com/undefined" blocked due to MIME type mismatch
Loading failed for the <script> with source ".../undefined"
```

**Root cause**: `config.dev.json` has a `datadog` object but no `datadogScriptUrl` key. `initializeDatadog()` in `AppStartupOrchestratorService` was doing `script.setAttribute('src', scriptUrl)` without checking if `scriptUrl` was falsy, so the browser tried to load `<appOrigin>/undefined`.

**Fix**: Added a `if (!scriptUrl) { return; }` guard before script injection. Environments without `datadogScriptUrl` (dev, mock) now skip Datadog script injection cleanly.

### ℹ️ AADSTS50058 errors — NOT from this app (lines 69–88, 110–129)

The full callstack is inside `acnwidgetlogin.js` (`notificationsadmin.ciostage.accenture.com`). This is the Accenture notification widget doing its own `ssoSilent`, which fails because Firefox blocks third-party cookies. **This repo does not control that widget.** See `cookie-theory-refutations.md` and `edge-strict-aadsts50058-storm.md` for the full documented root cause.

### ℹ️ Double `msal:initializeEnd` — expected behavior

Two `msal:initializeEnd` events separated by ~4 s is normal for redirect flow:
1. First cycle: app loads, no session, MSAL redirects to AAD.
2. Second cycle: app re-loads after AAD redirect, MSAL processes the auth code.

These ~4 seconds are inherent to the redirect round-trip, not a bug in this repo.

## Related Documents

- `troubleshooting/auth-relogin-race-condition.md`
- `identity-user-data.md`
- `security-permissions.md`