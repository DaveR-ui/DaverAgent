# Development Rules and Standards

Non-negotiable rules to maintain high quality and security in the backend.

## Documentation Language
- **Rule**: All documentation, code comments, and project-related files MUST be written in **ENGLISH**.

## Code Standards

### Formatting & Linting
- **Formatter**: `gofmt` (or `goimports`) — all files must be formatted before commit
- **Linter**: `go vet ./...` — must pass clean
- **Naming**:
  - Exported types/functions: `CamelCase` (e.g., `ClientService`, `NewPowderHandler`)
  - Unexported: `camelCase` (e.g., `isAllowedOrigin`)
  - Constants: `CamelCase` for exported (e.g., `ErrNotFoundItem`)
  - Files: `snake_case.go` (e.g., `client_model.go`, `powder_service.go`)
  - Handlers: `xxxHandler.go` (existing convention, mixed case)
  - Repositories: `gorm_xxx.go` (e.g., `gorm_powder.go`)

### Code Organization
- **One entity per file** in domain (e.g., `client_model.go`, `powder_model.go`)
- **One repository per entity** in repository (e.g., `gorm_cliente.go`)
- **One service per entity** in service (e.g., `client_service.go`)
- **One handler per entity** in transport (e.g., `clientHandler.go`)
- **All interfaces** in `internal/domain/interfaces.go`
- **All error constants** in `internal/domain/0_models.go` (or model file)
- **All routes** in `internal/transport/http/router.go`
- **DI wiring** in `cmd/server/main.go`

## Error Handling
- **Domain errors** are string variables: `var ErrNotFoundItem = "Item not found"`
- **Repositories** map GORM errors: `errors.Is(err, gorm.ErrRecordNotFound)` → `errors.New(domain.ErrNotFoundItem)`
- **Services** return domain errors: `errors.New(domain.ErrInvalidInput)`
- **Handlers** map to HTTP status codes:
  - `domain.ErrNotFoundItem` → `404 Not Found`
  - `domain.ErrAlreadyExists` → `409 Conflict`
  - `domain.ErrInvalidInput` → `400 Bad Request`
  - Binding errors → `400 Bad Request`
  - Catch-all → `500 Internal Server Error`
- **Error response format**: Always `gin.H{"error": message}`
- **NEVER panic** — always return errors up the stack

## Security
- **Auth**: JWT with HMAC signing, secret from Viper config (`SECRET_KEY`)
- **Password**: bcrypt hashing via `golang.org/x/crypto/bcrypt`
- **CORS**: Origin validated against Viper allowlist (`CORS.ALLOW_ORIGIN`)
- **SQL Injection**: Use GORM parameterized queries only — NO raw string concatenation
- **Context propagation**: `context.Context` as first arg from handler → service → repository
- **Role-based access**: `RequireRoles()` middleware on write/delete operations
- **Secrets**: Never hardcode — use Viper config + GCP Secret Manager in production
- **Non-privileged user**: Docker container runs as `appuser`, not `root`

## Context Propagation
- **Every function** from Transport down to Repository MUST accept and pass `context.Context`
- **GORM queries** MUST use `r.db.WithContext(ctx)` — never bare `r.db`
- **Handler**: `c.Request.Context()`
- **Service**: receives `ctx`, passes to repo
- **Repository**: receives `ctx`, passes to GORM

## Testing
- **Framework**: Go standard `testing` package
- **Pattern**: Table-driven tests
- **File naming**: `xxx_test.go` next to source file
- **Mocks**: Mock domain interfaces, NOT concrete implementations
- **Coverage**: Run with `go test -cover ./...`
- **No running DB required**: Unit tests must work without a database

## Database and Migrations
- **Non-Production Status**: The application is currently in development and NOT in production.
- **Rule**: Backward compatibility between database schema changes is NOT required at this stage. Tables can be dropped and recreated from scratch to maintain a clean schema.
- **Migration**: `AutoMigrate` using `domain.TablesToMigrate` slice in `cmd/server/main.go`
- **New tables**: MUST be added to `TablesToMigrate` in `internal/domain/0_models.go`
- **Soft deletes**: All entities use `gorm.DeletedAt`
- **Audit fields**: All entities have `CreatedAt`, `UpdatedAt`, `DeletedAt`

## Seeding and Testing Data
- **Rule**: All new domain entities MUST have a corresponding seed logic and JSON data file(s) organized in `internal/domain/jsons/` (and subfolders if applicable) for future testing and environment setup.

## Pagination
- **Query params**: `page` (default 1), `page_size` (default 10, max 100)
- **Service clamping**: `page < 1 → 1`, `pageSize < 1 → 10`, `pageSize > 100 → 100`
- **Offset**: `(page - 1) * pageSize`
- **Response**: `XxxListResponse` with `Items`, `Total`, `Page`, `PageSize`, `TotalPages`
- **Order**: Applied before Offset/Limit
