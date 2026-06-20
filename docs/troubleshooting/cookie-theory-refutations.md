---
last_updated: 2026-06-16
description: catalog of refuted "cookie reset" theories for the AADSTS50058 storm, with evidence and search methodology
tags: [auth, msal, aadsts50058, cookies, refuted-hypothesis, troubleshooting]
status: ACTIVE
---

# Cookie Theory Refutations

> [!IMPORTANT]
> This document captures hypotheses that were investigated and **refuted** during the 2026-06-16 AADSTS50058 investigation. Future agents: read this **before** spending time re-investigating cookie-related causes for the storm.

## Purpose

- Document the user's original theory that "the cookie gets reset during bootstrap, which is what causes the AADSTS50058 storm".
- Capture the exact evidence and search steps used to refute it.
- Provide a re-runnable search methodology so a future agent can verify the refutation cheaply.
- Prevent repeated investigation of the same theory.

## Theory #1: "Setting or clearing a cookie during the bootstrap window resets the MSAL silent flow"

This was the theory proposed by the user who pasted the Edge incognito console logs. The user observed the `AADSTS50058` storm and inferred that "the cookie gets reset" was the cause. The investigation found **no code path in this repo that writes, deletes, or otherwise mutates a cookie during the bootstrap window** that would affect MSAL.

### Investigation steps (in order)

1. **Exhaustive search for cookie mutations in `src/`.** The following regex patterns were used against the entire `src/` tree:
   - `document\.cookie`
   - `cookieService\.set`
   - `cookieService\.delete`
   - `setCookie`
   - `clearCookie`
   - `removeCookie`
   - `localStorage\.(set|remove)Item`
   - `sessionStorage\.(set|remove)Item`
   - `indexedDB`
   - `msalCache`

   **Result — only one hit**:
   - `src/app/core/services/datadog-session.service.ts:14-24` — `setCookie(name, val, exdays)` writes `document.cookie = name + '=' + value + ';' + expires + ';path=/;secure'` at **line 23**. The cookie name is `_dduserid` (Datadog's RUM session ID). The only caller is `setDataDogSessionId()` (lines 4-13), which is gated on the cookie not already existing.

2. **Verify that `DatadogSessionService.setDataDogSessionId()` is never called in the application code.** Grep for `setDataDogSessionId` across `src/`. **Result — zero hits** in the application code. The service exists and the method is defined, but no component, service, effect, or guard calls it. The grep evidence is the only thing that supports this; if a future change adds a caller, the refutation weakens.

3. **Verify that MSAL's `storeAuthStateInCookie` is `false` on Edge.** The flag is set in `src/app/core/rebarauth/rebar.auth.module.ts:31, 51`:
   ```typescript
   const isIE = window.navigator.userAgent.indexOf('MSIE ') > -1 || window.navigator.userAgent.indexOf('Trident/') > -1;
   // ...
   cache: {
     cacheLocation: BrowserCacheLocation.LocalStorage,
     storeAuthStateInCookie: isIE // set to true for IE 11. Remove this line to use Angular Universal
   }
   ```
   In Edge, `isIE` is `false`, so MSAL stores auth state in `localStorage`, not in a cookie. **No MSAL-controlled cookies are written by this app in Edge.**

4. **Verify that the AAD SSO cookie lives on a different origin from the app.** The AAD SSO cookie is set on `login.microsoftonline.com` (visible in `config.dev.json`'s `authority` field at `config.dev.json:23`). The app is served from `dataservicesportal-dev.ciodev.accenture.com` (visible in `redirectUri` at `config.dev.json:25`). Cookies are origin-bound: a `document.cookie` write from the app cannot affect a cookie on `login.microsoftonline.com`. **App-side cookie writes cannot reset the AAD SSO cookie.**

5. **Verify that the AAD silent iframe is the only consumer of the AAD SSO cookie, and that the only ways the cookie can be missing are browser policy or AAD session expiration.** The AAD SSO cookie is read inside the hidden iframe that MSAL opens to `login.microsoftonline.com` during `acquireTokenSilent`. If the cookie is missing from that iframe, the only explanations are:
   - The user is not signed in to AAD (the cookie was never set).
   - The AAD session has expired (the cookie was set but its `Max-Age` has elapsed).
   - The browser is blocking third-party cookies in the iframe (Edge Strict, Safari ITP, Chrome 3P deprecation).
   - The AAD tenant has been misconfigured (out of repo).

   None of these explanations involve "app code writes a cookie that resets the AAD SSO cookie". That mechanism is structurally impossible because of step 4.

### Verdict

**REFUTED.**

The repo writes no cookies during the bootstrap window that would affect MSAL. The only cookie writer is `DatadogSessionService.setDataDogSessionId()` (`datadog-session.service.ts:4-13`), and that method is never called. Even if it were called, it writes a `_dduserid` cookie on the app's origin — not the AAD SSO cookie on `login.microsoftonline.com`. MSAL itself writes no cookies in Edge (`storeAuthStateInCookie: isIE` is `false`). The user's observation of "the cookie gets reset" was likely a misreading of the symptom or a conflation with the DevTools cookie panel showing transient state.

The actual cause of the storm is browser policy. See [`edge-strict-aadsts50058-storm.md`](edge-strict-aadsts50058-storm.md) for the full root cause and mitigations.

### Lesson for future agents

When investigating `AADSTS50058` storms, do not assume the app is writing or clearing cookies. The most likely causes, in order of frequency:

1. **Browser third-party cookie policy** (Edge Strict, Safari ITP, Chrome 3P deprecation). Verify with `edge://settings/privacy` (or the equivalent in the user's browser) and confirm the tracking-prevention setting.
2. **AAD session expiration** (the SSO cookie is gone because the user logged out of AAD elsewhere, or the AAD session `Max-Age` elapsed).
3. **AAD tenant / app-registration misconfiguration** (out of repo; ask the AAD team).
4. **Network-level blocking** (corporate proxy stripping `login.microsoftonline.com` cookies).

Only after ruling all four out should you grep the repo for cookie writers. And when you do, remember:

- `document.cookie` writes on the app's origin do NOT affect cookies on `login.microsoftonline.com`.
- MSAL's `storeAuthStateInCookie` is `false` on all non-IE browsers (`rebar.auth.module.ts:31, 51`).
- `localStorage` and `sessionStorage` are not cookies; they cannot affect MSAL's silent iframe flow.

## Search methodology used

The exact grep patterns and files inspected, so a future agent can re-run the same checks if needed:

| Step | Grep pattern | Files inspected | Result |
| --- | --- | --- | --- |
| 1a | `document\.cookie` | `src/**/*.ts` | 1 hit: `src/app/core/services/datadog-session.service.ts:23` |
| 1b | `cookieService\.(set\|delete)` | `src/**/*.ts` | 0 hits |
| 1c | `setCookie\|clearCookie\|removeCookie` | `src/**/*.ts` | 1 hit: `src/app/core/services/datadog-session.service.ts:14` (definition) |
| 1d | `localStorage\.(set\|remove)Item` | `src/**/*.ts` | Hits exist; not MSAL-related |
| 1e | `sessionStorage\.(set\|remove)Item` | `src/**/*.ts` | Hits exist; not MSAL-related (used for routing and DD payload) |
| 2 | `setDataDogSessionId` | `src/**/*.ts` | 0 hits outside the definition site |
| 3 | `storeAuthStateInCookie` | `src/**/*.ts` | 1 hit: `src/app/core/rebarauth/rebar.auth.module.ts:51`, value is `isIE` |
| 4 | `login\.microsoftonline\.com` | `src/config/*.json` | Present in `authority` field of all env configs (e.g. `config.dev.json:23`) |
| 5 | `redirectUri` | `src/config/*.json` | Present in all env configs; points to the app's own origin (e.g. `config.dev.json:25`) |

To re-run all five steps in a single sweep:

```bash
# from the repo root
rg -n 'document\.cookie' src/
rg -n 'cookieService\.(set|delete)' src/
rg -n '(setCookie|clearCookie|removeCookie)' src/
rg -n 'setDataDogSessionId' src/
rg -n 'storeAuthStateInCookie' src/
```

(Use `rg` if installed, or fall back to `grep -R`.)

## Cross-references

- [`edge-strict-aadsts50058-storm.md`](edge-strict-aadsts50058-storm.md) — the actual root cause and mitigations for the storm. **This is the doc to read if you are investigating AADSTS50058 errors in Edge Strict.**
- [`startup-auth-bootstrap-analysis.md`](startup-auth-bootstrap-analysis.md) — canonical startup analysis. The 2026-06-16 readiness fix and the storm summary are in the **Most Recent Update (2026-06-16)** and **Known Issue: AADSTS50058 Storm** sections.
- [`auth-relogin-race-condition.md`](auth-relogin-race-condition.md) — covers a different auth failure mode (re-login loop in the `RebarAuthService` constructor). Not the same root cause as the storm.
