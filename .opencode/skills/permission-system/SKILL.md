---
name: permission-system
description: "Implementa, modifica o verifica el sistema de permisos atómicos sectorizados por feature en Go. Se debe usar este skill cada vez que el usuario pida agregar nuevos permisos, modificar reglas de autorización basadas en feature, agregar roles al sistema de permisos, crear/revisar endpoints de permisos, o configurar middleware RequirePermission. Asegura que la caché de Postgres (UNLOGGED + BIGINT bitmask), las tablas de permisos dinámicos (role_permissions, user_permissions), y la invalidación por versión sean respetadas."
---

# Sistema de Permisos

Este skill asiste en la implementación y mantenimiento del sistema de permisos atómicos por feature utilizando PostgreSQL Unlogged Cache + permisos dinámicos en DB.

## Flujo de Trabajo

Cuando se te solicite trabajar con los permisos (agregar nuevas features, modificar roles, implementar verificación de acciones):

1. **Lectura del Documento Base:**
   El agente DEBE seguir estrictamente la arquitectura definida en `.opencode/skills/permission-system/references/permissionArch.md`.
   Usa la herramienta `read` para leer el archivo para entender las reglas del sistema de caché (Unlogged), modelos de base de datos, respuestas DTO, capa de servicios, y middleware.

2. **Convenciones Arquitectónicas:**
   - **Bitmask:** Los permisos internos son `uint64` (BIGINT en DB). NUNCA stores JSONB con arrays de strings en la cache.
   - **Conversión:** `Action.ToStringSlice()` y `ActionsFromSlice()` son los únicos puntos de conversión bitmask ↔ strings.
   - **Database (Cache):** Toda caché persiste mediante `ON CONFLICT DO UPDATE` en tabla `UNLOGGED`.
   - **Database (Permisos):** Los permisos base viven en `role_permissions`. Overrides individuales en `user_permissions`.
   - **Invalidación:** Usar `BumpCacheVersion()` para invalidar toda la cache. No borrar entries manualmente salvo en troubleshooting.
   - **TTL:** 15 minutos con jitter de ±2 min para evitar thundering herd.
   - **Features válidas:** Solo las definidas en `service.ValidFeatures` son aceptadas.
   - **Extensibilidad:** Para agregar una nueva acción, agregar al final del bloque `iota` en `permission_model.go` y actualizar `actionMap` + `reverseActionMap`.

3. **Puntos Clave:**
   - Modelos van en `internal/domain/permission_model.go`
   - Tablas se crean/verifican desde `cmd/db/db.go` (`CreateCachePermissionsTable`)
   - Seed de permisos por defecto en `SeedRolePermissions()`
   - Lógica de resolución en `internal/service/permission_service.go`
   - Handler en `internal/transport/http/permissionHandler.go`
   - Middleware `RequirePermission` en `router.go`
   - Cleanup job se inicia en `main.go` con intervalo de 30 min

4. **Agregar Nueva Feature:**
   - Agregar key a `service.ValidFeatures`
   - Agregar seeds en `SeedRolePermissions()` para cada rol
   - Documentar el cambio en `permissionArch.md`

5. **Agregar Nueva Acción:**
   - Agregar constante al final del bloque `iota` en `permission_model.go`
   - Agregar entry en `actionMap` y `reverseActionMap`
   - Actualizar seeds en `SeedRolePermissions()` si aplica
   - Documentar el cambio en `permissionArch.md` y `troubleshoots.md`

**Nota:** Cualquier cambio que afecte esta arquitectura debe reflejarse en `.opencode/skills/permission-system/references/permissionArch.md` como fuente de verdad.
