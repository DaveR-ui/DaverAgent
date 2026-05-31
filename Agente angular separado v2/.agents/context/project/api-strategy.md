---
last_updated: 2026-05-09
description: Dual-environment API connection strategy using dev server proxy and production same-origin routing.
tags: [api, proxy, cors, environments]
status: active
---

# API Connection Strategy

## Overview

The frontend connects to the backend API using a **dual-environment strategy** that eliminates CORS issues in development while keeping production clean and relative.

The key principle: **the browser never sees cross-origin requests**. In development, the Angular dev server acts as a transparent proxy. In production, the frontend and backend share the same origin domain.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     DEVELOPMENT (ng serve)                   │
│                                                              │
│  Browser (localhost:4200)                                    │
│       │                                                      │
│       │  GET /api/v1/clients  ← same origin, NO CORS         │
│       ▼                                                      │
│  Angular Dev Server                                          │
│       │                                                      │
│       │  proxy.conf.json → rewrites + forwards               │
│       ▼                                                      │
│  https://back-matafuegos-necochea-production.up.railway.app  │
│       │                                                      │
│       ▼                                                      │
│  Backend API                                                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                     PRODUCTION (Railway)                     │
│                                                              │
│  Browser (spa-matafuegos-necochea-production.up.railway.app) │
│       │                                                      │
│       │  GET /api/v1/clients  ← same origin, NO CORS         │
│       ▼                                                      │
│  Railway edge → serves SPA + proxies /api to backend         │
│       │                                                      │
│       ▼                                                      │
│  Backend API                                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## Configuration Files

### 1. `proxy.conf.json` (root)

Development-only proxy configuration. The Angular dev server reads this file on startup and forwards matching requests to the real backend.

```json
{
  "/api": {
    "target": "https://back-matafuegos-necochea-production.up.railway.app",
    "secure": true,
    "changeOrigin": true,
    "logLevel": "debug",
    "headers": {
      "Host": "back-matafuegos-necochea-production.up.railway.app",
      "Origin": "https://spa-matafuegos-necochea-production.up.railway.app"
    }
  }
}
```

**Key fields:**

| Field | Purpose |
|---|---|
| `"/api"` | Route prefix to intercept. Any request starting with `/api` is proxied. |
| `target` | Real backend URL. |
| `secure` | `true` = validate TLS certificates. Set to `false` only for local backends with self-signed certs. |
| `changeOrigin` | `true` = rewrites the `Host` header to match the target. |
| `logLevel` | `"debug"` = logs every proxied request in the terminal. Useful for troubleshooting. |
| `headers.Host` | Overrides the Host header so the backend sees its own domain, not `localhost`. |
| `headers.Origin` | Spoofs the production origin so the backend's CORS policy accepts the request. |

**Why `Host` and `Origin` headers are critical:**

Railway's edge proxy validates incoming requests. Without these headers, the backend sees `Host: localhost:4200` and `Origin: http://localhost:4200`, which triggers a **403 Forbidden** because those origins are not in the allowed CORS list. By injecting the production values, the proxy makes the request indistinguishable from a real production request.

### 2. `angular.json` — serve configuration

The proxy is wired into the `development` serve configuration:

```json
"serve": {
  "builder": "@angular/build:dev-server",
  "configurations": {
    "production": {
      "buildTarget": "spa-matafuegos:build:production"
    },
    "development": {
      "buildTarget": "spa-matafuegos:build:development",
      "proxyConfig": "proxy.conf.json"
    }
  },
  "defaultConfiguration": "development"
}
```

**Important:** `proxyConfig` must be inside the `development` configuration, NOT in the top-level `options`. The `@angular/build` dev-server does not inherit proxy settings from `options` reliably.

### 3. Environment files

**`src/environments/environment.ts`** (development):

```ts
export const environment = {
  production: false,
  apiUrl: '',
}
```

**`src/environments/environment.production.ts`** (production):

```ts
export const environment = {
  production: true,
  apiUrl: '',
}
```

Both use an **empty string** for `apiUrl`. This makes all API calls relative:

- Dev: `'' + '/api/v1/auth/login'` → `/api/v1/auth/login` → caught by proxy
- Prod: `'' + '/api/v1/auth/login'` → `/api/v1/auth/login` → served by same-origin Railway

---

## How Services Use It

All services build URLs with the pattern:

```
`${environment.apiUrl}/api/v1/{resource}`
```

Examples from the codebase:

| Service | URL Pattern |
|---|---|
| `AuthService` | `${environment.apiUrl}/api/v1/auth/login` |
| `ClientService` | `${environment.apiUrl}/api/v1/clients` |
| `InvoiceService` | `${environment.apiUrl}/api/v1/invoices` |
| `TaxConditionSelector` | `${environment.apiUrl}/api/v1/clients/tax-conditions` |

Since `apiUrl` is empty, all requests resolve to `/api/v1/...` — which the proxy intercepts in development.

---

## HTTP Interceptors

Two interceptors sit between services and the HTTP transport layer:

| Interceptor | File | Purpose |
|---|---|---|
| `authInterceptor` | `src/shared/data/auth-interceptor.ts` | Attaches `Authorization: Bearer {token}` to outgoing requests |
| `errorInterceptor` | `src/shared/data/error-interceptor.ts` | Centralized error handling — maps HTTP status codes to user notifications |

Neither interceptor modifies the URL. They operate purely on headers and error streams.

---

## Troubleshooting

### 403 Forbidden on login

**Symptom:** Request hits Railway but returns 403.

**Cause:** Missing or incorrect `Host`/`Origin` headers in `proxy.conf.json`. The backend rejects requests that don't appear to come from an allowed origin.

**Fix:** Verify `proxy.conf.json` has both headers set to production values. Restart `ng serve` (proxy only loads on startup).

### CORS error in browser

**Symptom:** Browser shows `Access-Control-Allow-Origin` mismatch.

**Cause:** The proxy is not intercepting the request. Check that:
1. `apiUrl` is empty in the active environment file
2. The request URL starts with `/api`
3. `ng serve` was restarted after proxy changes

**Verify:** In DevTools → Network tab, the request should show:
- `Host: localhost:4200` (browser side)
- `server: railway-edge` (response from backend, proving proxy worked)

### Proxy not loading

**Symptom:** No proxy log in terminal, requests go directly.

**Cause:** `proxyConfig` placed in `options` instead of `configurations.development`.

**Fix:** Move `proxyConfig` inside `"development"` in `angular.json`.

### "Cannot connect to target" error

**Symptom:** Dev server crashes with `ECONNREFUSED` or similar.

**Cause:** Backend URL in `proxy.conf.json` is unreachable.

**Fix:** Verify the target URL is accessible from your network. Check Railway dashboard for service status.

---

## Adding a New API Endpoint

1. Append the endpoint path to the relevant service using `${environment.apiUrl}/api/v1/...`
2. No proxy changes needed — the `"/api"` prefix catches all `/api/v1/*` routes
3. If the backend requires a custom header, add it to `proxy.conf.json` under `headers`

---

## Related Documents

- [API Contracts](api-contracts.md) — endpoint definitions and models
- [Docker Deployment](deployment.md) — production nginx proxy configuration
- [Project Rules](rules.md) — coding standards, including HTTP patterns
