---
name: sessions-setup
description: Use when bootstrapping, auditing, or repairing the opencode home under ~/.config/opencode/, especially for humans/, projects/, sessions/, humano.md, project.md, session snapshots, or bootstrap scripts.
---

# Sessions Setup

Use this skill for opencode home bootstrap and session-structure maintenance.

## Source of Truth

- Structure and naming: `.opencode/session-structure.md`
- Bootstrap/sync scripts: `.opencode/scripts/`
- Policy details: `references/humano-md-policy.md`, `references/project-md-policy.md`

## What to do

1. Audit `~/.config/opencode/` before changing anything.
2. Distinguish:
   - `humans/` and `projects/` = source-of-truth inputs
   - `sessions/` = working snapshots and per-task artifacts
3. If base structure is missing, run the bootstrap script first.
4. Prefer updating source docs/scripts instead of relying on implicit startup assumptions.
5. Keep bootstrap idempotent and non-destructive by default.

## Canonical Commands

```powershell
# Verify only
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -VerifyOnly

# Create/update missing base structure
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1"
```

## Rules

- Treat delivery/session startup checks as prompt/documentation behavior unless there is explicit runtime code.
- Do not overwrite human-authored session snapshots unless the operator explicitly asks for it.
- Keep naming explicit: source vs snapshot vs per-session artifact.
