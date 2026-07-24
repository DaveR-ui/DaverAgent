# Agente Opencode — `goland-api`

Esta carpeta contiene toda la configuración del sistema de agentes (delivery, orchestrator, coder, tester, etc.) que opera sobre el repo `goland-api` (Go 1.24, Gin, GORM, PostgreSQL).

## Fuente de verdad: una sola

| Archivo | Ubicación | Rol |
|---|---|---|
| `opencode.json` | raíz del repo | **Única fuente de verdad** de la config. El runtime de opencode la lee al arrancar. La mantiene el `install-agent.ps1` (con `-Update`) o se edita a mano. |

No hay `jason-opencode.json` ni otra copia duplicada. Si querés cambiar un modelo, un permiso o un agente, editá `opencode.json` directamente.

## Modelos

El catálogo raw está en [`llm-reference.md`](./llm-reference.md). El routing efectivo vive en `opencode.json` y se resume así:

| Modelo | Carácter | Agentes |
|---|---|---|
| `opencode-go/minimax-m3` | El más barato | `delivery`, `explorer`, `project-context`, `vision-relay`, `tester`, `external-scout` |
| `opencode-go/glm-5.2` | El más creativo | `architect`, `reviewer` |
| `opencode-go/kimi-k3` | El más inteligente | `coder`, `orchestrator` |

**Prioridad**: si un agente declara `model:` en su frontmatter `.md` y otro valor en `opencode.json`, **gana `opencode.json`**. El frontmatter es documentación, no runtime.

## Estructura

```
.opencode/
├── opencode (config) ───────────────────
├── opencode.json                       # Config del runtime (única fuente)
├── llm-reference.md                    # Catálogo raw de modelos
├── README.md                           # Este archivo
├── INSTALL.md                          # Cómo instalar el agente en otro repo
│
├── agents/                             # System prompts por agente
│   ├── delivery.md                     # Interfaz con el humano
│   ├── orchestrator.md                 # Coordinador (delegable a fondo)
│   ├── coder.md                        # Implementación
│   ├── reviewer.md                     # Code review
│   ├── vision-relay.md                 # Inspección de imágenes
│   ├── architect.md                    # Wrapper -> subagents/architect.md
│   └── subagents/                      # Specs canónicos (los lee opencode runtime)
│       ├── architect.md
│       ├── coder.md
│       ├── tester.md
│       ├── reviewer.md
│       ├── explorer.md
│       ├── project-context.md
│       ├── documenter.md
│       ├── external-scout.md
│       └── vision-relay.md
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

Definidos en `opencode.json` (modo `subagent`). Se invocan desde `delivery` u `orchestrator` con el `task` tool.

| Agente | Modelo | Propósito |
|---|---|---|
| `delivery` | minimax-m3 | Interfaz con el humano. NO delega trabajo técnico. |
| `orchestrator` | kimi-k3 | Coordina trabajo multi-paso, hace fan-out de subagentes. |
| `coder` | kimi-k3 | Implementa features, fixes, refactors. Devuelve `CoderOutput`. |
| `tester` | minimax-m3 | Tests. Devuelve `TesterOutput`. |
| `reviewer` | glm-5.2 | Code review, security, performance. Devuelve `ReviewerOutput`. |
| `architect` | glm-5.2 | Diseño, boundaries, patrones. Devuelve `ArchitectOutput`. |
| `explorer` | minimax-m3 | Búsqueda y mapeo en el repo. Devuelve `ExplorerOutput`. |
| `project-context` | minimax-m3 | Lee/escribe `docs/`. |
| `vision-relay` | minimax-m3 | Inspección barata de imágenes (un path + una pregunta → respuesta corta). |
| `external-scout` | minimax-m3 | Trae docs de libs Go externas vía webfetch. |

## Protocolos (cómo piensa el agente)

Los protocolos viven en [`.opencode/protocols/`](./protocols/README.md). El más importante es [`.opencode/protocols/prompt-pipeline.md`](./protocols/prompt-pipeline.md), que define el análisis en 2 fases que el `delivery` aplica a cada prompt, sin excepción. El `delivery.md` lo referencia por anchor en vez de duplicar el contenido.

## Permisos de los agentes

- `orchestrator` y los subagentes NO tienen skills externos prehabilitados. El único skill built-in legítimo es `customize-opencode` (del runtime de opencode, no repo-local).
- Toda la info del proyecto (Postgres, permission system, etc.) vive en `docs/context/` y se lee **on demand**.

## Actualizar la config

Si tocás `opencode.json` (agregás un subagente, cambiás un modelo, etc.), no necesitás correr nada más — opencode lo relee al próximo arranque. Si en cambio querés regenerar todo desde el schema del installer:

```powershell
& ".\.opencode\scripts\install-agent.ps1" -VerifyOnly   # ver qué cambiaría
& ".\.opencode\scripts\install-agent.ps1"                 # aplicar
```

El installer hace backup automático en `.opencode/.backups/<timestamp>/` antes de sobrescribir.

## Solución de problemas

**"No me toma la config"** — Verificá que `opencode.json` es JSON válido: `Get-Content .\opencode.json -Raw | ConvertFrom-Json`.

**"Quiero volver a la versión anterior"** — Si el cambio lo hizo `install-agent.ps1`, hay backup en `.opencode/.backups/<timestamp>/`. Si lo hiciste a mano, depende de tu propio control de versiones.
