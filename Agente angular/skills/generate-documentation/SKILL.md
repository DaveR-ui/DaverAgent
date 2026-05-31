---
name: generate-documentation
description: Guidelines and standards for creating AI-optimized documentation and updating the Agent Knowledge Hub.
---

# Generate Documentation Skill

## Principles (AI-Optimized)

All documentation in `.github/` follows these principles for optimal AI consumption:

- **Concise > Verbose**: Use bullet points, code examples, tables over paragraphs
- **Patterns > Prose**: Show code patterns instead of lengthy explanations
- **Structure**: Consistent headers, clear sections, minimal nesting (max 3 levels)
- **Examples**: Include real project code when possible
- **Status Markers**: Use `(WIP)`, `(TODO)`, `(DEPRECATED)` for incomplete sections
- **Language**: English only

**Target Audience**: AI agents and developers with technical context.

## Required Frontmatter

Every markdown file in `.github/` MUST start with:

```yaml
---
last_updated: YYYY-MM-DD
description: this is a brief one-line summary of the file's purpose
tags: [relevant, keywords]
---
```

## Required Component Doc Format

When documenting a component or feature flow, always include:

1. **Component Path & Overview** — where it lives and its primary purpose.
2. **Data Flow** — state management used (Signals, `rxResource()`, selectors, etc.).
3. **Known Anti-Patterns (AVOID)** — incorrect/deprecated usages found in `src/`.
4. **Standard Pattern (USE)** — definitive implementation using modern Angular.

## Checklist

1. Add YAML frontmatter (`last_updated`, `description`, `tags`) to every new file.
2. Structure docs with: Path & Overview → Data Flow → Anti-Patterns → Standard Pattern → CRITICAL sections.
3. Use tables for Anti-Pattern vs Standard comparisons; use `> [!CAUTION]` for breaking rules.
4. After creating a context doc, add a row to the **Component Map** in `AGENTS.md`.

## Adding to the Component Map

After creating a context doc, add a row to `AGENTS.md`:

| Component | Primary Doc | Secondary Docs | Key Issues Fixed |
|---|---|---|---|
| `your-component.ts` | `your-doc-file.md` | `angular-reactivity.md` | What it fixes |