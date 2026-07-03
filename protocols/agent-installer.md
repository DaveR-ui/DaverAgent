# Protocol: Agent Installer

Conventions for installing and reconfiguring the opencode agent system in a repository. Conversational wrapper around `.opencode/scripts/install-agent.ps1` — handles the mechanics so the human can drive the install through natural language.

## Source of truth

- **Script**: `.opencode/scripts/install-agent.ps1` — the actual installer
- **Schema**: `.opencode/scripts/install-agent.schema.json` — data-driven question list
- **Question reference**: `docs/context/agent-installer-questions.md` — what each question means
- **Update protocol**: `docs/context/agent-update-protocol.md` — what gets preserved/overwritten

## The 4 phases

| Phase | Generates | Questions |
|---|---|---|
| 1 — Project Metadata | `docs/project.md` | name, stack, architecture, **slices** |
| 2 — Context Docs | `docs/context/*.md` | which context docs to enable |
| 3 — Project Slang | session slang template | initial slang entries |
| 4 — Agent Selection | subagent files + `opencode.json` | which subagents, default agent, doc language |

## When this protocol applies

The human wants to:

- **Install** the agent for the first time in a fresh repo
- **Update** the agent after a stack change, new context doc, or new subagent
- **Add a slice** to the routing table in `docs/project.md`
- **Add or remove a subagent** from the roster
- **Refresh the slang dictionary** with new terms
- **Audit** what the installer would change (run with `-VerifyOnly`)

Do NOT use this for:

- Day-to-day coding tasks (delegate to `coder` directly)
- Documentation edits (delegate to `documenter` or `project-context`)
- Just running the agent (use `delivery`)

## How to drive it

### Install (first time)

1. Run `install-agent.ps1 -VerifyOnly` to see the planned output (zero writes).
2. Run `install-agent.ps1` interactively. The human answers 4 phases of questions. Defaults are offered for every prompt.
3. The script writes `docs/project.md`, the selected context docs, the subagent files, and `opencode.json`.
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
2. If it is genuinely new, write the file at `.opencode/agents/subagents/<id>.md` manually. The agent roster in `opencode.json` needs the new entry too.
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
| Context docs | architecture, api-contracts, rules, naming-registry |
| Default agent | delivery |
| Subagents | coder, tester, reviewer, architect, explorer, documenter |
| Doc language | en |

## Example conversations

**Human**: "Set up the agent for this project."

You: Run the installer in interactive mode. The 4 phases walk through everything.

**Human**: "I added a new context doc called `cache-strategy.md`."

You: Edit `install-agent.schema.json` to add the new entry under `context_templates`. Re-run `install-agent.ps1 -Update` so the new file generates and `docs/context/README.md` gets the new row.

**Human**: "Update the slices table to include a new 'reports' slice."

You: Ask for the four fields. Edit `docs/project.md` directly. Confirm by reading the file back.

**Human**: "What would the installer change if I ran it now?"

You: Run `install-agent.ps1 -VerifyOnly`. Report the diff.

## Rules

- Always offer the human a chance to back up before any overwrite.
- Never edit `docs/context/*.md` substance in this protocol — that is the `project-context` subagent's job. This protocol only generates stubs.
- Never edit `opencode.json` directly — always go through the installer so the schema-driven generation stays consistent.
- After any update, run `-VerifyOnly` once to confirm the state matches expectations.
