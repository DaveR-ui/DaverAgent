# Opencode Agent — DaverAgent

This folder contains the entire configuration of the agent system (delivery, orchestrator, coder, tester, etc.), ready to clone/copy as `.opencode/` into the repo that will use it.

## Source of truth: one single part, no duplicates

| File | Location | Role |
|---|---|---|
| `jason-opencode.json` | root of this tree | **Base runtime config**. Copied into the destination repo as `opencode.json`. Only top-level: `default_agent`, `compaction`, `references`, global `permission` and `instructions`. **No `agent` block.** |
| `.opencode/agents/subagents/*.md` | one file per agent | **Complete agent definition**: `description`, `mode`, `model`, `temperature`, `permission`, `output_schema` and the system prompt. The runtime loads them by scanning `agent(s)/**/*.md`. |

**Golden rule**: EVERYTHING about an agent lives in its `.md` (including model and temperature). `opencode.json` has no `agent` block. No duplication. To change a model, edit the agent's frontmatter and restart opencode.

## Structure

> This repo is the **source tree**: the files live at the root (`agents/`, `protocols/`, ...) and get copied into the destination repo as `.opencode/`. That is why this README and the agents reference paths with the `.opencode/` prefix — it is the shape they have in the installed repo.

```
DaverAgent/                     (source tree → copied as .opencode/ into the destination repo)
├── jason-opencode.json         # Base runtime config -> copy as opencode.json in the destination repo
│                              #  (default_agent, compaction, references, permission, instructions)
├── readme.md                  # This file
├── install.md                 # How to install the agent into another repo
│
├── agents/
│   └── subagents/             # One file per agent (read by the opencode runtime)
│       ├── delivery.md        # Interface with the human (primary)
│       ├── orchestrator.md    # Coordinator (deeply delegable)
│       ├── coder.md           # Implementation (language=angular|go, references docs/context/)
│       ├── reviewer.md        # Code review
│       ├── tester.md          # Tests
│       ├── architect.md       # Design
│       ├── explorer.md        # Search and mapping
│       ├── project-context.md # docs/ reading (read-only, lookups and context assembly)
│       ├── external-scout.md  # External docs via webfetch
│       ├── interpreter.md     # Step 0 normalization
│       ├── analista.md        # Second opinion
│       ├── documenter.md      # Documentation
│       └── *.schema.json      # Schemas of the structured returns
│
├── protocols/                  # Agent operating conventions (5 + README)
│   ├── readme.md               # Index
│   ├── prompt-pipeline.md      # Step 0 Interpret (interpreter subagent) + Phase 2 Reduce
│   ├── session-recovery.md     # Recovery for interrupted/STUCK sessions
│   ├── broad-investigation-template.md # Scaffold for wide-surface audits
│   ├── agent-installer.md      # 4 phases of the installer
│   └── subagent-spec-template.md # Canonical subagent shape + output_schema bridge
│
├── workflows/                  # Thinking instructions
│   ├── dispatch.md             # Interpreter-first gate (read by delivery every turn)
│   └── orchestrate.md          # Rules the orchestrator applies before acting
│
├── scripts/                    # Installer + helpers
│   ├── install-agent.ps1       # 4 phases: regenerates docs/project.md, context docs, subagents, opencode.json
│   ├── install-agent.schema.json # Question list that guides the installer (4 phases)
│   ├── validate-agent.sh       # Integrity lint of the agent tree (CI-friendly)
│   └── session-recover.ps1     # Walk of the session API for recovery
│
├── tests/                      # Test suite of the agent tree
│   ├── run-tests.sh            # Master runner: validator + schemas
│   ├── schema_check.py         # Mini JSON Schema validator (stdlib, no deps)
│   ├── test-output-schemas.py  # Schema <-> fixtures <-> .md examples contracts
│   ├── test-validate-agent.sh  # Runs validate-agent.sh and asserts it passes
│   └── fixtures/               # Golden fixtures for outputs and routing packets
│
└── .github/workflows/          # CI (runs run-tests.sh on every push/PR)
```

## Available subagents

Defined in `.opencode/agents/subagents/*.md` (`subagent` mode). Invoked from `delivery` or `orchestrator` via the `task` tool.

| Agent | Purpose |
|---|---|
| `delivery` | Interface with the human. Does NOT delegate technical work. |
| `orchestrator` | Executes Phase 2 (Reduce), coordinates multi-step work, fans out subagents. |
| `coder` | Implementation (language=angular|go). References the stack docs in `docs/context/`. Returns `CoderOutput`. |
| `tester` | Tests. Returns `TesterOutput`. |
| `reviewer` | Code review, security, performance. Returns `ReviewerOutput`. |
| `architect` | Design, boundaries, patterns. Returns `ArchitectOutput`. |
| `analista` | Second opinion, plan critique, stuck-recovery. Returns `AnalystOutput`. |
| `explorer` | Search and mapping in the repo. Returns `ExplorerOutput`. |
| `project-context` | Lookups and context assembly from `docs/` (read-only). The only writer of `docs/` is `documenter`. |
| `external-scout` | Brings docs of external libraries via webfetch. |
| `interpreter` | Normalizes the prompt (Step 0 of the pipeline). |
| `documenter` | Writes/maintains `docs/`. Returns `DocumenterOutput`. |

Models and temperatures live in **each agent's frontmatter** (`.opencode/agents/subagents/<id>.md`). Changing a model = editing the agent's frontmatter + restarting opencode.

(*) Without a declared `model:`: the subagent inherits the model of the primary agent that invokes it (opencode default). `model:` is an optional override.

## Protocols (how the agent thinks)

The protocols live in [`.opencode/protocols/`](./protocols/readme.md). The most important is [`.opencode/protocols/prompt-pipeline.md`](./protocols/prompt-pipeline.md), which defines the 2-stage analysis applied to every prompt without exception: Step 0 (Interpret) is executed by the `interpreter`; Phase 2 (Reduce) is executed by the `orchestrator`. `delivery.md` references it by anchor instead of duplicating the content.

## Agent permissions

- `orchestrator` and the subagents have NO external skills pre-enabled. The only legitimate built-in skill is `customize-opencode` (of the opencode runtime, not repo-local).
- All project info (Postgres, permission system, etc.) lives in `docs/context/` and is read **on demand**.

## Updating the config

- **Change an agent's model/temperature** → edit the frontmatter of `.opencode/agents/subagents/<id>.md` (`model` / `temperature`) and restart opencode. Nothing else.
- **Change an agent's definition** (prompt, tools, permissions, schema) → edit `.opencode/agents/subagents/<id>.md`.
- **Add an agent** → create `.opencode/agents/subagents/<id>.md` with its full frontmatter (`description`, `mode`, `model`, `temperature`, `permission`, `output_schema`). Do not touch `opencode.json`.
- To regenerate `docs/project.md`, the context docs and the subagents from the installer schema:

```powershell
& ".\.opencode\scripts\install-agent.ps1" -VerifyOnly   # see what would change
& ".\.opencode\scripts\install-agent.ps1"                 # apply
```

The installer makes an automatic backup in `.opencode/.backups/<timestamp>/` before overwriting.

## Validating the config

Before committing changes to `.opencode/`, run the full test suite (Git Bash / WSL):

```bash
bash .opencode/tests/run-tests.sh
```

It includes two suites, all with exit code 0/1 (CI-ready):

1. **`validate-agent.sh`** (integrity lint): that `opencode.json` is valid JSON, that every agent `.md` declares `model` in its frontmatter and does not use the deprecated `tools:` field (uses `permission:`), that every `output_schema` points to an existing file, that the `permission.task` of `delivery`/`orchestrator` point to real subagents, and that the mandatory frontmatter (`description`/`mode`) exists. `docs/` paths (of the destination repo) are reported as WARN, not errors.
2. **`test-output-schemas.py`** (output contracts): every valid fixture in `tests/fixtures/outputs/` validates against its schema, every invalid fixture is rejected, the golden routing packets in `tests/fixtures/prompts/` validate against `interpreter.schema.json`, and the JSON examples documented in the `.md` files stay in sync with their schemas.

## Troubleshooting

**"My config is not picked up"** — Verify that `opencode.json` is valid JSON: `Get-Content .\opencode.json -Raw | ConvertFrom-Json`.

**"I want to go back to the previous version"** — If the change was made by `install-agent.ps1`, there is a backup in `.opencode/.backups/<timestamp>/`. If you made it by hand, it depends on your own version control.
