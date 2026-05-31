---
last_updated: 2026-05-08
description: source of truth for logged-in user identity, profile data, and user-related fields available in the frontend
tags: [identity, user-data, msal, claims, user-info, profile, enterpriseid, eid, microsoft-graph]
status: ACTIVE
---

# Identity & User Data

> [!TIP]
> Use this document when a feature needs the logged-in user's name, enterprise ID, UPN, photo, or a payload-compatible requestor object.

## Purpose

- Define the supported ways to supply user data in this frontend.
- Clarify which source is authoritative for each user field.
- Prevent new work from rediscovering identity logic in `src/`.

## Source Of Truth By Use Case

| Need | Preferred source | File(s) | Notes |
| --- | --- | --- | --- |
| Logged-in user claims from authentication | `RebarAuthService.getUserClaims()` | `src/app/core/rebarauth/rebar.auth.service.ts`, `src/app/core/models/user.domain.ts` | Raw identity claims from MSAL/Azure AD |
| Logged-in user name + enterprise ID in app state | `selectUserInfo` | `src/app/state/user-info/user-info.selector.ts`, `src/app/state/user-info/user-info.reducer.ts` | Best source for normal feature work inside the app |
| Initial app bootstrap of user identity | `AppComponent.continueLoading()` | `src/app/app.component.ts` | Dispatches initial user identity into the store |
| User profile from backend | `UserInfoService.getUserInformation()` | `src/app/core/services/user-info.service.ts` | Calls `/api/workflow/user-info`; keep as backend-backed profile source |
| User photo(s) | `UserInfoService.getUsersPhoto()` | `src/app/core/services/user-info.service.ts`, `src/app/state/users-pictures/users-pictures.effects.ts` | Reads Microsoft Graph photo blob and stores base64 picture |
| LaunchDarkly user key | `UserInfo.enterpriseId` | `src/app/shared/services/launchdarkly.service.ts` | Uses the stored enterprise ID as LaunchDarkly context key |

## Supported User Data Sources

### 1. Authentication Claims

**Files**
- `src/app/core/rebarauth/rebar.auth.service.ts`
- `src/app/core/models/user.domain.ts`

**How to access**
- `RebarAuthService.getUserClaims()` returns raw token claims.
- `new UserClaims(rebarAuthService.getUserClaims())` normalizes them into a frontend-friendly shape.

**Available fields from `UserClaims`**
- `fullEnterpriseId`: raw `preferred_username` claim, typically full UPN/email.
- `enterpriseId`: derived alias without domain, computed from `fullEnterpriseId.split('@')[0]`.
- `name`: display name from claims.
- `roles`: raw role list from claims.
- `isASGUser()`: convenience helper based on `roles`.

**Use when**
- Bootstrapping the app.
- Working near authentication boundaries.
- A feature needs raw identity claims rather than app state.

> [!TIP]
> **Authentication Race Conditions**: If the app experiences recurring login redirects during bootstrap, see the [Auth Flow & Race Conditions Annex](troubleshooting/auth-relogin-race-condition.md).

### 2. Global User Info Store

**Files**
- `src/app/app.component.ts`
- `src/app/state/user-info/user-info.actions.ts`
- `src/app/state/user-info/user-info.reducer.ts`
- `src/app/state/user-info/user-info.selector.ts`

**How it is populated**
- `AppComponent.continueLoading()` dispatches `setInitialUserInfo({ eId, name })` using `UserClaims.fullEnterpriseId` and `UserClaims.name`.
- The reducer stores those values in `IUserInfoState.data`.

**Available fields from `UserInfo`**
- `enterpriseId`
- `name`
- `picture`

> [!CAUTION]
> In the current app state, `UserInfo.enterpriseId` is populated with the full enterprise identifier used at bootstrap, not necessarily the stripped alias-only EID. In practice this is often the full UPN/email because `AppComponent` dispatches `UserClaims.fullEnterpriseId`.

**Use when**
- A normal feature needs the logged-in user.
- A component needs the current user's display name or enterprise identifier.
- You need a local mapping from current user data into another frontend model, such as `Employee`.

### 3. Backend User Profile Service

**Files**
- `src/app/core/services/user-info.service.ts`

**Method**
- `getUserInformation()`

**Endpoint**
- `GET /api/workflow/user-info`

**Returned shape**
- `UserInfo`
  - `enterpriseId`
  - `name`
  - `picture`

**Use when**
- The source of truth must come from backend profile data.
- A future feature requires a server-owned profile payload rather than bootstrapped claims.

### 4. Microsoft Graph User Photos

**Files**
- `src/app/core/services/user-info.service.ts`
- `src/app/state/users-pictures/users-pictures.effects.ts`

**Method**
- `getUsersPhoto(usersMails: string[])`

**External endpoint**
- `GET {microsoftGraph}/users/{mail}/photo/$value`

**Returned shape**
- `UserPicture`
  - `enterpriseId`
  - `picture`

**Normalization note**
- `users-pictures.effects.ts` strips the domain from `enterpriseId` before writing it into the pictures map.

## Common Field Meanings

| Field | Meaning | Typical shape | Where found |
| --- | --- | --- | --- |
| `preferred_username` | Raw identity claim from Azure/MSAL | `john.doe@accenture.com` | Claims only |
| `fullEnterpriseId` | Frontend wrapper over `preferred_username` | `john.doe@accenture.com` | `UserClaims` |
| `enterpriseId` | Used inconsistently across the app; may be UPN/email or alias-only depending on source | `john.doe@accenture.com` or `john.doe` | `UserClaims`, `UserInfo`, pictures map, domain models |
| `name` | Display name of logged-in user | `John Doe` | Claims and `UserInfo` |
| `roles` | User roles from token claims | `string[]` | `UserClaims` |
| `picture` | Base64 user photo | `data:image/...` | `UserInfo`, `UserPicture` |
| `userPrincipalName` | Email/UPN used by Microsoft Graph and `Employee` | `john.doe@accenture.com` | `Employee`, Graph lookups |
| `accentureId` | Alias-only identity used by many requestor payloads | `john.doe` | `Employee`, workflow payloads |
| `id` | Generic object identifier for directory/person records | varies | `Employee` |

## Standard Patterns

### Use the logged-in user inside a feature

Preferred pattern:

```ts
import { Store } from '@ngrx/store';
import { selectUserInfo } from '@state/user-info/user-info.selector';

store = inject(Store);
currentUserInfo = this.store.selectSignal(selectUserInfo);
```

Use this when the feature already depends on store state and only needs the current logged-in user.

### Convert logged-in user data into an `Employee`

Use this when a workflow payload still expects `requestor: Employee`.

```ts
const userPrincipalName = userInfo?.enterpriseId?.trim();
const accentureId = userPrincipalName?.split('@')[0]?.trim() ?? '';
const displayName = userInfo?.name?.trim() || accentureId || userPrincipalName || '';

return new Employee({
  id: userPrincipalName,
  displayName,
  accentureId,
  userPrincipalName,
});
```

## Anti-Patterns To Avoid

| Avoid | Why |
| --- | --- |
| Re-searching the codebase for `eid` every time a feature needs current user data | This document is now the SSOT |
| Assuming `enterpriseId` always means alias-only EID | In this repo it may carry the full UPN/email depending on source |
| Introducing a new user-info store slice for a feature | Reuse `selectUserInfo` unless a new backend-owned contract is required |
| Pulling raw claims deep inside feature code when app state already has the needed fields | Prefer `selectUserInfo` for normal feature work |
| Treating photo identity keys and requestor payload identity keys as identical | The pictures flow strips the domain; workflow payloads often need `accentureId` or `Employee` |

## Quick Guidance

- Need logged-in user name in a component: use `selectUserInfo`.
- Need logged-in user alias/EID for a requestor payload: derive `accentureId` from `UserInfo.enterpriseId` or from `UserClaims.enterpriseId`.
- Need raw authentication claims: use `RebarAuthService.getUserClaims()`.
- Need backend profile data: use `UserInfoService.getUserInformation()`.
- Need profile photo(s): use `UserInfoService.getUsersPhoto()` and the users-pictures flow.