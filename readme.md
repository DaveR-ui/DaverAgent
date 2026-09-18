# DaverAgent — Global opencode Configuration

This repository **is** the global configuration of the opencode agent system
(delivery, orchestrator, coder, tester, …). Clone it into `~/.config/opencode`
(or `$XDG_CONFIG_HOME/opencode`) and every project on the machine shares the
same agents.

- **One copy per machine.** No per-project `.opencode/` copies, no duplicated
  agent prompts.
- **Global config, per-project docs.** The agent system lives here; project
  facts live in each project's `docs/` and are resolved per session.
- **Portable.** The install is a git clone plus `scripts/bootstrap.sh`; no
  absolute paths are hardcoded anywhere except the documented `engram` binary
  path in `opencode.json` (and its fallback default in `plugins/engram.ts`).

## Install (per machine)

```bash
git clone https://github.com/DaveR-ui/DaverAgent.git ~/.config/opencode
bash ~/.config/opencode/scripts/bootstrap.sh        # install or update
```

`scripts/bootstrap.sh` is idempotent and adds a `--verify-only` mode:

```bash
bash scripts/bootstrap.sh --verify-only   # report what would change, write nothing
```

If the target already exists and is **not** a clone of this repository, the
script backs it up to `~/.config/opencode.bak.<timestamp>` before cloning. See
[`install.md`](./install.md) for the full checklist and the optional per-project
documentation bootstrap.

## Path contract

Two path vocabularies coexist. The normative resolution rule is the
`references.agent-system.description` in `opencode.json` (opencode injects that
reference's absolute root into every agent's context).

| Vocabulary | Examples | Resolves against |
|---|---|---|
| **Agent-system assets** | `agents/`, `protocols/`, `workflows/`, `scripts/`, `tests/`, `templates/` | The `agent-system` reference in `opencode.json` |
| **Project documents** | `docs/project.md`, `docs/context/**` | The session working directory (each project's repo) |

`opencode.json` lists `docs/project.md` under `instructions`; projects without a
`docs/` folder are silently skipped. A project that wants explicit
`docs/context` / `docs/protocols` references can drop
[`templates/project-opencode.json`](./templates/project-opencode.json) in as its
own `opencode.json`.

**Golden rule:** never create a global `docs/`, and never hardcode an absolute
path (the `engram` binary path noted above is the one documented exception). The
read tool does not expand `~`.

## Structure

```
~/.config/opencode/              # == this repository
├── opencode.json                # Canonical global runtime config (no `agent` block)
├── readme.md                    # This file
├── install.md                   # Install / update checklist
│
├── agents/                      # FLAT global agents (the runtime scans agents/*.md)
│   ├── delivery.md              # Interface with the human (primary)
│   ├── orchestrator.md          # Coordinator (deeply delegable)
│   ├── coder.md                 # Implementation (language=angular|go)
│   ├── tester.md                # Tests (framework=vitest|karma-jasmine|playwright|go)
│   ├── reviewer.md              # Code review
│   ├── architect.md             # Design
│   ├── explorer.md              # Search and mapping (read-only)
│   ├── project-context.md       # docs/ reading (read-only)
│   ├── external-scout.md        # External docs via webfetch
│   ├── standards-scout.md       # Standards/pattern discovery before coding (read-only)
│   ├── interpreter.md           # Step 0 normalization + image inspection
│   ├── analista.md              # Second opinion
│   ├── documenter.md            # Documentation
│   └── *.schema.json            # Structured-return schemas
│
├── protocols/                   # Agent operating conventions (read on demand)
├── workflows/                   # Thinking instructions
├── commands/                    # Human-facing slash commands (e.g. /session)
├── plugins/                     # Portable plugins (session tool, steer inbox, session export, engram, GitKraken hooks)
├── scripts/                     # bootstrap.sh + validators
├── tests/                       # Test suite of the agent tree
└── templates/                   # Optional per-project opencode.json shim
```

> `plugins/`, `commands/` and the root `package.json` + `package-lock.json` are
> tracked (the committed lockfile pins the plugin dependency so `npm install` is
> reproducible; `node_modules/` stays gitignored). `plugins/` holds portable
> plugin modules; `commands/` holds slash commands.

## Available agents

Defined in `agents/<id>.md` (`subagent` mode, except `delivery` which is
`primary`). Invoked from `delivery` or `orchestrator` via the `task` tool.

| Agent | Purpose |
|---|---|
| `delivery` | Interface with the human. Does NOT delegate technical work to itself. |
| `orchestrator` | Executes Phase 2 (Reduce), coordinates multi-step work, fans out subagents. |
| `coder` | Implementation (`language=angular|go`). Returns `CoderOutput`. |
| `tester` | Tests (`framework=vitest|karma-jasmine|playwright|go`). Returns `TesterOutput`. |
| `reviewer` | Code review, security, performance. Returns `ReviewerOutput`. |
| `architect` | Design, boundaries, patterns. Returns `ArchitectOutput`. |
| `analista` | Second opinion, plan critique, stuck-recovery. Returns `AnalystOutput`. |
| `explorer` | Search and mapping in the repo. Returns `ExplorerOutput`. |
| `project-context` | Lookups and context assembly from `docs/` (read-only). |
| `external-scout` | Brings docs of external libraries via webfetch. |
| `standards-scout` | Discovers the project's standards/patterns before coding (read-only, ranked output). Text return. |
| `interpreter` | Normalizes the prompt (Step 0) and inspects a single image. |
| `documenter` | Writes/maintains `docs/`. Returns `DocumenterOutput`. |

Temperature lives in **each agent's frontmatter** (`agents/<id>.md`). No agent
currently declares `model:`, so a subagent inherits the model of the primary
agent that invokes it — model is inherited unless an agent adds an explicit
`model:` override in its frontmatter. Changing either = editing the agent's
frontmatter and restarting opencode.

## Protocols

The protocols live in [`protocols/`](./protocols/readme.md). The most important
is [`protocols/prompt-pipeline.md`](./protocols/prompt-pipeline.md): Step 0
(Interpret) is executed by the `interpreter`; Phase 2 (Reduce) is executed by
the `orchestrator`.

## Agent permissions

- `orchestrator` and the subagents have no external skills pre-enabled. The only
  legitimate built-in skill is `customize-opencode` (part of the opencode
  runtime, not repo-local).
- All project info lives in each project's `docs/context/` and is read **on
  demand**.

## Session tool

The session capability ships two ways:

- **Agent tool** — [`plugins/session-tool.js`](./plugins/session-tool.js)
  registers a `session` tool (`children`, `tree`, `parent`, `messages`,
  `status`, `todo`, `diff`, `send`). Read ops target the caller's session by
  default. `send` (which prompts another session) is restricted to the
  `orchestrator` and `delivery` agents and asks for confirmation first.
- **Slash command** — [`commands/session.md`](./commands/session.md) gives a
  human-facing entry point: `/session <session-id> [op]`. Commands inject a
  prompt, so the command delegates the actual read/write to the tool above.

## Steering inbox

[`plugins/steer-inbox.js`](./plugins/steer-inbox.js) is a file-based steering
inbox. While an agent turn is running, append one JSON object per line (JSONL)
to the inbox; the plugin delivers each message to the active session over
opencode's **v2 steer channel** (`delivery:"steer"`), applied in the same turn
at the next step boundary.

- **Inbox** — `$XDG_STATE_HOME/opencode/steer-inbox.jsonl`, else
  `~/.local/state/opencode/steer-inbox.jsonl`. It lives in the state dir
  (outside this repo), so runtime state never pollutes `git status`.
- **Override / kill switch** — `OPENCODE_STEER_INBOX` (absolute path);
  `OPENCODE_STEER_INBOX_DISABLE=1` disables the plugin.
- **Line format** — `{"text":"...", "session":"ses_..."}`; `text` is required,
  `session` (or `target`) optionally names the target session.

```bash
echo '{"text":"use the staging DB"}' >> ~/.local/state/opencode/steer-inbox.jsonl
```

An `<inbox>.offset` byte-offset sidecar steers each line once within a running
process (at-most-once); a crash between delivery and the offset write can
re-deliver one line after restart. Malformed lines are skipped, and a line with
no known session waits for a later drain. **Routing:** an explicit
`session`/`target` wins, otherwise the most-recently-active session (ambiguity
resolves to most-recently-active). The inbox path is global per machine and has
no cross-process lock — run a single opencode instance per machine, or give
instances distinct `OPENCODE_STEER_INBOX` paths, to avoid the same line being
steered twice.

**Safe by default / opt-in:** an absent inbox file leaves the plugin completely
inert. It never throws and never blocks (async fs, fire-and-forget), sends no
model override, reads no credentials, and connects nothing — so the session's
own already-available default Zen model is used. To use a preferred
`opencode-go/deepseek-v4.1-flash`, connect the `opencode-go` integration once in
the opencode UI; the session can then select it. No `opencode.json` entry is
needed — local plugins auto-load from `plugins/`.

## Session export

[`plugins/session-export.js`](./plugins/session-export.js) keeps a
machine-readable snapshot of the opencode session list and each session's run
state, so external consumers (e.g. a KDE Plasma widget) can render the active
sessions without talking to the local server themselves.

- **Output file** — `$XDG_STATE_HOME/opencode/sessions.json`, else
  `~/.local/state/opencode/sessions.json`. It lives in the state dir (outside
  this repo), so runtime state never pollutes `git status`.
- **Override / kill switch** — `OPENCODE_SESSION_EXPORT` (absolute path);
  `OPENCODE_SESSION_EXPORT_DISABLE=1` disables the plugin.

```json
{
  "updatedAt": "2026-09-13T22:30:00.000Z",
  "sessions": [
    {"id":"ses_...","title":"...","parentID":null,
     "status":"idle","updated":1757800200000}
  ]
}
```

`status` is one of `idle`, `busy`, `retry` (or `unknown`); `parentID` is `null`
for top-level sessions; `updated` is epoch milliseconds. Sessions are sorted by
status rank (busy, retry first), then by `updated` descending.

**Safe by default / no-throw:** writes are async and fire-and-forget, atomic
(temp file + `fs.rename`), and never throw. If the local server is unreachable
the previous snapshot is left untouched. It sends no model override, reads no
credentials, and connects nothing — no `opencode.json` entry is needed, since
local plugins auto-load from `plugins/`.

**Restart required:** opencode must be **restarted** after adding or changing
the plugin for it to load.

## Updating the config

- **Change an agent's temperature** → edit the `temperature:` in the frontmatter
  of `agents/<id>.md`, then restart opencode. The model is inherited from the
  invoking primary unless the agent declares an explicit `model:` override.
- **Change an agent's definition** (prompt, tools, permissions, schema) → edit
  `agents/<id>.md`.
- **Add an agent** → create `agents/<id>.md` with its frontmatter
  (`description`, `mode`, `temperature`, `permission`, `output_schema`, plus an
  optional `model:` override). Do not touch `opencode.json` (it has no `agent`
  block).
- **Update the global install** → `bash scripts/bootstrap.sh` (or
  `--verify-only` first).

The per-project documentation bootstrap is separate; see [`install.md`](./install.md).

## Validating the config

Before committing changes to the agent system, run the full test suite (Git
Bash / WSL):

```bash
bash tests/run-tests.sh
```

It runs eight suites, all exit-code driven (CI-ready):

1. **`scripts/validate-agent.sh`** (integrity lint): that `opencode.json` is
   valid JSON, that the flat `agents/` layout is intact, that no agent uses the
   deprecated `tools:` field, that every `output_schema` points to an existing
   file, that `delivery`/`orchestrator` `permission.task` targets are real
   agents, and that the mandatory frontmatter (`description`/`mode`) exists.
   Project `docs/` paths are reported as WARN, not errors.
2. **`tests/test-output-schemas.py`** (output contracts): every valid fixture in
   `tests/fixtures/outputs/` validates against its schema, every invalid fixture
   is rejected, the golden routing packets validate against
   `interpreter.schema.json`, and the JSON examples documented in the agent
   `.md` files stay in sync with their schemas.
3. **`tests/test-docs-validator.sh`** (docs validator): the bundled
   `templates/docs-validate.js` derives from upstream onrails without drift.
4. **`tests/test-conformance-register.py`** (divergence register): the declared
   onrails divergences in `templates/docs-conformance.json` are machine-checked.
5. **`tests/test-agent-hardening.py`** (permission matrix): `subagent_depth: 4`,
   no `lsp` block, the read-only/edit/`websearch` denies, the `permission.task`
   catch-all model, and the absence of fabricated runtime claims.
6. **`tests/test-session-tool.py`** (session capability): the `session` plugin
   tool, the `/session` slash command, and the harness wiring.
7. **`tests/test-steer-inbox.py`** (steering inbox): the `steer-inbox` plugin's
   structure, safe/no-throw async behavior, v2 steer delivery channel, env
   overrides, and `node --check` parse guard.
8. **`tests/test-session-export.py`** (session export): the `session-export`
   plugin's structure, safe/no-throw async behavior, atomic write, env
   overrides, and `node --check` parse guard, plus the runner wiring.

## Troubleshooting

**"My config is not picked up"** — Verify `opencode.json` is valid JSON:
`python3 -m json.tool opencode.json`.

**"I want to go back to the previous version"** — If the change was made by
`scripts/bootstrap.sh`, restore the `~/.config/opencode.bak.<timestamp>`
directory. If you edited by hand, use your own version control.

**"A project doesn't see its `docs/`"** — Confirm the project has
`docs/project.md` (or drop in
[`templates/project-opencode.json`](./templates/project-opencode.json) for
explicit `docs/context` / `docs/protocols` references).
