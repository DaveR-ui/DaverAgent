---
last_updated: 2026-05-30
description: diagnostico y resolucion de dependencia circular entre CoreModule y ProjectDetailsPageComponent que causaba errores masivos en Karma
tags: [troubleshooting, circular-dependency, core-module, karma, ngmodule, project-details-page, angular-21]
---

# Circular Dependency: CoreModule ↔ ProjectDetailsPageComponent

## Resumen Ejecutivo

**Fecha**: 2026-05-30  
**Impacto**: 50+ specs fallaban con "Error loading" en Karma  
**Causa raíz**: Dependencia circular entre `CoreModule` y `ProjectDetailsPageComponent`  
**Solución**: Extracción de interfaces compartidas y reorganización de imports  
**Resultado**: 5889 tests SUCCESS, 0 FAILED

---

## Síntomas Observados

### Errores en Karma
Al ejecutar `npm test`, Karma reportaba múltiples errores de carga:

```text
Error during loading: Uncaught Error loading /base/spec-app-core-components-acpa-multiple-acpa-multiple.component.spec.js
Error during loading: Uncaught Error loading /base/spec-app-core-components-add-contact-add-contact.component.spec.js
Error during loading: Uncaught Error loading /base/spec-app-core-components-authviews-authviews.component.spec.js
... (50+ errores similares)
```

### Error Específico en Browser Console
El error raíz aparecía en la consola del navegador:

```text
TypeError: Cannot read properties of undefined (reading 'ngModule')
    at isModuleWithProviders (_debug_node-chunk.mjs:7492:16)
    at expandModuleWithProviders (_debug_node-chunk.mjs:17633:7)
    at Array.map (<anonymous>)
    at CoreModule2.get (_debug_node-chunk.mjs:17348:84)
    at getNgModuleDef (_effect-chunk2.mjs:478:10)
    at isNgModule (_debug_node-chunk.mjs:7495:12)
    at transitiveScopesFor (_debug_node-chunk.mjs:17593:7)
    at setScopeOnDeclaredComponents (_debug_node-chunk.mjs:17574:28)
    at flushModuleScopingQueueAsMuchAsPossible (_debug_node-chunk.mjs:17306:11)
    at _TestBedImpl.checkGlobalCompilationFinished (testing.mjs:1503:7)
```

### Comportamiento Engañoso
- Los specs **pasaban individualmente** pero fallaban en ejecución combinada
- El error aparecía en specs **no relacionados** con `ProjectDetailsPageComponent`
- Karma continuaba ejecutando tests pero reportaba "problemas durante la carga"

---

## Análisis de Causa Raíz

### Diagrama de Dependencia Circular

```
┌───────────────────────────────────────────────────────────────────┐
│                         CoreModule                                │
│  (src/app/core/core.module.ts)                                    │
│                                                                   │
│  imports: [                                                       │
│    CloudResourcesComponent,        ───────────────────────┐       │
│    ContactsListComponent,          ───────────────────┐   │       │
│    RoleIdGridViewComponent,        ───────────────┐   │   │       │
│    ContactsByTicketAccordionComponent,   ─────┐   │   │   │       │
│    ...                                        │   │   │   │       │
│  ]                                            │   │   │   │       │
└───────────────────────────────────────────────┼───┼───┼───┼───────┘
                                                │   │   │   │
                                                ▼   ▼   ▼   ▼
┌─────────────────────────────────────────────────────────────────┐
│              project-details-page.component.ts                  │
│                                                                 │
│  // Exporta interfaces usadas por componentes de CoreModule     │
│  export interface IContactTable { ... }                         │
│  export { ProjectView } from './project-view.enum';             │
│                                                                 │
│  @Component({                                                   │
│    imports: [                                                   │
│      CoreModule,  ◄────────────────────────────────────┐        │
│      CloudResourcesComponent,                          │        │
│      ...                                               │        │
│    ]                                                   │        │
│  })                                                    │        │
│  export class ProjectDetailsPageComponent { ... }      │        │
└────────────────────────────────────────────────────────┼────────┘
                                                         │
                                                         │
┌────────────────────────────────────────────────────────┼────────┐
│                    CIRCULAR DEPENDENCY                 │        │
│                                                        │        │
│  1. CoreModule comienza a inicializarse                │        │
│  2. Carga CloudResourcesComponent                      │        │
│  3. CloudResourcesComponent importa ProjectView        │        │
│     desde project-details-page.component.ts            │        │
│  4. project-details-page.component.ts intenta          │        │
│     importar CoreModule                                │        │
│  5. CoreModule aún no está inicializado → undefined    │        │
│  6. ProjectDetailsPageComponent almacena undefined     │        │
│     en su metadata de imports                          │        │
│  7. Angular TestBed falla al procesar metadata         │        │
│     corrupta durante compilación global                │        │
└─────────────────────────────────────────────────────────────────┘
```

### Cadenas de Dependencia Problemáticas

#### Cadena 1: CloudResourcesComponent
```typescript
// src/app/core/components/cloud-resources/cloud-resources.component.ts
import { ProjectView } from '@core/pages/project-details-page/project-details-page.component';
```

#### Cadena 2: ContactsListComponent
```typescript
// src/app/core/components/contacts-list/contacts-list.component.ts
import { IContactTable } from '@core/pages/project-details-page/project-details-page.component';
```

#### Cadena 3: RoleIdGridViewComponent
```typescript
// src/app/core/components/role-id-grid-view/role-id-grid-view.component.ts
import { IContactTable } from '@core/pages/project-details-page/project-details-page.component';
```

#### Cadena 4: ContactsByTicketAccordionComponent
```typescript
// src/app/core/components/contacts-by-ticket-accordion/contacts-by-ticket-accordion.component.ts
import { IContactTable } from '@core/pages/project-details-page/project-details-page.component';
```

### Problema Adicional: DropdownValuesEffects Duplicado

En `src/app/app.config.ts`, `DropdownValuesEffects` estaba registrado dos veces:

```typescript
const appEffects = [
  UserInfoEffects,
  LaunchdarklyFlagsEffects,
  // ...
  DropdownValuesEffects,      // Línea 79 - Primera aparición
  // ...
  ProjectCloudEffects,
  DropdownValuesEffects,      // Línea 109 - DUPLICADO
  CloudResourcesEffects,
  // ...
];
```

---

## Solución Aplicada

### Estrategia General
1. **Extraer interfaces compartidas** a archivos de dominio independientes
2. **Importar desde enum directo** en lugar del componente que causa el ciclo
3. **Eliminar duplicados** en configuración de effects

### Cambio 1: Crear `contact-table.domain.ts`

**Archivo nuevo**: `src/app/core/models/contact-table.domain.ts`

```typescript
import { IFormDropdown } from '@core/models/dropdown-values.domain';
import { Employee } from '@core/models/employee.domain';

export interface IContactTable {
  employee: Employee;
  role: IFormDropdown;
  id: string;
  notification?: boolean;
  enaEngNumber?: string;
  enaEngCreatedOn?: string;
  contactId?: string;
}
```

### Cambio 2: Actualizar `project-details-page.component.ts`

**Antes**:
```typescript
// ... imports ...

export class ProjectDetailsPageComponent { ... }

export interface IContactTable {
  employee: Employee;
  role: IFormDropdown;
  id: string;
  notification?: boolean;
  enaEngNumber?: string;
  enaEngCreatedOn?: string;
  contactId?: string;
}

import { ProjectView } from './project-view.enum';
export { ProjectView } from './project-view.enum';
```

**Después**:
```typescript
// ... imports ...
import { IContactTable } from '@core/models/contact-table.domain';
export { IContactTable } from '@core/models/contact-table.domain';
import { ProjectView } from './project-view.enum';
export { ProjectView } from './project-view.enum';

export class ProjectDetailsPageComponent { ... }
```

### Cambio 3: Actualizar Imports en Componentes de CoreModule

**Archivos modificados** (5 componentes):

```typescript
// ANTES (causa dependencia circular)
import { IContactTable } from '@core/pages/project-details-page/project-details-page.component';

// DESPUÉS (rompe el ciclo)
import { IContactTable } from '@core/models/contact-table.domain';
```

**Lista de archivos**:
- `src/app/core/components/role-id-grid-view/role-id-grid-view.component.ts`
- `src/app/core/components/role-id-grid-view/role-id-grid-view.component.spec.ts`
- `src/app/core/components/contacts-list/contacts-list.component.ts`
- `src/app/core/components/contacts-by-ticket-accordion/contacts-by-ticket-accordion.component.ts`
- `src/app/core/components/contacts-by-ticket-accordion/contacts-by-ticket-accordion.component.spec.ts`

### Cambio 4: Actualizar Imports de ProjectView

**Archivos modificados** (10+ archivos):

```typescript
// ANTES (causa dependencia circular)
import { ProjectView } from '@core/pages/project-details-page/project-details-page.component';

// DESPUÉS (importa directo del enum)
import { ProjectView } from '@core/pages/project-details-page/project-view.enum';
```

**Lista de archivos**:
- `src/app/core/components/cloud-resources/cloud-resources.component.ts`
- `src/app/core/components/cloud-management/cloud-management.component.ts`
- `src/app/core/components/resource-management/resource-management.component.ts`
- `src/app/core/components/resource-management-list-grid/resource-management-list-grid.component.ts`
- `src/app/core/components/tracking-list/tracking-list.component.ts`
- `src/app/core/models/modal.domain.ts`
- `src/app/core/models/navigation-data.domain.ts`
- `src/app/core/services/tracking-list.service.ts`
- `src/app/core/services/project-cloud.service.ts`
- `src/app/core/services/project.service.ts`
- `src/app/core/services/project-gcp-list.service.ts`
- `src/app/core/services/project-azure-list.service.ts`
- `src/app/state/cloud-resources/cloud-resources.actions.ts`
- `src/app/state/tracking-list/tracking-list.actions.ts`
- `src/app/state/project-cloud/project-cloud.actions.ts`
- `src/app/state/navigation/navigation.reducer.ts`
- `src/app/state/project-resources/project-resources.actions.ts`
- `src/app/state/project-gcp-list/project-gcp-list.actions.ts`
- `src/app/state/project-azure-list/project-azure-list.actions.ts`

### Cambio 5: Eliminar DropdownValuesEffects Duplicado

**Archivo**: `src/app/app.config.ts`

**Antes**:
```typescript
const appEffects = [
  UserInfoEffects,
  LaunchdarklyFlagsEffects,
  UsersPicturesEffects,
  EmployeeSearchEffects,
  DropdownValuesEffects,      // Línea 79
  DS_DropdownValuesEffects,
  // ...
  ProjectCloudEffects,
  DropdownValuesEffects,      // Línea 109 - ELIMINAR
  CloudResourcesEffects,
  // ...
];
```

**Después**:
```typescript
const appEffects = [
  UserInfoEffects,
  LaunchdarklyFlagsEffects,
  UsersPicturesEffects,
  EmployeeSearchEffects,
  DropdownValuesEffects,      // Línea 79 - ÚNICO
  DS_DropdownValuesEffects,
  // ...
  ProjectCloudEffects,
  CloudResourcesEffects,      // Sin duplicado
  // ...
];
```

---

## Archivos Modificados

### Archivos Nuevos (1)
- `src/app/core/models/contact-table.domain.ts`

### Archivos Modificados (25+)
- `src/app/app.config.ts`
- `src/app/core/pages/project-details-page/project-details-page.component.ts`
- `src/app/core/components/role-id-grid-view/role-id-grid-view.component.ts`
- `src/app/core/components/role-id-grid-view/role-id-grid-view.component.spec.ts`
- `src/app/core/components/contacts-list/contacts-list.component.ts`
- `src/app/core/components/contacts-by-ticket-accordion/contacts-by-ticket-accordion.component.ts`
- `src/app/core/components/contacts-by-ticket-accordion/contacts-by-ticket-accordion.component.spec.ts`
- `src/app/core/components/cloud-resources/cloud-resources.component.ts`
- `src/app/core/components/cloud-management/cloud-management.component.ts`
- `src/app/core/components/resource-management/resource-management.component.ts`
- `src/app/core/components/resource-management-list-grid/resource-management-list-grid.component.ts`
- `src/app/core/components/tracking-list/tracking-list.component.ts`
- `src/app/core/models/modal.domain.ts`
- `src/app/core/models/navigation-data.domain.ts`
- `src/app/core/services/tracking-list.service.ts`
- `src/app/core/services/project-cloud.service.ts`
- `src/app/core/services/project.service.ts`
- `src/app/core/services/project-gcp-list.service.ts`
- `src/app/core/services/project-azure-list.service.ts`
- `src/app/state/cloud-resources/cloud-resources.actions.ts`
- `src/app/state/tracking-list/tracking-list.actions.ts`
- `src/app/state/project-cloud/project-cloud.actions.ts`
- `src/app/state/navigation/navigation.reducer.ts`
- `src/app/state/project-resources/project-resources.actions.ts`
- `src/app/state/project-gcp-list/project-gcp-list.actions.ts`
- `src/app/state/project-azure-list/project-azure-list.actions.ts`

---

## Verificación

### Comando de Prueba
```bash
npm test -- --watch=false --browsers=ChromeHeadless --code-coverage=false
```

### Resultado Esperado
```text
Chrome Headless 148.0.0.0 (Windows 10): Executed 5889 of 5932 (skipped 43) SUCCESS
TOTAL: 5889 SUCCESS
```

### Resultado Antes del Fix
```text
Error during loading: Uncaught Error loading /base/spec-app-core-components-*.spec.js
... (50+ errores)
Chrome Headless: Executed 5473 of 5932 (1 FAILED) (skipped 34)
```

---

## Lecciones Aprendidas

### 1. Interfaces en Archivos de Componente
**Anti-patrón**: Definir interfaces compartidas dentro de archivos de componente que son importados por otros módulos.

**Problema**: Cuando el componente A exporta una interfaz y el módulo B importa esa interfaz, se crea una dependencia hacia el archivo del componente, no solo hacia la interfaz.

**Solución**: Extraer interfaces compartidas a archivos de dominio independientes (`*.domain.ts`).

### 2. Re-exportaciones Convenientes
**Anti-patrón**: Re-exportar enums/interfaces desde componentes para "facilitar" imports.

```typescript
// project-details-page.component.ts
export { ProjectView } from './project-view.enum';  // ❌ Crea dependencia innecesaria
```

**Problema**: Otros archivos importan desde el componente en lugar del enum directo, creando dependencias circulares.

**Solución**: Importar siempre desde el archivo fuente original.

### 3. Detección Temprana de Dependencias Circulares
**Herramientas recomendadas**:
- `madge`: `npx madge --circular src/`
- `dpdm`: `npx dpdm --no-warning --no-tree --circular src/`
- ESLint plugin: `eslint-plugin-import` con regla `import/no-cycle`

### 4. Síntomas de Dependencias Circulares en Angular
- Specs pasan individualmente pero fallan en conjunto
- Errores `Cannot read properties of undefined (reading 'ngModule')`
- Errores `Cannot read properties of undefined (reading 'ɵcmp')`
- Karma reporta "Error loading" en múltiples specs no relacionados

### 5. Orden de Inicialización de Módulos
Angular inicializa módulos en orden de dependencia. Si el Módulo A depende del Módulo B, y el Módulo B depende del Módulo A, uno de ellos estará `undefined` durante la inicialización del otro.

---

## Prevención

### Reglas para Nuevos Desarrollos

1. **Nunca definir interfaces compartidas en archivos de componente**
   - Usar archivos `*.domain.ts` o `*.model.ts`

2. **Nunca re-exportar desde componentes**
   - Importar siempre desde el archivo fuente

3. **Validar con herramientas de análisis estático**
   - Ejecutar `madge --circular` antes de merge

4. **Revisar imports en Code Review**
   - Verificar que no se importen componentes completos solo para usar tipos

5. **Mantener enums y tipos en archivos independientes**
   - `project-view.enum.ts` ✅
   - `contact-table.domain.ts` ✅

---

## Referencias

- [Common Errors - ngModule undefined](common-errors.md#typeerror-cannot-read-properties-of-undefined-reading-ngmodule)
- [TestBed Cross-Suite Flaky Tests](testbed-cross-suite-flaky-tests.md)
- [Angular Module Loading Order](https://angular.dev/guide/ngmodules)
- [Circular Dependencies in JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules#creating_module_cycles)

---

## Historial de Cambios

| Fecha | Autor | Cambio |
|-------|-------|--------|
| 2026-05-30 | AI Agent | Documento inicial con análisis completo y solución |
