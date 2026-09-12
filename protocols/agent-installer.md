# Protocol: Agent Installer

How the agent system is installed and reconfigured. There are two distinct
install paths — do not conflate them:

1. **Global install (per machine)** — `scripts/bootstrap.sh` (or
   `bootstrap.ps1`) clones/updates this repository into `~/.config/opencode`.
   This carries the agents, protocols, workflows, and `opencode.json`.
2. **Per-project docs bootstrap (per repository)** — `scripts/install-agent.ps1`
   generates a project's `docs/project.md`, `docs/context/*.md` stubs, the
   `docs/context/context-index.md` hub, the generated `docs/tag-index.md`, and the
   slang snapshot, then installs the derived validator at `docs/validate.js` and
   runs it (best-effort; needs Node). It does **not** create agents or `opencode.json`.

Path rules live in `opencode.json` → `references.agent-system`: opencode injects
that reference's absolute root into agent context, so agent-system assets are
read by joining the injected root with the relative path; project docs resolve
inside the project.

## Source of truth

- **Global bootstrap**: `scripts/bootstrap.sh` / `scripts/bootstrap.ps1`
- **Docs bootstrap**: `scripts/install-agent.ps1`
- **Schema**: `scripts/install-agent.schema.json` — data-driven question list
  for the docs bootstrap (3 phases below)
- **Path contract**: `opencode.json` → `references.agent-system`

## When this protocol applies

The human wants to:

- **Install** the agent system on a new machine (`bash scripts/bootstrap.sh`)
- **Update** the agent system after a change (`bash scripts/bootstrap.sh`)
- **Bootstrap a project's docs** for the first time (`install-agent.ps1`)
- **Add a slice** to the routing table in a project's `docs/project.md`
- **Add or update a subagent** (edit `agents/<id>.md`)
- **Audit** what the bootstrap would change (`--verify-only` / `-VerifyOnly`)

Do NOT use this for:

- Day-to-day coding tasks (delegate to `coder` (language=angular|go) directly)
- Documentation edits (delegate to `documenter` or `project-context`)
- Just running the agent (use `delivery`)

## Global install (per machine)

> For the human-facing, copy-paste checklist, see [`install.md`](../install.md).

1. Run `bash scripts/bootstrap.sh --verify-only` to see what would happen
   (zero writes).
2. Run `bash scripts/bootstrap.sh` to clone or update the config at
   `~/.config/opencode`.
3. If the target already exists and is **not** a clone of this repository,
   bootstrap backs it up to `~/.config/opencode.bak.<timestamp>` first.
4. Restart opencode so it reloads `opencode.json` and `agents/`.

Windows: `& ".\scripts\bootstrap.ps1" -VerifyOnly` then
`& ".\scripts\bootstrap.ps1"`.

## Per-project docs bootstrap (3 phases)

| Phase | Generates | Questions |
|---|---|---|
| 1 — Project Metadata | `docs/project.md` | name, stack, architecture, **slices** |
| 2 — Context Docs | `docs/context/*.md` | which context docs to enable |
| 3 — Project Slang | project slang snapshot | initial slang entries |

> Phase 4 (agent selection + `opencode.json` generation) is **obsolete** under
> the global model. Agents are global; `opencode.json` in the global config is
> the canonical tracked file. The docs bootstrap never regenerates either.

When a subagent helper is written in the future, it MUST follow
[`subagent-spec-template.md`](./subagent-spec-template.md) — canonical full
shape or the thin variant, plus the `output_schema` ↔ sibling schema bridge.

### How to drive the docs bootstrap

```powershell
# From the global config directory, targeting a project:
& "$HOME\.config\opencode\scripts\install-agent.ps1" -RepoPath "C:\path\to\project" -NonInteractive -VerifyOnly
& "$HOME\.config\opencode\scripts\install-agent.ps1" -RepoPath "C:\path\to\project" -NonInteractive
```

1. Run with `-VerifyOnly` to see the planned output (zero writes).
2. Run without it to apply. With `-NonInteractive` the script takes defaults for
   every question; omit the flag to drive the 3 phases interactively.
3. Fill in the substance of each generated `docs/context/*.md` stub.

## Update (existing docs bootstrap)

1. Run `install-agent.ps1 -VerifyOnly` to see the diff.
2. Walk the human through the affected phases, reusing answers where unchanged.
3. Run `install-agent.ps1 -Update`. Existing files are backed up to
   `<project>/.agent-backups/<timestamp>/` before any overwrite.
4. Report what changed and where the backups are.

## Add a slice

1. Read the current Slices table in the project's `docs/project.md`.
2. Ask the human: slice id, description, keywords, entry points, primary agents.
3. Add a new row to the Slices table. Do NOT touch the script.
4. The orchestrator picks it up automatically on the next handoff.

## Migrate an existing project (legacy -> onrails)

Existing projects created before the onrails adoption still use the legacy names.
Migration is **human-confirmed, never silent**; the legacy names are read-accepted
only until **2026-10-12**.

1. Impact scan: `grep -rn "context/README\|protocols/README\|_TAG-INDEX" <project>/docs`.
2. For each hit, confirm with the human, then rename:

   | Legacy | Canonical |
   |---|---|
   | `docs/context/README.md` | `docs/context/context-index.md` |
   | `docs/_TAG-INDEX.md` | `docs/tag-index.md` (generated) |
   | `docs/protocols/README.md` | removed - register each protocol with a link from `docs/project.md` |

3. Add the missing frontmatter: context docs `last_updated, status, description, tags, version` (+ `doc_language` on `docs/project.md`); notes `id, category, tags, aliases, related, version, status`.
4. Widen a 4-column Slices table to 5 columns (`Slice | Description | Keywords | Entry points | Primary agents`); rename `## Backend Structure` to `## Repository Structure` and add `## Common Lookups`.
5. Record provenance with the note key `moved_from` on renamed notes.
6. Regenerate + validate: `node docs/validate.js --write && node docs/validate.js` (must exit 0).

After **2026-10-12** the legacy names are unsupported: agents report them instead of reading them.

## Add a subagent

1. If the new subagent matches an existing pattern, write the file directly at
   `agents/<id>.md` following [`subagent-spec-template.md`](./subagent-spec-template.md).
2. All per-agent config lives in the new agent's frontmatter — `description`,
   `mode`, `model`, `temperature`, `permission`, and
   `output_schema: ./<id>.schema.json` plus the sibling schema file if the
   subagent returns structured JSON. Nothing goes in `opencode.json` — there is
   no `agent` block.
3. Restart opencode and run `bash tests/run-tests.sh` to confirm the validator
   and schema contracts still pass.

## Backup discipline

- **Docs bootstrap**: backups live at
  `<project>/.agent-backups/<timestamp>/<relative-path>`.
- **Global bootstrap**: the whole previous config is moved to
  `~/.config/opencode.bak.<timestamp>`.
- Backups are created only when something would actually be overwritten.
- Never delete old backups in the scripts; the human prunes them.

## Defaults that work

If the human is unsure, these docs-bootstrap defaults cover the most common
cases:

| Question | Default |
|---|---|
| Architecture pattern | layered |
| Primary language | go |
| Context docs | architecture, project-rules |
| Doc language | en |

## Example conversations

**Human**: "Set up the agent on this new machine."

You: Run `bash scripts/bootstrap.sh --verify-only`, show the plan, then
`bash scripts/bootstrap.sh`. Restart opencode.

**Human**: "Set up the docs for this project."

You: Run `install-agent.ps1 -RepoPath <project> -NonInteractive -VerifyOnly`,
then without the flag. The 3 phases walk through everything.

**Human**: "I added a new context doc called `cache-strategy.md`."

You: Add the file under the project's `docs/context/` and update the hub in
`docs/context/context-index.md` (legacy name `docs/context/README.md` during the
migration window).

**Human**: "Update the slices table to include a new 'reports' slice."

You: Ask for the five fields (id, description, keywords, entry points, primary agents). Edit the project's `docs/project.md` directly.
Confirm by reading the file back.

**Human**: "What would the bootstrap change if I ran it now?"

You: Run `install-agent.ps1 -VerifyOnly` (or `bootstrap.sh --verify-only`).
Report the diff.

## Rules

- Always offer the human a chance to back up before any overwrite.
- Never edit the substance of `docs/context/*.md` in this protocol — that is the
  `project-context` subagent's job. This protocol only generates stubs.
- The global `opencode.json` is the canonical tracked artifact: edit it
  deliberately and validate it, but never regenerate it from the docs bootstrap.
- After any update, run `--verify-only` once to confirm the state matches
  expectations.
