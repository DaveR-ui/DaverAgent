---
last_updated: 2026-06-16
description: root cause and mitigation of the AADSTS50058 storm observed during app bootstrap in Edge with Strict tracking prevention (incognito)
tags: [auth, msal, aadsts50058, edge, third-party-cookies, troubleshooting, dev-only]
status: ACTIVE
---

# AADSTS50058 Storm in Edge Strict Tracking Prevention

> [!WARNING]
> This document describes a **browser-policy-driven** noise pattern, **not** an application defect. Read it before re-investigating `AADSTS50058` errors at boot.

## Purpose

- Capture the exact symptom, trigger chain, and root cause of the `AADSTS50058` storm observed in Edge incognito with Strict tracking prevention.
- Document 3 ranked mitigations so a future agent does not invent a fourth.
- Explicitly differentiate the storm from the legacy "relogin race condition" documented in [`auth-relogin-race-condition.md`](auth-relogin-race-condition.md) and from the "cookie reset" theory refuted in [`cookie-theory-refutations.md`](cookie-theory-refutations.md).
- Provide a verification recipe to confirm a mitigation worked.

## Symptom

The user sees, in the browser console, **three or more `AADSTS50058` errors** in a tight burst during the post-auth bootstrap window:

```
AADSTS50058: A silent sign-in request was sent but no user is signed in.
AADSTS50058: A silent sign-in request was sent but no user is signed in.
AADSTS50058: A silent sign-in request was sent but no user is signed in.
```

Telltale: the burst appears between the two log lines

```
[LOAD SEQUENCE] Pre-warming LaunchDarkly with enterpriseId from redirect
... (pre-warm window) ...
LaunchDarkly client initialized
```

i.e. inside the `continueLoading(...)` window. The app still loads; the user is still logged in; navigation continues. **The storm is console noise, not a functional failure.**

## Root cause (one sentence)

**The AAD silent iframe cannot read the AAD SSO cookie from `login.microsoftonline.com` when the parent origin is treated as a third party by the browser's tracking-prevention policy.**

The AAD SSO cookie is set on the `login.microsoftonline.com` origin. MSAL's silent flow opens a hidden iframe to that origin to read the cookie and exchange it for a fresh access token. In Edge with **Strict tracking prevention in incognito mode**, the browser partitions or drops third-party cookies; the iframe cannot see the SSO cookie; AAD returns `AADSTS50058` / `login_required` because it has no session to honor the `prompt=none` request.

This is the same root cause that affects:

- Edge incognito (Strict tracking prevention) — the user's environment.
- Safari (Intelligent Tracking Prevention, default).
- Any browser configured to block third-party cookies.
- Chrome with `chrome://flags/#third-party-cookies-deprecation` flipped on.

It does **not** affect:

- Edge with `Balanced` or `Basic` tracking prevention.
- Chrome with default settings.
- Firefox with default settings.
- Any non-incognito Edge window that has the SSO cookie as a first-party cookie.

## Trigger chain (file:line)

1. `src/app/app.component.ts:170-180` — `continueLoading(userClaims)` is invoked after `RebarAuthService.authObserver$` emits `true`.
2. The function fires:
   - `this.pubSubAuditService.auditLogin().pipe(take(1)).subscribe()` at `app.component.ts:171` — HTTP GET to `gatewayWorkflowUrl + '/api/workflow/UserEvent/AuditLogin'` (see `src/app/core/services/pub-sub-audit.service.ts:15-28`).
   - `getDropdownValues()` at `app.component.ts:177`
   - `getSecurityRoles()` at `app.component.ts:178`
   - `getNotificationList()` at `app.component.ts:179`
3. The first three URLs above are listed in `src/config/config.dev.json`'s `msal.auth.framework.protectedResourceMap` (lines 27-36). MSAL classifies them as protected and the `MsalInterceptor` (registered at `src/app/core/rebarauth/rebar.auth.module.ts:110-115`) calls `acquireTokenSilent({ scopes: [...] })` for each.
4. `acquireTokenSilent` opens a hidden iframe to `https://login.microsoftonline.com` to read the AAD SSO cookie and exchange it for an access token.
5. In Edge incognito + Strict, the browser blocks the SSO cookie in the iframe. AAD responds with `AADSTS50058` / `login_required`.
6. MSAL's silent-flow retry policy **attempts the call 3 times per protected URL** before surfacing the final error. With 1+ protected calls and the retry policy, the user sees the "storm" of 3+ `AADSTS50058` lines.

```
AppComponent.continueLoading()            [app.component.ts:170-180]
   │
   ├─► pubSubAuditService.auditLogin()    [app.component.ts:171]
   │       │
   │       └─► HTTP GET <gatewayWorkflowUrl>/api/workflow/UserEvent/AuditLogin
   │               │
   │               └─► MsalInterceptor   [rebar.auth.module.ts:110-115]
   │                       │
   │                       └─► acquireTokenSilent({scopes})
   │                               │
   │                               └─► AAD iframe to login.microsoftonline.com
   │                                       │
   │                                       └─► SSO cookie BLOCKED by Edge Strict
   │                                               │
   │                                               └─► AADSTS50058 (login_required)
   │                                                       │
   │                                                       └─► MSAL retries 3x ──► "storm"
   │
   ├─► dispatch(getDropdownValues())       [app.component.ts:177]   (state action → effect → HTTP)
   ├─► dispatch(getSecurityRoles())        [app.component.ts:178]   (state action → effect → HTTP)
   └─► dispatch(getNotificationList())     [app.component.ts:179]   (state action → effect → HTTP)
```

## Affected environments

| Environment | Storm? | Why |
| --- | --- | --- |
| Edge incognito + Strict tracking prevention | **YES** | Third-party cookies blocked; SSO cookie invisible to silent iframe |
| Edge incognito + Balanced/Basic | No | Cookie is allowed |
| Edge normal window | No | Cookie is first-party |
| Safari (ITP default) | YES (likely) | Third-party cookies blocked after 24h |
| Chrome (default) | No | Third-party cookies still allowed by default |
| Chrome with 3P cookies off | YES | Same as Edge Strict |
| Firefox (default) | No | Third-party cookies allowed by default in private mode |
| Cypress E2E | No | Uses mock environment (`environment.providers === 'mock'`) — `RebarAuthService.authenticationEnabled()` returns `false` at `rebar.auth.service.ts:58-60`, so the protected calls never reach MSAL |

## Relationship to the 2026-06-16 readiness fix (Slice 1+6)

The 2026-06-16 PR to `src/app/core/rebarauth/rebar.auth.service.ts:140-151` added an `idTokenClaims` precondition to `tryResolveAuthentication()`. **This fix does NOT eliminate the AADSTS50058 storm.** The fix makes the readiness signal honest (it no longer emits `true` before claims are hydrated), but the protected HTTP calls still fire from `continueLoading(...)` once the signal does emit, and the silent iframe still hits the cookie wall.

The two changes target different layers:

| Layer | What it fixes | What it does NOT fix |
| --- | --- | --- |
| Readiness precondition (`rebar.auth.service.ts:140-151`) | Premature emission of `authObserver$ = true` while claims are still empty | MSAL retry storm inside the iframe |
| Datadog call-site guard (`app.component.ts:202-205`) | CSP `Refused to execute script from '…/undefined'` when `datadogScriptUrl` is missing | Anything auth-related |

The storm is browser-policy driven, so the fix has to be browser-side or have to wrap the protected calls.

## Mitigations (ranked by code invasion)

### Mitigation 1 (no code) — change Edge tracking prevention

For local dev, set Edge to `Balanced` or `Basic` tracking prevention (NOT `Strict`). This is the only mitigation with zero code change and zero risk. The AAD SSO cookie is allowed in the silent iframe in `Balanced`/`Basic` mode, and the storm disappears.

To set this in Edge: `edge://settings/privacy` → Tracking prevention → set to `Balanced` (default) or `Basic` (more permissive).

### Mitigation 2 (low invasion) — silently catch errors in `continueLoading`

Add `.pipe(catchError(() => of(null)))` to each of the 4 protected calls in `src/app/app.component.ts:170-180`. Concretely:

```typescript
// app.component.ts:170-180 (proposed — NOT APPLIED)
continueLoading(userClaims: UserClaims) {
  this.pubSubAuditService.auditLogin()
    .pipe(take(1), catchError(() => of(null)))
    .subscribe();
  // ...
}
```

Equivalent wrappers would be needed on the NgRx effects that handle `getDropdownValues`, `getSecurityRoles`, and `getNotificationList` to suppress their downstream MSAL retries.

- **Pros**: silences the storm in the console; minimal change.
- **Cons**: **band-aid**. The protected calls still fail silently. Downstream features (dropdowns, security roles, notifications, audit logging) may not get the data they need. Validate with the calling features before adopting.
- **Risk**: silent data loss for protected calls. Not recommended for production; acceptable as a dev-only ergonomic improvement.

### Mitigation 3 (out of repo) — AAD app registration + CDN

Configure the AAD application registration to support `prompt=none` cleanly with the silent iframe, or configure the CDN/edge to set `Sec-Fetch-Site: same-origin` for the silent iframe. Requires infra/IT work. Cannot be done in this repo.

This is the only long-term fix; the others are stopgaps.

## Verification

To confirm you are seeing the storm described here (and not a different AADSTS50058 cause):

1. Open `edge://settings/privacy` and confirm Tracking prevention is set to `Strict`. (Setting to `Balanced` should make the storm disappear, which confirms this is the cause.)
2. Open `edge://flags/#third-party-storage-partitioning` and verify the flag is enabled (this is the underlying mechanism).
3. Open the app in an incognito window with `Strict` enabled.
4. Look for 3 `AADSTS50058` errors in the DevTools Console between the two `Pre-warming LaunchDarkly` / `LaunchDarkly client initialized` log lines.
5. Confirm the app still navigates to the expected page and the user is logged in (i.e. the storm is not a functional failure).

To confirm a mitigation worked:

- **Mitigation 1**: change Edge tracking prevention, reload, count `AADSTS50058` errors. Should be 0.
- **Mitigation 2**: apply the `catchError` wrappers, reload, count `AADSTS50058` errors. Should be 0, but the dropdown/security-roles/notifications data may be missing — verify by inspecting the store state in the NgRx DevTools.
- **Mitigation 3**: requires CDN/AAD config changes; verify in a staging environment with the AAD team.

## Cross-references

- [`startup-auth-bootstrap-analysis.md`](startup-auth-bootstrap-analysis.md) — canonical startup analysis. The 2026-06-16 readiness fix is documented in the **Most Recent Update (2026-06-16)** section, and the storm is summarized in the **Known Issue: AADSTS50058 Storm in Edge Strict Tracking Prevention** section.
- [`auth-relogin-race-condition.md`](auth-relogin-race-condition.md) — covers a **different** auth failure mode: a re-login loop in the `RebarAuthService` constructor. Not the same root cause; not the same symptom.
- [`cookie-theory-refutations.md`](cookie-theory-refutations.md) — catalog of refuted hypotheses for the storm, including the "cookie reset during bootstrap" theory the user originally proposed. **Read this before re-investigating cookie-related AADSTS50058 causes.**
