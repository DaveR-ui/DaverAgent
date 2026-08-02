# Agente Opencode — DaverAgent

Esta carpeta contiene toda la configuración del sistema de agentes (delivery, orchestrator, coder-angular, coder-go, tester, etc.) listo para clonar/copiar como `.opencode/` en el repo que lo vaya a usar.

## Fuente de verdad: dos partes, sin duplicados

| Archivo | Ubicación | Rol |
|---|---|---|
| `jason-opencode.json` | raíz de esta tree | **Config base**. Se copia al repo destino como `opencode.json`. Define solo los **modelos y temperaturas** por agente (los knobs que cambiás seguido), más `default_agent`, `plugin`, `compaction`, `permission` global e `instructions`. |
| `.opencode/agents/subagents/*.md` | un archivo por agente | **Definición del agente**: `description`, `mode`, `tools`, `permission`, `output_schema` y el system prompt. El runtime los carga por escaneo de `agent(s)/**/*.md`. |

**Regla de oro**: modelo y temperatura viven solo en `opencode.json`; todo lo demás vive solo en el archivo del agente. No hay duplicación entre ambos. Para cambiar un modelo, editá `opencode.json` y reiniciá opencode.

## Modelos

| Modelo | Carácter | Agentes |
|---|---|---|
| `opencode-go/minimax-m3` | El más barato | `delivery`, `explorer`, `project-context`, `vision-relay`, `tester`, `external-scout`, `interpreter`, `documenter` |
| `opencode-go/kimi-k3` | El más inteligente (No acepta temperaturas) | `coder-angular`, `coder-go`, `orchestrator`, `architect`, `reviewer`, `analista` |

## Estructura

```
.opencode/
├── jason-opencode.json                # Config base -> copiar como opencode.json en el repo destino
├── README.md                          # Este archivo
├── INSTALL.md                         # Cómo instalar el agente en otro repo
│
├── agents/
│   └── subagents/                     # Un archivo por agente (los lee el runtime de opencode)
│       ├── delivery.md                # Interfaz con el humano
│       ├── orchestrator.md            # Coordinador (delegable a fondo)
│       ├── coder-angular.md           # Implementación Angular (referencia docs/context/)
│       ├── coder-go.md                # Implementación Go (referencia docs/context/)
│       ├── reviewer.md                # Code review
│       ├── tester.md                  # Tests
│       ├── architect.md               # Diseño
│       ├── explorer.md                # Búsqueda y mapeo
│       ├── project-context.md         # Lee/escribe docs/
│       ├── vision-relay.md            # Inspección de imágenes
│       ├── external-scout.md          # Docs externas vía webfetch
│       ├── interpreter.md             # Normalización Step 0
│       ├── analista.md                # Segunda opinión
│       ├── documenter.md              # Documentación
│       └── *.schema.json              # Schemas de los returns estructurados
│
├── agents agnostic/                    # Definiciones alternativas (referencia, no usadas)
│
├── protocols/                          # Convenciones operativas del agente
│   ├── README.md                       # Índice
│   ├── prompt-pipeline.md              # Step 0 Interpret (interpreter subagent) + Phase 2 Reduce
│   ├── agent-installer.md              # 4 fases del installer
│   └── broad-investigation-template.md # Scaffold para auditorías wide-surface
│
├── workflows/                          # Thinking instructions
│   └── orchestrate.md                  # Reglas que el orchestrator aplica antes de actuar
│
├── plugins/                            # Plugins del runtime
│   └── prompt-fetcher/                 # Tool: fetch_original_prompt (lee el primer mensaje de una sesión)
│
├── scripts/                            # PowerShell helpers
│   └── install-agent.ps1               # 4 fases: regenera docs/project.md, context docs, subagents, opencode.json
│
├── .git/                               # Historial interno de .opencode/
└── .backups/                           # Backups automáticos del installer (no commitear)
```

## Subagents disponibles

Definidos en `.opencode/agents/subagents/*.md` (modo `subagent`). Se invocan desde `delivery` u `orchestrator` con el `task` tool.

| Agente | Modelo | Propósito |
|---|---|---|
| `delivery` | minimax-m3 | Interfaz con el humano. NO delega trabajo técnico. |
| `orchestrator` | kimi-k3 | Coordina trabajo multi-paso, hace fan-out de subagentes. |
| `coder-angular` | kimi-k3 | Implementación Angular. Referencia los docs Angular de `docs/context/`. Devuelve `CoderOutput`. |
| `coder-go` | kimi-k3 | Implementación Go. Referencia los docs Go de `docs/context/`. Devuelve `CoderOutput`. |
| `tester` | minimax-m3 | Tests. Devuelve `TesterOutput`. |
| `reviewer` | kimi-k3 | Code review, security, performance. Devuelve `ReviewerOutput`. |
| `architect` | kimi-k3 | Diseño, boundaries, patrones. Devuelve `ArchitectOutput`. |
| `analista` | kimi-k3 | Segunda opinión, crítica de planes, stuck-recovery. Devuelve `AnalystOutput`. |
| `explorer` | minimax-m3 | Búsqueda y mapeo en el repo. Devuelve `ExplorerOutput`. |
| `project-context` | minimax-m3 | Lee/escribe `docs/`. |
| `vision-relay` | minimax-m3 | Inspección barata de imágenes (un path + una pregunta → respuesta corta). |
| `external-scout` | minimax-m3 | Trae docs de librerías externas vía webfetch. |
| `interpreter` | minimax-m3 | Normaliza el prompt (Step 0 del pipeline). |
| `documenter` | minimax-m3 | Escribe/mantiene `docs/`. Devuelve `DocumenterOutput`. |

Los modelos y temperaturas de la columna "Modelo" viven en `opencode.json` (→ `agent.<id>`); la definición de cada agente vive en su `.md`. Cambiar un modelo = editar `opencode.json` + reiniciar opencode.

## Protocolos (cómo piensa el agente)

Los protocolos viven en [`.opencode/protocols/`](./protocols/README.md). El más importante es [`.opencode/protocols/prompt-pipeline.md`](./protocols/prompt-pipeline.md), que define el análisis en 2 fases que el `delivery` aplica a cada prompt, sin excepción. El `delivery.md` lo referencia por anchor en vez de duplicar el contenido.

## Permisos de los agentes

- `orchestrator` y los subagentes NO tienen skills externos prehabilitados. El único skill built-in legítimo es `customize-opencode` (del runtime de opencode, no repo-local).
- Toda la info del proyecto (Postgres, permission system, etc.) vive en `docs/context/` y se lee **on demand**.

## Actualizar la config

- **Cambiar modelo/temperatura** de un agente → editá `opencode.json` (`agent.<id>`) y reiniciá opencode. Nada más.
- **Cambiar la definición de un agente** (prompt, tools, permisos, schema) → editá `.opencode/agents/subagents/<id>.md`.
- **Agregar un agente** → creá `.opencode/agents/subagents/<id>.md` y sumá `agent.<id>` (model + temperature) a `opencode.json`.
- Para regenerar `docs/project.md`, los context docs y los subagents desde el schema del installer:

```powershell
& ".\.opencode\scripts\install-agent.ps1" -VerifyOnly   # ver qué cambiaría
& ".\.opencode\scripts\install-agent.ps1"                 # aplicar
```

El installer hace backup automático en `.opencode/.backups/<timestamp>/` antes de sobrescribir.

## Solución de problemas

**"No me toma la config"** — Verificá que `opencode.json` es JSON válido: `Get-Content .\opencode.json -Raw | ConvertFrom-Json`.

**"Quiero volver a la versión anterior"** — Si el cambio lo hizo `install-agent.ps1`, hay backup en `.opencode/.backups/<timestamp>/`. Si lo hiciste a mano, depende de tu propio control de versiones.
