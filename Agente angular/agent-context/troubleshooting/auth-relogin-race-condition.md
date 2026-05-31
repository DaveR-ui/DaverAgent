---
last_updated: 2026-05-28
description: Diagnosis of login race conditions and recurring redirection loops involving MSAL and RebarAuthService.
tags: [auth, login, msal, race-condition, rebar-auth, identity]
status: ACTIVE
---

# Annex: Auth Flow & Login Race Conditions

> [!IMPORTANT]
> This document is designed for AI agents to understand the critical failure points in the authentication startup flow.

## 🔍 Diagnosis Summary

The application experiences intermittent "re-login loops" or unexpected redirections during bootstrap. The root cause is a race condition in the coordination between the MSAL library and the `RebarAuthService`.

## 🏗️ Technical Architecture of the Failure

### 1. The Relogin Culprit: `RebarAuthService`
- **Location**: `src/app/core/rebarauth/rebar.auth.service.ts`
- **Logic**: Subscribes to `msalBroadcastService.inProgress$`.
- **Trigger**: When status enters `InteractionStatus.None` (MSAL is idle).
- **Execution Flow**:
  1. `checkAndSetActiveAccount()` is called to sync the MSAL session.
  2. `isUserAuthenticated()` is checked.
  3. If `false` (no active account/no accounts found), `login()` is invoked.
  4. `login()` may trigger `auth.loginRedirect()` if `getAllAccounts()` is empty.

### 2. The Race Condition
The `authObserver$` in `RebarAuthService` considers `InteractionStatus.None` as the "go" signal. However:
- `InteractionStatus.None` only means MSAL is not currently moving between states.
- It does **not** guarantee that account hydration from storage or the active account selection process has finished.
- If `isUserAuthenticated()` runs before MSAL satisfies the "account present" condition, the service erroneously triggers a new login.

### 3. Coordination Gap: `AppComponent`
- **Location**: `src/app/app.component.ts`
- **Logic**: Calls `msalService.handleRedirectObservable().subscribe()`.
- **Failure Mode**: The result of the redirect (token/account info) is discarded. There is no signaling mechanism between `AppComponent` (which handles the redirect completion) and `RebarAuthService` (which monitors the idle state).

## 📍 Critical Code Checkpoints

| File | Symbol | Role |
| --- | --- | --- |
| `src/app/core/rebarauth/rebar.auth.service.ts` | `authObserver$` | Monitors MSAL status to start auth checks. |
| `src/app/core/rebarauth/rebar.auth.service.ts` | `checkAndSetActiveAccount()` | Attempts to bind MSAL accounts to the active session. |
| `src/app/app.component.ts` | `handleRedirectObservable()` | Entry point for MSAL redirect processing. |

## 🛠️ Debugging & Verification

When troubleshooting authentication issues:
1. **Log `InteractionStatus` transitions**: Ensure `checkAndSetActiveAccount` isn't firing "too early" while storage is still being read.
2. **Account Hydration**: Verify `msalService.instance.getAllAccounts()` immediately after `handleRedirectObservable` resolves.
3. **Guard interference**: Check `app-routing.module.ts` for commented-out guards that might skip initialization steps.
4. **Session/Redirect state**: Check if `base-href` in `angular.json` or `index.html` matches the MSAL redirect URI config.

## 🔗 Related Documentation
- [Identity & User Data](../identity-user-data.md): For using user claims after successful authentication.
- [Security Permissions](../security-permissions.md): For role-based access control after login.
