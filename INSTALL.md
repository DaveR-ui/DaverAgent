# Install the agent system into a new project

> One-page, copy-paste checklist for the **human**. Every step has a `VerifyOnly` mode that writes nothing — use it before applying.

## 0. Prerequisites

- PowerShell 5.1+ (Windows) or PowerShell 7+ (cross-platform).
- The agent source tree: clone the repo that carries `.opencode/` (this one, or any sibling that has it), or copy `.opencode/` from a sibling project.
- Your project must have a `docs/` folder at its root (the installer creates it if missing).
- A `.gitignore` that ignores `.opencode/.backups/`.

## 1. Add `.opencode/` to your project

From the root of your project:

```powershell
# Option A: clone (if you have access)
git clone https://github.com/<owner>/<agent-repo>.git .opencode

# Option B: copy from a sibling project
Copy-Item -Recurse -Force "..\other-project\.opencode" ".\.opencode"
```

The folder is self-contained. It includes the agent system prompts (`.opencode/agents/subagents/*.md`), the protocols, and the base config `jason-opencode.json`.

## 2. Copy the base config to `opencode.json`

`jason-opencode.json` is the **runtime base config**: copy it to the root of your project as `opencode.json`. It contains only top-level runtime settings (`default_agent`, `compaction`, `references`, global `permission`, `instructions`). Everything about an agent — `description`, `mode`, `model`, `temperature`, `permission`, `output_schema` — lives in its `.md` file under `.opencode/agents/subagents/`. There is no `agent` block in `opencode.json`.

```powershell
Copy-Item ".\.opencode\jason-opencode.json" ".\opencode.json"
```

> `model:` in each agent's frontmatter (`.opencode/agents/subagents/<id>.md`) is optional — adjust the ids (`opencode-go/...`) if your provider differs; when omitted, the subagent inherits the invoking primary agent's model (per opencode docs).

## 3. Update `.gitignore`

Append these lines to your `.gitignore` (idempotent — re-add is safe):

```gitignore
# Agent runtime state
.opencode/.backups/
.opencode/.worktrees/
```

`opencode.json` at the repo root is **version-controlled** — it is the canonical config. Do NOT add it to `.gitignore`.

## 4. Verify the installer plan (no writes yet)

From the project root, in PowerShell:

```powershell
& ".\.opencode\scripts\install-agent.ps1" -NonInteractive -VerifyOnly
```

You should see a list of files the installer would create, update, or skip. Read every line. Confirm:

- `docs/project.md` is in the "would create" list (if missing).
- `docs/context/*.md` includes the strategy docs you care about.
- `.opencode/agents/subagents/*.md` shows the subagents you want.

If the schema is missing a context doc, subagent, or protocol you need, extend it before continuing.

## 5. Apply the installer (writes files)

```powershell
& ".\.opencode\scripts\install-agent.ps1" -NonInteractive
```

The script is **non-destructive by default**: it never overwrites an existing file unless you pass `-Update`. It creates files that are missing and skips files that already match.

## 6. Verify `opencode.json`

`opencode.json` is the config you copied in step 2. Confirm it is valid and has the right agents:

```powershell
Get-Content -LiteralPath ".\opencode.json" -Raw | ConvertFrom-Json | Out-Null
if ($?) { "opencode.json is valid" }

# List the configured agents
(Get-Content -LiteralPath ".\opencode.json" -Raw | ConvertFrom-Json).agent.PSObject.Properties.Name
```

## 6b. Validate the agent tree

Run the full test suite (Git Bash / WSL) before moving on:

```bash
bash .opencode/tests/run-tests.sh
```

It must exit 0. It runs the integrity lint (`validate-agent.sh`) and the output-schema contract tests. `docs/` paths reported as WARN are expected when `docs/project.md` / `docs/context/` do not exist yet — they are created in step 5 or by you.

## 7. Edit the generated stubs

The installer creates stubs; you fill in the substance:

| File | Fill in |
|---|---|
| `docs/project.md` | Real project name, stack, commands, slices, domain entities |
| `docs/context/architecture.md` | Layers, dependency rules |
| `docs/context/rules.md` | Coding standards, error handling, security |
| `~/.config/opencode/humans/<you>/humano.md` | Your personal slang dictionary (optional) |

The `delivery` agent picks up these docs on the next session and starts routing tasks through them.

---

## Updating later

| Change | Command |
|---|---|
| Add a slice to `docs/project.md` | Edit the file directly. |
| Add or update a subagent | Edit `.opencode/agents/subagents/<id>.md` (frontmatter includes `model`/`temperature`). |
| Change a model / temperature | Edit `.opencode/agents/subagents/<id>.md` -> `model` / `temperature`, then restart opencode. `opencode.json` is untouched. |
| Add a new context doc type | Add the file under `docs/context/` and update the index in `docs/context/README.md`. |
| Regenerate everything from scratch | Delete `docs/project.md` and the unwanted `docs/context/*.md` stubs, then re-run `install-agent.ps1`. |
| Audit what would change | Append `-VerifyOnly` to any of the above scripts. |

## Troubleshooting

**"The agent ignores my `docs/project.md`."**
Make sure the `instructions` array in `opencode.json` references the path you used (relative to the project root). The default is `docs/project.md`.

**"`opencode.json` keeps changing on every install."**
You are editing the auto-generated file directly. Either commit to the curated `opencode.json` shipped with the agent tree and let `install-agent.ps1` skip it, or stop editing it and let the installer regenerate it from the schema (use `-Update` to allow overwrites).