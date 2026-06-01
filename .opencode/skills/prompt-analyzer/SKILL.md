---
name: prompt-analyzer
description: Analyzes raw prompts using project dictionary for domain inference, classifies prompt type, identifies modules, extracts hints, and formulates clarifying questions following strict rules. Use as the first analysis step before scope definition.
license: MIT
metadata:
  category: iniciacion
  workflow: prompt-analysis
  phase: 1
---

## What I Do

- **Load project dictionary** from `.opencode/project-dictionary.md` to understand domain terms
- **Infer simple context** automatically using dictionary keyword mapping and inference rules
- **Classify prompts** into: `bug`, `task`, `feature-design`, `update`
- **Identify target module(s)** based on keyword-to-module mapping
- **Extract user hints** - clear signals the user provided about the problem
- **Formulate clarifying questions** when needed, following strict question rules
- **Output structured analysis** ready for the next phase (context reduction)

## When to Use Me

Use this skill when:
- A raw prompt arrives and needs domain-aware analysis
- The prompt contains jargon, abbreviations, or project-specific terms
- You need to classify and understand the problem before scoping
- Clarification is needed but must follow structured question rules

## Input Requirements

1. **Raw prompt** from the user
2. **Project context** from `.opencode/project.md`
3. **Project dictionary** from `.opencode/project-dictionary.md`

## Analysis Process

### Step 1: Load Dictionary
Read `.opencode/project-dictionary.md` and load:
- Domain glossary (term definitions)
- Keyword mapping (user words → modules)
- Inference rules (simple auto-resolve vs. consult)
- Question rules (how to formulate questions)

### Step 2: Term Resolution
For each significant term in the prompt:
1. Check if it exists in the **Domain Glossary** → resolve meaning
2. Check if it exists in the **Keyword Mapping** → identify module
3. If not found → flag as "unknown term" (may need clarification)

### Step 3: Auto-Inference (Simple)
Apply **Simple Inference Rules** from the dictionary:
- If rule matches → apply inference automatically
- Do NOT ask the user about things covered by simple rules
- Example: user says "railway" → infer deploy platform = Railway.app

### Step 4: Classification
Determine prompt type:

| Type | Trigger | Keywords |
|------|---------|----------|
| `bug` | Something broken | error, crash, falla, no anda, roto, broken, issue |
| `task` | Specific work to do | agregar, poner, cambiar, mover, limpiar, migrate |
| `feature-design` | New capability | nuevo, crear, diseñar, implementar, feature |
| `update` | Modify existing | mejorar, optimizar, ajustar, upgrade, refactor |

### Step 5: Module Identification
Map prompt terms to modules using **Keyword Mapping**:
- Direct keyword match → module identified
- Multiple keywords → multiple modules
- No match → flag for clarification

### Step 6: Hint Extraction
Extract explicit hints from the user:
- What parameters did they mention?
- What environment/context did they specify?
- What behavior did they observe?
- What did they already try?

### Step 7: Clarification Decision
Determine if clarification is needed:

**DO NOT ask if:**
- All terms resolved via dictionary
- Inference rules cover the ambiguity
- The prompt is clear and actionable

**ASK if:**
- Unknown terms that block understanding
- Multiple valid interpretations exist
- Bug with conditional behavior (need resource type + environment)
- Feature scope is ambiguous (which environments?)

### Step 8: Question Formulation (if needed)
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
- Deploy platform from known keywords
- Module from keyword mapping
- Prompt type from clear keywords
- Environment when explicitly stated

### What to Ask About
- Terms not in dictionary that block understanding
- Which specific resource type (when multiple exist)
- Which environment (when behavior differs by environment)
- Scope boundaries (when feature could mean multiple things)
- Priority/urgency (when not stated and affects approach)

## Question Examples

### Good Question (Bug with conditional behavior)
> El modal de edición tiene lógica diferente según tipo de recurso y ambiente.
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

## Integration with SDD Agent

This skill is **Phase 1** of the SDD Agent workflow:

```
Raw Prompt → prompt-analyzer → Structured Analysis → context-reductor → Scope → Resolution
```

The output of this skill feeds directly into:
- **context-reductor** (if clarification not needed)
- **User** (if clarification needed, wait for response)

## Notes

- The dictionary (`.opencode/project-dictionary.md`) is the source of truth for domain terms
- Simple inferences save time; complex ambiguities save accuracy by asking
- Questions are a safety valve - use them, don't guess
- Always preserve the original prompt verbatim
- If the dictionary doesn't cover a term, flag it but don't block analysis
