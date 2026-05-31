---
name: project-navigator
description: Guía de navegación, leyes arquitectónicas (Scope Rule) y gestión de tareas pendientes.
---

# Skill: Project Navigator

## Goal
Mantener el orden arquitectónico del repositorio, asegurar que cada archivo esté en su lugar correcto según su ámbito y gestionar el progreso del proyecto.

## Instructions

### 1. La Ley Absoluta del Alcance (Scope Rule)
- **Compartido por 2+ features**: DEBE ir en `src/shared/`.
- **Usado por 1 sola feature**: DEBE quedarse local en `src/features/[feature-name]/`.
- **Singleton/App-wide**: DEBE ir en `src/core/`.

### 2. Estructura de Directorios
- `src/features/[name]/`: Contiene `page/`, `ui/`, `services/` y modelos locales.
- `src/shared/ui/`: Átomos y moléculas reutilizables (botones, inputs).
- `src/core/layout/`: El shell de la aplicación (navbar, footer).

### 3. Seguimiento de Tareas
- Al terminar cualquier tarea, actualizar `task-memory.md` y revisar `todo.md`.
- Proponer siempre el siguiente paso lógico al usuario.

## Constraints
- **PROHIBIDO**: Crear archivos en la raíz de `src/` sin categorizar.
- **PROHIBIDO**: Importar elementos de una feature específica desde otra feature (Cross-feature imports). Usar `shared` como puente.

## Examples

### Correct Placement
- Nuevo botón genérico -> `src/shared/ui/button/`
- Guardado de Clientes -> `src/features/client/services/client.service.ts`
- Navbar principal -> `src/core/layout/navbar/`
