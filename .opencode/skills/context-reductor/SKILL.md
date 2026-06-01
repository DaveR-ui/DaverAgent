---
name: context-reductor
description: Analyzes prompts and project structure to identify relevant modules, evaluate complexity, detect hot spots, and define scope boundaries. Returns complexity level, hot spot notes, and complexity evaluation. Use after prompt analysis to define work boundaries.
license: MIT
metadata:
  category: iniciacion
  workflow: scope-definition
  phase: 2
---

## What I Do

- **Identify relevant modules** that are in scope for the given prompt
- **Analyze inputs and outputs** to understand data flow and dependencies
- **Evaluate complexity** using complexity indicators from the project dictionary
- **Detect hot spots** - known problematic areas from the project dictionary
- **Define boundaries** between what is IN scope and what is OUT of scope
- **List key files** that will need to be read or modified
- **Return complexity assessment** with level, hot spot notes, and evaluation

## When to Use Me

Use this skill when:
- A prompt has been analyzed by `prompt-analyzer` and needs scope definition
- You need to know which modules/files are relevant to a task
- You need to establish clear boundaries before starting development
- You need to assess the complexity of the problem
- You want to identify potential risk areas (hot spots)

## Input Requirements

1. **Structured analysis** from `prompt-analyzer` (prompt type, modules, hints)
2. **Project context** from `.opencode/project.md`
3. **Project dictionary** from `.opencode/project-dictionary.md` (for complexity indicators and hot spot patterns)

## Scope Analysis Process

### Step 1: Load Context
Read:
- `.opencode/project.md` for project structure
- `.opencode/project-dictionary.md` for complexity indicators and hot spot patterns
- Prompt analysis output from `prompt-analyzer`

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

### Step 5: Evaluate Complexity
Apply **Complexity Indicators** from the project dictionary:

| Level | Indicators |
|-------|------------|
| **Baja** | Single file change, isolated logic, no dependencies |
| **Media** | Cross-module (2-3 files), known patterns, clear boundaries |
| **Media-Alta** | Conditional branching by environment/type, state changes |
| **Alta** | Multi-environment behavior, external integrations, shared state |
| **Muy Alta** | Data migration, schema changes, breaking changes |

### Step 6: Detect Hot Spots
Check identified modules against **Hot Spot Patterns** from the dictionary:
- Is this a known problematic area?
- What are the specific risks?
- What should the developer watch out for?

### Step 7: Trace Dependencies
- **Upstream**: What does this work depend on?
- **Downstream**: What depends on this work?

### Step 8: Define Boundaries
Explicitly state what is IN and OUT of scope:
- Always define OUT of scope explicitly
- Be specific with module names and file paths
- Avoid vague descriptions

## Output Template

```markdown
## Scope Definition

### Problem Summary
[Brief summary of what needs to be solved]

### Complexity Assessment
- **Level**: [Baja | Media | Media-Alta | Alta | Muy Alta]
- **Justification**: [Why this level, referencing complexity indicators]

### Hot Spots
| Hot Spot | Location | Risk Level | Notes |
|----------|----------|------------|-------|
| [pattern] | [file/module] | [Alto/Medio/Bajo] | [What to watch for] |

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
| Module | Inputs | Outputs | State Changes |
|--------|--------|---------|---------------|
| [module] | [what comes in] | [what goes out] | [what changes] |

### Dependencies
- **Upstream**: [Modules this work depends on]
- **Downstream**: [Modules that depend on this work]

### Risk Areas
- [Areas where changes could have unexpected side effects]
- [Legacy code or technical debt to be aware of]
- [Environment-specific behaviors to consider]

### Assumptions
- [Any assumptions made during scope definition]

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

## Integration with SDD Agent

This skill is **Phase 2** of the SDD Agent workflow:

```
Raw Prompt → prompt-analyzer → Structured Analysis → context-reductor → Scope + Complexity → Resolution
```

The output of this skill provides the SDD Agent with:
- **Complexity level** → determines which subagent/model to use
- **Hot spots** → warns the coder about risky areas
- **Scope definition** → boundaries for the implementation
- **Key files** → specific files to read/modify

## Notes

- The project dictionary's complexity indicators and hot spot patterns are the reference
- If the dictionary is incomplete, use general complexity heuristics but flag the gap
- Complexity evaluation should be honest - overestimating is better than underestimating
- Hot spots are cumulative - if multiple hot spots are involved, bump complexity level
