# SDD Agent - Structured Development Driver

## Overview

The **SDD Agent** (Structured Development Driver) is an orchestrator agent that coordinates the supply chain for prompt execution in OpenCode. It receives raw user prompts, analyzes them with domain-specific knowledge, evaluates complexity, defines work boundaries, and dispatches to specialized subagents for resolution.

Unlike agents that jump directly into coding, the SDD Agent ensures that every problem is fully understood, properly scoped, and appropriately matched to the right specialist before any code is written.

---

## The Problem It Solves

When users describe problems or request features, they often:

- Use domain-specific jargon or abbreviations
- Provide incomplete context (missing environment, resource type, etc.)
- Don't realize their request has different complexity levels
- Expect the agent to "just know" what they mean

Without proper analysis, agents make assumptions, work on the wrong scope, or produce solutions that don't fit the actual problem. The SDD Agent eliminates this by creating a structured pipeline between the user's intent and the implementation.

---

## Architecture

### The Supply Chain Metaphor

```
Raw Material          Processing              Packaging              Delivery
(User Prompt)    →    (Analysis)         →    (Brief Assembly)   →   (Dispatch)
```

Each phase transforms the input, reducing uncertainty and adding structure:

| Phase | Input | Output | Purpose |
|-------|-------|--------|---------|
| **0. Context Loading** | Project files | Domain knowledge | Load technical structure and domain dictionary |
| **1. Prompt Analysis** | Raw prompt + dictionary | Structured analysis | Understand what's being asked with domain context |
| **2. Context Reduction** | Analysis + project structure | Scope + complexity | Define boundaries, assess difficulty, flag risks |
| **3. Brief Assembly** | All outputs | Development brief | Package everything for the specialist |
| **4. Dispatch** | Brief + routing table | Subagent execution | Send to the right specialist with full context |

---

## Phase Details

### Phase 0: Context Loading

The SDD Agent loads two critical files:

- **`project.md`** - Technical structure: languages, architecture, commands, conventions
- **`project-dictionary.md`** - Domain context: term definitions, keyword mappings, inference rules, complexity indicators, hot spot patterns

This dual-context approach means the agent understands both *how the project is built* and *what the project does*.

### Phase 1: Prompt Analysis

Using the `prompt-analyzer` skill, the agent:

1. **Resolves terms** - Looks up every significant term in the project dictionary
2. **Auto-infers** - Applies simple inference rules automatically (e.g., "railway" → Railway.app deploy)
3. **Classifies** - Determines if it's a bug, task, feature design, or update
4. **Identifies modules** - Maps keywords to project modules
5. **Extracts hints** - Captures explicit information the user provided
6. **Decides on clarification** - Determines if questions are needed

**Key principle**: Infer simple things automatically. Ask about complex ambiguities. Questions follow strict rules - concise, problem-declaring, impact-showing.

### Phase 2: Context Reduction & Complexity Evaluation

Using the `context-reductor` skill, the agent:

1. **Maps modules** - Identifies exactly which modules are in and out of scope
2. **Analyzes I/O** - Understands data flow through affected modules
3. **Evaluates complexity** - Rates from Baja to Muy Alta using defined indicators
4. **Detects hot spots** - Flags known problematic areas from the dictionary
5. **Defines boundaries** - Explicit in-scope and out-of-scope declarations
6. **Assesses risk** - Identifies where things could go wrong

The complexity level directly influences which subagent and model are selected.

### Phase 3: Development Brief Assembly

All analysis is compiled into a structured brief containing:

- Original prompt (preserved verbatim)
- Prompt analysis results (type, resolved terms, hints, inferences)
- Complexity assessment (level, justification, hot spots, recommendation)
- Scope definition (in-scope, out-of-scope, key files)
- Risk areas
- Resolution plan

### Phase 4: Subagent Dispatch

The SDD Agent consults the model routing table to select the right specialist:

| Prompt Type | Subagent | Model Strategy |
|-------------|----------|----------------|
| Bug | Coder | Standard model |
| Task | Coder | Standard model |
| Feature Design | Architect → Coder | Design first, then implement |
| Update | Coder or Reviewer | Depends on scope |

Higher complexity problems may trigger multi-stage dispatch (architect for design, coder for implementation, reviewer for validation).

---

## Key Components

### Project Dictionary

The `project-dictionary.md` is the brain of the domain understanding system. It contains:

- **Domain Glossary** - Definitions of project-specific terms, jargon, and abbreviations
- **Keyword Mapping** - Maps user words to project modules
- **Inference Rules** - What to auto-resolve vs. what to ask about
- **Question Rules** - How to formulate clarifying questions (concise, impact-focused)
- **Complexity Indicators** - Criteria for rating problem difficulty
- **Hot Spot Patterns** - Known problematic areas to watch

This file is living documentation - it grows as the project evolves.

### Prompt Analyzer Skill

The `prompt-analyzer` skill is the first processing stage. It:

- Reads the dictionary before analyzing any prompt
- Resolves terms automatically when possible
- Classifies prompts into four types
- Formulates questions following strict rules when clarification is needed
- Outputs structured analysis ready for the next phase

### Context Reductor Skill

The `context-reductor` skill is the scoping engine. It:

- Identifies relevant modules and files
- Evaluates complexity using defined indicators
- Detects hot spots from the dictionary
- Defines explicit boundaries (in vs. out)
- Returns a complete scope definition with risk assessment

---

## Design Principles

### 1. Never Infer User Intent on Complex Matters

Simple inferences save time (dictionary lookups, keyword mappings). Complex ambiguities require questions. The line is clear: if the dictionary covers it, infer. If not, ask.

### 2. Questions Are a Safety Valve

Questions follow strict rules:
- **Concise**: Max 2-3 sentences
- **Declare the problem**: State what you need and why
- **One decision per question**: Don't combine decisions
- **Show impact**: Present options with practical consequences
- **Minimal change first**: Least invasive option always goes first

### 3. Scope Must Be Explicit

Every development brief defines what is IN scope and what is OUT of scope. No vague boundaries. No "and related stuff." Specific modules, specific files, specific exclusions.

### 4. Hot Spots Are Warnings, Not Blockers

Known problematic areas are flagged so the subagent knows where to be careful. They don't prevent work - they inform it.

### 5. Complexity Drives Resource Selection

A baja complexity bug gets a quick coder dispatch. A muy alta complexity feature design gets architect → coder → reviewer pipeline. The complexity level determines the investment.

### 6. Preserve the Original Prompt

Every output includes the exact original prompt verbatim. This ensures traceability and prevents the analysis from losing the user's original intent.

---

## File Structure

```
.opencode/
├── project.md                    # Technical project structure
├── project-dictionary.md         # Domain terms, inference rules, hot spots
├── model-routing.md              # Subagent model selection
├── agents/
│   ├── sddagent.md               # SDD Agent definition
│   └── subagents/                # Specialist subagents
│       ├── coder.md
│       ├── architect.md
│       ├── reviewer.md
│       ├── tester.md
│       ├── documenter.md
│       ├── explorer.md
│       └── opencode-expert.md
└── skills/
    ├── prompt-analyzer/
    │   └── SKILL.md              # Phase 1: Prompt analysis
    └── context-reductor/
        └── SKILL.md              # Phase 2: Scope & complexity
```

---

## Usage Flow

1. **User sends a prompt** - "El modal de edición de recursos GCP en prod no guarda los cambios"
2. **SDD Agent loads context** - Reads project.md and project-dictionary.md
3. **Prompt analysis** - Resolves "modal", "GCP", "prod", "recursos". Classifies as `bug`. Identifies frontend modal module and GCP resource module.
4. **Context reduction** - Evaluates complexity (Media-Alta: conditional by environment + resource type). Detects hot spot (environment-specific logic). Defines scope.
5. **Brief assembly** - Packages everything into a structured brief.
6. **Dispatch** - Sends to coder subagent with full context, hot spot warnings, and scope boundaries.
7. **Resolution** - Coder implements the fix with full understanding of the problem.

---

## Benefits

- **Reduced rework** - Problems are understood before code is written
- **Better scoping** - Explicit boundaries prevent scope creep
- **Appropriate resource allocation** - Complexity drives model/subagent selection
- **Domain awareness** - Dictionary-driven inference means the agent "speaks the project's language"
- **Traceable decisions** - Original prompts preserved, analysis documented
- **Risk mitigation** - Hot spots flagged before work begins
- **User respect** - Questions are concise and impact-focused, not interrogations

---

## Extending the SDD Agent

The SDD Agent is designed to grow:

- **Add more phases** - Testing, deployment, documentation phases can be added
- **Expand the dictionary** - New terms, rules, and hot spots as the project evolves
- **New skills** - Additional analysis skills for specific domains
- **Custom routing** - Project-specific subagent selection rules
- **Metrics** - Track complexity accuracy, resolution time, rework rate

The supply chain metaphor means each phase is a modular component that can be enhanced independently.
