# Analysis: canonical-prompter vs prompt-analyzer + Doc Maintainer Design

## 1. Skill Comparison

### canonical-prompter (`.opencode/skills/canonical-prompter/SKILL.md`)
- **132 lines**, simple and generic
- No dependency on project dictionary
- Produces: type, enhanced prompt, acceptance criteria, edge cases, constraints
- Clarification protocol: general (list what's needed, don't proceed)
- Phase: not explicitly numbered

### prompt-analyzer (`.opencode/skills/prompt-analyzer/SKILL.md`)
- **207 lines**, domain-aware and structured
- Requires `.opencode/project-dictionary.md` (glossary, keyword mapping, inference rules, question rules)
- Produces: term resolution table, classification + confidence, identified modules with confidence, user hints, auto-inferences, unknown terms, clarification decision
- Clarification protocol: strict rules (max 2-3 sentences, one decision per question, show impact, minimal change first)
- Phase: explicitly Phase 1 of SDD workflow

### Overlap
| Feature | canonical-prompter | prompt-analyzer |
|---------|:------------------:|:---------------:|
| Classify prompt type | ✅ | ✅ |
| Preserve original prompt | ✅ | ✅ |
| Acceptance criteria | ✅ | ❌ |
| Edge cases | ✅ | ❌ |
| Constraints | ✅ | ❌ |
| Term resolution (dictionary) | ❌ | ✅ |
| Module identification | informal | structured table |
| Auto-inference | ❌ | ✅ |
| Hint extraction | ❌ | ✅ |
| Confidence level | ❌ | ✅ |
| Strict question rules | ❌ | ✅ |

### Problem
The SDD Agent system prompt calls `canonical-prompter` as Phase 1, but `prompt-analyzer` is more capable and defines itself as Phase 1. This is an orchestration inconsistency.

### Resolution
**Unify into a single skill** that:
1. Uses the dictionary if available, falls back to generic mode if not
2. Includes acceptance criteria + edge cases (from canonical-prompter)
3. Includes term resolution + module identification + hints (from prompt-analyzer)
4. Uses strict question rules (from prompt-analyzer)
5. Includes confidence level (from prompt-analyzer)

The unified skill should be named `prompt-analyzer` (more descriptive) and replace `canonical-prompter`.

---

## 2. Doc Maintainer Skill Design

### Current State
`Agente angular separado v2/.agents/utils/` has two Node.js scripts:
- `validate-links.mjs` (120 lines) - finds broken internal markdown links
- `repair-links.mjs` (118 lines) - auto-repairs broken links by filename matching

### What They Do Well
- Recursively find all `.md` files
- Strip fenced code blocks and inline code to avoid false positives
- Skip images, external URLs, anchor-only links
- Resolve paths relative to source file
- `repair-links`: processes in reverse order to preserve line numbers, handles ambiguous matches

### What's Missing for a Full Doc Maintainer

| Capability | Status | Notes |
|-----------|--------|-------|
| Internal link validation | ✅ exists | validate-links.mjs |
| Internal link repair | ✅ exists | repair-links.mjs |
| Code-doc consistency | ❌ missing | Do module/function names in docs match actual code? |
| Duplicate detection | ❌ missing | Same info repeated across multiple files? |
| Content placement | ❌ missing | Is info in the right file? |
| External link validation | ❌ missing | Are http/https URLs still alive? |
| Frontmatter consistency | ❌ missing | Are YAML metadata fields consistent? |
| Dead reference detection | ❌ missing | References to files/components that no longer exist |

### Proposed Skill: `doc-maintainer`

The skill should be an **LLM-driven analysis skill** that uses the existing scripts as tools and adds semantic validation:

```
doc-maintainer/SKILL.md
├── Phase 1: Structural Validation (scripts)
│   ├── Run validate-links.mjs → broken internal links
│   ├── Run repair-links.mjs → auto-fix unambiguous broken links
│   └── Report ambiguous repairs for manual review
├── Phase 2: Semantic Validation (LLM)
│   ├── Code-doc consistency check
│   ├── Duplicate content detection
│   ├── Content placement verification
│   └── Dead reference detection
├── Phase 3: External Validation (optional)
│   ├── External URL liveness check
│   └── API endpoint verification
└── Output: Validation report with severity levels
```

### Severity Levels
- **CRITICAL**: Broken links, references to non-existent code
- **WARNING**: Duplicate content, misplaced info, ambiguous links
- **INFO**: External links to verify, stylistic suggestions

### Integration with SDD Agent
This skill is NOT part of the prompt→resolution pipeline. It's a **standalone maintenance skill** that can be triggered:
- On demand: user asks to validate documentation
- After changes: when code changes are made, validate docs are still accurate
- Scheduled: periodic documentation health check

---

## 3. Action Items

1. **Unify** `canonical-prompter` + `prompt-analyzer` → single `prompt-analyzer` skill
2. **Delete** `canonical-prompter` skill after unification
3. **Create** `doc-maintainer` skill with link validation + semantic checks
4. **Copy/adapt** `validate-links.mjs` and `repair-links.mjs` to `.opencode/utils/`
5. **Update** SDD Agent workflow to use unified `prompt-analyzer`
