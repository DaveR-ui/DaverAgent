---
last_updated: 2026-05-09
description: Docker multi-stage build, nginx configuration, and Railway deployment guide for the Angular SPA.
tags: [deployment, docker]
status: active
---

# Docker Deployment - SPA Matafuegos

Documentation for containerization and Railway deployment for the Angular SPA Matafuegos application.

---

## Why Docker + Nginx (and not Node)

Angular static files (HTML, CSS, JS) **do not need Node.js** to run. Node is only used during `ng build`. Once compiled, they are files that any web server can serve.

Using a `node:22` image to serve statics results in images of **~1.2GB+**. With `nginx:alpine`, the final image weighs **~10-15MB**. The difference is 100x.

Nginx also provides:
- **Native gzip** (reduces transfer size ~70%)
- **Static asset caching** with long expiration headers
- **SPA routing** with `try_files` (without this, refresh on client-side routes returns 404)

---

## Architecture: Multi-Stage Build

```
┌─────────────────────────┐      ┌─────────────────────────┐
│   STAGE 1: Builder      │      │   STAGE 2: Runtime       │
│   node:22-alpine        │      │   nginx:alpine (~7MB)    │
│                          │      │                          │
│   1. Copy package.json  │      │   1. Copy nginx.conf     │
│   2. npm ci (deps)      │──────▶   2. Copy dist/browser   │
│   3. Copy src code      │      │   3. Expose port 80      │
│   4. npm run build      │      │   4. nginx daemon off    │
│                          │      │                          │
│   ~800MB (discarded)    │      │   ~10-15MB (final image) │
└─────────────────────────┘      └─────────────────────────┘
```

Only the result of `dist/spa-matafuegos/browser` passes to the final image. Everything else (node_modules, Angular cache, source maps, TypeScript) stays in the builder stage and is discarded.

---

## Container Files

### Dockerfile

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json bun.lockb ./
RUN npm install --frozen-lockfile || npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/dist/spa-matafuegos/browser /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**Line-by-line breakdown:**

| Line | Reason |
|---|---|
| `FROM node:22-alpine AS builder` | Alpine = 5MB base vs 910MB of `node:22` (Debian). Removes Python, gcc, vim, systemd, etc. that are not needed for building. |
| `COPY package.json bun.lockb ./` | Copied **before** source code to leverage Docker layer caching. If only code changes and not dependencies, `npm install` is cached and not re-executed. |
| `RUN npm install --frozen-lockfile \|\| npm ci` | Installs exact dependencies from lockfile. `--frozen-lockfile` is from Bun/NPM, `npm ci` is the standard fallback. |
| `COPY . .` | Source code is copied now (after installing deps, to not invalidate the cache). |
| `RUN npm run build` | Executes `ng build` (production by default per angular.json). Generates `dist/spa-matafuegos/browser/`. |
| `FROM nginx:alpine` | Clean second stage. Only contains nginx + musl libc. ~7MB. |
| `COPY nginx.conf ...` | Custom nginx configuration for SPA routing and gzip. |
| `COPY --from=builder /app/dist/.../browser` | Only the build output is copied. No node_modules, .angular/cache, or .ts files. |
| `EXPOSE 80` | Documents the port. Railway uses it automatically. |
| `CMD ["nginx", "-g", "daemon off;"]` | Runs nginx in foreground (required for Docker, otherwise the container stops). |

### nginx.conf

```nginx
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;
    gzip_min_length 256;
}
```

**Breakdown:**

| Directive | Reason |
|---|---|
| `try_files $uri $uri/ /index.html` | **Critical for SPAs.** Without this, navigating to `/clientes` returns 404 because nginx looks for the file `/clientes` which doesn't exist. With `try_files`, any route that doesn't exist returns `index.html`, and Angular Router handles the rest. |
| `expires 1y` + `immutable` | Angular generates files with hashes (e.g., `main-ABC123.js`). If the name changed, it's a new file. If it didn't change, it's identical. Can be cached aggressively without issues. |
| `gzip on` + types | Reduces transfer ~70%. Angular JS files are quite heavy uncompressed. `gzip_min_length 256` avoids compressing very small files where the gzip header overhead is greater than the compression. |

### .dockerignore

```
node_modules
dist
.git
.angular
.storybook
.vscode
.idea
coverage
test-results
playwright-report
blob-report
storybook-static
e2e
*.log
.env
.DS_Store
Thumbs.db
```

**Why it's critical:** Without `.dockerignore`, `COPY . .` copies **everything** in the working directory to the container, including:
- `node_modules/` (~340MB, already installed via `npm ci`)
- `.git/` (~187MB, irrelevant in production)
- `dist/` (~5MB, regenerated during build)
- `.angular/cache` (~50MB, CLI cache)
- System files (.DS_Store, Thumbs.db)

This can add **800MB+ of junk** to the image.

---

## Optimization Guide (Future Reference)

The following techniques applied to this project and/or may be useful if further optimization is needed:

### 1. .dockerignore → Savings: ~800MB

Always create `.dockerignore` before the Dockerfile. It's the optimization with the highest ROI (5 minutes, hundreds of MB saved).

The heaviest files that are filtered:
- `node_modules/` (reinstalled inside the container, copying it is wasteful)
- `.git/` (version history, not needed in production)
- `dist/` (regenerated with `npm run build`)
- `.angular/cache` (CLI cache, not needed)
- `coverage/`, `test-results/`, `playwright-report/` (testing artifacts)

### 2. Alpine Base Image → Savings: ~600MB

```
node:22        → 910MB (Full Debian: curl, wget, vim, Python, gcc, systemd...)
node:22-alpine → 174MB (Alpine Linux: musl libc, BusyBox, the minimum)
```

Alpine uses `apk` instead of `apt`, `musl` instead of `glibc`, and BusyBox instead of GNU coreutils. For standard Node.js apps (without native C++ dependencies), it works without issues.

**Caveat:** If using native modules (node-gyp, bcrypt, sharp), Alpine may require `RUN apk add --no-cache python3 make g++`.

### 3. Multi-Stage Build → Savings: ~340MB

Without multi-stage, the final image includes:
- Full `node_modules/` (~340MB with devDependencies)
- npm cache (`~/.npm`)
- Temporary build files

With multi-stage, only what is strictly necessary is copied to the final stage. For our case (Angular SPA), that's just the `dist/spa-matafuegos/browser/` folder.

### 4. Layer Order (Docker Cache) → Savings: Build Time

Docker caches layers. If a layer doesn't change, it's reused without recalculating.

```dockerfile
# ❌ BAD: any change in src forces dependency reinstallation
COPY . .
RUN npm ci

# ✅ GOOD: only changes in package.json invalidate the dependency cache
COPY package.json bun.lockb ./
RUN npm ci
COPY . .
```

Order matters: what changes less frequently goes first. Dependencies change much less than source code.

**Impact:** Build time from ~4 minutes to ~20 seconds when only code changes.

### 5. Production Dependencies Only → Savings: ~120MB

```
npm install       → installs EVERYTHING (dev + prod)
npm ci --only=production → installs only prod
```

In our case we don't apply this directly because **the builder doesn't go to production** — the final stage is nginx, not node. But if deploying a Node.js server, this difference is ~120MB of eslint, jest, vitest, playwright, etc.

### 6. Distroless → Final image ~24MB

Google offers `gcr.io/distroless/nodejs22` images that contain **only Node.js and the app**, no shell, no package manager, nothing else.

For our SPA **it doesn't apply** (we use nginx, not node), but if you had an Express/NestJS server in production:

```dockerfile
FROM node:22-alpine AS builder
WORKDIR /app
COPY package.json bun.lockb ./
RUN npm ci --only=production
COPY . .

FROM gcr.io/distroless/nodejs22-debian12
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
CMD ["dist/main.js"]
```

**Limitation:** No shell. Cannot do `docker exec -it container sh`. For debugging use `kubectl debug` or logs.

### When NOT to optimize?

- If the image is built once and runs forever (savings are insignificant)
- If active debugging inside the container is needed (distroless prevents it)
- If native modules don't compile on Alpine (use `node:22-slim` as an intermediate alternative)

---

## Railway Deployment

### Steps

1. **Connect repo**: In Railway, create new project → connect GitHub repo
2. **Auto-detection**: Railway detects the Dockerfile automatically
3. **Environment variables**: If `environment.production.ts` needs API URLs, configure in Railway → Variables
4. **Port**: Railway automatically maps port 80 of the container to the public URL

### Local build for testing

```bash
# Build image
docker build -t spa-matafuegos .

# Run locally
docker run -p 8080:80 spa-matafuegos

# Open in browser
# http://localhost:8080
```

### Verify image size

```bash
docker images spa-matafuegos
# Expected: ~10-15MB (nginx:alpine + static files)
```

### Inspect layers

```bash
docker history spa-matafuegos
# Shows the size of each layer
```

---

## Quick Optimization Checklist

| # | Technique | Estimated Time | Typical Savings | Applied in this project |
|---|---|---|---|---|
| 1 | `.dockerignore` | 5 min | ~800MB | Yes |
| 2 | Alpine base image | 2 min | ~600MB | Yes (builder) |
| 3 | Multi-stage build | 10 min | ~340MB | Yes |
| 4 | Layer order (cache) | 3 min | Build time | Yes |
| 5 | Prod dependencies only | 2 min | ~120MB | N/A (nginx runtime) |
| 6 | Distroless | 20 min | Up to ~500MB more | No (nginx runtime) |

**Final result: ~10-15MB image vs ~2GB+ without optimization.**
