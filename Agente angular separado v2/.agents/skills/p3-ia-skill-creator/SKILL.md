---
name: skill-creator
description: Meta-skill used to automatically generate new skills. It creates the folder structure, generates the SKILL.md boilerplate, and handles registration in the SSOT.
license: MIT
compatibility: opencode
metadata:
  last_updated: 2026-04-24
  pillar: p3
  status: active
---

# 🏭 Skill: Skill Creator (Meta-Skill)

## Goal
Automate the expansion of the agent ecosystem. Ensure every new skill follows the mandatory "AI-Optimized" format and is correctly registered.

## 🛡️ Governance Filter (Pre-Creation Check)
Before creating a new skill, the agent MUST perform this validation:
1.  **Deduplication Scan**: Search `.agents/skills/` for existing skills that solve the same problem.
2.  **Granularity Check**: Is the task large enough to justify a skill (>5 steps)? If it's a simple pattern, add it to `patterns-catalog.md` instead.
3.  **Conflict Search**: Does the new skill contradict any rule in `rules.md` or `coding-conventions.md`?
4.  **Governance Question**: "I found [X] existing skill(s). This new skill is different because [Reason]. Should I proceed or update the existing one?"

## Instructions

### 1. Requirements Gathering
Before generating files, ask the user or analyze the prompt for:
*   **Skill Name**: Lowercase-hyphenated with pillar prefix (e.g., `p1-framework-api-validator`).
*   **Pillar Classification**:
    *   `p1-`: Language & Framework Standards.
    *   `p2-`: Project & SafeGuard Standards.
    *   `p3-`: IA Orchestration & Logic.
*   **Trigger**: When exactly should this skill activate?
*   **Domain**: What specific problem does it solve? (e.g., Angular Testing, Security).

### 2. Scaffolding Generation
Create the following directory structure in `.agents/skills/`:
*   `📂 .agents/skills/<skill-name>/`
    *   `📄 SKILL.md`: The core logic and "brain" of the skill.
    *   `📂 references/`: (Optional) For deep technical details > 500 lines.
    *   `📂 scripts/`: (Optional) Reusable bash/python scripts.

### 3. SKILL.md Template Generation
Generate the content using this mandatory structure:
*   **Frontmatter**: Use the OpenCode standard:
    ```yaml
    ---
    name: <skill-name>
    description: <trigger-phrase>
    license: MIT
    compatibility: opencode
    metadata:
      last_updated: YYYY-MM-DD
      pillar: [p1|p2|p3]
      status: active
    ---
    ```
*   **Goal**: Clear "Why" and "What".
*   **Context Reference (MANDATORY)**: A section linking to the authoritative documentation in `.agents/context/`.
*   **Instructions**: Numbered steps for the agent.
*   **Decision Rules**: "If/Then" logic and safety guards.
*   **Output Format**: Explicit definition of what the skill returns.
*   **Constraints**: Prohibitions and mandates.
*   **Examples**: At least one practical example.

### 4. Automated Registration
Immediately after creation, update the following SSOT files:
*   **Action**: Add a new row to `.agents/skills/SKILLS_INDEX.md`.
*   **Format**: `| <skill-name> | <brief-purpose> | <trigger> |`.
*   **Action**: Add a new entry to `AGENTS.md` under the skills list if the skill is user-facing.

## Decision Rules
*   **Reference Guard**: NEVER use `.github/` paths; all internal links must use `.agents/`.
*   **Deduplication**: Check `SKILLS_INDEX.md` first. If a similar skill exists, suggest an update instead of a new creation.
*   **Lean Content**: Keep the generated `SKILL.md` under 10,000 characters to optimize context windows.
*   **Folder-First**: If the skill logic is dense, always create a `references/` subfolder and link it from the main `SKILL.md`.

## Output Format
Return a Creation Report:
*   **Confirmation**: List of folders and files created.
*   **Registration Status**: Confirmation of entry in `SKILLS_INDEX.md`.
*   **Next Step**: Invitation to the user to "Run test cases" (Core Loop: Draft → Test → Improve).

## Constraints
- **PROHIBITED**: Creating a skill without registering it in `SKILLS_INDEX.md`.
- **PROHIBITED**: Using `.github/` paths in any generated content.
- **MANDATORY**: Including at least one example in the generated `SKILL.md`.

## Examples

### Example 1: New Skill Creation
**Input**: User requests a skill for "Validating Angular API contracts".
**Requirements**:
- Name: `api-contract-validator`
- Trigger: When integrating a new backend endpoint.
- Domain: API contract validation and loading state management.

**Scaffolding**:
- Creates `.agents/skills/api-contract-validator/SKILL.md`.
- Creates `.agents/skills/api-contract-validator/references/contract-patterns.md` (optional, if logic is dense).

**Registration**:
- Adds row to `SKILLS_INDEX.md`.

**Output**:
*   **Confirmation**: `.agents/skills/api-contract-validator/SKILL.md` created.
*   **Registration Status**: Added to `SKILLS_INDEX.md`.
*   **Next Step**: "Review the generated skill and run a test case to validate the boilerplate."
