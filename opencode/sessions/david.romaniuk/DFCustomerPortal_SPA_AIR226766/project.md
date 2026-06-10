# Project Information

> **SOURCE**: Synced from `C:/projects/DFCustomerPortal_SPA_AIR226766/.opencode/project.md`
> **REVIEW POLICY**: Review approximately once per month or earlier if the project context changes materially.
> **LAST REVIEWED**: 2026-06-10
> **NEXT REVIEW DUE**: 2026-07-10
> **REVIEW CADENCE**: monthly (~30 days)

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
- **Testing**: Jasmine + Karma, Cypress 13, Playwright 1.58, json-server 0.17

## Architecture
- **Pattern**: Signals-First with OnPush Change Detection
- **Component Style**: Standalone components mandatory for new code
- **Critical Rule**: Documentation in `.github/agent-context/` overrides legacy patterns in `src/`

## Project Slang (Inferred from Codebase)

| Term | Meaning | Location | Confidence |
|------|---------|----------|------------|
| RebarAuthService | servicio puente entre MSAL y el bootstrap de la app | `.github/agent-context/troubleshooting/auth-relogin-race-condition.md`, `src/app/core/rebarauth/rebar.auth.service.ts` | high |
| authObserver$ | señal actual de “MSAL idle”, usada erróneamente como “auth ready” | `.github/agent-context/troubleshooting/startup-auth-bootstrap-analysis.md`, `src/app/core/rebarauth/rebar.auth.service.ts` | high |
| Access_AdminAdministration | permiso backend que habilita acceso al área de administración | `.github/agent-context/security-permissions.md`, `src/app/core/models/security-roles.domain.ts` | high |
| ASG user | tipo de usuario con flujo especial de autorización | `.github/agent-context/troubleshooting/startup-auth-bootstrap-analysis.md`, `src/app/app.component.ts` | medium |
| continueLoading | cascada actual de dispatches post-login para flags, roles y datos globales | `.github/agent-context/troubleshooting/startup-auth-bootstrap-analysis.md`, `src/app/app.component.ts` | high |

## Key Skills
- canonical-prompter
- context-reductor
- librarian

## Additional Notes
- For auth/startup work, consult `.github/agent-context/troubleshooting/startup-auth-bootstrap-analysis.md` first.
- For authorization semantics, consult `.github/agent-context/security-permissions.md`.
