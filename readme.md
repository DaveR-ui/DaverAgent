# DaverAgent — Global opencode Configuration

This repository **is** the global configuration of the opencode agent system
(delivery, orchestrator, coder, tester, …). Clone it into `~/.config/opencode`
(or `$XDG_CONFIG_HOME/opencode`) and every project on the machine shares the
same agents.

- **One copy per machine.** No per-project `.opencode/` copies, no duplicated
  agent prompts.
- **Global config, per-project docs.** The agent system lives here; project
  facts live in each project's `docs/` and are resolved per session.
- **Portable.** The install is a git clone; no absolute paths are hardcoded.
  Machine-specific paths (e.g. an MCP server binary) must be provided through a
  gitignored `opencode.local.json` override, never committed here.

## Install (per machine)

```bash
git clone https://github.com/DaveR-ui/DaverAgent.git ~/.config/opencode
```

There is no separate install step: opencode reads the config directly from the
clone. Update with `git pull` in the clone and validate with
`bash tests/run-tests.sh`.

## Path contract

Two path vocabularies coexist. The normative resolution rule is the
`references.agent-system.description` in `opencode.json` (opencode injects that
reference's absolute root into every agent's context).

| Vocabulary | Examples | Resolves against |
|---|---|---|
| **Agent-system assets** | `agents/`, `protocols/`, `scripts/`, `tests/` | The `agent-system` reference in `opencode.json` |
| **Project documents** | `docs/project.md`, `docs/context/**` | The session working directory (each project's repo) |

`opencode.json` lists `docs/project.md` under `instructions`. Under opencode V1,
relative instruction paths are resolved against the session working directory
(searched upward to the git worktree root), so a project without a `docs/`
folder is silently skipped. A project that wants explicit `docs/context` /
`docs/protocols` references declares them in its own `opencode.json`
`references` block.

**Golden rule:** never create a global `docs/`, and never hardcode an absolute
path. The read tool does not expand `~`.

## Structure

```
~/.config/opencode/              # == this repository
├── opencode.json                # Canonical global runtime config (no `agent` block)
├── readme.md                    # This file
│
├── agents/                      # FLAT global agents (the runtime scans agents/*.md)
│   ├── delivery.md              # Interface with the human (primary)
│   ├── orchestrator.md          # Coordinator (deeply delegable)
│   ├── coder.md                 # Implementation (language=angular|go)
│   ├── tester.md                # Tests (framework=vitest|karma-jasmine|playwright|go)
│   ├── reviewer.md              # Code review
│   ├── architect.md             # Design
│   ├── explorer.md              # Search and mapping (read-only)
│   ├── external-scout.md        # External docs via webfetch
│   ├── interpreter.md           # Step 0 normalization + image inspection
│   ├── analista.md              # Second opinion
│   ├── documenter.md            # Documentation
│   └── *.schema.json            # Structured-return schemas
│
├── protocols/                   # Agent operating conventions (read on demand)
├── scripts/                     # Validators
└── tests/                       # Test suite of the agent tree
```

> A `plugins/` directory and a root `package.json` + lockfile are **optional**:
> they exist only if you add portable plugins (or other JS dependencies). This
> repo ships **neither** — do not add an empty `package.json` just to match a
> diagram. Any `node_modules/` is gitignored.

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
| `external-scout` | Brings docs of external libraries via webfetch. |
| `interpreter` | Normalizes the prompt (Step 0) and inspects a single image. |
| `documenter` | Writes/maintains `docs/`. Returns `DocumenterOutput`. |

Models and temperatures live in **each agent's frontmatter**
(`agents/<id>.md`). Changing a model = editing the agent's frontmatter and
restarting opencode. Without a declared `model:`, a subagent inherits the model
of the primary agent that invokes it.

## Protocols

The protocols live in `protocols/`:

- [`prompt-pipeline.md`](./protocols/prompt-pipeline.md) — Step 0 (Interpret) is
  executed by the `interpreter`; Phase 2 (Reduce) is executed by the
  `orchestrator`.
- [`subagent-spec-template.md`](./protocols/subagent-spec-template.md) — canonical
  shape for subagent definitions.
- [`session-recovery.md`](./protocols/session-recovery.md) — recovery flow for
  interrupted or STUCK sessions in the delivery → orchestrator → subagent
  hierarchy.
- [`broad-investigation-template.md`](./protocols/broad-investigation-template.md) —
  5-section scaffold for prompts that map, inventory, or audit the repo.

## Agent permissions

- `orchestrator` and the subagents have no external skills pre-enabled. The only
  legitimate built-in skill is `customize-opencode` (part of the opencode
  runtime, not repo-local).
- All project info lives in each project's `docs/context/` and is read **on
  demand**.

## Updating the config

- **Change an agent's model/temperature** → edit the frontmatter of
  `agents/<id>.md` (`model` / `temperature`), then restart opencode.
- **Change an agent's definition** (prompt, tools, permissions, schema) → edit
  `agents/<id>.md`.
- **Add an agent** → create `agents/<id>.md` with its full frontmatter
  (`description`, `mode`, `model`, `temperature`, `permission`,
  `output_schema`). Do not touch `opencode.json` (it has no `agent` block).
- **Update the global install** → `git pull` in the `~/.config/opencode` clone.

## Validating the config

Before committing changes to the agent system, run the full test suite:

```bash
bash tests/run-tests.sh
```

It includes two suites, both exit-code driven (CI-ready):

1. **`scripts/validate-agent.sh`** (integrity lint), nine checks: that
   `opencode.json` is valid JSON; that the flat `agents/` layout is intact and
   no agent uses the deprecated `tools:` field; that every `output_schema`
   points to an existing file; that every `permission.task` allow target in any
   agent resolves to a real agent; that the mandatory frontmatter
   (`description`/`mode`) exists; that config `instructions`/`references` paths
   resolve (project `docs/` paths are reported as WARN, not errors); that every
   `*.schema.json` parses as valid JSON; that every `agents/*.schema.json` is
   structurally closed (draft 2020-12, `additionalProperties: false`, non-empty
   `required`, a description on every property); and that every `re_route_to`
   enum value resolves to an agent.
2. **`tests/test-output-schemas.py`** (output contracts): every valid fixture in
   `tests/fixtures/outputs/` validates against its schema, every invalid fixture
   is rejected, the golden routing packets validate against
   `interpreter.schema.json`, the JSON examples documented in the agent `.md`
   files stay in sync with their schemas, and every `required` field is
   exercised by its valid fixture.

## Troubleshooting

**"My config is not picked up"** — Verify `opencode.json` is valid JSON:
`python3 -m json.tool opencode.json`.

**"I want to go back to the previous version"** — Use your own version control
(Git) to check out the previous state of the clone.

**"A project doesn't see its `docs/`"** — Confirm the project has
`docs/project.md`; it is listed under `instructions` in `opencode.json`.
