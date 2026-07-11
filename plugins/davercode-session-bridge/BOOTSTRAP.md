# ⚠️ BOOTSTRAP — davercode-session-bridge

> **Este plugin requiere instalación manual.** No se autodetecta.
> El glob de auto-discovery de opencode (`{plugin,plugins}/*.{ts,js}`) **solo captura archivos planos**, no subdirectorios con `index.ts`. Como este plugin vive en un subdirectorio, tenés que registrarlo a mano en `opencode.json` e instalar sus dependencias.

---

## Pasos (en orden)

### 1. Instalar dependencias del plugin

Desde la raíz del repo:

```bash
cd .opencode/plugins/davercode-session-bridge
bun install
```

Esto baja `@opencode-ai/plugin@1.17.18` (declarado en `package.json`).

> El `node_modules/`, `bun.lock` y `package-lock.json` del plugin ya están gitignored por `.opencode/.gitignore`, así que no contaminan el repo.

### 2. Registrar el plugin en `opencode.json`

En la **raíz del monorepo**, editá `opencode.json` y asegurate de que exista la clave `plugin`:

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": ["./.opencode/plugins/davercode-session-bridge"],
  ...
}
```

> Si tu `opencode.json` ya tiene otras entradas en `plugin`, agregá el path de este plugin a la lista existente (no la reemplaces).

### 3. Reiniciar el proceso de opencode

El runtime de opencode **lee la configuración una vez por proceso**. Si ya tenés un TUI / `bun dev` corriendo, **cerralo y volvé a abrirlo** para que cargue el nuevo `plugin` entry.

Sin este paso, el plugin no se carga aunque esté en `opencode.json`.

### 4. Verificar la instalación

Después de `bun install` corre automáticamente un `postinstall` hook. Si querés verificar manualmente:

```bash
cd .opencode/plugins/davercode-session-bridge
bun run check
```

Salida esperada si todo está OK:

```
davercode-session-bridge: install OK
```

Si falta algo, el script imprime un warning accionable y sale con code 1.

### 5. Smoke test end-to-end

Dispará cualquier subagente (incluso trivial). El plugin debería:

- Loguear `session created` vía `client.app.log()` (visible en el panel de logs del TUI).
- Cuando la sesión quede `idle` o `error`, escribir un snapshot en:
  ```
  ~/.config/opencode/sessions/{human_id}/{project_slug}/{DDMMYYYY-runtime}/{uuid}.md
  ~/.config/opencode/sessions/{human_id}/{project_slug}/{DDMMYYYY-runtime}/{uuid}.json
  ```
- Exponer el tool `session_status` a los subagentes (lista compacta de sesiones recientes).

Forma rápida de validar sin gastar tokens:

```bash
cd packages/opencode
bun run src/index.ts run --model "opencode-go/minimax-m3" "Respond with the single word: pong"
```

Después:

```bash
ls -lh ~/.config/opencode/sessions/*/{project_slug}/{DDMMYYYY-runtime}/*.json
```

Si ves un `.json` y un `.md` con `schemaVersion: "1.0"`, el plugin está operativo.

---

## Contexto del proyecto

> **Para entender este plugin en su contexto:**

Este repositorio es un **fork** de [`sst/opencode`](https://github.com/sst/opencode) (la AI coding agent open source). La carpeta `.opencode/` **no es parte de opencode upstream** — es un **sistema de agentes especializado** que se está desarrollando sobre opencode, con dos objetivos principales:

- **Observar el ciclo de vida de las sesiones** del runtime desde adentro, vía plugins como este. Cada plugin es un "órgano" del sistema de agentes: traduce eventos nativos del runtime a estado ejecutivo persistente (snapshots, logs estructurados, herramientas).
- **Sustituir gradualmente las convenciones file-based** (`~/.config/opencode/sessions/...`, manifestos, interruption logs) por las APIs nativas que opencode expone. Este plugin es una pieza del plan documentado en `docs/context/agent-improvement-plan.md`.

El sistema se perfecciona continuamente **leyendo el código fuente y las APIs internas de opencode** desde el propio monorepo: `packages/opencode`, `packages/core`, `packages/schema`, `packages/protocol` y el SDK público `@opencode-ai/plugin`. Implicaciones prácticas:

- **Las APIs internas de opencode pueden cambiar entre versiones upstream**. Si un test falla o el plugin deja de funcionar después de un `git pull`, lo más probable es que un nombre de evento, una forma de payload o un punto de inyección haya cambiado en opencode. Antes de asumir que el bug es del plugin, revisá el código del runtime (`packages/opencode/src/...`).
- **El shape de los eventos `session.*` está en transición**. El V2 runtime está migrando de eventos planos (`session.idle`, `session.error`, etc.) a `session.status` con `status.type: "idle" | "retry" | "busy"`. Este plugin escucha los eventos planos, que siguen funcionando en v1.17.18 (la versión upstream actual de DaverCode) pero pueden ser removidos en una versión futura — en ese caso hay que migrar el `event` hook para escuchar `session.status` y filtrar por `status.type === "idle"`.
- **El `glob` de auto-discovery de plugins en `ConfigPlugin.load` (`packages/opencode/src/config/plugin.ts:21`) tampoco recorre subdirectorios**, así que el registro explícito en `opencode.json` es necesario hasta que se arregle upstream (o hasta que el plugin se reorganice como archivo plano).

Para más contexto, ver:

- [`docs/project.md`](../../../docs/project.md) — entry point del proyecto: stack, comandos, slices, convenciones.
- [`docs/context/agent-improvement-plan.md`](../../../docs/context/agent-improvement-plan.md) — plan de migración del sistema de agentes a mecanismos nativos del runtime.
- [`docs/context/architecture.md`](../../../docs/context/architecture.md) — arquitectura del monorepo (capas, dirección de dependencias, slices).
- [`docs/context/opencode-runtime.md`](../../../docs/context/opencode-runtime.md) — capacidades nativas del runtime de opencode y mapeo a qué puede reemplazar el manejo file-based.

---

## Troubleshooting

| Síntoma | Causa probable | Fix |
|---|---|---|
| `bun run check` dice "plugin NOT registered in opencode.json" | Falta la entrada `plugin` en `opencode.json` | Agregala según el paso 2 |
| `bun run check` dice "@opencode-ai/plugin not installed" | `node_modules` falta | `bun install` en este dir |
| El plugin carga pero no escribe snapshots | El proceso de opencode no se reinició después de editar `opencode.json` | Cerrá y reabrí el TUI / `bun dev` |
| El tool `session_status` no aparece en subagentes | El plugin no está cargado | Verificar `opencode.json` + reiniciar proceso |
| `bun typecheck` falla | `node_modules` no instalado o versión de TS incompatible | `bun install` en este dir |
| El path no resuelve | El path en `opencode.json` es relativo a otra config | Usar `./.opencode/plugins/davercode-session-bridge` (anclado a la raíz del monorepo) |

## Por qué este plugin no se autodetecta

Técnicamente: `ConfigPlugin.load` en `packages/opencode/src/config/plugin.ts:21` corre:

```ts
Glob.scan("{plugin,plugins}/*.{ts,js}", { cwd: dir, absolute: true, dot: true, symlink: true })
```

El glob matchea **archivos** como `plugins/foo.ts` o `plugins/bar.js`, pero **no recurre** a `plugins/<name>/index.ts`. El loader sí soporta directorios con `package.json` (ver `resolvePathPluginTarget` en `plugin/shared.ts:175-192`), pero la ruta de auto-discovery no los recorre.

Por eso: **registro explícito obligatorio** en `opencode.json` hasta que se arregle el glob upstream.

## Versionado

- Plugin: `0.1.0` (en `package.json`).
- Schema de snapshot: `1.0` (campo `schemaVersion` en el JSON). Breaking changes incrementan la versión mayor.
- Compatible con `@opencode-ai/plugin@1.17.18` (la versión upstream de DaverCode).
