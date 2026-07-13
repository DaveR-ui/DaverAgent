# Opencode Home Structure

Authoritative guide for `~/.config/opencode/`.

## Why this exists

The delivery agent and session workflow use files outside the repo for human-specific state and reusable session artifacts. This is prompt/configuration behavior, not app runtime code.

## Canonical layout

```text
~/.config/opencode/
├── README.md                             # top-level explanation and quick commands
├── opencode.jsonc                        # global opencode config
├── humans/
│   ├── README.md                         # why human sources live here
│   └── {human_id}/
│       └── humano.md                     # master human profile source
├── projects/
│   ├── README.md                         # why project sources live here
│   └── {project_id}/
│       └── project.md                    # master project source copied from repo docs
└── sessions/
    ├── README.md                         # snapshot/session rules
    ├── _scripts/                         # bootstrap, sync, new-session helpers
    ├── _templates/                       # templates copied by bootstrap
    └── {human_id}/
        ├── humano.md                     # synced human snapshot used by sessions
        └── {project_id}/
            ├── project.md                # condensed project snapshot used by sessions
            └── {DDMMYYYY-keywords}/
                ├── general-context.md    # raw prompt + translation + metadata
                ├── enhanced-prompt.md    # optional prompt-analysis output
                ├── scope.md              # optional scope-analysis output
                ├── assets/               # attached files/images for the task
                └── orchestrator-snapshots/
                    └── {uuid}.md         # per-orchestrator-instance snapshot (delivery writes this)
```

## Purpose of each relevant item

| Path | Purpose |
|---|---|
| `opencode.jsonc` | Global opencode config loaded at startup. |
| `README.md` | Human-readable explanation of the global opencode home. |
| `humans/` | Source-of-truth human profiles; personal, editable, not task-specific. |
| `humans/{human_id}/humano.md` | Master human vocabulary/preferences file. |
| `projects/` | Source-of-truth project context snapshots derived from repo docs. |
| `projects/{project_id}/project.md` | Master project context source for a repo/project. |
| `sessions/` | Working area for snapshots and per-task session artifacts. |
| `sessions/_scripts/` | Global copies of the helper scripts for bootstrap/sync/create-session flows. |
| `sessions/_templates/` | Reusable templates used when creating missing files or new sessions. |
| `sessions/{human_id}/humano.md` | Session-facing copy of the human source. |
| `sessions/{human_id}/{project_id}/project.md` | Session-facing condensed copy of the project source. |
| `sessions/{human_id}/{project_id}/{session_id}/general-context.md` | Preserves the original request and session metadata. |
| `sessions/{human_id}/{project_id}/{session_id}/assets/` | Stores task-specific attachments. |
| `sessions/{human_id}/{project_id}/{session_id}/orchestrator-snapshots/{uuid}.md` | Per-orchestrator-instance snapshot; `delivery` writes this when the orchestrator returns its `agent-snapshot`. |
| `sessions/{human_id}/{project_id}/{session_id}/assets/` | Task-specific attachments. |

### Subagent outcomes

Subagent outcomes do **not** live in the file tree. They flow through the runtime:

- The `task` tool, when called with a subagent that has an `output_schema` in `opencode.json`, validates the return and includes the structured JSON in the `Subagent.Completed` event on the EventV2 bus.
- `GET /session/:id/children` returns a `ChildInfo[]` array (status, summary, agent type, durationMs) for every subagent spawned from a parent session.
- The `session-archiver` protocol reads the durable event stream and produces `session-digest.md` from it (no per-agent files involved).

The legacy `summary.md` / `output-full.md` / `manifest.md` layout and the file-based interruption bus (`traffic-light.md` / `interruption-log.md` / `reasoning-full.md`) have been removed. New agents must not write those files.

## Source vs snapshot rules

- Edit `humans/{human_id}/humano.md` as the master human file.
- Edit `projects/{project_id}/project.md` as the master project file.
- Treat files under `sessions/{human_id}/...` as snapshots/working copies.
- Bootstrap creates missing sources and snapshots; sync scripts refresh them intentionally.

## Current startup assumptions

The current startup logic is instruction-driven, not a separate runtime service.

Relevant assumption points in this repo:
- `.opencode/agents/delivery.md`
- `docs/project.md` (project entry point; mirrored into the opencode home by `sync-project.ps1`)
- `docs/context/README.md` (strategic docs index)
- `.opencode/protocols/sessions-setup.md` (bootstrap + humano.md / project.md two-tier policies)
- `.opencode/protocols/README.md` (index of all agent protocols)

In other words: the delivery agent prompt assumes the structure exists unless docs/scripts tell it how to bootstrap it. The repo-level project source of truth is `docs/project.md`. There is no `.opencode/project.md` and no `AGENT.md`.

## Bootstrap flow

Canonical repo-side script:

```powershell
# verify expected structure without changing files
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -VerifyOnly

# create missing base structure and refresh docs/scripts/templates
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -RefreshDocumentation -RefreshScripts -RefreshTemplates
```

What it does:

1. Ensures base directories exist.
2. Creates top-level and nested README files.
3. Copies helper scripts into `sessions/_scripts/`.
4. Copies templates into `sessions/_templates/`.
5. Creates missing `humano.md` source/snapshot files.
6. Creates missing `project.md` source/snapshot files.

## Naming improvements

To reduce ambiguity:

- use **source** for `humans/` and `projects/`
- use **snapshot** for files under `sessions/{human}/{project}/`
- use **session artifact** for files inside a specific `{DDMMYYYY-keywords}` folder
- prefer `bootstrap-opencode-structure.ps1` over the older ambiguous `init-sessions.ps1`
- prefer `project-source-template.md` and `project-session-template.md` over a single ambiguous `project-template.md`

`init-sessions.ps1` may remain as a compatibility wrapper.
