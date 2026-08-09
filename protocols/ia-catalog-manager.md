# Protocol: IA Catalog Manager

Unified CRUD operations for the project's canonical doc tree — `docs/context/`, `docs/protocols/`, and the per-slice docs. Create, read, update, move/rename, or delete docs with automatic registry synchronization and link validation.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-catalog-manager`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

Any time a doc needs to be added, moved, renamed, or removed in the canonical doc tree. This is the single entry point for those operations so callers do not need to know which specific role handles creation, renaming, or deletion. Every operation automatically synchronizes the registry files and validates cross-references.

## Scope

| Target | Path | Examples |
|---|---|---|
| **Context docs** | `docs/context/` | `rules.md`, `architecture.md`, slice-specific `errors.md` |
| **Project protocols** | `docs/protocols/` | `api-endpoint-factory.md` (this workspace) |
| **Index / entry point** | `docs/project.md` (Slices), `docs/context/README.md`, `docs/_TAG-INDEX.md` | — |

> **Note**: the former skill tree at `frontend/.agents/skills/` was removed on 2026-08-09; its "Skills / Workflows" categories collapsed into `docs/protocols/` and `.opencode/protocols/`. Operations targeting agent-system docs (e.g. `.opencode/agents/`, `.opencode/protocols/`) follow the same CRUD flow but use a different registry (see [ia-dev](./ia-dev.md) and [subagent-spec-template.md](./subagent-spec-template.md)).

## Registry files (must stay in sync)

Every CRUD operation that adds, removes, or renames an asset MUST update these files when applicable:

| File | Tracks | Update when |
|---|---|---|
| `docs/project.md` | Slices, stack, commands | New or removed slice |
| `docs/context/README.md` | Index of context docs | Doc create / rename / delete |
| `docs/_TAG-INDEX.md` | Tag-based fast lookup | Doc create / rename / delete with tags |
| `docs/protocols/README.md` | Project-level protocol index | New or removed project protocol |
| `.opencode/protocols/README.md` | Agent-system protocol index | New or removed agent protocol |
| Subagent file (if applicable) | Per-agent references | New doc an agent should consult |

## Pre-flight (all operations)

1. Identify the **operation** — Create, Read, Update, Move/Rename, or Delete.
2. Identify the **target type** — Context doc, project protocol, agent protocol, or index entry.
3. Identify the **target path** or proposed name.
4. Run the **Safety Guard** check below before proceeding.

## Safety guard (mandatory)

Before any destructive or structural operation, validate:

- **Protected files** — NEVER delete or rename `docs/project.md`, `docs/context/rules.md`, `docs/context/architecture.md`, `docs/context/README.md`, `docs/_TAG-INDEX.md`, or any agent-system file in `.opencode/`.
- **Deduplication** — for Create, search existing assets. If a similar doc exists, propose an Update instead.
- **Impact scan** — for Move/Rename/Delete, list all files that reference the target. Search across `docs/`, `.opencode/`, and `AGENTS.md`.
- **Governance question** — present the impact scan results and ask: "This affects [N] references. Proceed?"

## Create

### Create a context doc

1. Ask for: target folder (e.g. `docs/context/`, `docs/protocols/`), filename, purpose.
2. Create file with the mandatory frontmatter used in this workspace (see [ia-docs-gen](./ia-docs-gen.md)):
   ```yaml
   ---
   last_updated: YYYY-MM-DD
   description: one-line purpose summary
   tags: [relevant, keywords]
   ---
   ```
3. Register in:
   - `docs/context/README.md` — add a row under the appropriate section.
   - `docs/_TAG-INDEX.md` — add the relevant tag entries.
4. If the doc defines a routable pattern, add it to the Slices table in `docs/project.md`.

### Create an agent protocol

Follow [subagent-spec-template.md](./subagent-spec-template.md) for the template, then register in `.opencode/protocols/README.md`.

## Read

- **List all docs** — read `docs/context/README.md` and present grouped by topic.
- **List all protocols** — read `.opencode/protocols/README.md`.
- **Find by name or tag** — search `docs/_TAG-INDEX.md` for tag matches; use `grep` across `docs/` for broader text search.
- **Show dependencies** — for a given doc, grep its name/path across `docs/` and `.opencode/` to show what references it.

## Update

1. Locate the target file.
2. Apply content changes.
3. Update `last_updated` in frontmatter.
4. If the description or tags changed, update the relevant index entry.

## Move / rename

1. Identify the current path and the new path.
2. **Impact scan** — grep the old name/path across `docs/`, `.opencode/`, `AGENTS.md`. List every file and line that references it.
3. Move the file using filesystem operations.
4. Update all references in the impact scan.
5. Update registries (`docs/context/README.md`, `docs/_TAG-INDEX.md`, `docs/project.md` Slices, `.opencode/protocols/README.md`, etc.).
6. **Validate links** — run the link validation check.

## Delete

1. **Safety guard** — confirm the target is NOT a protected file.
2. **Impact scan** — grep the name/path across `docs/`, `.opencode/`, `AGENTS.md`. Present results.
3. **Extract knowledge** — if the asset contains patterns or rules not documented elsewhere, promote them to `docs/context/rules.md` or the relevant slice doc before deletion.
4. Remove the file/folder.
5. Clean registries (indexes, tag dictionaries, routing tables).
6. **Validate links** — run the link validation check.

## Link validation (post-operation)

After any Create, Move/Rename, or Delete:

1. Scan all `.md` files under `docs/` (and `.opencode/` if touched) for markdown links `[text](path)`.
2. For each link, resolve the target path relative to the source file.
3. Check if the target file exists.
4. Report:
   - All links valid — operation complete.
   - Broken links found — list each file, line, and broken target. Fix or flag for manual review.

## Decision rules

- **Single entry point** — if the user asks to create, rename, move, or delete anything under `docs/context/`, `docs/protocols/`, or `.opencode/protocols/`, use this protocol. Bulk prune / archive operations follow the Delete flow above with user confirmation (the dedicated skill-creator / pruner protocols were removed on 2026-08-09).
- **Atomic operations** — one CRUD operation at a time. Do not batch multiple creates / deletes unless explicitly requested.
- **Registry-first** — the registry files are the source of truth for discoverability. An unregistered asset is invisible to agents.
- **English only** — all generated content must be in English (per `docs/project.md` → `doc_language`).
- **Lean content** — keep generated docs under 10,000 characters where practical.

## Output format

Return an **Operation Report** after every CRUD action:

```
## Catalog Operation Report

**Operation**: [Create | Read | Update | Move/Rename | Delete]
**Target**: [path or name]
**Type**: [Context Doc | Project Protocol | Agent Protocol | Index Entry]

**Actions Taken**:
- [list of file changes]

**Registries Updated**:
- [list of registry files modified]

**Link Validation**: [All valid | N broken links found]

**Next Step**: [recommendation]
```

## Constraints

- **PROHIBITED**: deleting protected files (see Safety Guard).
- **PROHIBITED**: creating a doc without registering it in the appropriate index.
- **PROHIBITED**: renaming or moving a file without updating all cross-references.
- **MANDATORY**: running link validation after any structural change.
- **MANDATORY**: presenting the impact scan before any Delete or Move/Rename.

## Integration

In the opencode runtime, the canonical doc writer is the [documenter](../agents/subagents/documenter.md) subagent. Use the catalog-manager protocol when the operation spans multiple indexes or registries (e.g. rename a doc that appears in `docs/context/README.md`, `docs/_TAG-INDEX.md`, AND `docs/project.md` Slices). Bulk archive / cleanup follows the Delete flow with user confirmation; new agent protocols follow [subagent-spec-template.md](./subagent-spec-template.md).
