# AGENTS.md — Global Agent System

This repository **is** the global opencode configuration for every machine it is
installed on. Its contents are cloned into `~/.config/opencode` (or
`$XDG_CONFIG_HOME/opencode`) by [`scripts/bootstrap.sh`](./scripts/bootstrap.sh),
so there is exactly **one** copy of the agent system shared by every project.

## What opencode loads from here

| Loaded automatically by the runtime | Read on demand by agents |
|---|---|
| `opencode.json` | `protocols/**` — operating conventions |
| `AGENTS.md` (this file) | `workflows/**` — thinking instructions |
| `agents/<id>.md` (+ `agents/<id>.schema.json`) | `scripts/**`, `tests/**` |
| `plugins/**`, `commands/**`, `skills/**` | `templates/**` |

`protocols/` and `workflows/` are **not** auto-loaded; agents read them
explicitly when a task calls for them.

## Path contract (read before resolving any path)

Two path vocabularies coexist. Do not mix them.

1. **Agent-system assets** — `agents/`, `protocols/`, `workflows/`, `scripts/`,
   `templates/`. These belong to the global agent system and are referenced
   **repo-root-relative** (e.g. `protocols/prompt-pipeline.md`,
   `workflows/orchestrate.md`, `agents/coder.md`). The `agent-system` entry in
   `opencode.json` → `references` resolves to this repository's root
   (`~/.config/opencode`); resolve agent-system paths under that root.
   Never hardcode absolute paths (`/home/...`): the read tool does not expand
   `~`, and absolute paths break on a second machine.

2. **Project documents** — `docs/project.md`, `docs/context/**`,
   `docs/protocols/**`. These belong to whichever project the session is
   running in and resolve relative to the session working directory, never
   globally. `opencode.json` lists `docs/project.md` under `instructions`; when
   a project has no `docs/`, that instruction is silently skipped and agents
   fall back to code exploration.

**Never create a global `docs/`.** Project docs live inside each project's repo.

## Global rules

- Agent-system files (`agents/`, `protocols/`, `workflows/`, `scripts/`,
  `templates/`, `AGENTS.md`, `opencode.json`) are always written in **English**.
- Project documentation follows the project's `doc_language` (see that
  project's `docs/project.md`), or English when the project declares none.
- Per-agent configuration (`description`, `mode`, `model`, `temperature`,
  `permission`, `output_schema`) lives in each agent's frontmatter.
  `opencode.json` carries top-level runtime config only — there is no `agent`
  block.
- The `delivery` agent is the sole human interface; all human-facing
  communication flows through it.

## Editing the agent system

Changes to `agents/`, `protocols/`, `workflows/`, or `opencode.json` are
high-leverage and follow the review loop documented in
[`agents/delivery.md`](./agents/delivery.md) (section "Agent-system changes
require review"): draft → review (`reviewer` or `analista`) → apply → verify
with `bash tests/run-tests.sh`.

## Installing / updating on a machine

```bash
bash scripts/bootstrap.sh               # install or update at ~/.config/opencode
bash scripts/bootstrap.sh --verify-only # report what would happen, write nothing
```

An existing non-repo `~/.config/opencode` is backed up to
`~/.config/opencode.bak.<timestamp>` before bootstrap writes anything. See
[`install.md`](./install.md) for the full checklist.
