# Protocol: IA Docs Gen

Standards for creating AI-optimized documentation in the canonical doc tree, including required frontmatter, the component-doc format, and the skill-to-doc reference rule.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-docs-gen`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

Whenever a new context doc, project protocol, or component doc is created in `docs/`. The protocol ensures the resulting file is concise, scannable, and machine-friendly — the format the rest of the agent system assumes.

## Principles (AI-optimized)

All documentation in this workspace follows these principles for optimal AI consumption:

- **Concise over verbose** — bullet points, code examples, tables over paragraphs.
- **Patterns over prose** — show code patterns instead of lengthy explanations.
- **Structure** — consistent headers, clear sections, minimal nesting (max 3 levels).
- **Examples** — include real project code when possible.
- **Status markers** — use `(WIP)`, `(TODO)`, `(DEPRECATED)` for incomplete sections.
- **Language** — English only (per [`docs/project.md`](../../docs/project.md) → `doc_language`).

**Target audience**: AI agents and developers with technical context.

## Required frontmatter

### Context documentation (`docs/context/`, `docs/protocols/`)

Every markdown file under `docs/` (other than `docs/project.md`) MUST start with:

```yaml
---
last_updated: YYYY-MM-DD
description: brief one-line summary of the file's purpose
tags: [relevant, keywords]
status: [active | wip | deprecated]
---
```

> **Note**: the workspace does not interpret `tags` for routing — they exist for human lookup via `docs/_TAG-INDEX.md`.

### Agent protocols (`.opencode/protocols/`)

Agent protocols follow a different convention: `# Protocol: <Name>` title, subtitle description paragraph, and sectioned prose. See [ia-catalog-manager](./ia-catalog-manager.md) and the existing protocols (`prompt-pipeline.md`, `agent-installer.md`, `broad-investigation-template.md`) for examples. No frontmatter required.

## Required component-doc format

When documenting a component or feature flow, always include:

1. **Component path and overview** — where it lives and its primary purpose.
2. **Data flow** — state management used (Signals, `rxResource()`, selectors, etc.).
3. **Known anti-patterns (AVOID)** — incorrect or deprecated usages found in source.
4. **Standard pattern (USE)** — definitive implementation using the project's modern conventions.
5. **Key issues fixed** — one-line summary per issue the doc resolves.

## Skill-to-doc reference rule

Every doc should make the relationship to the agent system explicit:

- Use a "Reference" or "Context" section in component docs to link to the slice entry in `docs/project.md`.
- Skills (this protocol set) link to the canonical project docs they reference, rather than duplicating them.
- **Example**: a doc about Angular testing should link to the slice's `testing` doc and the relevant `docs/context/rules.md` standards.

## Checklist

1. Add YAML frontmatter (`last_updated`, `description`, `tags`) to every new file.
2. Structure docs with: Path and Overview → Data Flow → Anti-Patterns → Standard Pattern → CRITICAL sections.
3. Use tables for anti-pattern vs standard comparisons; use `> [!CAUTION]` for breaking rules.
4. After creating a context doc, register it in `docs/context/README.md` and (if applicable) `docs/_TAG-INDEX.md`.
5. If the doc defines a new slice, add a row to the Slices table in [`docs/project.md`](../../docs/project.md).

## Adding to the index

After creating a context doc, add a row to `docs/context/README.md`:

| Component | Primary Doc | Secondary Docs | Key Issues Fixed |
|---|---|---|---|
| `your-component.ts` | `your-doc-file.md` | `angular-reactivity.md` | What it fixes |

## Constraints

- **PROHIBITED**: writing a doc without the required frontmatter.
- **PROHIBITED**: long prose paragraphs where a table or code block would do.
- **MANDATORY**: linking each new doc from the appropriate index.
- **MANDATORY**: keeping nesting to a maximum of 3 levels.

## Integration

The [documenter](../agents/subagents/documenter.md) subagent is the canonical writer for this protocol. Use the protocol above as the format spec the documenter checks against when reviewing its own output. Component docs that already have richer examples in `docs/context/architecture.md` or `docs/context/rules.md` should reference those instead of duplicating the standards.
