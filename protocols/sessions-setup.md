# Protocol: Sessions Setup

Conventions for opencode home bootstrap and session-structure maintenance. Defines what lives in `~/.config/opencode/`, which files are sources of truth, and which scripts to use.

## Source of truth

- **Structure and naming**: `.opencode/session-structure.md`
- **Bootstrap/sync scripts**: `.opencode/scripts/`
- **Policy details**: see [humano.md policy](#humano-md-policy) and [project.md policy](#project-md-policy) below

## What to do

1. Audit `~/.config/opencode/` before changing anything.
2. Distinguish:
   - `humans/` and `projects/` = source-of-truth inputs
   - `sessions/` = working snapshots and per-task artifacts
3. If base structure is missing, run the bootstrap script first.
4. Prefer updating source docs/scripts instead of relying on implicit startup assumptions.
5. Keep bootstrap idempotent and non-destructive by default.

## Canonical commands

```powershell
# Verify only
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -VerifyOnly

# Create/update missing base structure
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1"
```

## Session Bootstrap Workflow

The session startup process is defined in `.opencode/workflows/session-bootstrap.md` and executed by the `session-manager` subagent (`.opencode/agents/session-manager.md`).

The delivery agent launches the session-manager in parallel with prompt analysis:

1. **session-manager** runs the 4-phase bootstrap workflow (check → sync → decide → create)
2. **delivery** runs canonical-prompter + context-reductor on the prompt
3. When both complete, delivery combines results and makes the routing decision

The session-manager returns a structured **Session Bootstrap Report** with:
- Session path (for orchestrator handoff)
- Context status (human slang count, project slang count)
- Files created
- Warnings (if any)

## Rules

- Treat delivery/session startup checks as prompt/documentation behavior unless there is explicit runtime code.
- Do not overwrite human-authored session snapshots unless the operator explicitly asks for it.
- Keep naming explicit: source vs snapshot vs per-session artifact.

## humano.md policy

### Source vs copy

| File | Location | Rule |
|------|----------|------|
| **Source** | `humans/{human_id}/humano.md` | Master copy. Edit here, then sync. |
| **Sessions copy** | `sessions/{human_id}/humano.md` | Exact copy. Never edit directly. |

### Dictionary structure

The dictionary has TWO sections:

1. **Slang/Colloquialisms** — how the human talks in their language
2. **Technical Terms** — project-specific jargon the human uses

### Dictionary rules

- Dictionary is for **TRANSLATION only**, not style matching.
- The agent does NOT imitate the human's colloquialisms.
- Agent speaks in neutral/professional tone in the human's language.
- If a term is about the **project domain**, it goes in `project.md` (Project Slang).
- If a term is about **how this human talks**, it goes in `humano.md`.

### Health thresholds

| Term Count | Status | Action |
|------------|--------|--------|
| 0-50 | Compact (OK) | Continue adding |
| 51-100 | Growing | Be selective |
| 101+ | Large | Alert human, suggest pruning |

## project.md policy

### Two-tier structure (in `~/.config/opencode/`)

| Tier | Location | Content |
|---|---|---|
| **Master source** | `projects/{project_id}/project.md` | Mirror of `docs/project.md` with review metadata header. Updated when the repo changes. |
| **Session slang snapshot** | `sessions/{human_id}/{project_id}/project.md` | **Project slang / lunfardo del proyecto.** Internal jargon, abbreviations, how this codebase names things. Inferred from codebase with confidence levels. NOT a copy of `docs/project.md`. |

### Why two tiers

- `docs/project.md` is the **canonical metadata** (stack, commands, domain entities). It is part of the repo, version-controlled, and shared across all humans working on the project.
- The session slang snapshot is **per-human and per-project**. It captures how THIS human refers to project concepts. Like `humano.md`, it is a translation dictionary, not a doc to be edited for the world.

### Master source contains

1. The full content of `docs/project.md` (verbatim)
2. A header with:
   - `ROLE: master source file`
   - `SOURCE REPO: {repo_path}/docs/project.md`
   - `LAST REVIEWED`, `NEXT REVIEW DUE`, `REVIEW CADENCE: monthly`

### Session slang snapshot contains

1. The header above (sans `SOURCE REPO` link, replaced with `SESSION FOR`)
2. A short note explaining the difference from `humano.md`
3. A table: Term | Meaning | Location (code) | Confidence
4. Optionally: business-specific dictionaries (e.g., domain-specific jargon → English equivalents)

### Sync direction

- `docs/project.md` → `projects/{project_id}/project.md`: handled by `sync-project.ps1`.
- `projects/{project_id}/project.md` → `docs/project.md`: NEVER automatic. The repo doc is the source of truth; if it needs to change, edit the repo.
- `projects/{project_id}/project.md` → `sessions/{human_id}/{project_id}/project.md`: only the human-agnostic project content is mirrored; the slang table is per-human and stays in the session.

### Review cadence

- Default: **monthly (~30 days)**
- Review earlier if:
  - `docs/project.md` changed materially
  - Architecture or base technology changed
  - The human starts using new project jargon
