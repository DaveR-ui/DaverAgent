# Project Dictionary

Este archivo contiene definiciones de dominio, palabras clave y reglas de inferencia
para que el SDD Agent entienda el contexto del proyecto y pueda analizar prompts
con conocimiento del dominio.

---

## Project Metadata

| Campo | Valor |
|-------|-------|
| **Nombre** | [Nombre del proyecto] |
| **Dominio** | [Ej: matafuegos, gestion de recursos cloud, e-commerce] |
| **Deploy** | [Ej: Railway, AWS, GCP, Azure, on-premise] |
| **Arquitectura** | [Ej: monolito, microservicios, serverless] |

---

## Domain Glossary

Diccionario de términos del dominio. El prompt analyzer usa esto para inferir
significado cuando el usuario usa jerga, abreviaturas o nombres internos.

### Infraestructura y Deploy

| Término | Significado | Notas |
|---------|-------------|-------|
| railway | Plataforma de deploy Railway.app | PaaS, similar a Heroku |
| polvo | [Definir - término interno del proyecto] | |
| reverse proxy | Proxy inverso | Nginx, Traefik, Caddy, etc. |
| npd | Non-Production Deployment | Ambientes de testing/staging |
| prod | Production | Ambiente productivo |
| staging | Pre-producción | Ambiente de prueba antes de prod |
| dev | Development | Ambiente de desarrollo local |

### Recursos Cloud

| Término | Significado | Notas |
|---------|-------------|-------|
| gcp | Google Cloud Platform | |
| azure | Microsoft Azure | |
| aws | Amazon Web Services | |
| recurso | Entidad gestionada en cloud | VM, bucket, base de datos, etc. |
| contenedor | Container/Docker | Imagen ejecutable |

### Términos del Proyecto

| Término | Significado | Notas |
|---------|-------------|-------|
| [agregar] | [definición] | [contexto] |
| [agregar] | [definición] | [contexto] |

---

## Keyword Mapping

Mapeo de palabras clave del usuario a módulos y conceptos del sistema.

| Keyword del usuario | Módulo asociado | Tipo |
|---------------------|-----------------|------|
| matafuego | [modulo correspondiente] | entidad |
| extintor | [modulo correspondiente] | alias de matafuego |
| recurso | [modulo correspondiente] | entidad |
| ambiente | [modulo correspondiente] | configuracion |
| deploy | [modulo correspondiente] | proceso |
| modal | [componente UI] | frontend |
| editar | [modulo correspondiente] | accion |
| crear | [modulo correspondiente] | accion |
| eliminar | [modulo correspondiente] | accion |

---

## Inference Rules

Reglas que el prompt analyzer aplica para inferir contexto automáticamente.

### Reglas de Inferencia Simple (auto-resolver)

Estas inferencias el agente las resuelve sin preguntar:

1. **Si el usuario dice "railway"** → el deploy es en Railway.app
2. **Si el usuario menciona un recurso cloud** → buscar en el módulo de gestión de recursos
3. **Si el usuario dice "no anda" / "rompió" / "falla"** → clasificar como `bug`
4. **Si el usuario dice "agregar" / "poner" / "crear"** → clasificar como `task` o `feature-design`
5. **Si el usuario menciona "modal"** → el contexto incluye componentes UI frontend
6. **Si el usuario menciona ambiente sin especificar** → asumir que pregunta por todos los ambientes

### Reglas de Consulta (preguntar al usuario)

Estas situaciones requieren preguntar al usuario:

1. **Bug con comportamiento condicional** → preguntar: "¿Con qué tipo de recurso y ambiente ocurre?"
2. **Feature ambigua** → preguntar: "¿Qué ambiente(s) debe soportar?"
3. **Término no reconocido** → preguntar: "¿A qué te referís con [término]?"
4. **Múltiples interpretaciones válidas** → presentar opciones con impacto de cada una

---

## Question Rules

Lineamientos para formular preguntas al usuario.

### Reglas Obligatorias

1. **Concisión**: La pregunta debe ser directa, máximo 2-3 oraciones
2. **Declarar el problema**: Explicitar qué se necesita saber y por qué
3. **Una decisión por pregunta**: No combinar múltiples decisiones en una sola pregunta
4. **Mostrar impacto**: Presentar opciones en términos de consecuencia práctica
5. **Ofrecer mínimo cambio primero**: La opción menos invasiva siempre va primero

### Formato de Pregunta

```
[Contexto breve]. [Qué necesito saber].

Opciones:
- Opción A: [descripción] → [impacto práctico]
- Opción B: [descripción] → [impacto práctico]

¿Cuál preferís?
```

### Ejemplo Correcto

> El modal de edición tiene lógica diferente según el tipo de recurso y ambiente.
> Necesito saber con qué combinación estás probando para acotar el análisis.
>
> - GCP + prod: ruta de producción
> - Azure + npd: ruta de testing
>
> ¿Con qué recurso y ambiente te está fallando?

### Ejemplo Incorrecto

> ¿Podrías darme más detalles sobre qué tipo de recurso es, en qué ambiente
> está, qué versión usás, y si probaste con otros navegadores también?

---

## Complexity Indicators

Indicadores que ayudan al context-reductor a evaluar complejidad.

| Indicador | Complejidad | Descripción |
|-----------|-------------|-------------|
| Single file change | Baja | Un archivo, lógica aislada |
| Cross-module | Media | Afecta 2-3 módulos relacionados |
| Conditional branching | Media-Alta | Lógica que varía por ambiente/tipo |
| State management | Alta | Cambios en estado compartido |
| Multi-environment | Alta | Comportamiento diferente por ambiente |
| External integration | Alta | APIs externas, servicios third-party |
| Data migration | Muy Alta | Cambios en esquema o datos existentes |

---

## Hot Spot Patterns

Patrones conocidos que son "puntos calientes" propensos a bugs o complejidad.

| Patrón | Ubicación | Riesgo |
|--------|-----------|--------|
| Lógica condicional por ambiente | [archivo/componente] | Alto - fácil que se rompa un ambiente |
| Lógica condicional por tipo de recurso | [archivo/componente] | Alto - casos edge no cubiertos |
| Manejo de estados del modal | [archivo/componente] | Medio - estados inconsistentes |
| Integración con API externa | [archivo/componente] | Alto - timeouts, errores de red |

---

## Notes

- Este archivo es vivo: agregar términos, reglas y patrones a medida que se descubren
- Los términos entre corchetes `[...]` deben ser completados con información real del proyecto
- El prompt analyzer lee este archivo antes de procesar cualquier prompt
