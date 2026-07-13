# davercode-session-bridge

Plugin V1 de DaverCode que conecta el ciclo de vida de las sesiones de agente con los eventos nativos del runtime de opencode.

> **Contexto**: este plugin es parte de un **fork** de [`sst/opencode`](https://github.com/sst/opencode). La carpeta `.opencode/` no viene de opencode upstream — es un sistema de agentes especializado que se está desarrollando sobre opencode, perfeccionándose a partir del código fuente y las APIs internas del runtime. Ver [`docs/project.md`](../../../docs/project.md) para el contexto completo del proyecto y [`BOOTSTRAP.md`](./BOOTSTRAP.md) para la guía de instalación + troubleshooting.

## Qué hace

Escucha eventos de sesión emitidos por el runtime y los traduce a entradas de log estructuradas usando `client.app.log()`. También expone una herramienta llamada `session_status` para consultar las sesiones recientes de forma compacta.

## Eventos suscritos

El hook `event` filtra y registra cuatro tipos de eventos:

- `session.created` — se emite cuando se crea una sesión; incluye el `id` y el `title` de la sesión en los metadatos.
- `session.idle` — indica que una sesión quedó inactiva; registra el `sessionID`.
- `session.error` — captura errores de sesión; se envía con nivel `error` y el tipo de error en los metadatos.
- `session.compacted` — notifica que una sesión fue compactada; registra el `sessionID`.

## Herramienta expuesta

`session_status` recibe un argumento opcional `limit` y devuelve un resumen de líneas con el formato `id | title | created_at`, usando `client.session.list()`.

## Ganancia de la Fase A + C

Este plugin demuestra la migración hacia la observabilidad nativa: reemplaza `console.log` por el log estructurado del servidor (`client.app.log`), y escribe snapshots de sesión en el filesystem cuando la sesión termina (idle o error), probando que un plugin puede observar el ciclo de vida de las sesiones y persistir estado ejecutivo sin intervención manual.

## Runtime snapshots

Cuando una sesión pasa a estado `idle` o `error`, el plugin escribe un **snapshot** en el filesystem local con dos formatos:

- **`.md`** — formato legible con la misma estructura que un `agent-snapshot` (Status, Decisions, Files changed, Subagent outcomes, Commands run, Open questions, Resume instructions). Los campos que el event stream no provee se marcan como "Not available from runtime event stream".
- **`.json`** — formato estructurado validado contra un schema Zod local. Incluye `schemaVersion`, `generatedBy`, `generatedAt`, `sessionID`, `eventType`, `projectSlug`, `humanID`, `status` y `extra` (payload crudo del evento).

### Ubicación

Los snapshots se escriben en:

```
~/.config/opencode/sessions/{human_id}/{project_slug}/{DDMMYYYY-runtime}/{uuid}.md
~/.config/opencode/sessions/{human_id}/{project_slug}/{DDMMYYYY-runtime}/{uuid}.json
```

Donde:
- `human_id` se resuelve desde `OPENCODE_HUMAN_ID`, `USERNAME`, `USER` o `"unknown"`.
- `project_slug` es el nombre del directorio del proyecto (`basename` de `ctx.directory`).
- `DDMMYYYY` es la fecha actual en formato día-mes-año.
- `uuid` es un UUID v4 generado con `crypto.randomUUID()`.

### Schema version

El schema JSON tiene `schemaVersion: "1.0"`. Cualquier cambio breaking incrementará la versión mayor.

### Comportamiento ante errores de schema

Si el payload del evento no valida contra el schema Zod, el archivo `.json` **no se escribe**. El plugin loguea un error estructurado vía `client.app.log()` con los detalles de la falla de validación. El archivo `.md` tampoco se escribe en este caso. Esto garantiza que nunca se persiste un snapshot malformado.

### Comportamiento ante errores de I/O

Si la escritura en disco falla (permisos, disco lleno, etc.), el plugin loguea un error estructurado y continúa sin interrumpir el flujo de la sesión.

## Restricciones importantes

- Escribe snapshots en `~/.config/opencode/sessions/` solo cuando `session.idle` o `session.error` se disparan.
- No escribe durante `session.created` ni `session.compacted` (solo logging).
- La herramienta `session_status` es de solo lectura sobre `client.session.list()`.

## Implementación

El plugin recibe el `PluginInput` del runtime, que incluye un cliente SDK ya conectado (`ctx.client`). Las entradas de log viajan por HTTP al endpoint `/log` del servidor opencode. Los snapshots de sesión se escriben en `~/.config/opencode/sessions/` usando `node:fs/promises` cuando la sesión pasa a `idle` o `error`.

La herramienta `session_status` consulta `GET /session`, toma los primeros `limit` resultados y los formatea como líneas de texto legibles para el modelo.

## Por qué es útil

Antes de esta fase, los plugins o agentes auxiliares solían imprimir diagnósticos con `console.log`, perdiendo contexto y dificultando los filtros. Al usar `client.app.log()`:

- los logs llevan `service`, `level` y metadatos estructurados;
- el servidor puede enrutarlos, persistirlos o mostrarlos en el TUI;
- el plugin demuestra que el runtime expone el ciclo de vida de sesión de forma nativa.

## Desarrollo

El archivo `src/index.ts` es el punto de entrada. El código se organiza en:

- `src/schema.ts` — schema Zod de los snapshots.
- `src/snapshot.ts` — lógica de escritura de snapshots en disco.
- `src/logger.ts` — helper de log estructurado sobre `client.app.log()`.
- `src/index.ts` — wiring del plugin (event hook + tool).

No necesita un paso de build: opencode lo importa directamente como módulo ECMAScript. El `tsconfig.json` está incluido solo para validación local con `bun typecheck` o el editor.

## Cómo cargarlo

> **Importante: este plugin NO se autodetecta.** El glob de auto-descubrimiento de opencode (`ConfigPlugin.load` en `packages/opencode/src/config/plugin.ts`) matchea solo archivos planos con extensión `.ts` o `.js` en `.opencode/plugin(s)/`. Como este plugin vive en un subdirectorio (`.opencode/plugins/davercode-session-bridge/src/index.ts`), el auto-discovery lo ignora. Hay que registrarlo **explícitamente** en `opencode.json`:

```jsonc
{
  "plugin": ["./.opencode/plugins/davercode-session-bridge"]
}
```

Pasos:

1. **Instalar las dependencias del plugin** (necesario una vez por clon del repo):
   ```bash
   cd .opencode/plugins/davercode-session-bridge
   bun install
   ```

2. **Registrar el plugin en `opencode.json`** (en la raíz del monorepo), si no está ya:
   ```jsonc
   {
     "plugin": ["./.opencode/plugins/davercode-session-bridge"]
   }
   ```

3. **Reiniciar el proceso de opencode** (TUI / `bun dev` / `bun run src/index.ts run ...`). El runtime de opencode carga la configuración una vez por proceso; los cambios en `opencode.json` no se aplican hasta el próximo arranque.

4. **Verificar la instalación** con el script postinstall (corre automáticamente después de `bun install`) o manualmente:
   ```bash
   bun run check
   ```

El script `scripts/check-install.ts` valida que:
- el plugin esté registrado en `opencode.json`,
- las dependencias (`@opencode-ai/plugin`) estén instaladas,
- el plugin sea resoluble como módulo.

Si todo está OK, imprime `davercode-session-bridge: install OK`. Si falta algo, imprime un warning accionable y exit code 1.
