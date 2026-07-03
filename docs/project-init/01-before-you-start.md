# 01 — Before You Start

> Things to know before starting any opencode project initialization. Read this file FIRST.

---

## The single source of truth for paths

`.opencode/conventions.md` is the canonical reference for project doc paths. **Read it before anything else.** It defines:

- `project_entry_point` → `docs/project.md`
- `context_dir` → `docs/context/`
- `context_index` → `docs/context/README.md`
- `rules_file` → `docs/context/rules.md`
- `architecture_file` → `docs/context/architecture.md`

All agents reference `conventions.md` instead of hardcoding paths. If paths change, update `conventions.md` — not individual agents.

---

## The opencode home

The opencode home lives at `~/.config/opencode/` — **NOT** `~/.opencode/`.

On Windows the full path is: `C:\Users\{user}\.config\opencode\`

Key subdirectories:

| Path | Purpose |
|------|---------|
| `humans/{human_id}/humano.md` | Master human profile (language, work style, active projects) |
| `projects/{project_id}/project.md` | Master project context source |
| `sessions/{human_id}/{project_id}/{session_id}/` | Per-session working artifacts |

**Load `humano.md` before speaking with the human.** It contains language preference, work style, and active projects. Speaking the wrong language or ignoring stated preferences is the fastest way to lose trust.

---

## Greenfield reality

For greenfield projects, `docs/` is empty or near-empty. The first real task is usually **creating the documentation**, not consuming it.

- `sync-project.ps1` will **fail** until `docs/project.md` exists. This is **expected**, not an error. Re-run sync after creating the file.
- The project master source (`projects/{id}/project.md`) starts as a template with TODO placeholders. It gets populated when `docs/project.md` is created.

---

## The parallel startup flow

Initialization is not strictly sequential. Two things run concurrently:

1. **session-manager** (bootstrap) — creates directory structure, syncs `humano.md`, builds session paths.
2. **delivery** (prompt analysis) — analyzes the human's prompt, classifies intent, identifies modules.

They join when routing decisions are needed (the delivery agent needs the session path to write artifacts).

---

## Essential first-reads

Before doing anything, read these files in order:

1. `.opencode/conventions.md` — canonical paths
2. `.opencode/protocols/README.md` — index of all agent protocols
3. `.opencode/llm-routing.md` — model selection policy
4. `.opencode/session-structure.md` — opencode home layout
5. `docs/project.md` — project entry point (if it exists; if not, that's your first task)

---

## Gotchas

- **`$home` is read-only in PowerShell.** Use `$env:USERPROFILE` instead when scripting path resolution. `$home` resolves to the user's Documents folder in some contexts, not the profile root.
- **`conventions.md` may not exist in fresh installs.** The bootstrap script (`bootstrap-opencode-structure.ps1`) creates it. If you're reading a repo that hasn't been bootstrapped yet, the file won't be there.
- **Don't confuse `docs/protocols/` with `.opencode/protocols/`.** The former is project-specific conventions (query patterns, error catalogs). The latter is agent system behavior (how the agent system coordinates). They live in different roots for a reason.
- **The opencode home is outside the repo.** Files at `~/.config/opencode/` are not version-controlled with the project. Don't look for them in `git status`.
- **`humano.md` is per-human, not per-project.** A human with multiple projects has one `humano.md`, not one per project.

---

## Quick Reference

| What | Where |
|------|-------|
| Canonical paths | `.opencode/conventions.md` |
| Agent protocols index | `.opencode/protocols/README.md` |
| Model routing policy | `.opencode/llm-routing.md` |
| Opencode home layout | `.opencode/session-structure.md` |
| Project entry point | `docs/project.md` |
| Opencode home (Windows) | `C:\Users\{user}\.config\opencode\` |
| Human profile | `~/.config/opencode/humans/{human_id}/humano.md` |
| Bootstrap script | `.opencode/scripts/bootstrap-opencode-structure.ps1` |

| Rule | Detail |
|------|--------|
| Read order | conventions.md → protocols/README → llm-routing → session-structure → project.md |
| Greenfield sync | Fails until `docs/project.md` exists — expected, not an error |
| PowerShell home var | Use `$env:USERPROFILE`, never `$home` |
| Protocols location | `.opencode/protocols/` (agent system), `docs/protocols/` (project-specific) |