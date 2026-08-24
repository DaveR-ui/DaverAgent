# Agente Opencode — DaverAgent

Esta carpeta contiene toda la configuración del sistema de agentes (delivery, orchestrator, coder, tester, etc.) listo para clonar/copiar como `.opencode/` en el repo que lo vaya a usar.

## Fuente de verdad: una sola parte, sin duplicados

| Archivo | Ubicación | Rol |
|---|---|---|
| `jason-opencode.json` | raíz de esta tree | **Config runtime base**. Se copia al repo destino como `opencode.json`. Solo top-level: `default_agent`, `compaction`, `references`, `permission` global e `instructions`. **No tiene bloque `agent`**. |
| `.opencode/agents/subagents/*.md` | un archivo por agente | **Definición completa del agente**: `description`, `mode`, `model`, `temperature`, `permission`, `output_schema` y el system prompt. El runtime los carga por escaneo de `agent(s)/**/*.md`. |

**Regla de oro**: TODO lo de un agente vive en su `.md` (incluido modelo y temperatura). `opencode.json` no tiene bloque `agent`. No hay duplicación. Para cambiar un modelo, editá el frontmatter del agente y reiniciá opencode.

## Estructura

> Este repo es el **tree fuente**: los archivos viven en la raíz (`agents/`, `protocols/`, ...) y se copian al repo destino como `.opencode/`. Por eso este README y los agentes referencian rutas con prefijo `.opencode/` — es la forma que tienen en el repo instalado.

```
DaverAgent/                     (tree fuente → se copia como .opencode/ en el repo destino)
├── jason-opencode.json         # Config runtime base -> copiar como opencode.json en el repo destino
│                              #  (default_agent, compaction, references, permission, instructions)
├── README.md                  # Este archivo
├── INSTALL.md                 # Cómo instalar el agente en otro repo
│
├── agents/
│   └── subagents/             # Un archivo por agente (los lee el runtime de opencode)
│       ├── delivery.md        # Interfaz con el humano (primary)
│       ├── orchestrator.md    # Coordinador (delegable a fondo)
│       ├── coder.md         # Implementación (language=angular|go, referencia docs/context/)
│       ├── reviewer.md      # Code review
│       ├── tester.md        # Tests
│       ├── architect.md     # Diseño
│       ├── explorer.md      # Búsqueda y mapeo
│       ├── project-context.md # Lectura de docs/ (read-only, lookups y context assembly)
│       ├── external-scout.md  # Docs externas vía webfetch
│       ├── interpreter.md     # Normalización Step 0
│       ├── analista.md        # Segunda opinión
│       ├── documenter.md      # Documentación
│       └── *.schema.json      # Schemas de los returns estructurados
│
├── protocols/                  # Convenciones operativas del agente (5 + README)
│   ├── README.md               # Índice
│   ├── prompt-pipeline.md      # Step 0 Interpret (interpreter subagent) + Phase 2 Reduce
│   ├── session-recovery.md     # Recovery for interrupted/STUCK sessions
│   ├── broad-investigation-template.md # Scaffold para auditorías wide-surface
│   ├── agent-installer.md      # 4 fases del installer
│   └── subagent-spec-template.md # Canonical subagent shape + output_schema bridge
│
├── workflows/                  # Thinking instructions
│   ├── dispatch.md             # Gate interpreter-first (lo lee delivery cada turno)
│   └── orchestrate.md          # Reglas que el orchestrator aplica antes de actuar
│
├── scripts/                    # Installer + helpers
│   ├── install-agent.ps1       # 4 fases: regenera docs/project.md, context docs, subagents, opencode.json
│   ├── install-agent.schema.json # Question list que guía el installer (4 fases)
│   ├── validate-agent.sh       # Lint de integridad del tree de agentes (CI-friendly)
│   └── session-recover.ps1     # Walk de la session API para recovery
│
├── tests/                      # Test suite del tree de agentes
│   ├── run-tests.sh            # Runner maestro: validator + schemas
│   ├── schema_check.py         # Mini-validador JSON Schema (stdlib, sin deps)
│   ├── test-output-schemas.py  # Contratos schema <-> fixtures <-> ejemplos de los .md
│   ├── test-validate-agent.sh  # Corre validate-agent.sh y afirma que pasa
│   └── fixtures/               # Fixtures de outputs y routing packets dorados
│
└── .github/workflows/          # CI (corre run-tests.sh en cada push/PR)
```

## Subagents disponibles

Definidos en `.opencode/agents/subagents/*.md` (modo `subagent`). Se invocan desde `delivery` u `orchestrator` con el `task` tool.

| Agente | Modelo | Propósito |
|---|---|---|
| `delivery` | deepseek-v4-flash | Interfaz con el humano. NO delega trabajo técnico. |
| `orchestrator` | heredado (*) | Ejecuta Phase 2 (Reduce), coordina trabajo multi-paso, hace fan-out de subagentes. |
| `coder` | deepseek-v4-flash | Implementación (language=angular|go). Referencia los docs del stack en `docs/context/`. Devuelve `CoderOutput`. |
| `tester` | deepseek-v4-flash | Tests. Devuelve `TesterOutput`. |
| `reviewer` | deepseek-v4-flash | Code review, security, performance. Devuelve `ReviewerOutput`. |
| `architect` | heredado (*) | Diseño, boundaries, patrones. Devuelve `ArchitectOutput`. |
| `analista` | heredado (*) | Segunda opinión, crítica de planes, stuck-recovery. Devuelve `AnalystOutput`. |
| `explorer` | deepseek-v4-flash | Búsqueda y mapeo en el repo. Devuelve `ExplorerOutput`. |
| `project-context` | deepseek-v4-flash | Lookups y context assembly de `docs/` (read-only). El único escritor de `docs/` es `documenter`. |
| `external-scout` | deepseek-v4-flash | Trae docs de librerías externas vía webfetch. |
| `interpreter` | heredado (*) | Normaliza el prompt (Step 0 del pipeline). |
| `documenter` | deepseek-v4-flash | Escribe/mantiene `docs/`. Devuelve `DocumenterOutput`. |

Los modelos y temperaturas viven en el **frontmatter de cada agente** (`.opencode/agents/subagents/<id>.md`). Cambiar un modelo = editar el frontmatter del agente + reiniciar opencode.

(*) Sin `model:` declarado: el subagente hereda el modelo del agente primary que lo invoca (default de opencode). `model:` es un override opcional.

## Protocolos (cómo piensa el agente)

Los protocolos viven en [`.opencode/protocols/`](./protocols/README.md). El más importante es [`.opencode/protocols/prompt-pipeline.md`](./protocols/prompt-pipeline.md), que define el análisis en 2 fases que se aplica a cada prompt, sin excepción: Step 0 (Interpret) lo ejecuta el `interpreter`; Phase 2 (Reduce) la ejecuta el `orchestrator`. El `delivery.md` lo referencia por anchor en vez de duplicar el contenido.

## Permisos de los agentes

- `orchestrator` y los subagentes NO tienen skills externos prehabilitados. El único skill built-in legítimo es `customize-opencode` (del runtime de opencode, no repo-local).
- Toda la info del proyecto (Postgres, permission system, etc.) vive en `docs/context/` y se lee **on demand**.

## Actualizar la config

- **Cambiar modelo/temperatura** de un agente → editá el frontmatter de `.opencode/agents/subagents/<id>.md` (`model` / `temperature`) y reiniciá opencode. Nada más.
- **Cambiar la definición de un agente** (prompt, tools, permisos, schema) → editá `.opencode/agents/subagents/<id>.md`.
- **Agregar un agente** → creá `.opencode/agents/subagents/<id>.md` con su frontmatter completo (`description`, `mode`, `model`, `temperature`, `permission`, `output_schema`). No toques `opencode.json`.
- Para regenerar `docs/project.md`, los context docs y los subagents desde el schema del installer:

```powershell
& ".\.opencode\scripts\install-agent.ps1" -VerifyOnly   # ver qué cambiaría
& ".\.opencode\scripts\install-agent.ps1"                 # aplicar
```

El installer hace backup automático en `.opencode/.backups/<timestamp>/` antes de sobrescribir.

## Validar la config

Antes de commitear cambios a `.opencode/`, corré el test suite completo (Git Bash / WSL):

```bash
bash .opencode/tests/run-tests.sh
```

Incluye dos suites, todas con exit code 0/1 (listas para CI):

1. **`validate-agent.sh`** (lint de integridad): que `opencode.json` sea JSON válido, que cada agente `.md` declare `model` en su frontmatter y no use el campo deprecated `tools:` (usa `permission:`), que cada `output_schema` apunte a un archivo existente, que los `permission.task` de `delivery`/`orchestrator` apunten a subagentes reales, y que el frontmatter obligatorio (`description`/`mode`) exista. Los paths `docs/` (del repo destino) se reportan como WARN, no como error.
2. **`test-output-schemas.py`** (contratos de salida): cada fixture válido en `tests/fixtures/outputs/` valida contra su schema, cada fixture inválido es rechazado, los routing packets dorados en `tests/fixtures/prompts/` validan contra `interpreter.schema.json`, y los ejemplos JSON documentados en los `.md` se mantienen en sync con sus schemas.

## Solución de problemas

**"No me toma la config"** — Verificá que `opencode.json` es JSON válido: `Get-Content .\opencode.json -Raw | ConvertFrom-Json`.

**"Quiero volver a la versión anterior"** — Si el cambio lo hizo `install-agent.ps1`, hay backup en `.opencode/.backups/<timestamp>/`. Si lo hiciste a mano, depende de tu propio control de versiones.
