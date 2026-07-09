# 02 — Session Bootstrap

> Session manager, bootstrap script, and sync gotchas. Read this before invoking the session-manager subagent.

---

## The session-manager subagent

The session-manager is a subagent invoked via the **Task tool**. It is **not** a direct command — you launch it like any other subagent.

Responsibilities:

- Bootstrap the opencode home directory structure
- Sync `humano.md` from source to session snapshot
- Create the session path (`sessions/{human_id}/{project_id}/{DDMMYYYY-keywords}`)
- Initialize `agents/manifest.md` before subagents are released
- Return a **Session Bootstrap Report** with: status, summary, phase results, warnings, ready-for-handoff section

---

## The bootstrap script

Script: `.opencode/scripts/bootstrap-opencode-structure.ps1`

| Mode | Flags | What it does |
|------|-------|-------------|
| Verify | `-VerifyOnly` | Checks expected structure without changing files |
| Refresh | `-RefreshDocumentation -RefreshScripts -RefreshTemplates` | Creates missing dirs, READMEs, copies scripts and templates |

The script creates **23+ items** (directories, READMEs, templates, scripts). Don't panic if the output is long — that's normal.

---

## Session path format

```
sessions/{human_id}/{project_id}/{DDMMYYYY-keywords}
```

Example: `sessions/david.romaniuk/ab-ceramica/02072026-architecture-design-docs`

- Date is `DDMMYYYY` (day-first)
- Keywords are hyphenated, lowercase, descriptive of the session's task
- The full path is what subagents write their artifacts into

---

## Two-tier source/snapshot system

| Tier | Location | Role |
|------|----------|------|
| **SOURCE** | `humans/{id}/humano.md`, `projects/{id}/project.md` | Master files — edit these |
| **SNAPSHOT** | `sessions/{id}/humano.md`, `sessions/{id}/{project}/project.md` | Working copies — treat as read-only |

**Edit sources. Treat snapshots as working copies.** Bootstrap copies source → snapshot. If you edit a snapshot, your changes will be overwritten on the next sync.

---

## Session artifacts

Inside the session path:

| Artifact | Purpose |
|----------|---------|
| `general-context.md` | Raw prompt + translation + session metadata |
| `assets/` | Attached files/images for the task |
| `agents/manifest.md` | Index of all subagent outputs in this session |
| `agents/{agent}-{timestamp}/summary.md` | Short report returned to orchestrator |
| `agents/{agent}-{timestamp}/output-full.md` | Detailed report with diffs, logs, findings |

**Initialize `manifest.md` before releasing subagents.** Subagents append rows to it when they finish. If it doesn't exist, they'll error or skip the manifest step.

---

## Agent output structure

Each subagent writes to `agents/{agent}-{timestamp}/`:

- `summary.md` — 5-10 line report returned to the orchestrator (keeps context small)
- `output-full.md` — detailed report with diffs, logs, full findings (read on demand)

The orchestrator reads `summary.md` by default. It only reads `output-full.md` when it needs the full detail. This two-file pattern is how the system keeps context budgets manageable.

---

## Gotchas

- **`sync-project.ps1` fails if `docs/project.md` doesn't exist.** This is **expected** for greenfield projects. The error is loud but harmless. Re-run sync after creating `docs/project.md`.
- **The project master source starts as a template with TODO placeholders.** It gets populated when `docs/project.md` is created. Don't expect real content in `projects/{id}/project.md` until the project docs exist.
- **The project slang snapshot starts empty (0 terms).** Populate incrementally as project jargon is discovered. Don't try to pre-fill it — you'll guess wrong.
- **The session-manager uses Gemini 3.5 Flash.** It's I/O-bound (file creation, copying), so the cheap fast model is correct. Don't expect deep reasoning or analysis from it — that's not its job.
- **Bootstrap creates 23+ items.** The output is long. This is normal, not a sign of failure.
- **`manifest.md` must exist before subagents run.** If you skip this step, subagents may fail to log their outputs.
- **Session path date format is DDMMYYYY, not MMDDYYYY.** If you get the date wrong, the session path won't match what the session-manager created.

---

## Quick Reference

| Command / Path | Detail |
|----------------|--------|
| Bootstrap verify | `& ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -VerifyOnly` |
| Bootstrap refresh | `& ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -RefreshDocumentation -RefreshScripts -RefreshTemplates` |
| Session path format | `sessions/{human_id}/{project_id}/{DDMMYYYY-keywords}` |
| Source vs snapshot | Edit `humans/` and `projects/` sources; treat `sessions/` snapshots as read-only |
| Manifest | Initialize `agents/manifest.md` before releasing subagents |
| Agent output | `summary.md` (short) + `output-full.md` (detailed) per agent |
| Session-manager model | Gemini 3.5 Flash (I/O-bound, cheap) |