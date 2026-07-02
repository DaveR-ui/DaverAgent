# Protocol: Canonical Prompter

Conventions for analyzing a raw prompt before scope definition. Operates on a raw prompt + project context + human vocabulary and produces a structured analysis.

## Inputs

1. **Raw prompt** from the user (verbatim).
2. **Project context** from the project entry point and relevant context docs (see `.opencode/conventions.md`).
3. **Human context** from `humano.md` (vocabulary, communication preferences).

## Process

### 1. Term Resolution

For each significant term:

1. Check the **Translation Dictionary** in `humano.md` → resolve meaning.
2. If not found → infer from the project entry point architecture and module names (see `.opencode/conventions.md`).
3. Use general development terminology.
4. Flag ambiguous terms for potential clarification.

### 2. Auto-Inference

Apply heuristics:

- "no anda" / "rompió" / "falla" / "error" / "crash" → likely `bug`
- "agregar" / "poner" / "crear" / "add" / "create" → likely `task` or `feature-design`
- "mejorar" / "optimizar" / "mejor" / "improve" / "optimize" → likely `update`
- "modal" / "form" / "page" / "component" → frontend context
- "endpoint" / "route" / "api" / "handler" → backend context

### 3. Classification

| Type | Trigger | Keywords |
|------|---------|----------|
| `bug` | Something broken | error, crash, falla, no anda, roto, broken, issue, fix, not working |
| `task` | Specific work to do | agregar, poner, cambiar, mover, limpiar, migrate, add, remove, change |
| `feature-design` | New capability | nuevo, crear, diseñar, implementar, feature, new, create, design, build |
| `update` | Modify existing | mejorar, optimizar, ajustar, upgrade, refactor, improve, enhance, adjust |

Assign **confidence level**: high (clear keywords + context), medium (some ambiguity), low (multiple valid interpretations).

### 4. Module Identification

Map prompt terms to modules using the project entry point (see `.opencode/conventions.md`) + contextual analysis.

| Module | Confidence | Evidence |
|--------|------------|----------|
| [module] | [high/med/low] | [what in the prompt points here] |

### 5. Hint Extraction

Pull explicit hints from the user: parameters, environment, behavior observed, things already tried.

### 6. Acceptance Criteria

Generate testable criteria (checklist). What must work after this is done? What behavior should be observable? What should NOT break?

### 7. Edge Cases

Identify boundary conditions, error scenarios, unusual inputs, concurrent operations, environment-specific behaviors.

### 8. Clarification Decision

**Do NOT ask if:**

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

### 9. Question Formulation (when needed)

Rules:

1. **Concise**: Max 2-3 sentences.
2. **Declare the problem**: State what you need to know and why.
3. **One decision per question**.
4. **Show impact**: Options with practical consequences.
5. **Minimal change first**: Least invasive option goes first.

**Good example (bug with conditional behavior):**

> El componente tiene lógica diferente según tipo de recurso y ambiente.
> Para acotar el análisis necesito saber con qué combinación estás probando.
>
> - GCP + prod: ruta de producción
> - Azure + npd: ruta de testing
>
> ¿Con qué recurso y ambiente te está fallando?

**Good example (ambiguous feature):**

> La funcionalidad puede implementarse de dos formas:
>
> - Quick fix (5 min, 1 archivo): agrega el campo solo en el formulario
> - Clean approach (20 min, mejora estructura): agrega el campo en todo el flujo
>
> ¿Cuál preferís?

**Bad example (too broad):**

> ¿Podrías darme más detalles sobre el recurso, ambiente, versión, navegador, y si probaste otras cosas?

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

### Infer automatically

- Domain terms in the dictionary
- Module from keyword mapping or project structure
- Prompt type from clear keywords
- Environment when explicitly stated
- Frontend/backend context from terminology

### Ask about

- Terms not in dictionary that block understanding
- Which specific resource type (when multiple exist)
- Which environment (when behavior differs)
- Scope boundaries (when feature could mean multiple things)
- Priority/urgency (when not stated)
- Implementation approach (when multiple valid approaches with different trade-offs)

## Integration

Phase 1 of the Delivery Agent workflow:

```
Raw Prompt → canonical-prompter → Structured Analysis → context-reductor → Scope + Complexity + Hot Spots → Resolution
```

The output feeds into:

- **context-reductor** if clarification is not needed
- **User** if clarification is needed (wait for response)

## Notes

- The dictionary (`humano.md`) enhances analysis but is NOT required.
- If no dictionary exists, use the project entry point structure and general heuristics (see `.opencode/conventions.md`).
- Simple inferences save time; complex ambiguities save accuracy by asking.
- Questions are a safety valve — use them, don't guess.
- Always preserve the original prompt verbatim.
- If the dictionary doesn't cover a term, flag it but don't block analysis.
- Acceptance criteria should be testable and specific.
- Edge cases should be practical, not theoretical.
