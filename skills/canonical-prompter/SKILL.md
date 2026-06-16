---
name: canonical-prompter
description: Analyzes raw prompts with domain dictionary, classifies prompt type, resolves terms, identifies modules, extracts hints, produces structured analysis with acceptance criteria and edge cases. Use as the first analysis step before scope definition.
license: MIT
metadata:
  audience: developers
  workflow: prompt-analysis
  phase: 1
---

## What I Do

- **Load human context** from `humano.md` for vocabulary and communication preferences
- **Resolve terms** using dictionary glossary and keyword mapping (falls back to contextual inference if no dictionary)
- **Classify prompts** into: `bug`, `task`, `feature-design`, `update`
- **Identify target module(s)** based on keyword-to-module mapping or contextual analysis
- **Extract user hints** - clear signals the user provided about the problem
- **Apply auto-inferences** using dictionary rules or general heuristics
- **Generate acceptance criteria** and **edge cases** for the prompt
- **Formulate clarifying questions** when needed, following strict question rules
- **Output structured analysis** ready for the next phase (context reduction)

## When to Use Me

Use this skill when:
- A raw prompt arrives and needs structured analysis
- The prompt contains jargon, abbreviations, or project-specific terms
- You need to classify and understand the problem before scoping
- Clarification is needed but must follow structured question rules
- You want consistent prompt analysis across all development tasks

## Input Requirements

1. **Raw prompt** from the user
2. **Project context** from `.opencode/project.md`
3. **Human context** from `~/.config/opencode/sessions/{humano}/humano.md` (for vocabulary)

## Analysis Process

### Step 1: Load Context
Read:
- `.opencode/project.md` for project structure (always)
- `humano.md` for vocabulary and communication preferences

Load from humano.md:
- Translation Dictionary (term definitions)
- Communication preferences (tone, language, response style)

### Step 2: Term Resolution
For each significant term in the prompt:

1. Check if it exists in the **Translation Dictionary** → resolve meaning
2. If not found → infer meaning from project context (project.md architecture, module names)
3. Use general development terminology knowledge
4. Flag ambiguous terms for potential clarification

### Step 3: Auto-Inference
Apply general heuristics:
- "no anda" / "rompió" / "falla" / "error" / "crash" → likely `bug`
- "agregar" / "poner" / "crear" / "add" / "create" → likely `task` or `feature-design`
- "mejorar" / "optimizar" / "mejor" / "improve" / "optimize" → likely `update`
- "modal" / "form" / "page" / "component" → frontend context
- "endpoint" / "route" / "api" / "handler" → backend context

### Step 4: Classification
Determine prompt type:

| Type | Trigger | Keywords |
|------|---------|----------|
| `bug` | Something broken | error, crash, falla, no anda, roto, broken, issue, fix, not working |
| `task` | Specific work to do | agregar, poner, cambiar, mover, limpiar, migrate, add, remove, change |
| `feature-design` | New capability | nuevo, crear, diseñar, implementar, feature, new, create, design, build |
| `update` | Modify existing | mejorar, optimizar, ajustar, upgrade, refactor, improve, enhance, adjust |

Assign **confidence level**: high (clear keywords + context), medium (some ambiguity), low (multiple valid interpretations)

### Step 5: Module Identification
Map prompt terms to modules:
- Use project.md module structure + contextual analysis

| Module | Confidence | Evidence |
|--------|------------|----------|
| [module] | [high/med/low] | [what in the prompt points here] |

### Step 6: Hint Extraction
Extract explicit hints from the user:
- What parameters did they mention?
- What environment/context did they specify?
- What behavior did they observe?
- What did they already try?

### Step 7: Acceptance Criteria Generation
Generate testable acceptance criteria for the prompt:
- What must work after this is done?
- What behavior should be observable?
- What should NOT break?

Format as checklist:
```
- [ ] Criterion 1 (testable)
- [ ] Criterion 2 (testable)
- [ ] Criterion 3 (testable)
```

### Step 8: Edge Cases Identification
Identify edge cases to consider:
- Boundary conditions
- Error scenarios
- Unusual inputs
- Concurrent operations
- Environment-specific behaviors

### Step 9: Clarification Decision
Determine if clarification is needed:

**DO NOT ask if:**
- All terms resolved via dictionary or context
- Inference rules cover the ambiguity
- The prompt is clear and actionable
- Confidence level is high

**ASK if:**
- Unknown terms that block understanding
- Multiple valid interpretations exist
- Bug with conditional behavior (need resource type + environment)
- Feature scope is ambiguous (which environments?)
- Confidence level is low

### Step 10: Question Formulation (if needed)
Follow **Question Rules** strictly:

1. **Concise**: Max 2-3 sentences
2. **Declare the problem**: State what you need to know and why
3. **One decision per question**: Don't combine decisions
4. **Show impact**: Present options with practical consequences
5. **Minimal change first**: Least invasive option goes first

## Output Template

```markdown
## Prompt Analysis

### Original Prompt
[Exact original text - preserved verbatim]

### Term Resolution
| Term | Resolved As | Source |
|------|-------------|--------|
| [term] | [meaning] | dictionary/inference/context |

### Classification
- **Type**: [bug | task | feature-design | update]
- **Confidence**: [high | medium | low]
- **Reasoning**: [why this classification]

### Identified Modules
| Module | Confidence | Evidence |
|--------|------------|----------|
| [module] | [high/med/low] | [what in the prompt points here] |

### User Hints
- [Hint 1: explicit information provided]
- [Hint 2: parameters mentioned]
- [Hint 3: environment/context clues]

### Auto-Inferences Applied
- [Inference 1: what was inferred and why]
- [Inference 2: ...]

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Edge Cases to Consider
- [Edge case 1]
- [Edge case 2]

### Unknown Terms (if any)
- [Term that could not be resolved]

### Clarification Needed
[Yes/No]

If Yes:
**Question**: [Formulated following question rules]
**Options**:
- [Option A] → [Impact]
- [Option B] → [Impact]

### Ready for Next Phase
[Yes - if no clarification needed / No - if clarification pending]
```

## Inference Boundaries

### What to Infer Automatically
- Domain terms that exist in the dictionary
- Module from keyword mapping or project structure
- Prompt type from clear keywords
- Environment when explicitly stated
- Frontend/backend context from terminology

### What to Ask About
- Terms not in dictionary that block understanding
- Which specific resource type (when multiple exist)
- Which environment (when behavior differs by environment)
- Scope boundaries (when feature could mean multiple things)
- Priority/urgency (when not stated and affects approach)
- Implementation approach (when multiple valid approaches exist with different trade-offs)

## Question Examples

### Good Question (Bug with conditional behavior)
> El componente tiene lógica diferente según tipo de recurso y ambiente.
> Para acotar el análisis necesito saber con qué combinación estás probando.
>
> - GCP + prod: ruta de producción
> - Azure + npd: ruta de testing
>
> ¿Con qué recurso y ambiente te está fallando?

### Good Question (Ambiguous feature)
> La funcionalidad puede implementarse de dos formas:
>
> - Quick fix (5 min, 1 archivo): agrega el campo solo en el formulario
> - Clean approach (20 min, mejora estructura): agrega el campo en todo el flujo
>
> ¿Cuál preferís?

### Bad Question (Too broad)
> ¿Podrías darme más detalles sobre el recurso, ambiente, versión, navegador,
> y si probaste otras cosas?

## Clarification Protocol

If the prompt is too vague or missing critical information:
1. List the specific clarifications needed
2. Provide examples of what information would help
3. Do NOT proceed with enhancement until clarifications are resolved
4. If the fix reveals a bigger structural issue, present it as a decision point:
   - Quick fix first (minimal change)
   - Structural improvement as an option (with impact)

## Integration with Delivery Agent

This skill is **Phase 1** of the Delivery Agent workflow:

```
Raw Prompt → canonical-prompter → Structured Analysis → context-reductor → Scope + Complexity + Hot Spots → Resolution
```

The output of this skill feeds directly into:
- **context-reductor** (if clarification not needed)
- **User** (if clarification needed, wait for response)

## Notes

- The dictionary (`humano.md`) enhances analysis but is NOT required
- If no dictionary exists, use project.md structure and general heuristics
- Simple inferences save time; complex ambiguities save accuracy by asking
- Questions are a safety valve - use them, don't guess
- Always preserve the original prompt verbatim
- If the dictionary doesn't cover a term, flag it but don't block analysis
- Acceptance criteria should be testable and specific
- Edge cases should be practical, not theoretical
