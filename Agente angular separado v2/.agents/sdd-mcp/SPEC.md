# Especificaciones Técnicas: SDD Knowledge Server (MCP)

Este documento detalla los requerimientos y la arquitectura para el servidor MCP local escrito en Go, diseñado para servir como middleware de conocimiento entre el Agente SDD y el Hub de Conocimiento del proyecto.

## 1. Resumen del Proyecto
- **Nombre:** `sdd-mcp-server`
- **Lenguaje:** Go 1.22+
- **Protocolo:** Model Context Protocol (MCP) v1.0
- **Transporte:** Standard Input/Output (stdio)
- **SDK Principal:** `github.com/mark3labs/mcp-go`

## 2. Objetivos Principales
1. **Descubrimiento Progresivo:** Permitir que el agente solicite fragmentos específicos de documentación (Skills/SDD) en lugar de cargar todo el contexto.
2. **Validación Estructural:** Ofrecer herramientas para que el agente verifique si una propuesta de diseño cumple con las reglas del proyecto.
3. **Eficiencia Local:** Minimizar la latencia al realizar búsquedas y lecturas de archivos directamente desde el disco local.

## 3. Arquitectura de Recursos (Resources)
El servidor expondrá los siguientes esquemas de URI:

- **`sdd://skills/{category}/{name}`**
    - **Descripción:** Acceso directo a los archivos `SKILL.md`.
    - **Mapeo Físico:** `.agents/skills/{category}-{name}/SKILL.md`
- **`sdd://project/details`**
    - **Descripción:** Acceso al archivo `project-details.md` (SSOT del proyecto).
- **`sdd://architecture/decisions`**
    - **Descripción:** Listado y contenido de los ADRs (Architectural Decision Records).

## 4. Herramientas (Tools)
Se deben implementar las siguientes funciones programáticas:

### `search_sdd`
- **Propósito:** Realizar una búsqueda semántica o por palabras clave en todo el Hub de Conocimiento.
- **Argumentos:** `query` (string).
- **Retorno:** Lista de fragmentos y rutas de archivos relevantes.

### `validate_design_proposal`
- **Propósito:** Validar un bloque de código o descripción de diseño contra las reglas críticas del proyecto.
- **Argumentos:** `proposal_context` (string), `affected_files` (string[]).
- **Retorno:** Reporte de cumplimiento (Pass/Fail) con sugerencias de corrección.

### `get_component_boilerplate`
- **Propósito:** Generar estructuras básicas siguiendo las mejores prácticas de la versión actual de Angular (v19+).
- **Argumentos:** `component_name` (string), `type` (standalone/signal-based).

## 5. Estructura de Archivos Propuesta
```text
.agents/sdd-mcp/
├── main.go           # Inicialización del servidor y transporte stdio
├── go.mod            # Definición de dependencias
├── internal/
│   ├── mcp/
│   │   ├── server.go     # Configuración del SDK y handlers
│   │   ├── resources.go  # Definición de Resources
│   │   └── tools.go      # Definición de Tools
│   └── filesystem/
│       └── reader.go     # Lógica optimizada de lectura de archivos .md
└── SPEC.md           # Este archivo
```

## 6. Guía de Inicio Rápido
1. Crear directorio: `mkdir .agents/sdd-mcp`
2. Inicializar Go: `go mod init sdd-mcp`
3. Instalar SDK: `go get github.com/mark3labs/mcp-go`
4. Compilar binario: `go build -o sdd-mcp.exe main.go`
5. Configurar cliente MCP (Claude Desktop/Cursor/Etc.) apuntando al path del `.exe`.
