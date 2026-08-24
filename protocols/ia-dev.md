# Protocol: IA Dev

Guidelines for designing and managing autonomous agents in the opencode runtime: triggering conditions, system-prompt structure, file layout, and the canonical subagent spec. The reference material in `references/p3-ia-dev/` documents the full Claude-Code-derived patterns that informed the opencode subagent shape.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-dev`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

When creating, reviewing, or refactoring a subagent under `.opencode/agents/subagents/`, or when designing a per-specialization template. The canonical shape authority is [subagent-spec-template.md](./subagent-spec-template.md); this protocol is the more detailed authoring guide that sits underneath it.

## Overview

Agents are autonomous subprocesses that handle complex, multi-step tasks independently. Understanding agent structure, triggering conditions, and system-prompt design enables creating powerful autonomous capabilities.

**Key concepts:**

- Agents are for autonomous work; commands are for user-initiated actions.
- Markdown file format with YAML frontmatter.
- Triggering via `description` field with examples.
- System prompt defines agent behavior.
- Model and color customization.

## Mandatory startup step (delivery turn)

The delivery turn begins by applying the [interpreter subagent](../agents/subagents/interpreter.md) as Step 0 of [prompt-pipeline.md](./prompt-pipeline.md); other subagents inherit routing via the delivery/orchestrator handoff and do not invoke the interpreter directly.

Newly created subagents must still run the startup check against their handoff:

- The problem is explicit.
- Constraints are explicit.
- The source of truth is identified.
- Verification criteria are explicit.

If any of those are unclear and would affect architecture, endpoint choice, or state ownership, the subagent should surface the ambiguity immediately instead of compensating with broader implementation.

## Subagent file structure

### Complete format

```markdown
---
name: agent-identifier
description: Use this agent when [triggering conditions]. Examples:

<example>
Context: [Situation description]
user: "[User request]"
assistant: "[How assistant should respond and use this agent]"
<commentary>
[Why this agent should be triggered]
</commentary>
</example>

<example>
[Additional example...]
</example>

model: <model-id>
color: <color-name>
tools: ["Read", "Write", "Grep"]
---

You are [agent role description]...

**Your Core Responsibilities:**
1. [Responsibility 1]
2. [Responsibility 2]

**Analysis Process:**
[Step-by-step workflow]

**Output Format:**
[What to return]
```

The structural / variable split, the frontmatter spec, and the `output_schema` ↔ sibling schema bridge are defined authoritatively in [subagent-spec-template.md](./subagent-spec-template.md). The patterns below are the deeper authoring reference, useful when designing new specializations.

## Frontmatter fields

### name (required)

Subagent identifier used for namespacing and invocation.

- **Format**: lowercase, numbers, hyphens only.
- **Length**: 3-50 characters.
- **Pattern**: must start and end with alphanumeric.

**Good examples:** `code-reviewer`, `test-generator`, `api-docs-writer`, `security-analyzer`.

**Bad examples:** `helper` (too generic), `-agent-` (starts/ends with hyphen), `my_agent` (underscores not allowed), `ag` (too short, < 3 chars).

### description (required)

Defines when the host assistant should trigger this subagent. **This is the most critical field.**

**Must include:**

1. Triggering conditions ("Use this agent when...").
2. Multiple `<example>` blocks showing usage.
3. Context, user request, and assistant response in each example.
4. `<commentary>` explaining why the agent triggers.

**Best practices:**

- Include 2-4 concrete examples.
- Show proactive and reactive triggering.
- Cover different phrasings of the same intent.
- Explain reasoning in commentary.
- Be specific about when NOT to use the agent.

### model (optional)

Which model the subagent should use. Match the model to the task type:

- **Strong general reasoning** (orchestration, architecture, high-stakes review) — use a top-tier reasoning model.
- **Coding work** (implementation, code-heavy review, refactoring) — use a code-specialized model.
- **Cheap fast read-only** (lookup, documentation discovery) — use a fast low-cost model.

> **Default**: omission is valid — the subagent inherits the invoking primary agent's model (per opencode docs). Prefer an explicit `model:` override for predictable cost and capability; do not rely on legacy aliases.

### color (required)

Visual identifier for the subagent in the UI. Allowed values: `blue`, `cyan`, `green`, `yellow`, `magenta`, `red`.

**Guidelines:**

- Choose distinct colors for different agents in the same roster.
- Use consistent colors for similar agent types.
- Blue/cyan: analysis, review.
- Green: success-oriented tasks.
- Yellow: caution, validation.
- Red: critical, security.
- Magenta: creative, generation.

### tools (optional)

Restrict the subagent to specific tools (principle of least privilege).

**Format:** array of tool names.

```yaml
tools: ["Read", "Write", "Grep", "Bash"]
```

**Common tool sets:**

- Read-only analysis: `["Read", "Grep", "Glob"]`.
- Code generation: `["Read", "Write", "Grep"]`.
- Testing: `["Read", "Bash", "Grep"]`.
- Full access: omit the field or use `["*"]`.

## System-prompt design

The markdown body becomes the subagent's system prompt. Write in second person, addressing the subagent directly.

### Structure

```markdown
You are [role] specializing in [domain].

**Your Core Responsibilities:**
1. [Primary responsibility]
2. [Secondary responsibility]
3. [Additional responsibilities...]

**Analysis Process:**
1. [Step one]
2. [Step two]
3. [Step three]
[...]

**Quality Standards:**
- [Standard 1]
- [Standard 2]

**Output Format:**
Provide results in this format:
- [What to include]
- [How to structure]

**Edge Cases:**
Handle these situations:
- [Edge case 1]: [How to handle]
- [Edge case 2]: [How to handle]
```

### Best practices

**DO:**

- Write in second person ("You are...", "You will...").
- Be specific about responsibilities.
- Provide a step-by-step process.
- Define output format.
- Include quality standards.
- Address edge cases.
- Keep the system prompt under 10,000 characters.

**DON'T:**

- Write in first person ("I am...", "I will...").
- Be vague or generic.
- Omit process steps.
- Leave output format undefined.
- Skip quality guidance.
- Ignore error cases.

## Creating subagents

### AI-assisted generation

Use the prompt pattern documented in [`references/p3-ia-dev/agent-creation-system-prompt.md`](./references/p3-ia-dev/agent-creation-system-prompt.md). It extracts core intent, designs an expert persona, produces a comprehensive system prompt with boundaries / methodology / edge cases / output format, and returns a JSON shape that can be converted to the agent file format with frontmatter.

### Manual creation

1. Choose an identifier (3-50 chars, lowercase, hyphens).
2. Write `description` with examples.
3. Select a model based on task type.
4. Choose a color for visual identification.
5. Define tools (if restricting access).
6. Write the system prompt following the structure above.
7. Save as `.opencode/agents/subagents/<id>.md`.

## Validation rules

### Identifier validation

- 3-50 characters.
- Lowercase letters, numbers, hyphens only.
- Must start and end with alphanumeric.
- No underscores, spaces, or special characters.

### Description validation

- **Length**: 10-5,000 characters.
- **Must include**: triggering conditions and examples.
- **Best**: 200-1,000 characters with 2-4 examples.

### System-prompt validation

- **Length**: 20-10,000 characters.
- **Best**: 500-3,000 characters.
- **Structure**: clear responsibilities, process, output format.

## Subagent organization

### Agents directory

```
.opencode/
└── agents/
    └── subagents/
        ├── analyzer.md
        ├── reviewer.md
        └── generator.md
```

All `.md` files under `.opencode/agents/subagents/` are discovered automatically by the opencode runtime.

### Namespacing

Subagents are namespaced automatically:

- Single agent: `agent-name`.
- With specialization: `agent-name.specialization`.

## Testing subagents

### Test triggering

Create test scenarios to verify a subagent triggers correctly:

1. Write the subagent with specific triggering examples.
2. Use similar phrasing to the examples in the test.
3. Check that the host assistant loads the subagent.
4. Verify the subagent provides the expected functionality.

### Test system prompt

Ensure the system prompt is complete:

1. Give the subagent a typical task.
2. Check it follows the process steps.
3. Verify the output format is correct.
4. Test the edge cases mentioned in the prompt.
5. Confirm the quality standards are met.

## Quick reference

### Minimal subagent

```markdown
---
name: simple-agent
description: Use this agent when... Examples: <example>...</example>
model: <fast-model>
color: blue
---

You are a subagent that [does X].

Process:
1. [Step 1]
2. [Step 2]

Output: [What to provide]
```

### Frontmatter fields summary

| Field | Required | Format | Example |
|---|---|---|---|
| `name` | Yes | lowercase-hyphens | `code-reviewer` |
| `description` | Yes | Text + examples | `Use when... <example>...` |
| `model` | Yes | model identifier | fast low-cost model id |
| `color` | Yes | color name | `blue` |
| `tools` | No | array of tool names | `["Read", "Grep"]` |

### Best practices

**DO:**

- Include 2-4 concrete examples in `description`.
- Write specific triggering conditions.
- Route models explicitly by task type.
- Choose appropriate tools (least privilege).
- Write clear, structured system prompts.
- Test triggering thoroughly.

**DON'T:**

- Use generic descriptions without examples.
- Omit triggering conditions.
- Give all subagents the same color.
- Grant unnecessary tool access.
- Write vague system prompts.
- Skip testing.

## Additional resources

### Reference files (carried over from `p3-ia-dev`)

- [`references/p3-ia-dev/system-prompt-design.md`](./references/p3-ia-dev/system-prompt-design.md) — complete system-prompt patterns.
- [`references/p3-ia-dev/triggering-examples.md`](./references/p3-ia-dev/triggering-examples.md) — example formats and best practices.
- [`references/p3-ia-dev/agent-creation-system-prompt.md`](./references/p3-ia-dev/agent-creation-system-prompt.md) — the full AI-assisted generation prompt.

> **Note**: these reference files are preserved from the retired skill. The canonical opencode subagent shape is [subagent-spec-template.md](./subagent-spec-template.md); consult the reference files only for design depth.

## Implementation workflow

To create a new subagent:

1. Define the subagent's purpose and triggering conditions.
2. Choose the creation method (AI-assisted or manual).
3. Create `.opencode/agents/subagents/<id>.md`.
4. Write frontmatter with all required fields.
5. Write the system prompt following the best practices above.
6. Include 2-4 triggering examples in `description`.
7. Validate the file structure against [subagent-spec-template.md](./subagent-spec-template.md).
8. Test triggering with real scenarios.
9. Document the subagent in `.opencode/agents/subagents/README.md` (if the project maintains one) or in `docs/project.md` Slices.

## Startup prompt contract

When you write a subagent system prompt, include an explicit startup rule such as:

```markdown
Before doing any substantive work, run prompt analysis on the task.
Confirm the problem statement, constraints, source of truth, and verification path are clear.
If a missing detail would change the implementation approach, stop and surface that ambiguity first.
```

Focus on clear triggering conditions and comprehensive system prompts for autonomous operation.

## Constraints

- **PROHIBITED**: creating a subagent without registering its purpose in `docs/project.md` Slices (or the agent-system roster).
- **PROHIBITED**: giving all subagents the same color or the same model.
- **MANDATORY**: following the canonical shape in [subagent-spec-template.md](./subagent-spec-template.md).
- **MANDATORY**: keeping the system prompt under 10,000 characters.

## Integration

In the opencode runtime, the canonical authoring guide is [subagent-spec-template.md](./subagent-spec-template.md). Use this protocol as the **detailed reference** when designing new specializations, when reviewing an existing subagent for design quality, or when porting an agent from another runtime. The reference files in `references/p3-ia-dev/` are the carried-over design material; the opencode runtime does not require the original Claude-Code color / tools model and you should adapt accordingly.
