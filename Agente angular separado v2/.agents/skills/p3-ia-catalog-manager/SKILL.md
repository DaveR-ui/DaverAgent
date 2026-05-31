---
name: catalog-manager
description: Unified CRUD operations for the Agent Knowledge Hub. Create, read, update, move/rename, or delete skills and context documentation with automatic registry synchronization and link validation.
license: MIT
compatibility: opencode
metadata:
  last_updated: 2026-05-09
  pillar: p3
  status: active
---

# 📦 Skill: Catalog Manager (Unified CRUD for Skills & Docs)

## Goal
Provide a single entry point for all lifecycle operations on `.agents/skills/` and `.agents/context/`. Eliminates the need to know which specific skill handles creation, renaming, or deletion. Every operation automatically synchronizes all registry files and validates cross-references.

## Scope

| Target | Path | Examples |
|---|---|---|
| **Skills** | `.agents/skills/<name>/` | `p1-framework-angular-component/`, `p3-ia-analyzer/` |
| **Context Docs** | `.agents/context/` (4 subfolders) | `project/rules.md`, `standards/angular-reactivity/testing.md` |
| **Workflows** | `.agents/workflows/` | `orchestrate.md`, `new-feature.md` |

## Registry Files (SSOT — must stay in sync)

Every CRUD operation that adds, removes, or renames an asset MUST update these files when applicable:

| File | Tracks | Update When |
|---|---|---|
| `skills/SKILLS_INDEX.md` | All skills with pillar, focus, origin | Skill create / rename / delete |
| `context/orchestration/AGENTS.md` | Component-to-doc map, skill references | Doc create / rename / delete |
| `context/orchestration/_TAG-INDEX.md` + `tags-p1.md` / `tags-p2.md` / `tags-p3.md` | Tag-based fast lookup | Doc create / rename / delete with tags |
| `workflows/orchestrate.md` | Task routing table | Skill or doc used in routing |
| `AGENT-GUIDE.md` | Folder tree diagram | Skill create / rename / delete |
| `system prompt` (`.opencode/agents/`) | Available skills list | Skill create / rename / delete |

## Instructions

### Phase 0: Pre-Flight (all operations)
1. Identify the **operation**: Create, Read, Update, Move/Rename, or Delete.
2. Identify the **target type**: Skill, Context Doc, or Workflow.
3. Identify the **target path** or proposed name.
4. Run the **Safety Guard** check below before proceeding.

### Safety Guard (MANDATORY)
Before any destructive or structural operation, validate:
- **Protected files**: NEVER delete or rename `rules.md`, `coding-conventions.md`, `AGENTS.md`, `orchestrate.md`, `flow.md`, `persona.md`, `CHEATSHEET.md`, `_TAG-INDEX.md`, `tags-p1.md`, `tags-p2.md`, `tags-p3.md`, `SKILLS_INDEX.md`, `AGENT-GUIDE.md`.
- **Deduplication**: For Create — search existing assets. If a similar skill/doc exists, propose an Update instead.
- **Impact scan**: For Move/Rename/Delete — list all files that reference the target. **MANDATORY**: Search across all `.agents/context/`, `.agents/workflows/`, AND `.agents/skills/*/SKILL.md`.
- **Governance question**: Present the impact scan results and ask: "This affects [N] references (including skills). Proceed?"

---

### CREATE

#### Create a Skill
1. Ask for: name (with pillar prefix), description (pushy trigger phrase), pillar (p1/p2/p3).
2. Validate pillar prefix matches classification:
   - `p1-` → Language & Framework Standards
   - `p2-` → Project & SafeGuard Standards
   - `p3-` → IA Orchestration & Logic
3. Create directory: `.agents/skills/<name>/`
4. Create `SKILL.md` with mandatory OpenCode structure:
   ```yaml
   ---
   name: [regex: ^[a-z0-9]+(-[a-z0-9]+)*$]
   description: [trigger phrase]
   license: MIT
   compatibility: opencode
   metadata:
     last_updated: YYYY-MM-DD
     pillar: [p1|p2|p3]
     status: active
   ---
   ```
5. **MANDATORY**: Include a "References" or "Context" section in `SKILL.md` linking to the authoritative documentation in `context/`.
6. Register in:
   - `skills/SKILLS_INDEX.md` — add row under correct pillar section
   - `AGENT-GUIDE.md` — add entry in folder tree diagram
6. If the skill is referenced in routing, add to `workflows/orchestrate.md`.

#### Create a Context Doc
1. Ask for: target folder (`orchestration/`, `project/`, `standards/`, `memory/`), filename, purpose.
2. Create file with mandatory frontmatter:
   ```yaml
   ---
   last_updated: YYYY-MM-DD
   description: one-line purpose summary
   tags: [relevant, keywords]
   status: ACTIVE
   ---
   ```
3. Register in:
    - `context/orchestration/AGENTS.md` — add row to Component Map if applicable
    - Matching pillar tag dictionary (`tags-p1.md` / `tags-p2.md` / `tags-p3.md`) — add under matching tag(s)
4. If the doc defines a routable pattern, add to `workflows/orchestrate.md` routing table.

---

### READ

#### List All Skills
- Read `skills/SKILLS_INDEX.md` and present grouped by pillar.

#### List All Context Docs
- Read `_TAG-INDEX.md` for pillar dictionary routing, then navigate to `tags-p1.md` / `tags-p2.md` / `tags-p3.md`.
- Or list directory contents of `context/<subfolder>/`.

#### Find by Name or Tag
- Search `SKILLS_INDEX.md` for skill name.
- Search the pillar tag dictionaries (`tags-p1.md` / `tags-p2.md` / `tags-p3.md`) for tag matches.
- Use grep across `.agents/` for broader text search.

#### Show Dependencies
- For a given skill or doc, grep its name/path across all `.agents/` files to show what references it.

---

### UPDATE

#### Update a Skill
1. Locate `skills/<name>/SKILL.md`.
2. Apply content changes.
3. Update `last_updated` in frontmatter.
4. If `description` changed, update `SKILLS_INDEX.md` row.

#### Update a Context Doc
1. Locate the doc in `context/`.
2. Apply content changes.
3. Update `last_updated` in frontmatter.
4. If tags changed, update matching pillar tag dictionary (`tags-p1.md` / `tags-p2.md` / `tags-p3.md`).
5. If the doc moved between categories, update `AGENTS.md` Component Map.

---

### MOVE / RENAME

1. **Identify current path** and **new path**.
2. **Impact scan**: grep the old name/path across all `.agents/` files. List every file and line that references it.
3. **Move the file/folder** using filesystem operations.
4. **Update all references**: for each file in the impact scan, update the old path to the new path.
5. **Update registries**:
    - Skill rename → `SKILLS_INDEX.md`, `AGENT-GUIDE.md`, matching pillar tag dictionary (if tagged), `orchestrate.md` (if routed)
    - Doc rename → `AGENTS.md`, matching pillar tag dictionary, `orchestrate.md` (if routed)
6. **Validate links**: run the Link Validation check (below).

---

### DELETE

1. **Safety Guard**: confirm the target is NOT a protected file.
2. **Impact scan**: grep the name/path across all `.agents/`. Present results.
3. **Extract knowledge**: if the asset contains patterns or rules not documented elsewhere, promote them to `patterns-catalog.md` or `rules.md` before deletion.
4. **Remove the file/folder**.
5. **Clean registries**:
    - Skill → remove from `SKILLS_INDEX.md`, `AGENT-GUIDE.md`, matching pillar tag dictionary, `orchestrate.md`
    - Doc → remove from `AGENTS.md`, matching pillar tag dictionary, `orchestrate.md`
6. **Validate links**: run the Link Validation check.

---

### Link Validation (post-operation)

After any Create, Move/Rename, or Delete:

1. Scan all `.md` files under `.agents/` for markdown links `\[.*\]\(.*\)`.
2. For each link, resolve the target path relative to the source file.
3. Check if the target file exists.
4. Report:
   - ✅ All links valid — operation complete.
   - ❌ Broken links found — list each file, line, and broken target. Fix or flag for manual review.

---

## Decision Rules

- **Single entry point**: If the user asks to create, rename, move, or delete anything under `.agents/skills/` or `.agents/context/`, use THIS skill. Do NOT delegate to `p3-ia-skill-creator` or `p3-ia-pruner` unless the operation is a bulk prune/archive (which remains `p3-ia-pruner`'s domain).
- **Atomic operations**: One CRUD operation at a time. Do not batch multiple creates/deletes unless explicitly requested.
- **Registry-first**: The registry files are the source of truth for discoverability. An unregistered asset is invisible to agents.
- **English only**: All generated content (SKILL.md, context docs) must be in English.
- **Skill-to-Doc Coupling**: Skills MUST NOT contain dense project rules or standards. They should refer to the documentation in `context/` for that information.
- **Lean content**: Keep generated SKILL.md files under 10,000 characters.

## Output Format

Return an **Operation Report** after every CRUD action:

```
## Catalog Operation Report

**Operation**: [Create | Read | Update | Move/Rename | Delete]
**Target**: [path or name]
**Type**: [Skill | Context Doc | Workflow]

**Actions Taken**:
- [list of file changes]

**Registries Updated**:
- [list of registry files modified]

**Link Validation**: [✅ All valid | ❌ N broken links found]

**Next Step**: [recommendation]
```

## Constraints

- **PROHIBITED**: Deleting protected files (see Safety Guard).
- **PROHIBITED**: Creating a skill without registering it in `SKILLS_INDEX.md`.
- **PROHIBITED**: Renaming or moving a file without updating all cross-references.
- **MANDATORY**: Running Link Validation after any structural change.
- **MANDATORY**: Presenting the impact scan before any Delete or Move/Rename.

## Examples

### Example 1: Create a new skill
**User**: "Create a skill for validating API responses against TypeScript interfaces."
1. Classify as `p1-` (framework standard). Name: `p1-api-response-validator`.
2. Create `.agents/skills/p1-api-response-validator/SKILL.md`.
3. Add row to `SKILLS_INDEX.md` under Pillar 1.
4. Add entry to `AGENT-GUIDE.md` folder tree.
5. Run Link Validation.
6. Return Operation Report.

### Example 2: Rename a context doc
**User**: "Rename `testing.md` to `resource-testing.md`."
1. Impact scan: grep `testing.md` across `.agents/` → found in pillar tag dictionaries, `orchestrate.md`, `AGENTS.md`.
2. Rename file in `context/standards/angular-reactivity/`.
3. Update all 3 references.
4. Run Link Validation.
5. Return Operation Report.

### Example 3: Delete an orphaned workflow
**User**: "Remove `storybook.md` — we don't use it."
1. Safety Guard: not a protected file ✓.
2. Impact scan: grep `storybook.md` → found in `orchestrate.md`, `AGENT-GUIDE.md`.
3. Extract any unique patterns → none found.
4. Delete file.
5. Remove references from registries.
6. Run Link Validation.
7. Return Operation Report.
