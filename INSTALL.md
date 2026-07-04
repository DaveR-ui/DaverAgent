# Install the DaverAgent agent system into a new project

> One-page, copy-paste checklist. Follow the steps in order. Every step has a `VerifyOnly` mode that writes nothing — use it before applying.

This guide is for the **human**. It assumes you are starting from a fresh (or freshly-cloned) project repo and want to install the agent system that lives in `.opencode/` of this repo.

---

## 0. Prerequisites

- PowerShell 5.1+ (Windows) or PowerShell 7+ (cross-platform).
- The agent source tree: clone `DaveR-ui/DaverAgent` into your project as `.opencode/` (or copy `.opencode/` from a sibling project).
- Your project must have a `docs/` folder at its root (the installer creates it if missing).
- A `.gitignore` that ignores `.opencode/.backups/` (the installer writes backups there).

## 1. Add `.opencode/` to your project

From the root of your project:

```powershell
# If you have not cloned yet:
git clone https://github.com/DaveR-ui/DaverAgent.git .opencode

# Or, if you already have a sibling project that uses the agent:
# Copy-Item -Recurse -Force "..\other-project\.opencode" ".\.opencode"
```

The folder is self-contained. It includes the JSON config, the install/upgrade scripts, the agent system prompts, the protocols, and the reference docs for the *-expert subagents.

## 2. Update `.gitignore`

Append these lines to your `.gitignore` (idempotent — re-add is safe):

```gitignore
# DaverAgent runtime state
.opencode/.backups/
.opencode/.worktrees/

# The agent config that opencode reads at startup (see step 4)
opencode.json
```

`opencode.json` is **regenerated** by the installer, so it should not be committed. The source of truth is `.opencode/jason-opencode.json`.

## 3. Verify the installer plan (no writes yet)

From the project root, in PowerShell:

```powershell
& ".\.opencode\scripts\install-agent.ps1" -NonInteractive -VerifyOnly
```

You should see a list of files the installer would create, update, or skip. Read every line. Confirm:

- `docs/project.md` is in the "would create" list.
- `docs/context/*.md` includes the strategy docs you care about.
- `.opencode/agents/subagents/*.md` shows the subagents you want.
- `opencode.json` is in the "exists, kept" list (because we have not created it yet — that is fine).

If the schema is missing a context doc, subagent, or protocol you need, see [§ 7 Extending the schema](#7-extending-the-schema) below.

## 4. Materialise `opencode.json` (the file opencode actually reads)

The installer regenerates `opencode.json` from a small built-in template, but it preserves an existing curated file. We copy the curated source so the opencode runtime gets a richer config (model names, permissions, instructions list) than the installer's auto-generated one:

```powershell
# If you have a curated jason-opencode.json in the agent tree:
Copy-Item -LiteralPath ".\.opencode\jason-opencode.json" -Destination ".\opencode.json" -Force

# Validate
Get-Content -LiteralPath ".\opencode.json" -Raw | ConvertFrom-Json | Out-Null
if ($?) { "opencode.json is valid" }
```

If your agent tree does not ship a `jason-opencode.json`, let the installer generate `opencode.json` instead (skip the `Copy-Item` and re-run `install-agent.ps1` without `-VerifyOnly`).

## 5. Apply the installer (writes files)

```powershell
& ".\.opencode\scripts\install-agent.ps1" -NonInteractive
```

The script is **non-destructive by default**: it never overwrites an existing file. It creates files that are missing and skips files that already match. The first run typically creates:

- `docs/project.md`
- `docs/context/architecture.md`, `docs/context/api-contracts.md`, `docs/context/naming-registry.md`, `docs/context/README.md`
- `.opencode/agents/subagents/documenter.md` (the other subagents are already in the tree)

## 6. Bootstrap the opencode home (`~/.config/opencode/`)

The agent reads three things from your home directory: a `humano.md` (your personal dictionary), a `projects/<project>/project.md` (the master copy of the project metadata), and a `sessions/<you>/<project>/project.md` (your personal project slang). Bootstrap them:

```powershell
# Verify only — list what would be created
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -VerifyOnly

# Apply
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1"
```

This creates the directories and stub files under `$env:USERPROFILE\.config\opencode\`. It does **not** touch any file in the project repo.

## 7. Sync the canonical docs into the opencode home

After install + bootstrap, copy the canonical repo docs into the opencode home so the agent can read them on startup:

```powershell
# Copies docs/project.md -> ~/.config/opencode/projects/<project>/project.md
& ".\.opencode\scripts\sync-project.ps1"

# Copies humans/<you>/humano.md -> sessions/<you>/humano.md
& ".\.opencode\scripts\sync-humano.ps1"
```

## 8. Smoke test

```powershell
& ".\.opencode\scripts\test-opencode-structure.ps1"
```

Expected output: `VerifyOnly: 0 missing or stale item(s).` Any non-zero count means a file the agent expects is missing or empty.

## 9. Edit the generated stubs

The installer creates stubs; you fill in the substance:

| File | Fill in |
|---|---|
| `docs/project.md` | Real project name, stack, commands, slices, domain entities |
| `docs/context/architecture.md` | Layers, dependency rules |
| `docs/context/api-contracts.md` | HTTP status codes, response shape, pagination |
| `docs/context/naming-registry.md` | DB ↔ language ↔ JSON name mapping |
| `docs/context/rules.md` *(if enabled)* | Coding standards, error handling, security |
| `~/.config/opencode/humans/<you>/humano.md` | Your personal slang dictionary |
| `~/.config/opencode/sessions/<you>/<project>/project.md` | Project slang for this codebase |

The `deliver` agent picks up these docs on the next session and starts routing tasks through them.

---

## Updating later

| Change | Command |
|---|---|
| Add a slice to `docs/project.md` | Edit the file directly; run `sync-project.ps1`. |
| Add or update a subagent | Edit `.opencode/agents/subagents/<id>.md`; ensure the agent is in `jason-opencode.json`'s `agent.task` allowlist. |
| Add a new context doc type | Add an entry under `context_templates` in `.opencode/scripts/install-agent.schema.json`, then re-run `install-agent.ps1`. |
| Regenerate everything from scratch | Delete `docs/project.md` and the unwanted `docs/context/*.md` stubs, then re-run `install-agent.ps1`. The installer will not touch curated files unless you also delete them. |
| Audit what would change | Append `-VerifyOnly` to any of the above scripts. |

## Troubleshooting

**"The agent ignores my `docs/project.md`."**
Make sure the `instructions` array in `opencode.json` references the path you used (relative to the project root). The default is `docs/project.md`.

**"`opencode.json` keeps changing on every install."**
You are editing the auto-generated file directly. Either commit to a curated `jason-opencode.json` (step 4) and copy it on every install, or stop editing it and let the installer regenerate it from the schema.

**"Bootstrap warns about an existing `humano.md`."**
Bootstrap is non-destructive. It only fills in missing files. To replace a stub with a real dictionary, edit the file directly in `~/.config/opencode/humans/<you>/`.

**"I see `MISSING FILE ... project.md` after bootstrap."**
The bootstrap script writes a stub. To replace it with the real content, run `sync-project.ps1` after editing `docs/project.md`.

---

## Per-project checklist (TL;DR)

```powershell
# 0. Clone the agent tree (or copy from a sibling project)
git clone https://github.com/DaveR-ui/DaverAgent.git .opencode

# 1. Update .gitignore
Add-Content -LiteralPath ".\.gitignore" -Value "`n.opencode/.backups/`nopencode.json`n"

# 2. Verify the install plan
& ".\.opencode\scripts\install-agent.ps1" -NonInteractive -VerifyOnly

# 3. Copy the curated config
Copy-Item -LiteralPath ".\.opencode\jason-opencode.json" -Destination ".\opencode.json" -Force

# 4. Apply the installer
& ".\.opencode\scripts\install-agent.ps1" -NonInteractive

# 5. Bootstrap the opencode home
& ".\.opencode\scripts\bootstrap-opencode-structure.ps1"

# 6. Sync the canonical docs
& ".\.opencode\scripts\sync-project.ps1"
& ".\.opencode\scripts\sync-humano.ps1"

# 7. Smoke test
& ".\.opencode\scripts\test-opencode-structure.ps1"

# 8. Fill in the stubs (project.md, context docs, humano.md)
```

After step 8, `delivery` will read the new docs on the next session.
