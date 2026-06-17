# Opencode Project Configuration (Local)

> **Source of truth for project info**: `.github/agent-context/AGENTS.md`
> This file is for **opencode session configuration** only, not project documentation.

## Project Identifier

- **Display name**: DFCustomerPortal
- **Project ID**: AIR226766
- **Workspace root**: `C:\projects\DFCustomerPortal_SPA_AIR226766`

## Canonical Documentation

- **Entry point**: `.github/agent-context/AGENTS.md`
- **Architecture**: `.github/agent-context/architecture.md`
- **Coding conventions**: `.github/agent-context/coding-conventions.md`
- **Project rules**: `.github/agent-context/project-rules.md`
- **Tag index**: `.github/agent-context/_TAG-INDEX.md`
- For ALL project info, conventions, and decisions: see above.

## Opencode Paths

- **Opencode home**: `~/.config/opencode/`
- **Opencode home guide**: `~/.config/opencode/README.md`
- **Human profile source**: `~/.config/opencode/humans/david.romaniuk/humano.md`
- **Project context source**: `~/.config/opencode/projects/DFCustomerPortal_SPA_AIR226766/project.md`
- **Sessions root**: `~/.config/opencode/sessions/`
- **Session snapshots**: `~/.config/opencode/sessions/david.romaniuk/DFCustomerPortal_SPA_AIR226766/`
- **Bootstrap scripts (repo source)**: `.opencode/scripts/`
- **Agent prompts**: `.opencode/agents/`
- **Skills**: `.opencode/skills/`
- **Routing rules**: `.opencode/llm-routing.md`, `.opencode/model-routing.md`

## Repository Commands

```bash
# Build
npm run build
npm run build:local

# Test
npm test
npm run e2e

# Mock + app
npm run mock
npm run mock:local

# Lint
npm run lint
npm run lint:fix
npm run lint:agents
```

## Available Skills

| Skill | Purpose |
|---|---|
| `api-endpoint-factory` | Create API endpoints (4-layer) |
| `permission-system` | Atomic permissions (bitmask) |
| `postgres-best-practices` | Supabase Postgres optimization |
| `canonical-prompter` | Prompt analysis |
| `context-reductor` | Scope definition |
| `librarian` | Angular/Opencode/VSCode docs |
| `doc-maintainer` | Doc health validation |
| `customize-opencode` | Opencode config editing |
| `sessions-setup` | Sessions/bootstrap structure audit |

## LLM Routing

See `.opencode/llm-routing.md` and `.github/agent-workflows/llm-routing.md`.

## Important Notes

- This file is opencode config, NOT project documentation
- For project info (Angular version, conventions, anti-patterns), see `.github/agent-context/`
- Do not duplicate info from agent-context here
- For opencode home structure, bootstrap flow, and file purposes, see `.opencode/session-structure.md`
