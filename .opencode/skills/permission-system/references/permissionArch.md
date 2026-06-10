# Arquitectura del Sistema de Permisos

Este documento describe la arquitectura y estructura de datos para el sistema de permisos atómicos sectorizados por feature en el backend (Go) y la base de datos (PostgreSQL).

## 1. Estructura de Datos (Go)

Los permisos se representan como **bitmask** (`uint64`) para máxima eficiencia. Las conversiones a/from strings solo ocurren en los límites del sistema (JSON API).

```go
// internal/domain/permission_model.go

type Action uint64

const (
	ActionCreate Action = 1 << iota // 1
	ActionRead                      // 2
	ActionUpdate                    // 4
	ActionDelete                    // 8
	ActionPay                       // 16
)

// Métodos de conversión
func (a Action) ToStringSlice() []string    // bitmask → ["create", "read"]
func ActionsFromSlice([]string) Action       // ["create", "read"] → bitmask
func (a Action) Has(required Action) bool    // chequeo O(1)
```

### Modelo de CachePermission (tabla UNLOGGED)

```go
type CachePermission struct {
	UserID      string    `gorm:"primaryKey;size:100"`
	Feature     string    `gorm:"primaryKey;size:50"`
	Permissions uint64    `gorm:"column:permissions"`  // BIGINT, NO JSONB
	ExpiresAt   time.Time `gorm:"index"`
}
```

### Modelos de Permisos Dinámicos (DB)

```go
type RolePermission struct {
	Role    string `gorm:"primaryKey;size:50"`
	Feature string `gorm:"primaryKey;size:50"`
	Actions uint64 `gorm:"column:actions"`  // BIGINT
}

type UserPermission struct {
	UserID  string `gorm:"primaryKey;size:100"`
	Feature string `gorm:"primaryKey;size:50"`
	Actions uint64 `gorm:"column:actions"`  // BIGINT (override por usuario)
}
```

## 2. Base de Datos

### Tablas

| Tabla | Tipo | Propósito |
|-------|------|-----------|
| `cache_permissions` | UNLOGGED | Cache efímera con TTL. No se replica ni escribe WAL. |
| `role_permissions` | Normal | Mapeo role → feature → bitmask de acciones. |
| `user_permissions` | Normal | Overrides individuales por usuario (prioridad sobre role). |
| `permission_version` | Normal | Contador global para invalidación de cache. |

### DDL

```sql
-- Cache (UNLOGGED = sin WAL, extremadamente rápido)
CREATE UNLOGGED TABLE IF NOT EXISTS cache_permissions (
    user_id VARCHAR(100),
    feature VARCHAR(50),
    permissions BIGINT,
    expires_at TIMESTAMP WITH TIME ZONE,
    PRIMARY KEY (user_id, feature)
);
CREATE INDEX IF NOT EXISTS idx_cache_perms_expires ON cache_permissions(expires_at);

-- Permisos por rol (fuente de verdad)
CREATE TABLE IF NOT EXISTS role_permissions (
    role VARCHAR(50) NOT NULL,
    feature VARCHAR(50) NOT NULL,
    actions BIGINT NOT NULL,
    PRIMARY KEY (role, feature)
);

-- Overrides por usuario
CREATE TABLE IF NOT EXISTS user_permissions (
    user_id VARCHAR(100) NOT NULL,
    feature VARCHAR(50) NOT NULL,
    actions BIGINT NOT NULL,
    PRIMARY KEY (user_id, feature)
);

-- Versión de cache para invalidación
CREATE TABLE IF NOT EXISTS permission_version (
    id SERIAL PRIMARY KEY,
    version BIGINT NOT NULL DEFAULT 1
);
```

### Seed Inicial

Los permisos por defecto se seedean automáticamente en `cmd/db/db.go`:

| Rol | Feature | Actions (bitmask) | Acciones |
|-----|---------|-------------------|----------|
| admin | todas | 31 | create+read+update+delete+pay |
| manager | invoices | 23 | create+read+update+pay |
| manager | clients, fire-extinguishers, powders | 7 | create+read+update |
| manager | credentials | 2 | read |
| user | todas | 2 | read |

## 3. Repositorio GORM

El repositorio implementa:

- **`SetCache`**: Upsert con `ON CONFLICT DO UPDATE` (atómico)
- **`GetCache`**: Lee cache vigente (filtra por `expires_at > NOW()`)
- **`DeleteExpiredCache`**: Limpieza de entries expirados
- **`GetRolePermission`**: Lee `role_permissions`
- **`GetUserPermission`**: Lee `user_permissions` (override)
- **`BumpCacheVersion`**: Incrementa versión global → invalida toda cache
- **`GetCacheVersion`**: Lee versión actual

## 4. Servicio de Permisos

`PermissionService` implementa la lógica de resolución:

1. Intentar obtener de cache (`repo.GetCache`)
2. **Cache Miss**: Resolver permisos desde DB:
   - Primero checkea `user_permissions` (override individual)
   - Luego `role_permissions` (base por rol)
   - Fallback seguro a lógica hardcodeada si las tablas están vacías
3. Guardar resultado en cache con **TTL + jitter** (15 min ± 2 min)
4. Devolver respuesta como `[]string` (solo acciones permitidas)

### Métodos públicos

```go
GetPermissionsByFeature(ctx, userID, role, feature) (*FeaturePermissionsResponse, error)
InvalidateCache(ctx) error
InvalidateUserCache(ctx, userID string) error
StartCleanupJob(ctx, interval time.Duration)
```

### Cleanup Job

Se inicia en `main.go` con intervalo de 30 minutos. Borra entries expirados en background sin bloquear requests.

## 5. Endpoints

| Método | Ruta | Auth | Rol | Descripción |
|--------|------|------|-----|-------------|
| GET | `/api/v1/permissions?features=invoices,clients` | Bearer | Cualquiera | Obtiene permisos por feature |
| POST | `/api/v1/permissions/invalidate` | Bearer | Admin | Invalida toda la cache de permisos |

### Request/Response

```
GET /api/v1/permissions?features=invoices,clients
```

```json
{
  "invoices": ["create", "read", "update", "pay"],
  "clients": ["read"]
}
```

## 6. Middleware de Permisos

### `RequireRoles` (existente)
Chequea rol del usuario.

### `RequirePermission` (nuevo)
Chequea permiso atómico por feature + acción:

```go
// En router.go
clientRoutes.POST("",
    RequirePermission("clients", domain.ActionCreate, permissionService),
    handler.CreateClient,
)
```

Usa la cache interna, no impacta performance.

## 7. Features Válidas

Validación estricta en `service.ValidFeatures`:

```go
var ValidFeatures = map[string]struct{}{
    "invoices":         {},
    "clients":          {},
    "fire-extinguishers": {},
    "powders":          {},
    "credentials":      {},
}
```

Request con feature inválida retorna `400 Bad Request`.

---

**Nota:** Toda modificación futura sobre la estructura de permisos, roles, o acciones debe quedar documentada aquí.
