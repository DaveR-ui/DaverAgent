# Install the global agent system

> One-page, copy-paste checklist for the **human**. Every step has a verify-only
> mode that writes nothing — use it before applying.

## 0. Prerequisites

- Git.
- The agent source repository: `https://github.com/DaveR-ui/DaverAgent.git`.
- Bash (Linux/macOS/WSL/Git Bash) for `scripts/bootstrap.sh`.
- Node (optional; required only by the per-project docs validator).
- Python 3 (optional; used by the integrity linter and schema tests).

There is **no per-project `.opencode/` copy** anymore. The agent system is
installed once per machine at `~/.config/opencode` and shared by every project.

## 1. Install or update on a machine

```bash
bash scripts/bootstrap.sh --verify-only   # report what would happen, write nothing
bash scripts/bootstrap.sh                 # clone or update into ~/.config/opencode
```

`bootstrap.sh`:

- Clone the repo into `${XDG_CONFIG_HOME:-$HOME/.config}/opencode` when the
  target does not exist.
- `git pull --ff-only` when the target is already a clone of this repository
  (idempotent).
- **Back up** an existing non-repo target to
  `~/.config/opencode.bak.<timestamp>` before replacing it. Backups are never
  deleted automatically.

If you prefer an explicit clone:

```bash
git clone https://github.com/DaveR-ui/DaverAgent.git ~/.config/opencode
```

## 2. Confirm the layout

The repository root **is** the opencode config directory. opencode loads
`opencode.json` and `agents/*.md` directly from it.
`protocols/` and `workflows/` are read on demand by agents (not auto-loaded).

```bash
ls ~/.config/opencode
# opencode.json  agents/  protocols/  workflows/  scripts/  tests/  templates/ ...
```

## 3. Validate the config

Run the full test suite from the config directory:

```bash
cd ~/.config/opencode
bash tests/run-tests.sh
```

It must exit 0. It runs the integrity lint (`scripts/validate-agent.sh`) and the
output-schema contract tests. `docs/` paths reported as WARN are expected — they
belong to individual projects, not to the global config.

## 4. Optional — per-project documentation bootstrap

Project **facts** (stack, commands, slices, context docs) still live in each
project's own `docs/`. The former generator for those stubs is retired; create
them by hand, following the shape that
[`protocols/agent-installer.md`](./protocols/agent-installer.md) documents. A
project's `docs/` normally contains:

- `docs/project.md` — the entry point (stack, commands, domain entities, the
  5-column Slices table, Repository Structure, Common Lookups).
- `docs/context/context-index.md` — the hub linking each context doc.
- The `docs/context/*.md` files the project needs (architecture, project-rules,
  project-slang, …).

Copy the derived validator into the project to check the corpus:

```bash
cp ~/.config/opencode/templates/docs-validate.js /path/to/project/docs/validate.js
```

Validate a project's docs at any time with:

```bash
node docs/validate.js            # report errors/warnings (exit 1 on errors)
node docs/validate.js --write    # regenerate the generated indexes (write-if-diff)
```

The validator checks an **existing** corpus; it never creates missing artifacts.
To migrate a project created before the `documentation-onrails (version 1.4, snapshot 2026-09-12)` adoption (legacy
`docs/context/README.md`, `docs/protocols/README.md`, `docs/_TAG-INDEX.md`,
`docs/project-slang.md`, 4-column Slices), follow the checklist in
[`protocols/agent-installer.md`](./protocols/agent-installer.md) — human-confirmed;
the legacy names are read-accepted only until 2026-10-12.

To let a project reference its own `docs/context/` and `docs/protocols/` without
the global config guessing, copy the optional shim into the project root:

```bash
cp ~/.config/opencode/templates/project-opencode.json /path/to/project/opencode.json
```

## 5. Verify `opencode.json`

```bash
python3 -m json.tool ~/.config/opencode/opencode.json > /dev/null && echo "opencode.json is valid"
```

It contains top-level runtime config only (`model`, `small_model`,
`default_agent`, `compaction`, `references`, global `permission`,
`instructions`) and the `angular-cli` and `engram` MCP servers. There is **no**
`agent` block; per-agent config lives in each agent's frontmatter.

## 6. Author the project docs

Create these by hand and fill in the substance:

| File | Fill in |
|---|---|
| `docs/project.md` | Real project name, stack, commands, 5-column Slices table (id, description, keywords, entry points, primary agents), Repository Structure, Common Lookups, domain entities |
| `docs/context/architecture.md` | Layers, dependency rules |
| `docs/context/project-rules.md` | Coding standards, error handling, security |
| `docs/context/project-slang.md` | Project slang snapshot (author the rows by hand) |

The `delivery` agent picks these up on the next session and routes through them.

---

## Updating later

| Change | Command |
|---|---|
| Update the global agent system | `bash scripts/bootstrap.sh` |
| Audit what bootstrap would change | `bash scripts/bootstrap.sh --verify-only` |
| Add a slice to a project's `docs/project.md` | Edit the file directly. |
| Add or update an agent | Edit `agents/<id>.md` (frontmatter carries `temperature`; `model` is optional and inherited when omitted). |
| Change a model / temperature | Edit `agents/<id>.md` → optional `model` / `temperature`, restart opencode. |
| Add a new context doc type | Add the file under the project's `docs/context/` and update its index. |

## Troubleshooting

**"The agent ignores my project's `docs/project.md`."**
Confirm the project has `docs/project.md`. `opencode.json` lists it under
`instructions`, relative to the session working directory; when absent it is
silently skipped.

**"I have both a global and a project `opencode.json`."**
That is supported: opencode merges the project-level config over the global one.
Use `templates/project-opencode.json` as the starting point for the project file.

**"I want to go back to the previous version."**
Restore the `~/.config/opencode.bak.<timestamp>` directory created by the last
`bootstrap` run, or use version control.
