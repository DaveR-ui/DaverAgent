# Protocol: Context Reductor

Conventions for identifying scope, evaluating complexity, and surfacing risks after a prompt has been analyzed by the canonical prompter.

## Inputs

1. **Structured analysis** from `canonical-prompter` (prompt type, modules, hints, inferences).
2. **Project context** from `docs/project.md` and relevant `docs/context/*.md`.
3. **Project dictionary** from `humano.md` (for complexity indicators and hot spot patterns).

## Process

### 1. Parse Requirements

Extract from the prompt analysis:

- Prompt type (bug/task/feature-design/update)
- Identified modules
- User hints (parameters, environments, resource types)
- Auto-inferences applied

### 2. Map to Modules

A module is **in scope** if:

- **Direct mention** — the prompt explicitly names it
- **Functional dependency** — it provides needed functionality
- **Data dependency** — it owns data that will be modified
- **UI/UX boundary** — the task affects UI
- **API boundary** — the task affects APIs

### 3. Analyze Inputs and Outputs

For each identified module:

- What data flows in? (inputs)
- What data flows out? (outputs)
- What state is modified?
- What side effects exist?
- Where is the Source of Truth for this data?

### 4. Evaluate Complexity

| Level | Indicators |
|-------|------------|
| **Baja** | Single file change, isolated logic, no dependencies |
| **Media** | Cross-module (2-3 files), known patterns, clear boundaries |
| **Media-Alta** | Conditional branching by environment/type, state changes |
| **Alta** | Multi-environment behavior, external integrations, shared state |
| **Muy Alta** | Data migration, schema changes, breaking changes |

### 5. Detect Hot Spots

A step is a **Hot Spot** if it involves any of these critical decision points:

| Hot Spot Type | Trigger | Action |
|---------------|---------|--------|
| **State Ownership Pivot** | Moving state from legacy to new system | Mandatory user question |
| **Breaking Refactor** | Modifying component >900 lines | Mandatory user question |
| **Ambiguous Data Flow** | Multiple endpoints without documented reconciliation | Mandatory user question |
| **Standard Supremacy Violation** | Plan contradicts established project rules/conventions | Auto-flag as Hot Spot |
| **Compute Guard** | Plan touches >5 files with logic changes | Mandatory user question |
| **Security/Guardrails** | Requires temporary bypass of established rules | Mandatory user question |

For each Hot Spot, produce:

1. **The Decision**: What is the critical choice?
2. **Options**: At least two approaches with risk/benefit.
3. **Risk/Benefit**: Short bullets on compute cost and technical debt.
4. **Mandatory Question**: A direct A/B-style question the user must answer.

### 6. Hidden Assumption Detection

Identify **the one thing the plan takes for granted that, if wrong, breaks everything**. This is not an explicit decision — it's the invisible assumption no one is questioning.

Express it in one sentence:

> "This plan assumes [X]. If [X] is wrong, [consequence]."

### 7. Trace Dependencies

- **Upstream**: What does this work depend on?
- **Downstream**: What depends on this work?

### 8. Define Boundaries

Explicitly state what is IN and OUT of scope. Always define OUT of scope explicitly. Be specific with module names and file paths.

### 9. Define Verification Path

How will success be measured? What tests should pass? What behavior should be observable? What evidence proves the slice is complete?

## Output Template

```markdown
## Scope Definition

### Executive Summary
[One sentence: what will change and why]

### Complexity Assessment
- **Level**: [Baja | Media | Media-Alta | Alta | Muy Alta]
- **Justification**: [Why this level, referencing complexity indicators]

### Hidden Assumption
[The one thing this plan takes for granted that, if wrong, breaks everything. One sentence.]

### Hot Spots

If hot spots detected:

**Hot Spot #1**: [Description]
- **The Decision**: [What is the critical choice?]
- **Options**:
  - A: [Approach A] → [Risk/Benefit]
  - B: [Approach B] → [Risk/Benefit]
- **Mandatory Question**: [Direct question the user must answer]

If no hot spots detected:
- No hot spots identified for this scope.

### In-Scope Modules
| Module | Description | Why In Scope |
|--------|-------------|--------------|
| [Module name] | [What it does] | [Connection to the problem] |

### Out-of-Scope (Explicit Exclusions)
| Module/Area | Why Out of Scope |
|-------------|------------------|
| [Module name] | [Reason for exclusion] |

### Key Files
| File | Purpose | Action Needed |
|------|---------|---------------|
| [path/to/file] | [What it contains] | [read/modify/create] |

### Input/Output Analysis
| Module | Inputs | Outputs | State Changes | Source of Truth |
|--------|--------|--------|---------------|-----------------|
| [module] | [what comes in] | [what goes out] | [what changes] | [where truth lives] |

### Dependencies
- **Upstream**: [Modules this work depends on]
- **Downstream**: [Modules that depend on this work]

### Risk Areas
- [Areas where changes could have unexpected side effects]
- [Legacy code or technical debt to be aware of]
- [Environment-specific behaviors to consider]

### Verification Path
- [How success will be measured]
- [Tests that should pass]
- [Observable behavior that proves completion]

### Complexity Evaluation Summary
**Overall**: [Baja | Media | Media-Alta | Alta | Muy Alta]

**Factors**:
- [Factor 1]: [contribution to complexity]
- [Factor 2]: [contribution to complexity]
- [Factor 3]: [contribution to complexity]

**Recommendation**: [Proceed with caution | Standard approach | Quick fix viable | Needs architecture review]
```

## Decision Rules

- **No Validation, No Execution**: For Alta/Muy Alta complexity, the plan MUST be validated by the user before any implementation begins.
- **Standard Supremacy**: If the proposed scope contradicts established project rules or conventions, flag it as a Hot Spot automatically.
- **Compute Guard**: If the plan involves changing more than 5 files, it is a Hot Spot by default.
- **Hidden Assumption is Mandatory**: Every scope definition must include the hidden assumption, even if confidence is high.

## Integration

Phase 2 of the Delivery Agent workflow:

```
Raw Prompt → canonical-prompter → Structured Analysis → context-reductor → Scope + Complexity + Hot Spots + Hidden Assumption → Resolution
```

The output provides the Delivery Agent with:

- **Complexity level** → determines which subagent/model to use
- **Hot spots** → triggers mandatory user questions before dispatch
- **Hidden assumption** → surfaces invisible risk
- **Scope definition** → boundaries for the implementation
- **Key files** → specific files to read/modify
- **Verification path** → how the reviewer will validate success

## Notes

- If the dictionary is incomplete, use general complexity heuristics but flag the gap.
- Complexity evaluation should be honest — overestimating is better than underestimating.
- Hot spots are cumulative — if multiple hot spots are involved, bump complexity level.
- The hidden assumption is the most important thing you surface — it's what nobody is thinking about.
