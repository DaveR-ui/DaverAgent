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
`bash scripts/validate-agent.sh`.

## Path contract

Two path vocabularies coexist. The normative resolution rule is the
`references.agent-system.description` in `opencode.json` (opencode injects that
reference's absolute root into every agent's context).

| Vocabulary | Examples | Resolves against |
|---|---|---|
| **Agent-system assets** | `agents/`, `protocols/`, `scripts/` | The `agent-system` reference in `opencode.json` |
| **Project documents** | `docs/project.md`, `docs/context/**` | The session working directory (each project's repo) |

This repo deliberately declares **no** `instructions` key. On opencode V2
`instructions` is a documented no-op — accepted but **not loaded** — and V2's
only ambient instruction source is `AGENTS.md`, which this repo deliberately
does not ship. Project docs are therefore read **on demand** from explicit
paths. A project that wants explicit `docs/context` / `docs/protocols`
references declares them in its own `opencode.json` `references` block.

**Golden rule:** never create a global `docs/`, and never hardcode an absolute
path. The read tool does not expand `~`.

## Structure

```
~/.config/opencode/              # == this repository
├── opencode.json                # Top-level runtime config + built-in `agents.title` model slot
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
└── scripts/                     # Validators
```

> A `plugins/` directory and a root `package.json` + lockfile are **optional**:
> they exist only if you add portable plugins (or other JS dependencies). This
> repo ships **neither** — do not add an empty `package.json` just to match a
> diagram. Any `node_modules/` is gitignored.

## Available agents

Defined in `agents/<id>.md` (`subagent` mode, except `delivery` which is
`primary`). Invoked from `delivery` or `orchestrator` via the subagent tool.

This table owns the **purposes** (all agents, including `delivery`, `orchestrator`
and `interpreter`). The dispatch contract — structured returns and the
model-independence dispatch rule — is the authoritative table in
`agents/orchestrator.md` → `## Available Subagents`; it is not duplicated here.

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

Model lives in **each agent's frontmatter**
(`agents/<id>.md`). Changing a model = editing the agent's frontmatter and
restarting opencode. Without a declared `model:`, a subagent inherits the model
of the primary agent that invokes it. `opencode.json` carries the built-in
`agents.title.model` slot (title generation, and — by orchestrator convention —
the cheap, different-family slot read at dispatch time for `reviewer`/`analista`
and every Typed-Decision Panel panelist). The orchestrator dispatches those seats
with the model configured at `agents.title.model`, a different model family from
the primary, so the independent second opinions stay independent. Invariant: that
slot must stay cheap and from a *different model family* than the primary — if it
is pointed at a same-family model, the second opinions silently degrade to a
monoculture.

## Protocols

The protocols live in `protocols/`:

- [`prompt-pipeline.md`](./protocols/prompt-pipeline.md) — Step 0 (Interpret) is
  executed by the `interpreter`; Phase 2 (Reduce) is executed by the
  `orchestrator`.
- [`dispatch.md`](./protocols/dispatch.md) — turn-entry procedure for the
  `delivery` seat: the interpreter-first gate, the "about to ask" tripwire, and
  the hand-off into the pipeline.
- [`orchestrate.md`](./protocols/orchestrate.md) — pre-action thinking process for
  the `orchestrator` seat: Protocol Discovery → Context Refresh → Proposal →
  Implementation → Verification → Documentation.
- [`subagent-spec-template.md`](./protocols/subagent-spec-template.md) — canonical
  shape for subagent definitions.
- [`session-recovery.md`](./protocols/session-recovery.md) — recovery flow for
  interrupted or STUCK sessions in the delivery → orchestrator → subagent
  hierarchy.
- [`broad-investigation-template.md`](./protocols/broad-investigation-template.md) —
  5-section scaffold for prompts that map, inventory, or audit the repo.

## Agent permissions

- Global runtime permission rules live in `opencode.json` as the top-level
  `permissions` array of `{ action, resource, effect }`. Each agent also carries
  its own `permission:` block in its `.md` frontmatter. Valid V2 permission
  actions include `read`, `edit`, `glob`, `grep`, `list`, `bash`, `task`,
  `webfetch`, `websearch`, `question`, `external_directory`, `lsp`, `skill`, and
  `doom_loop`; `task` is the subagent-dispatch gate. `webfetch`/`websearch` are
  first-class V2 actions — verified against the installed runtime — so
  `external-scout`'s `webfetch: allow` and `delivery`'s `webfetch: deny` are
  legitimate rules, not leftovers.
- **Two permission vocabularies.** The top-level `permissions` array in
  `opencode.json` uses the runtime's action names verbatim — notably `shell` for
  shell execution (the shell tool asserts `action: "shell"`), `edit` for
  edit/write/patch, and `subagent` for dispatch. Each agent's `permission:`
  block in its `.md` frontmatter uses the agent-config keys (`bash`, `task`,
  `edit`, `read`, …), which the runtime aliases to `shell` / `subagent` /
  `edit`. Do NOT rename `shell` → `bash` in the global array: that turns the
  shell rules inert, because the evaluated action is `shell`. Verified against
  the installed runtime v2.0.8.
- Self `permission.task` grants remain on `explorer` and `reviewer` only — the
  two agents whose bodies document self fan-out (`## Sampling and Fan-out`).
  Every other subagent does not recurse and carries no `task` grant.
- `orchestrator` and the subagents have no external skills pre-enabled. Any
  built-in skills come from the opencode runtime itself, not from this repo (the
  runtime owns the skill names, which may change). **This repo ships no skills by
  design**: conventions are `protocols/*.md` — intentionally prose markdown, not
  `.opencode/skills/`, because skills are strict-text and protocols are the
  preferred mechanism here.
- All project info lives in each project's `docs/context/` and is read **on
  demand**.
- **Structured returns are a prose contract, not runtime-enforced.** The V2
  `output_schema` behavior is specified in
  [`protocols/subagent-spec-template.md`](./protocols/subagent-spec-template.md)
  (the SSOT), and `scripts/validate-agent.sh` performs the structural check on
  `agents/*.schema.json`.
- **`delivery`, `orchestrator`, and `external-scout` are prose-only contracts by
  design** — no `output_schema` is intended for them.

## Updating the config

- **Change an agent's model** → edit the frontmatter of `agents/<id>.md`
  (`model`), then restart opencode.
- **Change an agent's definition** (prompt, tools, permissions, schema) → edit
  `agents/<id>.md`.
- **Add an agent** → create `agents/<id>.md`. Required frontmatter: `description`
  and `mode`. Optional frontmatter: `model`, `permission`,
  `output_schema` — without a declared `model:`, the subagent inherits the
  invoking primary's model (see "Available agents" above). Then:
  - grant the new agent in `permission.task` in the delegating agents
    (`agents/delivery.md` / `agents/orchestrator.md`) — otherwise the new agent
    is never reachable;
  - if you declare `output_schema: ./<id>.schema.json`, also create the sibling
    `agents/<id>.schema.json`.
  Do not add a per-agent block to `opencode.json`; it carries only the built-in
  `agents.title.model` slot, and per-agent `model` stays in each
  agent's frontmatter.
- **Update the global install** → `git pull` in the `~/.config/opencode` clone.

## Validating the config

Before committing changes to the agent system, run the single integrity gate:

```bash
bash scripts/validate-agent.sh
```

It is exit-code driven (CI-ready) and checks:

- `opencode.json` is valid JSON;
- the flat `agents/` layout is intact, with frontmatter and a valid `mode` on every agent;
- unsupported fields are absent: no `instructions`, no `small_model`, no singular `agent` block;
- no `AGENTS.md` is shipped;
- no secret material is committed;
- every `output_schema` resolves to an existing file;
- `permission.task` grants fail closed (every allow target resolves to a real agent);
- every `references` entry resolves;
- every `*.schema.json` under `agents/` parses as valid JSON and is structurally
  closed (any `scripts/*.schema.json` is included when present; this repo
  currently ships none);
- every schema enum target (e.g. `re_route_to`) resolves to an agent;
- no dangling references: markdown links plus inline-code `agents/*.md` /
  `protocols/*.md` paths all resolve.

## Troubleshooting

**"My config is not picked up"** — Verify `opencode.json` is valid JSON:
`python3 -m json.tool opencode.json`.

**"I want to go back to the previous version"** — Use your own version control
(Git) to check out the previous state of the clone.

**"A project doesn't see its `docs/`"** — Expected: this repo declares no
`instructions` key. See "Path contract" above.
