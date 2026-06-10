# Project Information

## Overview
- **Project Name**: data-foundations-customer-portal (DFCustomerPortal)
- **Project ID**: AIR226766
- **Description**: Enterprise customer portal SPA for managing cloud resources, data security, access requests, and project workflows. Built on Accenture's Evergreen SPA template with Angular 21.

## Technology Stack
- **Frontend Framework**: Angular 21.2.7
- **Language**: TypeScript 5.9
- **State Management**: NgRx 21 (legacy) + Angular Signals (modern standard)
- **UI Libraries**: Angular Material 21, Bootstrap 5.3, AG Grid 32
- **Auth**: MSAL (Azure AD) via @azure/msal-angular 3.0.25
- **Feature Flags**: LaunchDarkly
- **Telemetry**: Datadog RUM
- **Styling**: SCSS with CSS variables and design tokens
- **Build Tool**: esbuild (via @angular/build)
- **Testing**: 
  - Unit: Jasmine + Karma
  - E2E: Cypress 13 + Playwright 1.58
  - Mocking: json-server 0.17

## Architecture
- **Pattern**: Signals-First with OnPush Change Detection
- **Component Style**: Standalone components (mandatory for new code)
- **Data Flow**: 
  - Local State: `signal()`, `computed()`, `linkedSignal()`
  - Async Data: `rxResource()` for API interactions
  - Global State: NgRx Store (minimal, being phased out)
- **Critical Rule**: Documentation in `.github/agent-context/` overrides patterns in `src/`. Never copy legacy patterns from `src/`.

## Project Structure
```
src/
├── app/
│   ├── core/                    # Core business logic
│   │   ├── components/          # Shared components
│   │   ├── containers/          # Smart components
│   │   ├── services/            # Business services
│   │   ├── models/              # Domain models
│   │   ├── guards/              # Route guards
│   │   ├── pipes/               # Custom pipes
│   │   ├── directives/          # Custom directives
│   │   ├── utils/               # Utility functions
│   │   └── pages/               # Page components
│   ├── state/                   # NgRx state slices (60+ features)
│   ├── shared/                  # Shared module (legacy)
│   ├── modal/                   # Modal system
│   ├── alert/                   # Alert components
│   ├── toast/                   # Toast notifications
│   ├── interceptors/            # HTTP interceptors
│   ├── universal-header/        # Header component
│   └── amethyst/                # Amethyst integration
├── assets/                      # Static assets
├── environments/                # Environment configs
│   ├── environment.ts           # Default
│   ├── environment.local.ts     # Local development
│   └── environment.prod.ts      # Production
└── config/                      # Runtime configuration

.github/agent-context/           # Authoritative documentation
├── AGENTS.md                    # Component-to-doc map
├── architecture.md              # Core architecture rules
├── project-rules.md             # Standards and anti-patterns
├── coding-conventions.md        # Coding standards
└── [feature-docs]/              # Feature-specific documentation

mocks/                           # json-server mock data
tests/                           # E2E tests
├── e2e/                         # Cypress tests
└── playwright/                  # Playwright tests
```

## Commands

### Development
```bash
# Start dev server
npm start

# Start with local config
npm run start:local

# Build for development
npm run watch
```

### Build
```bash
# Production build
npm run build

# Local build
npm run build:local

# CI build
npm run build:ci

# Bundle analysis
npm run bundle-report
```

### Testing
```bash
# Unit tests with coverage
npm test

# Unit tests headless
npm run test:headless

# E2E with Cypress
npm run e2e

# E2E regression tests
npm run test:regression

# Playwright with mocked API
npm run playwright:mocked

# Playwright E2E (real backend)
npm run playwright:e2e
```

### Mocking
```bash
# Start mock server + app
npm run mock

# Mock with local config
npm run mock:local

# Serve mock JSON only
npm run mock:json
```

### Docker
```bash
# Start with Docker Compose (nginx + json-server)
docker-compose up

# Build app for Docker
npm run buildapp:docker
```

### Linting
```bash
# Run ESLint
npm run lint

# Fix ESLint issues
npm run lint:fix

# Validate agent architecture
npm run lint:agents
```

## Environment Variables
Configuration is managed via:
- `src/environments/environment.*.ts` - Build-time config
- `src/config/` - Runtime config files
- LaunchDarkly flags (suffix: `_AIR226766`)

## Key Conventions

### Angular Standards (v20+)
- **Inputs**: Always use `input<T>()` or `input.required<T>()`
- **Outputs**: Prefer `output<T>()` over `EventEmitter`
- **DI**: Use `inject(Service)` instead of constructor injection
- **Async**: Use `rxResource()` for API calls, avoid manual subscriptions
- **Change Detection**: OnPush is mandatory
- **Components**: Must be standalone

### State Management
- **Local State**: Use `signal()`, `computed()`, `linkedSignal()`
- **Async Data**: Use `rxResource()` (project standard)
- **NgRx Store**: Minimal use only, being phased out
- **Signal Debugging**: All signals must include `debugName`

### Anti-Patterns (AVOID)
| Anti-Pattern | Standard Pattern |
|--------------|------------------|
| `Promise.then()` in components | `rxResource` / `toSignal` |
| Manual `.subscribe()` | Signals / `async` pipe |
| `UntilDestroy` / `untilDestroyed()` | `DestroyRef` + `takeUntilDestroyed()` |
| Complex logic in templates | `computed()` in TypeScript |
| Excessive NgRx Store/Selectors | Signals / Local State |
| `setTimeout` in components | Signal updates / `ChangeDetectorRef.markForCheck()` |
| `::ng-deep` | Only for third-party libraries (AG Grid) |
| `any` type | Exact interfaces / generics / `unknown` |

### Testing
- **Unit**: Jasmine + Karma (legacy) / Vitest (new)
- **E2E**: Cypress for regression, Playwright for new tests
- **Mocking**: json-server with `mocks/data.json`
- **No focused tests**: `fit()` and `fdescribe()` prohibited

### LaunchDarkly Flags
- All flag keys must include suffix `_AIR226766`
- Example: `LD_FLAG_MY_FEATURE = 'my_feature_AIR226766'`

## Domain Entities (State Slices)
- `cloud-resources/` - Cloud resource management
- `data-security/` - Data security configurations
- `data-requests-*` - Data request workflows
- `project-*` - Project management (list, details, contacts, documents)
- `administration-*` - Admin resources and deletion
- `access-packages/` - Access package management
- `security-roles/` - Role-based access control
- `user-info/` - User profile and identity
- `launchdarkly-flags/` - Feature flag state
- `workflow/` - Workflow management
- `ticket-eng/` - Engineering tickets
- `demand-*` - Demand management
- `audit-report/` - Audit reporting

## Key Documentation
- **Component Map**: `.github/agent-context/AGENTS.md`
- **Architecture Rules**: `.github/agent-context/architecture.md`
- **Project Rules**: `.github/agent-context/project-rules.md`
- **Coding Conventions**: `.github/agent-context/coding-conventions.md`
- **Troubleshooting**: `.github/agent-context/troubleshooting/`

## Cloud Provider
- **Provider**: AWS 3.0
- **Hosting**: CloudFront + S3 (secure hosting pattern)
- **Bundler**: cio-bundler utility for deployment packages

## CI/CD
- **Pipelines**: Azure Pipelines
  - `azure-pipelines-ci.yml` - Continuous integration
  - `azure-pipelines-cd.yml` - Continuous deployment
  - `azure-pipelines-AT.yml` - Acceptance testing
  - `azure-pipelines-e2e.yml` - E2E testing
  - `azure-pipelines-check-branch.yml` - Branch checks

## Key Skills
- `api-endpoint-factory` - Creating new API endpoints following 4-layer architecture
- `permission-system` - Managing the atomic permission system (bitmask + cache)
- `postgres-best-practices` - Supabase Postgres optimization rules
- `canonical-prompter` - Structuring and classifying prompts
- `context-reductor` - Defining scope and boundaries before development
- `librarian` - Documentation lookup and synthesis

## Important Notes
- **Legacy Code**: The `src/` directory contains legacy anti-patterns. DO NOT use as reference.
- **Documentation First**: Always check `.github/agent-context/` before implementing.
- **Signals Migration**: Project is actively migrating from NgRx to Signals.
- **Standalone Components**: All new components must be standalone.
- **No setTimeout**: Using `setTimeout` for UI flow is prohibited.
- **Refactoring Encouraged**: When touching legacy code, refactor to modern standards.
