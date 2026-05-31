# Troubleshooting del Sistema de Permisos

Este documento enumera los problemas más comunes relacionados con el sistema de permisos atómicos y su solución.

## 1. El permiso no se actualiza o no refleja el cambio en un rol

**Síntoma:** Un usuario con un rol específico sigue sin tener acceso a una nueva feature o acción.

**Causa probable:** La caché `UNLOGGED` de PostgreSQL aún conserva el estado anterior de los permisos (el TTL de 15 minutos no ha expirado).

**Solución:**
- Invalidar cache manualmente: `POST /api/v1/permissions/invalidate` (requiere rol admin)
- O limpiar directamente en DB: `DELETE FROM cache_permissions WHERE user_id = 'XYZ'`
- O esperar a que expire el TTL
- Validar que en `role_permissions` el nuevo rol/acción esté correctamente configurado

## 2. Picos de CPU o de uso de memoria en PostgreSQL

**Síntoma:** Al lanzar una nueva versión, el uso de memoria o CPU de Postgres se dispara en la tabla de caché.

**Causa probable:** Si el tráfico de validación de permisos es sumamente alto, las peticiones concurrentes están escribiendo en la tabla `UNLOGGED` simultáneamente (`Cache Miss` masivo).

**Solución:**
- El Upsert (`ON CONFLICT DO UPDATE`) está implementado correctamente para evitar duplicados
- El TTL tiene **jitter** (±2 min) para evitar regeneración en bloque (thundering herd)
- El cleanup job corre cada 30 minutos para borrar entries expirados
- Si el problema persiste, considerar aumentar el TTL a 30 min

## 3. El Bitmask está sobrepasando las acciones configuradas

**Síntoma:** Las respuestas del backend indican permisos inconsistentes o un string de permiso desconocido.

**Causa probable:** Modificaste las constantes de `Action` (e.g., `ActionCreate`, `ActionRead`) perdiendo la sincronía con el cálculo bit a bit.

**Solución:**
- Revisar que cada acción en `internal/domain/permission_model.go` use `iota` correctamente
- Verificar que `actionMap` y `reverseActionMap` estén sincronizados con las constantes
- Cada nueva acción debe agregarse al final del bloque `iota` y en ambos maps

## 4. Endpoint de Permisos retorna error 400

**Síntoma:** Al consultar `GET /api/v1/permissions?features=invoices` la API devuelve código `400 Bad Request`.

**Causa probable:** El query param `features` está vacío o contiene una feature no válida.

**Solución:**
- Validar que se envíe como `features=invoice,client,etc`
- Las features válidas están definidas en `service.ValidFeatures`
- Features inválidas retornan `400` con mensaje descriptivo

## 5. `RequirePermission` deniega acceso inesperadamente

**Síntoma:** Una ruta protegida con `RequirePermission("feature", Action)` retorna 403.

**Causa probable:**
- El usuario no tiene ese permiso en `role_permissions` ni en `user_permissions`
- La cache tiene datos stale (ver punto 1)
- El nombre de la feature no coincide exactamente (case-sensitive)

**Solución:**
- Verificar permisos en DB: `SELECT * FROM role_permissions WHERE role = 'X' AND feature = 'Y'`
- Invalidar cache y reintentar
- Verificar que el feature string en el middleware coincida con las keys de `ValidFeatures`

## 6. La tabla `cache_permissions` crece indefinidamente

**Síntoma:** La tabla UNLOGGED ocupa más espacio del esperado.

**Causa probable:** El cleanup job no está corriendo o el intervalo es demasiado largo.

**Solución:**
- Verificar que `permissionService.StartCleanupJob()` se llame en `main.go`
- El intervalo por defecto es 30 minutos
- Ejecutar manualmente: `DELETE FROM cache_permissions WHERE expires_at < NOW()`

## 7. Error al seedear `role_permissions`

**Síntoma:** Los permisos por defecto no se cargan al iniciar la app.

**Causa probable:** La tabla `role_permissions` ya tiene datos y el seed skippea entries existentes (comportamiento intencional).

**Solución:**
- Para forzar re-seed: `DELETE FROM role_permissions` y reiniciar la app
- O insertar manualmente: `INSERT INTO role_permissions (role, feature, actions) VALUES ('admin', 'invoices', 31)`

## 8. Bitmask values reference

| Valor | Acciones | Binary |
|-------|----------|--------|
| 1 | create | 00001 |
| 2 | read | 00010 |
| 3 | create + read | 00011 |
| 4 | update | 00100 |
| 7 | create + read + update | 00111 |
| 8 | delete | 01000 |
| 15 | create + read + update + delete | 01111 |
| 16 | pay | 10000 |
| 31 | all (create+read+update+delete+pay) | 11111 |
