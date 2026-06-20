---
name: context-reductor
description: Analyzes prompts and project structure to identify relevant modules, evaluate complexity, detect hot spots, find hidden assumptions, and define scope boundaries. Returns complexity level, hot spots with mandatory questions, hidden assumption, and verification path. Use after prompt analysis to define work boundaries.
license: MIT
metadata:
  audience: developers
  workflow: scope-definition
  phase: 2
---

## What I Do

- **Identify relevant modules** that are in scope for the given prompt
- **Analyze inputs and outputs** to understand data flow and dependencies
- **Evaluate complexity** using complexity indicators
- **Detect hot spots** - critical decision points that require user validation before execution
- **Detect hidden assumptions** - the one thing the plan takes for granted that, if wrong, breaks everything
- **Check standard supremacy** - flag if proposed changes contradict established project rules
- **Define boundaries** between what is IN scope and what is OUT of scope
- **List key files** that will need to be read or modified
- **Define verification path** - how success will be measured
- **Return complexity assessment** with level, hot spots, hidden assumption, and recommendation

## When to Use Me

Use this skill when:
- A prompt has been analyzed by `canonical-prompter` and needs scope definition
- You need to know which modules/files are relevant to a task
- You need to establish clear boundaries before starting development
- You need to assess the complexity of the problem
- You need to identify decision points that require user validation
- You want to surface invisible assumptions before they cause problems

## Input Requirements

1. **Structured analysis** from `canonical-prompter` (prompt type, modules, hints)
2. **Project context** from `docs/project.md` (entry point) and relevant `docs/context/*.md` files
3. **Project dictionary** from `humano.md` (for complexity indicators and hot spot patterns)

## Scope Analysis Process

### Step 1: Load Context
Read:
- `docs/project.md` for project structure
- Prompt analysis output from `canonical-prompter`

### Step 2: Parse Requirements
Extract from the prompt analysis:
- Prompt type (bug/task/feature-design/update)
- Identified modules
- User hints (parameters, environments, resource types)
- Auto-inferences applied

### Step 3: Map to Modules
Identify which project modules correspond to the requirements:
- **Direct mention**: If the prompt explicitly mentions a module → in scope
- **Functional dependency**: If a module provides needed functionality → in scope
- **Data dependency**: If a module owns data that will be modified → in scope
- **UI/UX boundary**: If the task affects UI → include relevant UI modules
- **API boundary**: If the task affects APIs → include endpoint and handler modules

### Step 4: Analyze Inputs and Outputs
For each identified module:
- What data flows in? (inputs)
- What data flows out? (outputs)
- What state is modified?
- What side effects exist?
- Where is the Source of Truth for this data?

### Step 5: Evaluate Complexity
Apply **Complexity Indicators**:

| Level | Indicators |
|-------|------------|
| **Baja** | Single file change, isolated logic, no dependencies |
| **Media** | Cross-module (2-3 files), known patterns, clear boundaries |
| **Media-Alta** | Conditional branching by environment/type, state changes |
| **Alta** | Multi-environment behavior, external integrations, shared state |
| **Muy Alta** | Data migration, schema changes, breaking changes |

### Step 6: Detect Hot Spots
A step is a **Hot Spot** if it involves any of these critical decision points:

| Hot Spot Type | Trigger | Action |
|---------------|---------|--------|
| **State Ownership Pivot** | Moving state from legacy to new system | Mandatory user question |
| **Breaking Refactor** | Modifying component >900 lines | Mandatory user question |
| **Ambiguous Data Flow** | Multiple endpoints without documented reconciliation | Mandatory user question |
| **Standard Supremacy Violation** | Plan contradicts established project rules/conventions | Auto-flag as Hot Spot |
| **Compute Guard** | Plan touches >5 files with logic changes | Mandatory user question |
| **Security/Guardrails** | Requires temporary bypass of established rules | Mandatory user question |

For each Hot Spot, you MUST produce:
1. **The Decision**: What is the critical choice?
2. **Options**: At least two approaches with risk/benefit
3. **Risk/Benefit**: Short bullets on compute cost and technical debt
4. **Mandatory Question**: A direct A/B-style question the user must answer

### Step 7: Hidden Assumption Detection
Before presenting the plan, identify **the one thing the plan takes for granted that, if wrong, breaks everything**. This is not an explicit decision — it's the invisible assumption no one is questioning.

Express it in one sentence:
> "This plan assumes [X]. If [X] is wrong, [consequence]."

### Step 8: Trace Dependencies
- **Upstream**: What does this work depend on?
- **Downstream**: What depends on this work?

### Step 9: Define Boundaries
Explicitly state what is IN and OUT of scope:
- Always define OUT of scope explicitly
- Be specific with module names and file paths
- Avoid vague descriptions

### Step 10: Define Verification Path
How will success be measured?
- What tests should pass?
- What behavior should be observable?
- What evidence proves the slice is complete?

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

**Hot Spot #2**: [Description]
...

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
|--------|--------|---------|---------------|-----------------|
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

## Module Identification Rules

1. **Direct mention**: If the prompt explicitly mentions a module or feature, it's in scope
2. **Functional dependency**: If a module provides functionality needed by the task, it's in scope
3. **Data dependency**: If a module owns data that will be modified, it's in scope
4. **UI/UX boundary**: If the task affects user interface, include the relevant UI modules
5. **API boundary**: If the task affects APIs, include the relevant endpoint and handler modules

## Complexity Evaluation Rules

### Baja (Low)
- Single file modification
- No cross-module dependencies
- Well-tested area
- No environment-specific logic

### Media (Medium)
- 2-3 files across related modules
- Known patterns, clear boundaries
- May involve simple conditional logic
- Standard CRUD operations

### Media-Alta (Medium-High)
- Conditional branching by environment or resource type
- State management changes
- Multiple user flows affected
- Requires testing across scenarios

### Alta (High)
- Multi-environment behavior differences
- External API integrations
- Shared state or global changes
- Performance-sensitive areas
- Security-impacting changes

### Muy Alta (Very High)
- Database schema changes
- Data migration required
- Breaking API changes
- Architecture-level modifications
- Cross-cutting concerns (auth, logging, etc.)

## Decision Rules

- **No Validation, No Execution**: For Alta/Muy Alta complexity, the plan MUST be validated by the user before any implementation begins
- **Standard Supremacy**: If the proposed scope contradicts established project rules or conventions, flag it as a Hot Spot automatically
- **Compute Guard**: If the plan involves changing more than 5 files, it is a Hot Spot by default
- **Hidden Assumption is Mandatory**: Every scope definition must include the hidden assumption, even if confidence is high

## Boundary Definition Guidelines

### Always define OUT of scope:
- Features or modules not affected by the change
- Future improvements that could be confused with current work
- Related but separate concerns
- Environments not mentioned (if behavior is environment-specific)

### Be specific:
- Use actual module names from the project
- Reference actual file paths when possible
- Avoid vague descriptions like "other stuff"

## Integration with Delivery Agent

This skill is **Phase 2** of the Delivery Agent workflow:

```
Raw Prompt → canonical-prompter → Structured Analysis → context-reductor → Scope + Complexity + Hot Spots + Hidden Assumption → Resolution
```

The output of this skill provides the Delivery Agent with:
- **Complexity level** → determines which subagent/model to use
- **Hot spots** → triggers mandatory user questions before dispatch
- **Hidden assumption** → surfaces invisible risk
- **Scope definition** → boundaries for the implementation
- **Key files** → specific files to read/modify
- **Verification path** → how the reviewer will validate success

## Notes

- If the dictionary is incomplete, use general complexity heuristics but flag the gap
- Complexity evaluation should be honest - overestimating is better than underestimating
- Hot spots are cumulative - if multiple hot spots are involved, bump complexity level
- The hidden assumption is the most important thing you surface - it's what nobody is thinking about
