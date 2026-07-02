# Project Documentation Conventions

> **Single source of truth for project doc paths.**
> Agent files, protocols, and workflows reference this file instead of hardcoding paths.
> To adapt the agent system to another project, update the values below.

## Canonical Paths

| Key | Path | Purpose |
|---|---|---|
| `project_entry_point` | `docs/project.md` | Project metadata, stack, commands, domain entities, slices table |
| `context_dir` | `docs/context/` | Strategic docs (architecture, rules, business logic, strategies) |
| `context_index` | `docs/context/README.md` | Index of all context docs |
| `project_protocols_dir` | `docs/protocols/` | Project-specific protocol templates (e.g., endpoint factory) |
| `rules_file` | `docs/context/rules.md` | Development standards |
| `architecture_file` | `docs/context/architecture.md` | Architecture patterns |

## How Agents Use These Paths

- **Reading project context**: Start at `project_entry_point`, then consult `context_index` to find the relevant strategic docs in `context_dir`.
- **Architecture decisions**: Read `architecture_file`.
- **Development standards**: Read `rules_file`.
- **Scaffold templates**: Look in `project_protocols_dir`.
- **Subsystem-specific docs**: Search `context_dir` for the relevant topic (permissions, database, etc.).

## Adaptation Notes

Another project might use different paths. For example:
- `project_entry_point` could be `AGENT.md` instead of `docs/project.md`
- `context_dir` could be `.opencode/docs/` instead of `docs/context/`
- `project_protocols_dir` could be empty if no project-specific protocols exist

Update this file to match the project's actual structure. All agent files, protocols, and workflows reference these keys rather than hardcoding paths.
