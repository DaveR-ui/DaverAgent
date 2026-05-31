# Plan de Ejecución: Corrección de Estilos - Pantalla Clientes (Dark Mode)

## Contexto
La pantalla de "Clientes" presenta inconsistencias visuales severas en el tema oscuro.
**Fuente de Verdad**: Captura de pantalla proporcionada por el usuario y tokens en `.agents/context/design/tokens.md`.

## Decisión de Diseño (HOT SPOT Resuelto)
- **Input de Búsqueda**: **Opción A (Outline)**.
  - Estilo: Borde sutil, fondo transparente/integrado.
  - Razón: Limpieza visual y consistencia con el tema oscuro.

## Pasos de Implementación

### Fase 1: Tipografía (Título y Subtítulo)
**Archivo**: `src/features/client/page/client-list/client-list.scss`
1.  **Selector**: `.title-group h1`
    -   Cambiar `color` a `var(--color-gray-100)` (o blanco).
    -   *Razón*: El token actual `--color-text-card` es oscuro e ilegible sobre fondo oscuro.
2.  **Selector**: `.subtitle`
    -   Cambiar `color` a `var(--color-gray-400)`.
    -   *Razón*: Asegurar contraste suficiente para texto secundario.

### Fase 2: Input de Búsqueda (Material Design)
**Archivo**: `src/features/client/page/client-list/client-list.html`
1.  **Cambio**: Modificar `<mat-form-field appearance="fill" ...>` a `<mat-form-field appearance="outline" ...>`.
2.  **Razón**: Eliminar el fondo rosado pálido por defecto de "fill" que rompe el tema oscuro.

**Archivo**: `src/features/client/page/client-list/client-list.scss`
1.  **Agregar/Actualizar**: Estilos para `.search-field`.
    -   Forzar color de texto a claro (`var(--color-gray-100)`).
    -   Forzar color de borde a sutil (`var(--color-gray-600)`).
    -   Forzar color de icono a claro.

### Fase 3: Empty State (Estado Vacío)
**Archivo**: `src/features/client/page/client-list/client-list.scss`
1.  **Selector**: `.empty-icon-wrapper`
    -   Cambiar `background` a `var(--color-gray-700)`.
    -   Cambiar `span` color a `var(--color-gray-300)`.
2.  **Selector**: `.empty-state h2`
    -   Cambiar `color` a `var(--color-gray-100)`.
    -   *Razón*: Invertir escala de grises para legibilidad en fondo oscuro.

### Fase 4: Footer (Consistencia Global)
**Archivo**: `src/core/layout/footer/footer.scss`
1.  **Verificar**: `background-color` debe ser `var(--color-gray-900)` (más oscuro que el contenido).
2.  **Verificar**: Texto debe ser `var(--color-gray-400)`.

## Archivos a Modificar
- `src/features/client/page/client-list/client-list.scss`
- `src/features/client/page/client-list/client-list.html`
- `src/core/layout/footer/footer.scss` (Solo si es necesario ajustar el global)

## Validación Post-Implementación
Una vez aplicados los cambios, usar el agente **`@frontend-vision`** para validar:
1.  Invocar: `@frontend-vision Revisa la captura de la pantalla de Clientes y confirma que el título es legible y el buscador tiene estilo Outline.`
2.  Criterio de Éxito: Título blanco/gris claro visible, buscador sin fondo rosa, empty state legible.

## Notas para el Agente Ejecutor
- Seguir estrictamente los tokens de `.agents/context/design/tokens.md`.
- No introducir nuevos colores hardcodeados; usar variables CSS.
- El plan ya cuenta con la aprobación del usuario (Opción A).
