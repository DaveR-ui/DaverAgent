# Production Deployment

This project is ready to run in Railway with PostgreSQL, but production should not reuse local defaults.

## Required Variables

- `DATABASE_URL`: provided by Railway PostgreSQL. The app now accepts this automatically.
- `SECRET_KEY`: required in production and must be a long random value.
- `CORS_ALLOW_ORIGIN`: required in production and must be your frontend origin, for example `https://app.example.com`.

## Recommended Variables

- `GIN_MODE=release`
- `SEED_DEFAULT_USER=false`

## Railway Notes

- The application refuses to boot on Railway if `SECRET_KEY` is missing or still uses the repository default.
- The application refuses to boot on Railway if the resolved database URL still points to `localhost`.
- On Railway, `SEED_DEFAULT_USER` is disabled by default unless you explicitly override it.

## Role Model

- `user`: read-only access to protected business resources.
- `manager`: can create and update business resources.
- `admin`: can create, update, delete, and create privileged users.

## Auth Routes

- `POST /api/v1/auth/register`: public registration, always creates a `user`.
- `POST /api/v1/auth/users`: admin-only route to create `user`, `manager`, or `admin` accounts.
- `POST /api/v1/auth/login`: returns access and refresh tokens.
- `GET /api/v1/auth/me`: returns the current authenticated user from the access token.
- `POST /api/v1/auth/refresh`: rotates refresh tokens.

## Protected Route Policy

- `GET` business endpoints: any authenticated role.
- `POST` and `PUT` on business resources: `manager` or `admin`.
- `DELETE` on business resources: `admin` only.

## First Admin in Production

Because public registration only creates `user` accounts, create the first admin using one of these methods:

1. Run once with `SEED_DEFAULT_USER=true`, log in with the seeded credentials, create a real admin through `POST /api/v1/auth/users`, then disable seeding again.
2. Insert the first admin directly in PostgreSQL.

## Security Warnings

- Do not deploy with the default `SECRET_KEY` from `config.yaml`.
- Do not enable `SEED_DEFAULT_USER` permanently in public production.
- On Railway, startup now fails if `CORS_ALLOW_ORIGIN` is missing or still equals `*`.
- Authorization is role-based at route level. If you later need tenant isolation or per-customer visibility rules, implement that separately.
