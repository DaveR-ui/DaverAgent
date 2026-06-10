# Sessions System

> Estructura de sesiones del Delivery Agent para gestión de contexto humano-proyecto-tarea.

## Arquitectura de Directorios

```
~/.config/opencode/
├── humans/                              # FUENTE de perfiles humanos
│   └── {human_id}/
│       └── humano.md                    # Perfil original (se edita aquí)
├── projects/                            # FUENTE de contextos de proyecto
│   └── {project_id}/
│       └── project.md                   # Contexto original (se edita aquí)
└── sessions/                            # SESIONES DE TRABAJO
    ├── _templates/                      # Templates con variables
    │   ├── humano-template.md
    │   ├── project-template.md
    │   └── general-context-template.md
    ├── README.md                        # Este archivo
    └── {human_id}/                      # Sesiones por humano
        ├── humano.md                    # COPIA desde humans/{human_id}/
        └── {project_id}/
            ├── project.md               # COPIA desde projects/{project_id}/ + repo
            └── {session_id}/
                ├── general-context.md   # Prompt original + clasificación
                ├── enhanced-prompt.md   # Output del Prompt Enhancer
                ├── scope.md             # Output del Context Reducer
                └── assets/              # Imágenes y archivos adjuntos
```

## Fuentes vs Copias

### Archivos Fuente (edición maestra)
| Archivo | Ubicación Fuente | Propósito |
|---------|-----------------|-----------|
| `humano.md` | `~/.config/opencode/humans/{id}/humano.md` | Perfil persistente del humano |
| `project.md` | `~/.config/opencode/projects/{id}/project.md` | Contexto base del proyecto |

### Archivos Copia (en sesiones)
| Archivo | Se Copia De | Cuándo |
|---------|-------------|--------|
| `sessions/{humano}/humano.md` | `humans/{humano}/humano.md` | Al crear primera sesión del humano |
| `sessions/{humano}/{proyecto}/project.md` | `projects/{proyecto}/project.md` + `{repo}/.opencode/project.md` | Al crear primera sesión del proyecto |

### Sincronización
- Las copias en sesiones son **snapshots** al momento de creación
- Si el fuente cambia, las sesiones existentes NO se actualizan automáticamente
- Para sincronizar: copiar manualmente o usar script de sync

## Templates con Variables

Los templates usan sintaxis `{{VARIABLE}}` para placeholders.

### humano-template.md
**Variables principales:**
- `{{HUMAN_ID}}` - Identificador único (ej: `david.romaniuk`)
- `{{HUMAN_NAME}}` - Nombre del humano
- `{{LANGUAGE}}` - Idioma principal (ej: `es-AR`)
- `{{OS_USERNAME}}` - Username del sistema operativo
- `{{DETAIL_LEVEL}}` - Nivel de detalle preferido
- `{{SHOW_THINKING}}` - Mostrar proceso de pensamiento
- `{{SESSION_NAME_FORMAT}}` - Formato de nombre de sesión
- Variables de diccionario: `{{SLANG_TERM_N}}`, `{{TECH_TERM_N}}`, etc.

### project-template.md
**Variables principales:**
- `{{PROJECT_NAME}}` - Nombre del proyecto
- `{{PROJECT_ID}}` - Identificador único
- `{{PROJECT_REPO_PATH}}` - Ruta al repositorio
- `{{PRIMARY_LANGUAGE}}` - Lenguaje principal
- `{{ARCH_PATTERN}}` - Patrón de arquitectura
- Variables de estructura: `{{PROJECT_STRUCTURE}}`, `{{KEY_CONVENTIONS}}`, etc.

### general-context-template.md
**Variables principales:**
- `{{SESSION_ID}}` - Identificador de sesión
- `{{SESSION_NAME}}` - Nombre de sesión (ej: `08062026-login-fix`)
- `{{ORIGINAL_PROMPT}}` - Prompt verbatim del humano
- `{{PROMPT_LANGUAGE}}` - Idioma del prompt
- `{{PROMPT_TYPE}}` - Clasificación (bug/task/feature-design/update)
- `{{ENHANCED_DESCRIPTION}}` - Traducción al inglés mejorada
- Variables de adjuntos: `{{ATTACHMENT_N}}`, `{{TYPE_N}}`, etc.

## Flujo de Creación de Sesión

### Regla de Complejidad
- Si la tarea es **simple** (consulta breve, cambio puntual, o trabajo de 1 paso sin necesidad de contexto persistente), **NO crear sesión**.
- Crear sesión solo cuando haya seguimiento multi-paso, adjuntos, contexto persistente, o cuando el humano lo pida explícitamente.
- Si una tarea empezó simple pero crece durante la conversación, recién ahí crear la sesión.

```
1. Humano envía prompt
        ↓
2. Delivery Agent identifica humano (OS username)
        ↓
3. Clasificar complejidad inicial
   ├── SIMPLE → trabajar sin sesión
   └── MODERATE/COMPLEX → continuar flujo de sesión
        ↓
4. ¿Existe sessions/{humano}/humano.md?
   ├── SÍ → Leer copia local
   └── NO → Copiar desde humans/{humano}/humano.md
        ↓
5. Delivery Agent identifica proyecto (repo actual)
        ↓
6. ¿Existe sessions/{humano}/{proyecto}/project.md?
   ├── SÍ → Leer copia local
   │        ├── Si `Next Review Due` sigue vigente → usar snapshot actual
   │        └── Si venció (~30 días) → revisar fuente y refrescar si hace falta
   └── NO → Copiar desde projects/{proyecto}/project.md
              + Merge con {repo}/.opencode/project.md
        ↓
7. Generar nombre de sesión: DDMMYYYY-keywords
        ↓
8. Crear estructura:
   sessions/{humano}/{proyecto}/{sesion}/
   ├── general-context.md (desde template)
   └── assets/
        ↓
9. Procesar adjuntos (si hay)
        ↓
10. Handoff al Orchestrator (en inglés)
```

## Política de Revisión de `project.md`

- `project.md` se trata como **snapshot revisado**, no como archivo a resincronizar en cada interacción.
- Cada copia debe registrar:
  - `Last Reviewed`
  - `Next Review Due`
  - `Review Cadence`
- Cadencia por defecto: **monthly (~30 days)**.
- Revisar antes si:
  - cambió materialmente `.opencode/project.md` del repo,
  - cambió la arquitectura/base tecnológica,
  - o la tarea necesita contexto nuevo no cubierto por el snapshot actual.

## Reglas del Diccionario

### Propósito
El diccionario en `humano.md` tiene UN SOLO PROPÓSITO: **traducir correctamente** entre el idioma del humano y el inglés.

### Lo que NO hace
- ❌ NO define cómo habla el agente
- ❌ NO imita coloquialismos del humano
- ❌ NO usa jerga del humano al comunicarse

### Lo que SÍ hace
- ✅ Traduce términos coloquiales del humano a inglés estándar
- ✅ Traduce términos técnicos del proyecto a inglés
- ✅ Mantiene tabla de referencia para consistencia

### Ejemplo

**Humano dice (es-AR):**
> "Che, el endpoint de laburar con clientes no anda, tira un 500 raro"

**Diccionario usa:**
| Term | English Translation |
|------|-------------------|
| che | (interjection, no translation needed) |
| no anda | doesn't work / is failing |
| tira | returns / throws |
| raro | unusual / unexpected |

**Agente traduce al Orchestrator (English):**
> "The client management endpoint is failing, returning an unexpected 500 error"

**Agente responde al humano (es-AR, neutral/profesional):**
> "El endpoint de gestión de clientes está fallando con un error 500. Voy a investigar la causa."

**Nótese:** El agente NO dice "Che, el endpoint no anda". Habla en español neutral/profesional.

## Comunicación

### Protocolo de Idiomas
| Dirección | Idioma | Contenido | Estilo |
|-----------|--------|-----------|--------|
| Humano → Agente | Idioma del humano | Completo | Como sea (coloquial, técnico, etc.) |
| Agente → Humano | Idioma del humano | Resumen + Plan | **Neutral/Profesional** |
| Agente → Orchestrator | Inglés | Completo | Técnico/Estándar |
| Orchestrator → Agente | Inglés | Completo | Técnico/Estándar |

### Filtrado por Defecto
El agente solo muestra al humano:
1. **Resumen contextual** - Qué se entendió del problema
2. **Plan general** - Qué se va a hacer

NO se muestra:
- Proceso de pensamiento interno
- Detalles técnicos de implementación (a menos que se pidan)
- Conversaciones entre agentes

## Health Checks

### Diccionario
| Términos | Estado | Acción |
|----------|--------|--------|
| 0-50 | Compact (OK) | Segregar agregando |
| 51-100 | Growing | Ser selectivo |
| 101+ | Large | Alertar al humano, sugerir limpieza |

### Sesiones
- Mantener `humano.md` alineado con la fuente cuando cambie vocabulario relevante
- Revisar `project.md` aproximadamente una vez por mes o antes si cambia el contexto técnico
- Limpiar sesiones antiguas/canceladas periódicamente
- Monitorear tamaño de `assets/` en sesiones activas

## Comandos Útiles (PowerShell)

### Crear nueva sesión
```powershell
# Variables
$human = "david.romaniuk"
$project = "DFCustomerPortal_SPA_AIR226766"
$session = "08062026-login-fix"
$base = "$env:USERPROFILE\.config\opencode\sessions"

# Crear estructura
New-Item -ItemType Directory -Path "$base\$human\$project\$session\assets" -Force

# Copiar templates y reemplazar variables
# (Script de inicialización pendiente)
```

### Sincronizar humano desde fuente
```powershell
$human = "david.romaniuk"
$source = "$env:USERPROFILE\.config\opencode\humans\$human\humano.md"
$target = "$env:USERPROFILE\.config\opencode\sessions\$human\humano.md"
Copy-Item -Path $source -Destination $target -Force
```

### Revisar/refrescar proyecto desde fuente + repo
```powershell
$project = "DFCustomerPortal_SPA_AIR226766"
$repoPath = "C:\projects\DFCustomerPortal_SPA_AIR226766"
$source = "$env:USERPROFILE\.config\opencode\projects\$project\project.md"
$repoSource = "$repoPath\.opencode\project.md"
$human = "david.romaniuk"
$target = "$env:USERPROFILE\.config\opencode\sessions\$human\$project\project.md"

# Ejecutar solo cuando `Next Review Due` esté vencido o el contexto técnico haya cambiado.
# Merge: fuente base + repo (repo tiene prioridad para secciones existentes)
# (Script de merge pendiente)
```
