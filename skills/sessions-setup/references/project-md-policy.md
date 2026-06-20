# project.md Policy

## Two-Tier Structure (in `~/.config/opencode/`)

| Tier | Location | Content |
|---|---|---|
| **Master source** | `projects/{project_id}/project.md` | Mirror of `docs/project.md` with review metadata header. Updated when the repo changes. |
| **Session slang snapshot** | `sessions/{human_id}/{project_id}/project.md` | **Project slang / lunfardo del proyecto.** Internal jargon, abbreviations, how this codebase names things. Inferred from codebase with confidence levels. NOT a copy of `docs/project.md`. |

## Why Two Tiers

- `docs/project.md` is the **canonical metadata** (stack, commands, domain entities). It is part of the repo, version-controlled, and shared across all humans working on the project.
- The session slang snapshot is **per-human and per-project**. It captures how THIS human refers to project concepts ("el polvo", "la factura"). Like `humano.md`, it is a translation dictionary, not a doc to be edited for the world.

## Master Source Contains

1. The full content of `docs/project.md` (verbatim)
2. A header with:
   - `ROLE: master source file`
   - `SOURCE REPO: {repo_path}/docs/project.md`
   - `LAST REVIEWED`, `NEXT REVIEW DUE`, `REVIEW CADENCE: monthly`

## Session Slang Snapshot Contains

1. The header above (sans `SOURCE REPO` link, replaced with `SESSION FOR`)
2. A short note explaining the difference from `humano.md`
3. A table: Term | Meaning | Location (code) | Confidence
4. Optionally: business-specific dictionaries (e.g. for a "metafuegos" project: `polvo`, `matafuego`, `factura` -> English equivalents)

## Sync Direction

- `docs/project.md` -> `projects/{project_id}/project.md`: handled by `sync-project.ps1`.
- `projects/{project_id}/project.md` -> `docs/project.md`: NEVER automatic. The repo doc is the source of truth; if it needs to change, edit the repo.
- `projects/{project_id}/project.md` -> `sessions/{human_id}/{project_id}/project.md`: only the human-agnostic project content is mirrored; the slang table is per-human and stays in the session.

## Review Cadence

- Default: **monthly (~30 days)**
- Review earlier if:
  - `docs/project.md` changed materially
  - Architecture or base technology changed
  - The human starts using new project jargon
