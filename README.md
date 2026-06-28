# Instalación del Agente Opencode

Esta carpeta contiene toda la configuración del sistema de agentes (delivery, orchestrator, coder, tester, etc.) que trabaja sobre este repo.

El archivo `jason-opencode.json` dentro de esta carpeta es la **fuente de verdad** de la configuración. Para que opencode la cargue al iniciar, hay que copiarla un nivel arriba con el nombre estándar `opencode.json`.

## Instalación rápida (1 paso)

Desde la raíz del repo:

```powershell
Copy-Item -LiteralPath ".\.opencode\jason-opencode.json" -Destination ".\opencode.json" -Force
```

Listo. Opencode ya levanta con la config de este repo.

**Importante**: si ya tenías un `opencode.json` propio, hacé un backup antes:

```powershell
Copy-Item -LiteralPath ".\opencode.json" -Destination ".\opencode.json.bak" -Force
Copy-Item -LiteralPath ".\.opencode\jason-opencode.json" -Destination ".\opencode.json" -Force
```

## Verificación

Después de copiar, confirmá que la config está vigente:

```powershell
# El archivo debe existir y ser JSON válido
Get-Content -LiteralPath ".\opencode.json" -Raw | ConvertFrom-Json | Out-Null

# Opencode lo lee al inicio; abrí el editor y verificá que reconoce los agentes
```

## ¿Por qué hay dos archivos?

| Archivo | Ubicación | Rol |
|---|---|---|
| `jason-opencode.json` | `.opencode/jason-opencode.json` | **Fuente de verdad** de la config. Se versiona en el repo, junto al resto de `.opencode/`. |
| `opencode.json` | `opencode.json` (raíz del repo) | **Copia que opencode lee al arrancar**. Es la convención del runtime. |

La razón: opencode busca `opencode.json` en la raíz del proyecto, pero nosotros queremos que la config viva **junto al resto de los archivos del agente** (`.opencode/agents/`, `.opencode/protocols/`, etc.) para mantener todo bajo control de versiones en una sola carpeta. Por eso la fuente es `jason-opencode.json` y se copia en el paso de instalación.

## Estructura del agente (qué hay en `.opencode/`)

```
.opencode/
├── jason-opencode.json         # Fuente de la config (copiala a ../opencode.json)
├── README.md                   # Este archivo
├── session-structure.md        # Layout de ~/.config/opencode/ (sesiones, humanos, proyectos)
├── model-routing.md            # Reglas de selección de modelo por categoría
├── llm-routing.md              # Routing real del runtime opencode
│
├── agents/                     # Definiciones de agentes (system prompts)
│   ├── delivery.md             # Agente principal (interfaz con el humano)
│   ├── orchestrator.md         # Coordinador efímero
│   ├── coder.md                # (legacy) — la versión activa está en subagents/
│   └── subagents/
│       ├── coder.md
│       ├── tester.md
│       ├── reviewer.md
│       ├── architect.md
│       ├── explorer.md
│       ├── project-context.md
│       ├── angular-expert.md
│       ├── opencode-expert.md
│       └── vscode-expert.md
│
├── protocols/                  # Convenciones operativas del agente
│   ├── README.md               # Índice
│   ├── canonical-prompter.md   # Phase 1: análisis de prompts
│   ├── context-reductor.md     # Phase 2: scope + complexity + hot spots
│   ├── interruption.md         # Bus de pause/resume (traffic-light + interruption-log)
│   ├── session-archiver.md     # Cierre y digestión de sesiones
│   ├── sessions-setup.md       # Bootstrap del opencode home
│   ├── doc-maintainer.md       # Validación de docs
│   └── agent-installer.md      # 4 fases del installer
│
├── workflows/                  # Instrucciones de razonamiento (cómo piensa el agente)
│   ├── orchestrate.md          # Reglas que el orchestrator aplica antes de actuar
│   └── session-bootstrap.md   # Workflow de gestión de sesión (ejecutado por session-manager)
│
├── docs/                       # Referencia para los subagents *-expert
│   ├── opencode/
│   ├── angular/
│   └── vscode/
│
├── scripts/                    # PowerShell helpers (ver abajo)
├── session-templates/          # Templates para nuevas sesiones
└── .backups/                   # Backups automáticos del installer (no commitear)
```

## Scripts disponibles (en `.opencode/scripts/`)

| Script | Propósito |
|---|---|
| `bootstrap-opencode-structure.ps1` | Crea la estructura base de `~/.config/opencode/` (humans/, projects/, sessions/) |
| `install-agent.ps1` | 4 fases: regenera `docs/project.md`, context docs, slang snapshot, subagents y `opencode.json` |
| `install-agent.schema.json` | Schema data-driven que `install-agent.ps1` consulta |
| `sync-project.ps1` | Sincroniza `docs/project.md` → `projects/{project_id}/project.md` |
| `sync-humano.ps1` | Sincroniza `humans/{human_id}/humano.md` → `sessions/{human_id}/humano.md` |
| `new-session.ps1` | Crea el directorio de una sesión nueva (`{DDMMYYYY-keywords}/`) |
| `init-sessions.ps1` | Wrapper legacy de bootstrap (deprecado, usar `bootstrap-opencode-structure.ps1`) |
| `test-opencode-structure.ps1` | Smoke test de la estructura |

### Uso típico

```powershell
# 1) Instalar/actualizar el agente
& ".\.opencode\scripts\install-agent.ps1" -VerifyOnly   # ver qué cambiaría
& ".\.opencode\scripts\install-agent.ps1"                 # aplicar cambios (con defaults)

# 2) Bootstrap del opencode home
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -VerifyOnly
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1"

# 3) Sincronizar contexto
& ".\.opencode\scripts\sync-project.ps1"
& ".\.opencode\scripts\sync-humano.ps1"
```

## Permisos de los agentes

Los agentes NO tienen skills externos habilitados. Toda la info del proyecto (stack, reglas, arquitectura, subsystemas) vive en `docs/context/` y se lee **on demand** cuando la tarea lo requiere.

- `delivery` es el único agente con permiso `external_directory: ~/.config/opencode/**` (necesario para escribir en el opencode home).
- `orchestrator` y subagentes no tienen skills precargados.

## Protocolos vs workflows vs context — la diferencia

| Carpeta | Qué vive ahí | Cuándo lo lee el agente |
|---|---|---|
| `docs/context/` | **Info del proyecto** (stack, reglas, arquitectura, convenciones) | Cuando la tarea toca ese tema (on demand) |
| `docs/protocols/` | **Plantillas del proyecto** (ej. scaffold de endpoints, patrones de creación) | Cuando la tarea usa ese patrón |
| `.opencode/protocols/` | **Convenciones del agente** (cómo analiza prompts, cómo pausa subagents, cómo cierra sesiones) | Siempre que el agente actúa |
| `.opencode/workflows/` | **Reglas de razonamiento** (qué pensar antes de actuar) | Al planificar una tarea |
| `.opencode/agents/` | **System prompts** de cada agente (identidad + permisos) | Al instanciar el agente |

## Actualizar la config

Si tocás `jason-opencode.json` (agregás un subagent, cambiás permisos, etc.), volvé a copiarlo a la raíz:

```powershell
Copy-Item -LiteralPath ".\.opencode\jason-opencode.json" -Destination ".\opencode.json" -Force
```

Si en cambio querés regenerar todo desde el installer (recomendado para cambios grandes), usá `install-agent.ps1` y dejá que él reescriba la config.

## Solución de problemas

**"No me toma la config"**
- Verificá que `opencode.json` existe en la raíz (no solo `.opencode/jason-opencode.json`).
- Verificá que el JSON es válido: `Get-Content .\opencode.json -Raw | ConvertFrom-Json`.

**"Quiero volver a la versión anterior"**
- Si venís de `install-agent.ps1`, hay un backup en `.opencode/.backups/<timestamp>/`.
- Si solo copiás manualmente, tenés que tener tu propio backup de `opencode.json`.

**"Falta la carpeta `humans/`, `projects/` o `sessions/` en `~/.config/opencode/`"**
- Corré `bootstrap-opencode-structure.ps1`. Es idempotente y no destructivo.
