# Protocol: Agent Installer

Conventions for installing and reconfiguring the opencode agent system in a repository. Conversational wrapper around `.opencode/scripts/install-agent.ps1` — handles the mechanics so the human can drive the install through natural language.

## Source of truth

- **Script**: `.opencode/scripts/install-agent.ps1` — the actual installer
- **Schema**: `.opencode/scripts/install-agent.schema.json` — data-driven question list
- **Question reference**: `docs/context/agent-installer-questions.md` — what each question means (currently does not exist; create if needed or remove this reference)
- **Update protocol**: `docs/context/agent-update-protocol.md` — what gets preserved/overwritten (currently does not exist; create if needed or remove this reference)
- **Script**: `.opencode/scripts/install-agent.ps1` — the actual installer, currently driven by inline questions and manual update logic.

## The 4 phases

| Phase | Generates | Questions |
|---|---|---|
| 1 — Project Metadata | `docs/project.md` | name, stack, architecture, **slices** |
| 2 — Context Docs | `docs/context/*.md` | which context docs to enable |
| 3 — Project Slang | session slang template | initial slang entries |
| 4 — Agent Selection | subagent files + `opencode.json` | which subagents, default agent, doc language |

> Phase 4 shape authority: every subagent file the installer scaffolds MUST follow [`subagent-spec-template.md`](./subagent-spec-template.md) — canonical full shape (Role → Scope → Stack / Context → Standards → Anti-Patterns → Structured Return → Rules) or the minimal shape for thin adapters, plus the `output_schema` ↔ sibling schema bridge. The same spec governs future per-specialization templates (`<role>.<specialization>.md`) when they are introduced.

## When this protocol applies

The human wants to:

- **Install** the agent for the first time in a fresh repo
- **Update** the agent after a stack change, new context doc, or new subagent
- **Add a slice** to the routing table in `docs/project.md`
- **Add or remove a subagent** from the roster
- **Refresh the slang dictionary** with new terms
- **Audit** what the installer would change (run with `-VerifyOnly`)

Do NOT use this for:

- Day-to-day coding tasks (delegate to `coder-angular` / `coder-go` directly)
- Documentation edits (delegate to `documenter` or `project-context`)
- Just running the agent (use `delivery`)

## How to drive it

### Install (first time)

> For the human-facing, copy-paste checklist that drives the full per-project install (clone, .gitignore, verify, apply, bootstrap, sync, smoke test), see [`INSTALL.md`](../INSTALL.md). The protocol below describes the same flow from the agent's point of view.

1. Run `install-agent.ps1 -NonInteractive -VerifyOnly` to see the planned output (zero writes).
2. Run `install-agent.ps1 -NonInteractive` to apply. With `-NonInteractive` the script takes defaults for every question. To drive the install interactively instead, omit the flag and answer the 4 phases of questions; defaults are offered for every prompt.
3. The script writes `docs/project.md`, the selected context docs, the subagent files, and (unless a curated `opencode.json` already exists) a generated `opencode.json`.
4. The human is responsible for filling in the substance of each generated `docs/context/*.md` stub.

### Update (existing install)

1. Run `install-agent.ps1 -VerifyOnly` to see the diff.
2. Walk the human through the affected phases. Use existing answers where nothing changed.
3. Run `install-agent.ps1 -Update`. Existing files are backed up to `.opencode/.backups/<timestamp>/` before any overwrite.
4. Report what changed and where the backups are.

### Add a slice

1. Read the current Slices table in `docs/project.md`.
2. Ask the human: slice id, description, entry points, primary agents.
3. Add a new row to the Slices table. Do NOT touch the script.
4. The orchestrator picks it up automatically on the next handoff.

### Add a subagent

1. If the new subagent matches an existing pattern (e.g. a new `*-expert` reader), add a body in `Get-AgentBody` in `install-agent.ps1` and re-run.
2. If it is genuinely new, write the file at `.opencode/agents/subagents/<id>.md` manually, following the canonical shape in [`subagent-spec-template.md`](./subagent-spec-template.md) (full or minimal shape). All per-agent config lives in the new agent's frontmatter — including `output_schema: ./<id>.schema.json` plus the sibling schema file if the subagent returns structured JSON (the spec documents the bridge). The only thing that goes in `opencode.json` is the new agent's `model` + `temperature` under `agent.<id>`.
3. Re-run `install-agent.ps1 -VerifyOnly` to confirm the new agent shows up.

## Backup discipline

- Backups live at `.opencode/.backups/<timestamp>/<relative-path>`.
- The script creates a backup only when a file would actually be overwritten AND its content would change.
- Never delete old backups in the script; the human prunes them.

## Defaults that work

If the human is unsure, these defaults cover the most common cases:

| Question | Default |
|---|---|
| Architecture pattern | layered |
| Primary language | go |
| Context docs | architecture, project-rules |
| Default agent | delivery |
| Subagents | coder-angular, coder-go, tester, reviewer, architect, explorer, documenter |
| Doc language | en |

> **Important for this repo (DaverCode fork of `sst/opencode`)**: the defaults above are the installer's *generic* defaults. They do **not** describe this repo. The actual values for this repo are:
>
> | Question | Real value for this repo |
> |---|---|
> | Architecture pattern | layered (monorepo: `schema ← protocol ← server ← core`) |
> | Primary language | typescript |
> | Framework | Effect 4 + Hono + Solid.js + `@opentui/solid` |
> | Database | SQLite (drizzle) |
> | ORM | drizzle-orm |
> | Auth | `@openauthjs/openauth` + AWS SSO |
> | Default agent | delivery |
> | Subagents | delivery, orchestrator, coder-angular, coder-go, tester, reviewer, architect, explorer, project-context, vision-relay, documenter |
> | Doc language | es (for `docs/`) / en (for `.opencode/`, code) |
>
> If a future run of the installer reuses the generic defaults, **the installer's stub output must be replaced** before the agent system is usable. See `docs/project.md` (Slices, Backend Structure, Domain Entities) for the canonical content.

## Example conversations

**Human**: "Set up the agent for this project."

You: Run the installer in interactive mode. The 4 phases walk through everything.

**Human**: "I added a new context doc called `cache-strategy.md`."

You: Add the new context doc under `docs/context/` and update the index in `docs/context/README.md`. Re-run `install-agent.ps1 -Update` if the installer maintains context doc stubs.

**Human**: "Update the slices table to include a new 'reports' slice."

You: Ask for the four fields. Edit `docs/project.md` directly. Confirm by reading the file back.

**Human**: "What would the installer change if I ran it now?"

You: Run `install-agent.ps1 -VerifyOnly`. Report the diff.

## Rules

- Always offer the human a chance to back up before any overwrite.
- Never edit `docs/context/*.md` substance in this protocol — that is the `project-context` subagent's job. This protocol only generates stubs.
- Never edit `opencode.json` directly — always go through the installer so the schema-driven generation stays consistent.
- After any update, run `-VerifyOnly` once to confirm the state matches expectations.
