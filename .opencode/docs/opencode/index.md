# OpenCode Documentation Index

Referencia central de toda la documentación de OpenCode.

## Core Concepts

| Topic | File | Description |
|-------|------|-------------|
| [Agentes](agents.mdx) | `agents.mdx` | Configurar y utilizar agentes especializados (primarios y subagentes) |
| [Herramientas](tools.mdx) | `tools.mdx` | Herramientas integradas y personalizadas que puede usar el LLM |
| [Habilidades](skills.mdx) | `skills.mdx` | Definir comportamiento reutilizable mediante archivos SKILL.md |
| [Reglas](rules.mdx) | `rules.mdx` | Instrucciones personalizadas via AGENTS.md y archivos de instrucciones |
| [Permisos](permissions.mdx) | `permissions.mdx` | Control de aprobaciones y restricciones para acciones del agente |
| [Modelos](models.mdx) | `models.mdx` | Configuración de proveedores y modelos LLM |

## Configuration & Extensions

| Topic | File | Description |
|-------|------|-------------|
| [Comandos](commands.mdx) | `commands.mdx` | Crear comandos personalizados para tareas repetitivas |
| [Servidores MCP](mcp-servers.mdx) | `mcp-servers.mdx` | Agregar herramientas externas via Model Context Protocol |
| [Complementos](plugins.mdx) | `plugins.mdx` | Extender OpenCode con plugins JavaScript/TypeScript |
| [Formateadores](formatters.mdx) | `formatters.mdx` | Formateo automático específico por lenguaje |
| [Temas](themes.mdx) | `themes.mdx` | Temas integrados y personalizados para la interfaz |

## Integrations

| Topic | File | Description |
|-------|------|-------------|
| [Servidores LSP](lsp.mdx) | `lsp.mdx` | Integración con Language Server Protocol para inteligencia de código |
| [Soporte ACP](acp.mdx) | `acp.mdx` | Usar OpenCode en editores compatibles con Agent Client Protocol |

## Quick Reference

### Agent Types
- **Primary Agents**: Build (default), Plan, Compact, Title, Summary
- **Subagents**: General, Explore, Scout

### Key Commands
- `/models` - Select LLM model
- `/theme` - Change UI theme
- `/init` - Generate AGENTS.md
- `/[custom]` - Run custom commands

### Configuration Files
- `opencode.json` / `opencode.jsonc` - Main configuration
- `tui.json` - UI settings
- `AGENTS.md` - Project rules
- `.opencode/` - Project-level config directory

### Directory Structure
```
.opencode/
├── agents/          # Custom agent definitions
├── commands/        # Custom command templates
├── docs/opencode/   # This documentation
├── plugins/         # JavaScript/TypeScript plugins
├── skills/          # Reusable skill definitions (SKILL.md)
└── themes/          # Custom theme JSON files
```
