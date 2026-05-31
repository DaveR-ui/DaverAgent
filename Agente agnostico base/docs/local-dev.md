# Local Development

This repository is configured to stay convenient for local testing.

## Default Behavior

- `SEED_DEFAULT_USER=true` by default outside Railway.
- `GIN_MODE=debug` by default.
- The app uses `DB_URL` from `config.yaml` unless overridden.

## Default Test User

When seeding is enabled, startup ensures this user exists:

- Email: `admin@admin.com`
- Password: `adminadmin`
- Role: `admin`

This is intended only for local development and manual testing.

## Local Run

```sh
go run cmd/server/main.go
```

## Local Run With Full Reset

```sh
go run cmd/server/main.go -f
```

This drops tables and reruns migrations and seeds.

## Docker Compose

```sh
docker compose up --build
```

The compose setup starts:

- PostgreSQL on `localhost:5432`
- API on `localhost:8080`
- pgAdmin on `localhost:9090`

## Useful Overrides

- `SEED_DEFAULT_USER=false`: disable the default user locally.
- `DB_URL=...`: point the API to another PostgreSQL instance.
- `SECRET_KEY=...`: test JWT signing with a custom key.
- `CORS_ALLOW_ORIGIN=http://localhost:3000`: allow a local frontend origin explicitly.

## Role Testing

- Use `POST /api/v1/auth/register` to create normal `user` accounts.
- Log in as the seeded admin and use `POST /api/v1/auth/users` to create `manager` or additional `admin` users.
- Use `GET /api/v1/auth/me` with `Authorization: Bearer <token>` to inspect the authenticated user and role.
