# Project Context

> **STATUS**: DEPRECATED. The master source now mirrors the project entry point (see `.opencode/conventions.md`) in-repo. This template is kept only for compatibility with very old bootstrap paths. The script `sync-project.ps1` no longer reads this template; it reads the project entry point directly and writes the slang snapshot from `project-session-template.md`.

> **ROLE**: master source file (legacy)
> **EDIT HERE**: `~/.config/opencode/projects/{{PROJECT_ID}}/project.md`
> **SOURCE REPO**: `{{PROJECT_REPO_PATH}}/<project_entry_point>` (see `.opencode/conventions.md`)

> **LAST REVIEWED**: {{LAST_REVIEWED}}
> **NEXT REVIEW DUE**: {{NEXT_REVIEW_DUE}}
> **REVIEW CADENCE**: monthly (~30 days)

## Overview
- **Project Name**: {{PROJECT_NAME}}
- **Project ID**: {{PROJECT_ID}}
- **Description**: {{PROJECT_DESCRIPTION}}

## Technology Stack
{{TECH_STACK}}

## Architecture
{{ARCHITECTURE}}

## Commands
{{COMMANDS}}

## Notes
{{NOTES}}
