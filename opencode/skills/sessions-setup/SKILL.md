---
name: sessions-setup
description: Initializes and maintains the opencode sessions directory structure (~/.config/opencode/sessions/). Use this skill whenever the delivery agent needs to bootstrap context, set up a new human profile, register a new project, create work sessions, sync humano.md or project.md, or audit session consistency. Also use when you see references to "sessions", "humano.md", "project.md", "session structure", or when the delivery agent workflow requires loading human/project context. Triggers on keywords like "setup sessions", "init sessions", "new session", "sync humano", "sync project", "session structure", "create session", "bootstrap context", "delivery agent setup".
---

# Sessions Setup

Initialize and maintain the delivery agent's session infrastructure at `~/.config/opencode/`.

## What I Do

- Initialize the full `~/.config/opencode/` directory structure (`humans/`, `projects/`, `sessions/`)
- Create and sync `humano.md` (human profile with translation dictionary)
- Create and sync `project.md` (project context, condensed version + Project Slang)
- Create new work sessions with proper naming and template
- Audit session consistency and fix drift
- Run PowerShell helper scripts for common operations

## When to Use Me

- First time setting up opencode sessions for a human
- Registering a new project in the sessions system
- Creating a new work session (`DDMMYYYY-keywords`)
- Syncing `humano.md` or `project.md` after source changes
- Auditing/fixing session directory consistency
- When the delivery agent needs to bootstrap its context

---

## Directory Structure

```
~/.config/opencode/
├── humans/
│   └── {human_id}/              # OS username (e.g., david.romaniuk)
│       └── humano.md            # Master profile (edit here, sync to sessions)
├── projects/
│   └── {project_id}/            # Repo folder name (e.g., DFCustomerPortal_SPA_AIR226766)
│       └── project.md           # Full project context (faithful copy of repo's .opencode/project.md)
└── sessions/
    ├── README.md                # System documentation
    ├── _scripts/                # PowerShell helper scripts
    │   ├── init-sessions.ps1    # Full bootstrap from scratch
    │   ├── sync-humano.ps1      # Sync humano.md source -> sessions
    │   ├── sync-project.ps1     # Sync project.md source -> sessions
    │   └── new-session.ps1      # Create new work session
    ├── _templates/              # File templates
    │   ├── humano-template.md
    │   ├── project-template.md
    │   └── general-context-template.md
    └── {human_id}/
        ├── humano.md            # Copy synced from humans/{human_id}/
        └── {project_id}/
            ├── project.md       # Condensed version + Project Slang section
            └── {DDMMYYYY-keywords}/
                ├── general-context.md
                ├── enhanced-prompt.md
                ├── scope.md
                └── assets/
```

---

## Naming Conventions

| Entity | Convention | Example |
|--------|-----------|---------|
| **Human ID** | OS username | `david.romaniuk` |
| **Project ID** | Repository folder name (not a shortened slug) | `DFCustomerPortal_SPA_AIR226766` |
| **Session ID** | `DDMMYYYY-keywords`, kebab-case, 2-4 keywords | `10062026-sessions-cleanup` |

---

## Procedures

### Procedure A: Full Bootstrap (First Time Setup)

Run the init script (idempotent, safe to re-run):

```powershell
& "$env:USERPROFILE\.config\opencode\sessions\_scripts\init-sessions.ps1" `
  -HumanId "david.romaniuk" `
  -ProjectId "DFCustomerPortal_SPA_AIR226766" `
  -RepoPath "C:\projects\DFCustomerPortal_SPA_AIR226766"
```

The script performs these steps:
1. Create base directories: `humans/`, `projects/`, `sessions/`, `sessions/_scripts/`, `sessions/_templates/`
2. Create `humans/{human_id}/humano.md` from template (if missing)
3. Create `projects/{project_id}/project.md` by copying repo's `.opencode/project.md` with review metadata header (if missing)
4. Create `sessions/{human_id}/humano.md` as copy of source
5. Create `sessions/{human_id}/{project_id}/project.md` as condensed version + Project Slang (if missing)
6. Copy templates to `sessions/_templates/` (if missing)
7. Copy scripts to `sessions/_scripts/` (if missing)
8. Create `sessions/README.md` (if missing)
9. Print summary of what was created

### Procedure B: Register New Human

1. Create `humans/{human_id}/humano.md` from `sessions/_templates/humano-template.md`
2. Fill in identity, language, communication preferences, and initial dictionary
3. Create `sessions/{human_id}/humano.md` as copy:
   ```powershell
   & "$env:USERPROFILE\.config\opencode\sessions\_scripts\sync-humano.ps1" -HumanId "{human_id}"
   ```

### Procedure C: Register New Project

1. Copy `{repo}/.opencode/project.md` to `projects/{project_id}/project.md`
2. Add review metadata header:
   ```markdown
   > **LAST REVIEWED**: YYYY-MM-DD
   > **NEXT REVIEW DUE**: YYYY-MM-DD
   > **REVIEW CADENCE**: monthly (~30 days)
   ```
3. Create condensed `sessions/{human_id}/{project_id}/project.md`:
   ```powershell
   & "$env:USERPROFILE\.config\opencode\sessions\_scripts\sync-project.ps1" `
     -HumanId "{human_id}" -ProjectId "{project_id}" -RepoPath "{repo_path}"
   ```
4. Review and edit the sessions copy to be a condensed version with Project Slang section

### Procedure D: Create New Session

1. Generate session name: `DDMMYYYY-keywords` (e.g., `10062026-sessions-cleanup`)
2. Run:
   ```powershell
   & "$env:USERPROFILE\.config\opencode\sessions\_scripts\new-session.ps1" `
     -SessionName "DDMMYYYY-keywords" -HumanId "{human_id}" -ProjectId "{project_id}"
   ```
3. Fill in `general-context.md` with original prompt, classification, and enhanced description

### Procedure E: Sync humano.md

1. Edit the **SOURCE** at `humans/{human_id}/humano.md`
2. Run:
   ```powershell
   & "$env:USERPROFILE\.config\opencode\sessions\_scripts\sync-humano.ps1" -HumanId "{human_id}"
   ```
3. The sessions copy at `sessions/{human_id}/humano.md` is overwritten with the source

### Procedure F: Sync project.md

1. Update source at `projects/{project_id}/project.md` from repo's `.opencode/project.md`
2. Run:
   ```powershell
   & "$env:USERPROFILE\.config\opencode\sessions\_scripts\sync-project.ps1" `
     -HumanId "{human_id}" -ProjectId "{project_id}" -RepoPath "{repo_path}"
   ```
3. **Note**: The sessions copy is a CONDENSED version. After sync, review and update the condensed version manually if needed.

### Procedure G: Audit Consistency

Check for:
- **Human ID consistency**: same ID across `humans/`, `sessions/`
- **Project ID consistency**: same ID across `projects/`, `sessions/{human_id}/`
- **humano.md drift**: compare source vs sessions copy (should be identical)
- **project.md review dates**: check `Next Review Due` (monthly cadence)
- **Missing templates or scripts**: verify `_templates/` and `_scripts/` are complete
- **Orphaned session folders**: sessions without `general-context.md` or with empty `assets/`

Manual audit commands:
```powershell
# Check humano.md drift
$base = "$env:USERPROFILE\.config\opencode"
fc.exe "$base\humans\david.romaniuk\humano.md" "$base\sessions\david.romaniuk\humano.md"

# List all sessions for a human/project
Get-ChildItem "$base\sessions\david.romaniuk\DFCustomerPortal_SPA_AIR226766" -Directory

# Check project.md review dates
Select-String -Path "$base\sessions\*\*\project.md" -Pattern "Next Review Due"
```

---

## project.md Policy

Two-tier structure:
- **Source** (`projects/{project_id}/project.md`): Faithful copy of repo's `.opencode/project.md` with review metadata
- **Sessions copy** (`sessions/{human_id}/{project_id}/project.md`): Condensed version with Project Slang

For full details on structure, contents, and review cadence, see `references/project-md-policy.md`.

---

## humano.md Policy

- **Source** (`humans/{human_id}/humano.md`): Master copy. Edit here, sync to sessions.
- **Sessions copy** (`sessions/{human_id}/humano.md`): Exact copy. Never edit directly.
- Dictionary is for **TRANSLATION only**, not style matching.

For full details on dictionary structure, rules, and health thresholds, see `references/humano-md-policy.md`.

---

## Scripts Reference

| Script | Purpose | Parameters |
|--------|---------|------------|
| `init-sessions.ps1` | Full bootstrap from scratch | `-HumanId`, `-ProjectId`, `-RepoPath` |
| `sync-humano.ps1` | Sync humano.md source to sessions | `-HumanId` |
| `sync-project.ps1` | Sync project.md source to sessions | `-HumanId`, `-ProjectId`, `-RepoPath` |
| `new-session.ps1` | Create new work session folder | `-SessionName`, `-HumanId`, `-ProjectId` |

All scripts are idempotent and located at `~/.config/opencode/sessions/_scripts/`.

Default parameter values:
- `-HumanId`: `david.romaniuk`
- `-ProjectId`: `DFCustomerPortal_SPA_AIR226766`
- `-RepoPath`: `C:\projects\DFCustomerPortal_SPA_AIR226766`

---

## Integration with Delivery Agent

The sessions-setup skill is the **first step** in the delivery agent workflow:

```
Human sends prompt
       |
       v
Delivery Agent loads sessions-setup skill
       |
       v
Check if humano.md exists in sessions/
  NO  -> Run Procedure B (Register New Human)
  YES -> Continue
       |
       v
Check if project.md exists in sessions/{human}/{project}/
  NO  -> Run Procedure C (Register New Project)
  YES -> Check Next Review Due
         EXPIRED -> Run Procedure F (Sync project.md)
         VALID   -> Continue
       |
       v
Classify complexity
  SIMPLE -> Work without session
  MODERATE/COMPLEX -> Run Procedure D (Create New Session)
       |
       v
Fill general-context.md with original prompt + classification
       |
       v
Handoff to orchestrator (in English)
```

### Session Complexity Rule

- **Simple** tasks (brief queries, single-step changes, no persistent context needed): do NOT create a session
- **Moderate/Complex** tasks (multi-step, attachments, persistent context, or human requests it): create a session
- If a task starts simple but grows during conversation, create the session at that point
