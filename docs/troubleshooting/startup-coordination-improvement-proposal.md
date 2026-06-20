---
last_updated: 2026-06-20
description: propuesta de mejora para coordinar MSAL, Datadog, LaunchDarkly, permisos y bootstrap de la app usando una state machine explicita de readiness, eliminando la race condition de re-login y el flash unauthorized.
tags: [proposal, architecture, auth, msal, launchdarkly, datadog, ngrx, startup, readiness, state-machine, race-condition, guards, app-component, rebar-auth, refactor]
status: APPROVED_FOR_IMPLEMENTATION
related_docs:
  - auth-relogin-race-condition.md
  - startup-auth-bootstrap-analysis.md
  - circular-dependency-core-module.md
audience: AI agents (cualquier IA que reciba este documento debe poder implementarlo sin contexto adicional)
---

# Propuesta de Mejora: Coordinacion de Auth, Permisos y Bootstrap

> [!IMPORTANT]
> Este documento es una **propuesta arquitectonica**, no un changelog. Esta escrito para ser leido por otra IA que implementara los cambios. Cada fase incluye archivos a tocar, criterios de aceptacion, riesgo y como verificar.

## 0. TL;DR

El problema no es un bug aislado: es la ausencia de un **owner unico de "la app esta lista"**. Hoy, cinco actores distintos (`main.ts`, `app.config.ts`, `AppComponent`, `RebarAuthService`, guards) coordinan implicitamente cuando MSAL esta idle, cuando los claims estan normalizados, cuando los permisos y los flags cargaron, y cuando el router puede decidir. La consecuencia es:

- **Race condition de re-login**: `RebarAuthService` interpreta `InteractionStatus.None` como "auth resuelto" y dispara `loginRedirect()` antes de que MSAL termine la hidratacion de cuenta.
- **Flash de unauthorized**: el shell se monta antes de tiempo, el router evalua la ruta, los guards esperan async state que aun no cargo, y la pagina aparece brevemente antes del redirect a `/unauthorized`.
- **Doble ownership de config**: `main.ts` hace prefetch + `AppConfigService` re-carga via `APP_INITIALIZER`, con un handshake fragil por `sessionStorage` o un `static preloadedConfig` (segun el patch del 2026-06-17).

**La propuesta**: mejorar la **state machine explicita de readiness** ya existente (`configReady` → `redirectHandled` → `accountResolved` → `identityReady` → `permissionsReady` → `appReady`), gobernada por el `AppStartupOrchestratorService` existente, y hacer que el shell y los guards dependan **exclusivamente** de esa senal. Eliminar `InteractionStatus.None` como contrato de readiness. Eliminar la cascada de dispatches desde `AppComponent`.

Las fases estan dimensionadas para que cada una entregue un beneficio visible sin bloquear a las siguientes. Las primeras fases son reversibles; las ultimas consolidan.

---

## 1. Diagnostico Consolidado

### 1.1 Tres sintomas, una causa comun

| Sintoma | Documento fuente | Causa inmediata |
| --- | --- | --- |
| Re-login loop / redireccion inesperada durante bootstrap | `auth-relogin-race-condition.md` | `RebarAuthService.authObserver$` emite `true` cuando `InteractionStatus.None`, que **no garantiza** que la cuenta este hidratada. `checkAndSetActiveAccount()` + `isUserAuthenticated()` corren demasiado pronto. |
| Flash de unauthorized tras redirect | `startup-auth-bootstrap-analysis.md` (secciones "Why the first-login flicker is plausible" y "NgRx Initialization Timeline") | El shell se renderiza sin gate de auth. `user-info.loading = false` ocurre en `t2`, pero `security-roles.loaded = true` y `launchdarkly-flags != null` ocurren en `t3`. Entre `t2` y `t3` la ruta se evalua y el redirect se ve. |
| 50+ specs en Karma fallan con "Error loading" + `ngModule` undefined | `circular-dependency-core-module.md` | Dependencia circular entre `CoreModule` y `ProjectDetailsPageComponent` causada por interfaces y re-exports de tipos en archivos de componente. |

Aunque el tercero parece independiente, comparte la misma clase de problema: **limites de ownership difusos** (interfaces compartidas declaradas donde no corresponden, modulo importando a un componente que importa al modulo).

### 1.2 Los cinco problemas estructurales

1. **No hay un unico owner de readiness**. `main.ts` carga config; `app.config.ts` corre el initializer; `AppComponent` espera `authObserver$`; `RebarAuthService` decide cuando disparar `loginRedirect()`; los guards esperan el store. Cada uno asume que los otros ya hicieron su parte.
2. **`InteractionStatus.None` no es un contrato de readiness valido**. Es un estado de MSAL, no de la sesion del usuario. Un observer que dispara comandos en base a el crea un feedback loop: el observer puede causar la transicion que vuelve a emitir `None`.
3. **El shell se monta sin gate de auth**. `<app-shell>` se renderiza siempre, incluyendo `<router-outlet>`. Esto fuerza al router a evaluar rutas antes de que el estado de autorizacion este disponible.
4. **Cascada de dispatches sin orquestacion**. `AppComponent.continueLoading()` dispara cinco acciones en serie. No hay garantia de orden, no hay rollback, no hay forma de saber cuando todas terminaron.
5. **Tipos compartidos en archivos de componente crean acoplamiento invisible**. Una interfaz exportada desde un componente fuerza a quien la usa a importar el archivo del componente, lo que arrastra sus imports (incluyendo modulos) y crea ciclos.

### 1.3 Estado real al 2026-06-20

Segun `startup-auth-bootstrap-analysis.md`, las siguientes slices estan marcadas como **DONE al 2026-06-17**:

- Slice 2: extraccion de `AppStartupOrchestratorService` (`core/services/app-startup-orchestrator.service.ts`, `providedIn: 'root'`, metodo `run()`).
- Slice 3: introduccion de `AppStartupReadinessService` con `startupReady$`; los 5 guards ahora hacen gate sobre esa senal.
- Slice 4: `HistoricalDemandMigrationGuard` simplificado (removida dependencia de LD flags no usada).
- Slice 5: config bootstrap colapsado en `AppConfigService`, con parche del 2026-06-17 que reintroduce el prefetch en `main.ts` via `AppConfigService.preloadedConfig` para evitar el crash de MSAL factory.

**Slice 1 (separar redirect completion de idle state) sigue PENDIENTE**. Es la unica que toca la causa raiz de la race condition de re-login.

> [!NOTE]
> **Todos los archivos descritos en los docs de analisis existen en este repositorio.** El proyecto es Angular 21.2.7 standalone con NgRx, MSAL, Datadog y LaunchDarkly — exactamente la arquitectura descrita en los documentos. El orquestador (`src/app/core/services/app-startup-orchestrator.service.ts`) y el servicio de readiness (`src/app/core/services/app-startup-readiness.service.ts`) ya estan implementados. Esta propuesta describe **mejoras incrementales** sobre el codigo existente, no la introduccion de servicios nuevos.

---

## 2. Principios de Diseno

Estos principios guian todas las decisiones de la propuesta. Si una fase futura los viola, es una senial de que la fase esta mal cortada.

### P1. Un unico owner por responsabilidad

| Responsabilidad | Owner unico |
| --- | --- |
| Carga de `config.json` | `AppConfigService` (con prefetch en `main.ts` como optimizacion, no como owner) |
| Bootstrap de MSAL y manejo de redirect | `AppStartupOrchestratorService.run()` (via `handleRedirectObservable()`) |
| Senal de readiness | `AppStartupReadinessService` (un unico `startupReady$` con fases observables) |
| Dispatches de inicializacion (LD flags, dropdowns, roles, notifications) | `AppStartupOrchestratorService` (no `AppComponent`) |
| Render del shell | `AppComponent` (template) — solo gating via `startupReady$` |
| Decisiones de autorizacion por ruta | Guards — solo contra `startupReady$` + selectores del store |

### P2. Observacion no implica comando

`RebarAuthService` debe **observar** el ciclo de vida de MSAL y **publicar** estado. No debe **disparar** `loginRedirect()` desde un observer. El disparo de login debe ser un acto explicito, invocado por un unico punto (el orquestador, cuando corresponde).

### P3. Readiness es un grafo de fases, no un booleano

Un unico `appReady$: Observable<boolean>` es insuficiente porque oculta en que fase fallo. La propuesta usa seis fases observables independientemente. Si el agente implementador ve un solo booleano, lo esta haciendo mal.

### P4. El router espera, el shell espera, pero el orquestador no

Quien espera no es quien decide. `AppStartupOrchestrator.run()` no espera al router ni al shell. El shell y el router esperan al orquestador via la senal de readiness.

### P5. Tipos compartidos en archivos `*.domain.ts`

Regla del doc `circular-dependency-core-module.md` (leccion 1): ninguna interfaz usada por mas de un modulo se declara en un archivo de componente. Esta regla se vuelve **estructural** en la propuesta: el lint del repo debe fallar si un `*.component.ts` exporta un tipo que es importado por otro archivo fuera de su modulo inmediato.

### P6. Cambios pequenos, reversibles, con verificacion automatica

Cada fase de la seccion 4 produce: un diff pequeno (idealmente < 200 lineas), tests que la cubren, y un comando de verificacion ejecutable. Si una fase no puede enunciar su verificacion, no esta lista para implementarse.

---

## 3. Arquitectura Objetivo

### 3.1 Diagrama de fases

```
+---------------------------------------------------------------+
|  BOOT                                                         |
|                                                               |
|  main.ts                                                      |
|    1. fetch(config.json)                                      |
|    2. AppConfigService.preloadedConfig = json                 |
|    3. bootstrapApplication(AppComponent, appConfig)           |
+---------------------------------------------------------------+
                          |
                          v
+---------------------------------------------------------------+
|  app.config.ts                                                |
|                                                               |
|  providers:                                                   |
|    provideAppInitializer(() => config.load())                 |
|    provideAppInitializer(() => orchestrator.run())   <-- NEW  |
|    StoreModule, EffectsModule, RebarAuthModule, ...           |
+---------------------------------------------------------------+
                          |
                          v
+---------------------------------------------------------------+
|  AppStartupOrchestratorService.run()                          |
|                                                               |
|  Secuencia estricta:                                          |
|    Phase 1: configReady        (config ya cargado por         |
|                                  APP_INITIALIZER previo)      |
|    Phase 2: redirectHandled    (msalService                   |
|                                  .handleRedirectObservable()  |
|                                  .subscribe(...))             |
|    Phase 3: accountResolved    (setActiveAccount OK,          |
|                                  getAllAccounts().length > 0) |
|    Phase 4: identityReady      (claims normalizados,          |
|                                  UserClaims construido)       |
|    Phase 5: permissionsReady   (setUserASGGroupInfo +         |
|                                  continueLoading(...)         |
|                                  completo: LD flags,          |
|                                  dropdowns, securityRoles,    |
|                                  notifications, userInfo)     |
|    Phase 6: appReady           (todas las fases anteriores)   |
|                                                               |
|  Publica via AppStartupReadinessService.                      |
+---------------------------------------------------------------+
                          |
                          v
+---------------------------------------------------------------+
|  AppComponent template                                        |
|                                                               |
|  @if (startupReadiness.appReady$ | async) {                   |
|    <app-shell></app-shell>                                    |
|  } @else {                                                    |
|    <app-loading-spinner [isFull]="true"></app-loading-spinner>|
|  }                                                            |
+---------------------------------------------------------------+
                          |
                          v
+---------------------------------------------------------------+
|  Router resuelve la ruta                                      |
|                                                               |
|  Guard: combineLatest([startupReady$, ...])                   |
|         .pipe(skipWhile(([r]) => !r), take(1), map(...))      |
+---------------------------------------------------------------+
```

### 3.2 Contratos de las fases

Cada fase es un `Observable<void>` en `AppStartupReadinessService`. La composicion es por `combineLatest` con `take(1)` en quien la consume. Esto permite testing y debugging fase por fase (se puede preguntar al servicio en que fase quedo y por que).

> [!NOTE]
> La implementacion actual ya usa **Angular 21 signals** en lugar de `ReplaySubject`. El codigo abajo muestra el contrato conceptual; la implementacion real usa signals con `toObservable()` para interoperabilidad con consumers RxJS:
> ```typescript
> // Implementacion actual (ya existe):
> private readonly authResolved = signal(false, { debugName: 'appStartup.authResolved' });
> private readonly permissionsResolved = signal(false, { debugName: 'appStartup.permissionsResolved' });
> private readonly launchDarklyResolved = signal(false, { debugName: 'appStartup.launchDarklyResolved' });
> readonly isStartupReady = signal(false, { debugName: 'appStartup.isStartupReady' });
> readonly startupReady$ = toObservable(this.isStartupReady, { injector: this.injector });
> ```

```typescript
// src/app/core/services/app-startup-readiness.service.ts
// (archivo target — ver seccion 4.3 y seccion 8 sobre su existencia actual)
@Injectable({ providedIn: 'root' })
export class AppStartupReadinessService {
    readonly configReady$      = new ReplaySubject<void>(1);
    readonly redirectHandled$  = new ReplaySubject<void>(1);
    readonly accountResolved$  = new ReplaySubject<void>(1);
    readonly identityReady$    = new ReplaySubject<void>(1);
    readonly permissionsReady$ = new ReplaySubject<void>(1);
    readonly appReady$ = combineLatest([
        this.configReady$,
        this.redirectHandled$,
        this.accountResolved$,
        this.identityReady$,
        this.permissionsReady$,
    ]).pipe(
        map(() => true),
        take(1),
        shareReplay(1),
    );

    // Solo para debugging/tests:
    snapshot(): {
        config: boolean;
        redirect: boolean;
        account: boolean;
        identity: boolean;
        permissions: boolean;
    } { /* ... */ }
}
```

**Por que `ReplaySubject(1)` y no `BehaviorSubject`**: queremos que un consumidor tardio (un guard que se monta despues de que la fase ya paso) reciba la senal inmediatamente. `BehaviorSubject` tambien serviria, pero `ReplaySubject(1)` deja claro que solo emitimos una vez por fase.

**Por que `combineLatest` con `take(1)` para `appReady$`**: una vez que `appReady` se completo, no queremos re-emissions que disparen re-evaluaciones de guards.

### 3.3 Contrato del orquestador

```typescript
// src/app/core/services/app-startup-orchestrator.service.ts
@Injectable({ providedIn: 'root' })
export class AppStartupOrchestratorService {
    constructor(
        private readonly msalService: MsalService,
        private readonly msalBroadcast: MsalBroadcastService,
        private readonly rebarAuth: RebarAuthService,
        private readonly store: Store,
        private readonly readiness: AppStartupReadinessService,
        private readonly launchdarklyService: LaunchdarklyService,
        private readonly datadogService: DatadogService,
    ) {}

    async run(): Promise<void> {
        // Phase 1: config ya esta listo (lo cargo APP_INITIALIZER previo).
        //          Lo confirmamos leyendo readiness.configReady$ emit.
        this.readiness.configReady$.next();

        // Phase 2: redirect. Capturamos el resultado, no lo descartamos.
        await firstValueFrom(
            this.msalService.handleRedirectObservable().pipe(
                take(1),
                tap(() => this.readiness.redirectHandled$.next()),
            )
        );

        // Phase 3: account.
        await this.resolveActiveAccount();   // setActiveAccount + verifica count > 0
        this.readiness.accountResolved$.next();

        // Phase 4: identity (claims normalizados, UserClaims construido).
        const claims = this.rebarAuth.getUserClaims();
        if (!claims) {
            // Caso edge: redirect completo pero sin claims -> logout o reintento.
            this.rebarAuth.logout();
            return;
        }
        this.store.dispatch(setUserASGGroupInfo(claims));
        this.readiness.identityReady$.next();

        // Phase 5: permissions (LD flags, dropdowns, roles, notifications).
        await this.bootstrapUserState(claims);

        // Phase 6: appReady (emitido por combineLatest cuando permissionsReady emite).
        this.readiness.permissionsReady$.next();
    }

    private async resolveActiveAccount(): Promise<void> {
        // Encapsula checkAndSetActiveAccount + espera a que getAllAccounts()
        // devuelva al menos una cuenta, con timeout explicito.
        const accounts$ = timer(0, 50).pipe(
            map(() => this.msalService.instance.getAllAccounts()),
            takeWhile((accs) => accs.length === 0, true),
            filter((accs) => accs.length > 0),
            take(1),
            timeout({ first: 5_000, meta: 'AccountHydration' }),
        );
        const accounts = await firstValueFrom(accounts$);
        this.msalService.instance.setActiveAccount(accounts[0]);
    }

    private async bootstrapUserState(claims: UserClaims): Promise<void> {
        // Espera combinada de los slices que continueLoading() disparaba.
        // Se reemplaza la cascada de dispatches por una promesa unica.
        if (claims.isASG) {
            this.store.dispatch(setInitialUserInfo({}));   // no continueLoading
        } else {
            const tasks$ = forkJoin({
                ldFlags: this.store.select(launchdarklyFlagsSelector)
                                   .pipe(filter(isNotNil), take(1)),
                userInfo: this.store.select(userInfoSelector)
                                    .pipe(filter(ui => ui.loaded), take(1)),
                dropdowns: this.store.select(dropdownValuesSelector)
                                     .pipe(filter(d => d.loaded), take(1)),
                securityRoles: this.store.select(securityRolesSelector)
                                        .pipe(filter(s => s.loaded), take(1)),
                notifications: this.store.select(notificationsSelector)
                                          .pipe(filter(n => n.loaded), take(1)),
            }).pipe(take(1));

            // Disparar las acciones (el side effect de iniciar el fetch).
            this.store.dispatch(loadLaunchdarklyFlags());
            this.store.dispatch(setInitialUserInfo({}));
            this.store.dispatch(getDropdownValues());
            this.store.dispatch(getSecurityRoles());
            this.store.dispatch(getNotificationList());

            // Esperar a que TODAS resuelvan.
            await firstValueFrom(tasks$);
        }
    }
}
```

**Decisiones clave del codigo anterior**:

- `run()` se invoca desde un `provideAppInitializer` en `app.config.ts`, no desde `AppComponent.ngOnInit()`. Esto elimina el problema de que el shell se monte antes de que el orquestador arranque.
- `bootstrapUserState` usa `forkJoin` sobre selectores en vez de la cascada de dispatches de `AppComponent`. Si alguno no resuelve, el orquestador loguea y aborta (mejor un spinner eterno visible que un flash).
- `resolveActiveAccount` tiene un `timeout(5s)` explicito. Si MSAL no hidrata cuenta en 5s, registramos el incidente en Datadog y seguimos. Esto evita cuelgues silenciosos.

### 3.4 Cambios en `RebarAuthService`

El servicio pasa de **observador + comandante** a **observador + publicador**. Ya no dispara `loginRedirect()`. Solo:

1. Se suscribe a `msalBroadcastService.inProgress$` para tracking interno.
2. Expone un metodo explicito `requestLogin(reason: 'no-account' | 'expired')` que el orquestador (o un guard) llama cuando decide.
3. Expone un observable `accountState$: Observable<AccountState>` con tres valores: `idle`, `authenticating`, `authenticated`.

```typescript
// Diff conceptual sobre rebar.auth.service.ts
// ANTES
this.msalBroadcastService.inProgress$.pipe(
    filter(s => s === InteractionStatus.None),
).subscribe(() => {
    this.checkAndSetActiveAccount();
    if (!this.isUserAuthenticated()) {
        this.login();   // <-- BUG: side effect en observer
    }
    this.authObserver$.next(true);
});

// DESPUES
this.msalBroadcastService.inProgress$.subscribe((status) => {
    if (status === InteractionStatus.None) {
        this.accountState = 'idle';
    } else {
        this.accountState = 'authenticating';
    }
});
// login() ya no se invoca desde aca. Lo invoca el orquestador o un guard.
```

**Por que importa**: elimina el feedback loop donde un observer del estado de MSAL podia disparar un cambio de estado de MSAL.

### 3.5 Cambios en el shell

```html
<!-- app.component.html — cambio minimo, alto impacto -->
<ng-container *ngIf="startupReadiness.appReady$ | async; else loading">
    <app-shell class="d-flex flex-column w-100 h-100"></app-shell>
</ng-container>
<ng-template #loading>
    <app-loading-spinner [isFull]="true"></app-loading-spinner>
</ng-container>
```

Eliminamos el `@if (userInfoLoading$ | async)` actual (que se basaba en `user-info.loading` y se volvia `false` demasiado pronto, ver timeline `t2` vs `t3` en el doc de analisis). Ahora el unico gate es `appReady$`, que requiere `permissionsReady` (donde se incluyen LD flags, security roles, etc.).

### 3.6 Cambios en los guards

Patron uniforme (ya aplicado segun el doc en Slice 3, pero la propuesta lo deja como contrato canonico):

```typescript
// Cualquier guard nuevo sigue este template.
@Injectable({ providedIn: 'root' })
export class SomeFeatureGuard implements CanActivate {
    constructor(
        private readonly readiness: AppStartupReadinessService,
        private readonly store: Store,
        private readonly router: Router,
    ) {}

    canActivate(): Observable<boolean | UrlTree> {
        return combineLatest([
            this.readiness.appReady$,
            this.store.select(selectSecurityRoles).pipe(
                filter(s => s.loaded),
                take(1),
            ),
            // Solo agregar fuentes que la decision final realmente use.
        ]).pipe(
            take(1),
            map(([ready, security]) => {
                if (!ready) return this.router.createUrlTree(['/']);   // shell en loading
                if (!security.permissions.includes('Pages.Foo')) {
                    return this.router.createUrlTree(['/unauthorized']);
                }
                return true;
            }),
        );
    }
}
```

**Regla**: el guard depende de `appReady$` + **solo** los selectores que su decision final consulta. Si despues del `combineLatest` se ignora una fuente, esa fuente se elimina del array (caso `AdminAiaManagementGuard` segun el doc de analisis).

### 3.7 Eliminar Datadog inline

`AppComponent` ya no contiene 35 lineas de `initializeDatadog()`. Se mueven a `DatadogService` con un metodo `initIfConfigured()` que:

1. Lee `config.datadog.datadogScriptUrl`.
2. Si es `undefined` o vacio, retorna sin error (caso dev/mock que ya causo el bug del 2026-06-18).
3. Si esta configurado, inyecta el script y configura RUM.

El orquestador llama a `datadogService.initIfConfigured()` justo despues de `identityReady` (necesitamos usuario identificado para el `usr.id` de RUM).

---

## 4. Plan por Fases

Las fases estan ordenadas por **dependencia + riesgo decreciente**. Cada fase produce un diff pequeno, aislado, verificable, y reversible. Si una fase falla su verificacion, no se avanza a la siguiente.

### Fase 0. Inventario y baseline (preimplementacion)

**Objetivo**: medir el estado actual antes de tocar nada. Sin esto, no se puede saber si una fase funciono.

**Tareas**:

1. Capturar el orden exacto de eventos durante el primer login en dev. Usar el log de `startup-auth-bootstrap-analysis.md` (seccion "Firefox Log Analysis") como baseline.
2. Medir tiempo entre `t1` (MSAL resuelve) y `t3` (securityRoles.loaded = true && ldFlags != null).
3. Contar cuantos specs pasan hoy (`npm test`).
4. `npx madge --circular src/` y guardar el output.
5. `npx dpdm --no-warning --no-tree --circular src/` y guardar el output.

**Criterio de aceptacion**: existe un archivo `docs/startup-baseline-2026-06-20.md` con esos numeros.

**Riesgo**: cero (solo lectura).

---

### Fase 1. Separar redirect completion de idle state (Slice 1 del doc de analisis)

**Objetivo**: eliminar la causa raiz de la race condition de re-login. Ningun observer dispara comandos de MSAL.

**Archivos a tocar**:

- `src/app/core/rebarauth/rebar.auth.service.ts` — quitar el `subscribe` que llama `login()` cuando `InteractionStatus.None`. Reemplazar por emision de `accountState$`.
- `src/app/core/rebarauth/rebar.auth.service.spec.ts` — agregar tests para `accountState$` y para verificar que `login()` no se llama desde el observer.
- `src/app/app.component.ts` — eliminar el `msalService.handleRedirectObservable().subscribe()` que descarta el resultado. Esa llamada pasa al orquestador (Fase 2).

**Cambio concreto (pseudo-diff)**:

```diff
// rebar.auth.service.ts
- this.msalBroadcastService.inProgress$
-     .pipe(filter(s => s === InteractionStatus.None))
-     .subscribe(() => {
-         this.checkAndSetActiveAccount();
-         if (!this.isUserAuthenticated()) {
-             this.login();
-         }
-         this.authObserver$.next(true);
-     });
+ this.msalBroadcastService.inProgress$.subscribe((status) => {
+     this.accountState$.next(
+         status === InteractionStatus.None ? 'idle' : 'authenticating'
+     );
+ });
```

**Criterio de aceptacion**:

- `rebar.auth.service.spec.ts`: `accountState$` emite `'idle'` cuando MSAL reporta `None` y `'authenticating'` en cualquier otro caso.
- `rebar.auth.service.spec.ts`: cuando MSAL emite `None` y no hay cuentas, `login()` **no** se invoca automaticamente.
- Reproducir la secuencia de re-login en dev: ya no ocurre.
- `npm test` pasa sin cambios en el conteo.

**Riesgo**: medio. Cambia el contrato de `RebarAuthService`. Si `AppComponent` o algun guard depende del side effect de `login()`, deja de funcionar. Verificar con busqueda exhaustiva.

**Como verificar**:

```bash
npm run lint
npm test -- --watch=false --browsers=ChromeHeadless --code-coverage=false
# Manual: en dev, forzar logout, deep-link a /administration, verificar que la app
# no entra en loop de re-login. Capturar log y comparar con baseline.
```

---

### Fase 2. Mover `handleRedirectObservable` al orquestador

**Objetivo**: que el manejo del redirect deje de vivir en `AppComponent` y viva en el orquestador. Capturar el resultado, no descartarlo.

**Archivos a tocar**:

- `src/app/core/services/app-startup-orchestrator.service.ts` — agregar el manejo de `handleRedirectObservable()` y emitir `redirectHandled$`.
- `src/app/app.component.ts` — eliminar el `subscribe` y delegar al orquestador.

**Cambio concreto**:

```typescript
// app-startup-orchestrator.service.ts (agregar)
private async handleRedirect(): Promise<void> {
    return new Promise<void>((resolve, reject) => {
        this.msalService.handleRedirectObservable().subscribe({
            next: (result) => {
                // Capturar el resultado, no descartar.
                if (result?.account) {
                    this.msalService.instance.setActiveAccount(result.account);
                }
                this.readiness.redirectHandled$.next();
                resolve();
            },
            error: (err) => {
                // Log a Datadog (si esta disponible) o console.error.
                reject(err);
            },
        });
    });
}
```

**Criterio de aceptacion**:

- El unico `handleRedirectObservable()` del codebase esta en el orquestador (`grep -r "handleRedirectObservable" src/`).
- `redirectHandled$` se emite **una vez** por sesion (verificable via `readiness.snapshot().redirect` en un test).
- En dev, el primer login tras redirect resuelve igual que antes (sin regresion funcional).

**Riesgo**: bajo. Es un movimiento de codigo sin cambio de logica, salvo por capturar el resultado.

**Como verificar**:

```bash
npm run lint
npm test
# Manual: login + redirect + reload. Verificar que el log muestra redirectHandled$ emit.
```

---

### Fase 3. Resolver cuenta activa con timeout explicito

**Objetivo**: encapsular `checkAndSetActiveAccount()` con un timeout y una verificacion de `getAllAccounts().length > 0`. Hoy se hace inline y sin proteccion.

**Archivos a tocar**:

- `src/app/core/services/app-startup-orchestrator.service.ts` — agregar metodo privado `resolveActiveAccount()` (mostrado en seccion 3.3).
- `src/app/core/services/app-startup-orchestrator.service.spec.ts` — agregar tests con `fakeAsync` + `tick` para verificar timeout.
- `src/app/core/rebarauth/rebar.auth.service.ts` — eliminar `checkAndSetActiveAccount()` publico o marcarlo `@deprecated` (la logica migra al orquestador).

**Criterio de aceptacion**:

- Si MSAL no hidrata cuenta en 5s, se loguea el incidente y `accountResolved$` no se emite (la app queda en loading, lo que es preferible a un estado corrupto).
- Si hidrata cuenta pero `setActiveAccount` falla, se loguea y se aborta el orquestador con un error visible.
- Specs: el caso de "MSAL hidrata inmediatamente" emite `accountResolved$` en el siguiente tick.

**Riesgo**: bajo. Solo cambia el manejo de errores.

**Como verificar**:

```bash
npm test -- --test-path-pattern=app-startup-orchestrator
# Manual: con DevTools, simular MSAL lento (throttling) y verificar que el spinner se mantiene.
```

---

### Fase 4. Bootstrap de user state via `forkJoin` (reemplazar cascada)

**Objetivo**: que `continueLoading()` deje de ser una cascada de dispatches. En su lugar, el orquestador dispara las acciones **y** espera a que todos los selectores resuelvan via `forkJoin`.

**Archivos a tocar**:

- `src/app/core/services/app-startup-orchestrator.service.ts` — agregar metodo `bootstrapUserState()` (mostrado en seccion 3.3).
- `src/app/app.component.ts` — eliminar el metodo `continueLoading()`.
- `src/app/state/user-info/user-info.effects.ts` — si hay alguna reaccion a `setInitialUserInfo` que dispare mas acciones, asegurar que se contabiliza en el `forkJoin` (probablemente no requiere cambio si los selectores ya incluyen todos los slices).
- Tests del orquestador: agregar tests de "todas las fuentes resuelven -> `permissionsReady$` emite" y "una fuente falla -> el orquestador no emite `permissionsReady$` y registra error".

**Criterio de aceptacion**:

- `grep -r "continueLoading" src/` no devuelve resultados (o solo en tests legacy que se actualizan).
- `bootstrapUserState` espera **al menos**: LD flags no null, userInfo.loaded, dropdowns.loaded, securityRoles.loaded, notifications.loaded.
- Si el usuario es ASG, el flujo corto-circuita a `setInitialUserInfo` sin esperar los demas.

**Riesgo**: medio. Si algun effect hace trabajo que no se refleja en los selectores actuales, hay un gap oculto. Auditar los effects de `userInfo`, `dropdowns`, `securityRoles`, `notifications`, `launchdarklyFlags` antes de empezar.

**Como verificar**:

```bash
npm test
# Manual: login como usuario no-ASG. Verificar en Redux DevTools que las 5 acciones
# disparan en el mismo tick (no en cascada con awaits intermedios) y que el spinner
# desaparece solo cuando todas terminaron.
```

---

### Fase 5. Datadog como servicio, inicializado despues de identity

**Objetivo**: eliminar la inicializacion inline de Datadog en `AppComponent`. Hacerla un servicio inyectable que se inicializa solo si el config lo provee y solo despues de tener identidad.

**Archivos a tocar**:

- `src/app/core/services/datadog.service.ts` (nuevo) — encapsula `initIfConfigured()`.
- `src/app/core/services/app-startup-orchestrator.service.ts` — llamar a `datadogService.initIfConfigured()` justo despues de `identityReady$`.
- `src/app/app.component.ts` — eliminar el bloque `initializeDatadog()`.

**Criterio de aceptacion**:

- En dev (donde `datadogScriptUrl` no esta configurado), no se intenta inyectar el script. No hay `https://...undefined` en la consola.
- En prod, Datadog RUM arranca **despues** de que el usuario esta identificado (asi `usr.id` esta disponible).
- Specs del nuevo servicio cubren: config ausente, config presente, error de carga.

**Riesgo**: bajo. Es un refactor de organizacion.

**Como verificar**:

```bash
npm test
# Manual en dev: verificar que no aparece el error "https://...undefined" en consola.
# Manual en prod: verificar que Datadog RUM recibe el evento de page view.
```

---

### Fase 6. Shell gating por `appReady$` (cierre del flash de unauthorized)

**Objetivo**: que el shell **no se monte** hasta que `appReady$` emita. Esto elimina el flash porque el router no evalua rutas sensibles hasta que los permisos estan listos.

**Archivos a tocar**:

- `src/app/app.component.html` — cambiar a `<ng-container *ngIf="appReady$ | async">` con template alternativo de loading.
- `src/app/app.component.ts` — exponer `appReady$` desde el orquestador o desde el readiness service.
- `src/app/core/containers/app-shell/app-shell.component.html` — eliminar la logica condicional de "auth not resolved yet" duplicada (ya no se llega al shell si no esta resuelto).

**Criterio de aceptacion**:

- En dev, durante el primer login, el spinner se mantiene visible hasta que el shell esta listo para mostrar contenido. No hay flash de pagina intermedia.
- `npm test` pasa (verificar que el cambio de template no rompe los tests del `AppComponent`).

**Riesgo**: medio. Si algun test del `AppComponent` asume que el shell esta siempre montado, hay que actualizarlo. Tambien: si el shell tiene subcomponentes con ciclo de vida propio (e.g. WebSocket connections), hay que revisar que no se conecten dos veces (una al montarse "fantasma" anterior, otra al verdadero mount).

**Como verificar**:

```bash
npm test
# Manual: deep-link a /administration/npd sin estar logueado.
# Esperado: redirect a login, luego login, luego spinner hasta que appReady$ emite,
# luego shell con la pagina de administracion (o /unauthorized si no tiene permisos).
# No debe haber flash de /administration entre medio.
```

---

### Fase 7. Reglas de lint para tipos compartidos (cierre del circulo vicioso)

**Objetivo**: que el antipatron descrito en `circular-dependency-core-module.md` no se repita. Esto es estructural, no solo de proceso.

**Archivos a tocar**:

- `.eslintrc.js` (o el equivalente) — agregar regla custom o usar `eslint-plugin-import` con `import/no-cycle` y `import/no-internal-modules` configurados.
- `package.json` — agregar `npm run lint:deps` que ejecuta `madge --circular` y `dpdm --circular`.
- `package.json` — agregar `npm run lint:agents` (ya existe segun la doc del proyecto, verificar) que tambien corra el chequeo de ciclos.
- `src/app/core/pages/project-details-page/project-details-page.component.ts` — eliminar las re-exports de tipos (`export { IContactTable }`, `export { ProjectView }`) si aun existen.
- Cualquier archivo que hoy importe tipos desde un componente: refactorizar a importar desde el archivo de dominio.

**Criterio de aceptacion**:

- `npm run lint:deps` retorna codigo 0.
- `npx madge --circular src/` retorna `✔ No circular dependency found`.
- ESLint falla en CI si un `*.component.ts` exporta un tipo que es importado por otro archivo fuera del mismo modulo.

**Riesgo**: bajo, salvo que el repo tenga muchos tipos mal ubicados (auditar antes con `grep -r "export interface" src/ | grep ".component.ts"`).

**Como verificar**:

```bash
npm run lint
npm run lint:deps
npm test
```

---

### Fase 8. Limpieza final y eliminacion de codigo muerto

**Objetivo**: remover lo que las fases anteriores dejaron obsoleto.

**Archivos a tocar** (verificar caso por caso, no aplicar a ciegas):

- `rebar.auth.service.ts` — eliminar `checkAndSetActiveAccount()` si quedo como `@deprecated`.
- `app.component.ts` — eliminar `continueLoading()`, `initializeDatadog()`, el `subscribe` a `authObserver$` (si quedo alguno).
- `app.component.html` — eliminar el `@if (userInfoLoading$ | async; as userInfoLoading)` redundante.
- Cualquier `console.log` con claims o datos de usuario que el doc `startup-auth-bootstrap-analysis.md` menciona (seccion "Extended Improvement Slices", item 9).

**Criterio de aceptacion**:

- `grep -r "console.log" src/app/app.component.ts src/app/core/rebarauth/` no devuelve lineas con claims o user data.
- `grep -r "continueLoading\|initializeDatadog\|checkAndSetActiveAccount" src/` no devuelve resultados (o solo en tests legacy marcados como skipped con justificacion).

**Riesgo**: bajo (es eliminacion de codigo ya no referenciado).

**Como verificar**:

```bash
npm test
npm run lint
npm run build
```

---

## 5. Resumen de Fases

| Fase | Nombre | Esfuerzo | Riesgo | Cubre que problema |
| --- | --- | --- | --- | --- |
| 0 | Baseline | XS | 0 | Medicion |
| 1 | Separar redirect de idle | S | M | Race condition re-login |
| 2 | Mover redirect a orquestador | XS | L | Coordinacion |
| 3 | Resolver cuenta con timeout | S | L | Edge case MSAL lento |
| 4 | Bootstrap via forkJoin | M | M | Cascada de dispatches |
| 5 | Datadog como servicio | S | L | Organizacion + bug 2026-06-18 |
| 6 | Shell gating por appReady | S | M | Flash de unauthorized |
| 7 | Lint de tipos compartidos | S | L | Prevencion de ciclos |
| 8 | Limpieza de codigo muerto | XS | L | Deuda tecnica |

XS = < 1h, S = 1-4h, M = 4-8h, L = bajo, M = medio, 0 = cero.

**Orden de implementacion recomendado**: 0, 1, 2, 3, 4, 5, 6, 7, 8. No saltar.

**Cual es la fase de maximo valor**: **Fase 1** (causa raiz de la race condition) + **Fase 6** (causa raiz del flash). Si solo se hicieran dos fases, esas son las que importan.

---

## 6. Decisiones Clave y Trade-offs

### 6.1 Por que `ReplaySubject` y no `BehaviorSubject` para las fases

`ReplaySubject(1)` deja explicito que cada fase emite **a lo sumo una vez** por sesion. `BehaviorSubject` podria funcionar pero sugiera "valor actual observable", lo que no es lo que queremos (no queremos que un consumer pida la fase actual repetidamente; queremos que la fase se emita y se consuma).

### 6.2 Por que `forkJoin` y no `combineLatest` para `bootstrapUserState`

`forkJoin` espera a que **todas** las fuentes completen. `combineLatest` emite cuando alguna cambia. En el bootstrap, queremos que `permissionsReady$` se emita una sola vez cuando **todo** esta listo, no en cada cambio intermedio. Si en el futuro se necesita reactividad a cambios de permisos, se agrega un selector separado.

### 6.3 Por que `provideAppInitializer` para el orquestador y no `APP_INITIALIZER` manual

`provideAppInitializer` (Angular 21) es la API moderna. El doc de analisis menciona `provideAppInitializer` en `app.config.ts`, asi que asumimos que el codebase esta en Angular 21 o lo soporta. Si no, se usa `{ provide: APP_INITIALIZER, multi: true, useFactory: () => orchestrator.run }`.

**Importante**: el orquestador debe correr **despues** del initializer de `AppConfigService`. Orden:

```typescript
providers: [
    provideAppInitializer(() => config.load()),         // 1ro: config
    provideAppInitializer(() => orchestrator.run()),   // 2do: bootstrap
]
```

Angular ejecuta los initializers en orden de declaracion. Si `orchestrator.run()` corre antes de que `config` este listo, falla igual que el caso del parche de 2026-06-17.

### 6.4 Por que no hacer todo `appReady$` derivado de un unico selector NgRx

Alternativa rechazada: agregar un slice `startup` al store con campos `configReady`, `redirectHandled`, etc., y un selector `selectAppReady`. Trade-offs:

- **Pro**: encaja con la arquitectura NgRx existente, todos los consumers usan el mismo mecanismo.
- **Contras**: requiere dispatch para cada fase, lo que mezcla bootstrap con logica de negocio. Los efectos asociados se vuelven propensos a re-emitir en situaciones inesperadas (e.g. un rehydrate del store podria re-disparar fases que ya pasaron).

`ReplaySubject` fuera del store es mas simple, mas testeable, y deja claro que el bootstrap es **one-shot**.

### 6.5 Standalone components y signals (ya migrados)

El proyecto **ya esta migrado** a standalone components y Angular 21 signals. El `AppStartupReadinessService` ya usa signals (`signal()`, `toObservable()`) en lugar de `ReplaySubject`. Los snippets de codigo de esta propuesta reflejan esta realidad: los contratos conceptuales muestran `ReplaySubject` para claridad arquitectonica, pero la implementacion real usa signals. No hay migracion pendiente en este frente.

### 6.6 Por que no abortar el orquestador si el usuario es ASG

El caso ASG (Application Server Group) se trata como un corto-circuito: el usuario es admin/sistema, no necesita LaunchDarkly ni dropdowns. Si se generaliza el "no emitir `permissionsReady$`", el shell nunca se monta. Por eso Fase 4 incluye el `if (claims.isASG)` que emite `permissionsReady$` apenas `setInitialUserInfo` se despacho (que es sincrnico respecto al effect que escucha).

### 6.7 Por que no usar `inject()` everywhere

Las fases estan escritas con inyeccion por constructor para compatibilidad con clases que aun no son `inject()`-friendly (algunos servicios del proyecto usan decorators de clase con metadata que se pierde con `inject()` en ciertos contextos). Si el codebase ya migro a `inject()`, se prefiere; si no, inyeccion por constructor es segura.

---

## 7. Metricas y Validacion

### 7.1 Metricas de exito por fase

| Fase | Metrica | Target |
| --- | --- | --- |
| 0 | Baseline capturado | Documento `docs/startup-baseline-2026-06-20.md` existe |
| 1 | Re-login loops en dev (5 intentos) | 0 ocurrencias |
| 2 | `handleRedirectObservable` en codigo | 1 ocurrencia (orquestador) |
| 3 | Timeout en `resolveActiveAccount` | 5000ms, testeado |
| 4 | Tiempo entre `t1` y `permissionsReady$` (mediana) | < 2s en dev |
| 5 | Logs con `undefined` en datadogScriptUrl | 0 |
| 6 | Flash de unauthorized en deep-link a /administration | 0 ocurrencias en 5 intentos |
| 7 | `madge --circular` | 0 ciclos |
| 8 | `console.log` con claims/user data | 0 |

### 7.2 Metricas de regresion (no deben empeorar)

| Metrica | Baseline | Post-implementacion |
| --- | --- | --- |
| Tests pasando | 5889 (segun doc circular-dependency) | >= 5889 |
| Tiempo a interactive (TTI) en prod | TBD (capturar en Fase 0) | <= baseline + 200ms (margen por el gate) |
| Bundle size inicial | TBD | <= baseline + 5KB (margen por el orquestador) |

### 7.3 Comandos de verificacion global

```bash
# Lint
npm run lint
npm run lint:deps      # si existe, si no: npx madge --circular src/

# Tests
npm test -- --watch=false --browsers=ChromeHeadless --code-coverage=false

# Build
npm run build
npm run build:local

# E2E (si aplica)
npm run e2e

# Manual smoke
npm run mock
npm run mock:local
```

### 7.4 Cuando abortar

Si despues de Fase 4 el tiempo `t1 -> permissionsReady$` no mejoro (o empeoro), replantear: probablemente el forkJoin espera un slice que ya estaba listo, o un effect hace trabajo redundante. Auditar antes de seguir con Fase 5.

---

## 8. Hidden Assumptions y Gaps

> Esta seccion es **para la IA que lee este documento y va a implementar**. No la saltes.

### 8.1 Estado real del codigo (confirmado 2026-06-20)

Los tres documentos fuente (`auth-relogin-race-condition.md`, `circular-dependency-core-module.md`, `startup-auth-bootstrap-analysis.md`) describen la arquitectura **actual** del repositorio. Todos los archivos mencionados existen:

- `src/app/app.config.ts` — con `provideAppInitializer` y providers de NgRx, MSAL, etc.
- `src/app/app.component.ts` — standalone component con `ngOnInit`.
- `src/app/core/rebarauth/rebar.auth.service.ts` — con `authObserver$` y logica de MSAL.
- `src/app/core/services/app-startup-orchestrator.service.ts` — **ya implementado** (`providedIn: 'root'`, metodo `run()`).
- `src/app/core/services/app-startup-readiness.service.ts` — **ya implementado** con Angular 21 signals (no `ReplaySubject`).
- `src/app/core/guards/` — contiene multiples guards (`administration.guard.ts`, `data-security.guard.ts`, etc.) que hacen gate sobre `startupReady$`.

**El proyecto es Angular 21.2.7 standalone** con NgRx, MSAL (`@azure/msal-angular`), Datadog (`@datadog/browser-rum`), y LaunchDarkly. **No es ASP.NET Zero / ABP.**

**Implicaciones para la implementacion**:

1. Las fases 1-8 de esta propuesta se aplican **directamente** sobre el codigo existente. No hay que mapear paths ni portar arquitectura.
2. El `AppStartupOrchestratorService` y el `AppStartupReadinessService` ya existen. Las fases describen **mejoras incrementales** (separar redirect de idle, agregar timeout, reemplazar cascada de dispatches, etc.), no creacion de servicios nuevos.
3. El `AppStartupReadinessService` ya usa Angular 21 signals (`signal()`, `toObservable()`). Los snippets conceptuales de esta propuesta que muestran `ReplaySubject` son para claridad arquitectonica; la implementacion real debe mantener signals.
4. Antes de empezar cualquier fase, verificar el estado actual de cada archivo con `git log --oneline -5 <archivo>` para entender cambios recientes.

### 8.2 Asunciones sobre el codebase descrito en los docs

- **Angular 21+** con `provideAppInitializer` (no `APP_INITIALIZER` manual).
- **NgRx** ya configurado con slices `userInfo`, `securityRoles`, `launchdarklyFlags`, `dropdownValues`, `notifications`.
- **MSAL 2.x+** via `@azure/msal-angular` (`MsalService`, `MsalBroadcastService`).
- **LaunchDarkly** via `launchdarkly-js-client-sdk` o equivalente, con servicio propio.
- **Datadog RUM** via `@datadog/browser-rum`.
- **AG Grid** no es relevante para esta propuesta.
- **Tests** con Jasmine + Karma (verificado por la convencion `*.spec.ts` y el comando `npm test`).
- **Linting** con ESLint (verificado por `.eslintrc.js`).

Si alguna de estas asunciones no se cumple, las fases afectadas requieren ajustes antes de implementarse.

### 8.3 Comportamientos no especificados en los docs

Los docs no cubren explicitamente:

- **Multiples tabs / sesiones concurrentes**: si el usuario tiene dos tabs abiertas y una dispara logout, como afecta al `appReady$` de la otra? Recomendacion: tratar `appReady$` como un observable por instancia de aplicacion; si la sesion se invalida, se hace un hard reload (`location.href = ''`) en vez de intentar re-disparar el bootstrap.
- **Token refresh durante bootstrap**: si un token expira justo cuando el orquestador intenta resolver la cuenta, que pasa? Recomendacion: `resolveActiveAccount` debe distinguir "no hay cuenta" (no autenticado) de "hay cuenta pero no se puede obtener token" (refresh). En el segundo caso, el orquestador intenta `acquireTokenSilent` y, si falla, delega a `RebarAuthService.requestLogin('expired')`.
- **Errores de red durante `bootstrapUserState`**: si uno de los endpoints falla (e.g. 500 en `/api/services/app/Role/GetAll`), el `forkJoin` rechaza y el orquestador aborta. La app queda en spinner. Recomendacion: agregar un timeout global de 10s; si expira, mostrar un mensaje de error con boton de retry que re-dispare las acciones afectadas.
- **Cambios de tenant en runtime**: si el usuario cambia de tenant (vía `changeTenantIfNeeded`), se hace `location.reload()`, asi que el orquestador se vuelve a correr. Confirmado por `app-session.service.ts:115`. El readiness service debe limpiarse en este caso; usar `providedIn: 'root'` con cleanup en `ngOnDestroy` no aplica (vive toda la sesion), pero un `location.reload()` reinicia todo, asi que no hay problema.

### 8.4 Lo que esta propuesta **no** resuelve

Para evitar scope creep:

- No introduce tests e2e para los flujos de bootstrap (queda como follow-up si se considera necesario).
- No toca la logica de inactividad / session-timeout (esa vive en `src/app/shared/common/session-timeout/` y se coordina via flags de LD).
- No toca la logica de impersonation / linked accounts.
- No resuelve el bug AADSTS50058 de Firefox (ver `startup-auth-bootstrap-analysis.md` seccion "AADSTS50058 errors"). Ese es un widget externo de Accenture, fuera del control de este repo.

---

## 9. Apendices

### 9.1 Tabla de mapeo: doc fuente -> archivos mencionados -> fase que los cubre

| Doc fuente | Archivo mencionado | Fase |
| --- | --- | --- |
| `auth-relogin-race-condition.md` | `src/app/core/rebarauth/rebar.auth.service.ts` | 1 |
| `auth-relogin-race-condition.md` | `src/app/app.component.ts` (handleRedirectObservable) | 2 |
| `startup-auth-bootstrap-analysis.md` Slice 1 | `rebar.auth.service.ts` (authObserver$) | 1 |
| `startup-auth-bootstrap-analysis.md` Slice 2 | `app-startup-orchestrator.service.ts` (nuevo) | 2-5 |
| `startup-auth-bootstrap-analysis.md` Slice 3 | guards + `app-startup-readiness.service.ts` | 6 + refactor de guards (implicito en 6) |
| `startup-auth-bootstrap-analysis.md` Slice 4 | `historical-demand-migration.guard.ts` | 6 (cleanup) |
| `startup-auth-bootstrap-analysis.md` Slice 5 | `main.ts` + `app-config.service.ts` | ya hecho (2026-06-17) |
| `startup-auth-bootstrap-analysis.md` "Extended Improvement Slices" item 1 | `app.component.html` (shell sin gate) | 6 |
| `startup-auth-bootstrap-analysis.md` item 2 | `user-info.reducer.ts` (loading prematuro) | cubierto por Fase 4 (forkJoin) |
| `startup-auth-bootstrap-analysis.md` item 3 | guards sin `take(1)` | cubierto por Fase 6 (template unico) |
| `startup-auth-bootstrap-analysis.md` item 4 | `data-security.guard.ts` (complejo) | 6 (aplicar template) |
| `startup-auth-bootstrap-analysis.md` item 5 | rutas de error inconsistentes | 8 |
| `startup-auth-bootstrap-analysis.md` item 6 | `rebar.auth.service.ts` (semantica) | 1 |
| `startup-auth-bootstrap-analysis.md` item 7 | cascada de dispatches en `app.component.ts` | 4 |
| `startup-auth-bootstrap-analysis.md` item 8 | `app-shell.component.ts` (routing logic) | 8 (cleanup) |
| `startup-auth-bootstrap-analysis.md` item 9 | `console.log` con claims | 8 |
| `startup-auth-bootstrap-analysis.md` item 10 | Datadog inline | 5 |
| `circular-dependency-core-module.md` | `core.module.ts` ↔ `project-details-page.component.ts` | ya resuelto (2026-05-30) |
| `circular-dependency-core-module.md` | reglas de prevencion | 7 |

### 9.2 Snippet: integracion del orquestador en `app.config.ts`

```typescript
// src/app/app.config.ts
import { ApplicationConfig, provideAppInitializer, inject } from '@angular/core';
import { AppConfigService } from './core/services/app-config.service';
import { AppStartupOrchestratorService } from './core/services/app-startup-orchestrator.service';

export const appConfig: ApplicationConfig = {
    providers: [
        // Phase 1: config primero (necesario para MSAL factory).
        provideAppInitializer(() => inject(AppConfigService).load()),

        // Phase 2: bootstrap de auth y permisos. Corre despues del config.
        provideAppInitializer(() => inject(AppStartupOrchestratorService).run()),

        // ... resto de providers (Store, Effects, Router, RebarAuthModule, etc.)
    ],
};
```

### 9.3 Snippet: tests del orquestador (template)

```typescript
// app-startup-orchestrator.service.spec.ts
describe('AppStartupOrchestratorService', () => {
    let service: AppStartupOrchestratorService;
    let msalService: jasmine.SpyObj<MsalService>;
    let readiness: AppStartupReadinessService;
    let store: MockStore;

    beforeEach(() => {
        msalService = jasmine.createSpyObj('MsalService', ['handleRedirectObservable']);
        readiness = new AppStartupReadinessService();
        store = ...; // MockStore de @ngrx/store/testing
        service = new AppStartupOrchestratorService(
            msalService, /* msalBroadcast */, /* rebarAuth */, store, readiness, /* ld */, /* datadog */
        );
    });

    it('emits configReady$ immediately on run()', async () => {
        msalService.handleRedirectObservable.and.returnValue(of({ account: fakeAccount }));
        await service.run();
        expect(readiness.snapshot().config).toBe(true);
    });

    it('emits redirectHandled$ after handleRedirectObservable resolves', async () => {
        msalService.handleRedirectObservable.and.returnValue(of({ account: fakeAccount }));
        await service.run();
        expect(readiness.snapshot().redirect).toBe(true);
    });

    it('does not emit accountResolved$ if getAllAccounts returns empty after 5s', fakeAsync(() => {
        spyOn(msalService.instance, 'getAllAccounts').and.returnValue([]);
        msalService.handleRedirectObservable.and.returnValue(of({ account: fakeAccount }));
        service.run();
        tick(5_100);
        expect(readiness.snapshot().account).toBe(false);
    }));

    it('emits permissionsReady$ only when all selectors are loaded', async () => {
        // Setup store with all slices loaded except securityRoles.
        store.overrideSelector(selectSecurityRoles, { loaded: false, permissions: [] });
        // ... other overrides ...
        msalService.handleRedirectObservable.and.returnValue(of({ account: fakeAccount }));
        await service.run();
        expect(readiness.snapshot().permissions).toBe(false);

        // Now load securityRoles.
        store.overrideSelector(selectSecurityRoles, { loaded: true, permissions: [...] });
        // Trigger re-evaluation: ...
        expect(readiness.snapshot().permissions).toBe(true);
    });
});
```

### 9.4 Glosario

- **ASG**: Application Server Group. En este contexto, un tipo de usuario (admin/sistema) con permisos elevados que no requiere cargar todos los slices de usuario regular.
- **`provideAppInitializer`**: API de Angular 19+ para registrar funciones que corren antes del bootstrap. Reemplaza a `APP_INITIALIZER` con menos boilerplate.
- **MSAL**: Microsoft Authentication Library. Libreria de Microsoft para OAuth/OpenID Connect contra Azure AD.
- **NgRx**: libreria de state management para Angular basada en el patron Redux.
- **`forkJoin`**: operador de RxJS que espera a que todos los observables fuente completen y emite un array con sus ultimos valores.
- **Race condition**: situacion donde el resultado depende del orden o timing de eventos no deterministas.
- **Re-export**: `export { X } from './y'` — re-exporta un simbolo desde otro archivo. Util para barrels, peligroso cuando crea acoplamiento invisible.

---

## 10. Historial

| Fecha | Autor | Cambio |
| --- | --- | --- |
| 2026-06-20 | AI Agent (delivery) | Propuesta inicial basada en los 3 docs fuente. |
| 2026-06-20 | AI Agent (orchestrator) | Corregido: eliminada seccion 8.1 incorrecta (ASP.NET Zero), reframed como mejora incremental, actualizados snippets para Angular 21 signals. |
