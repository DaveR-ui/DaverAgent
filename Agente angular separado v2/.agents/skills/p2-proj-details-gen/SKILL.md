---
name: project-details-generator
description: Maintains the project-details.md SSOT. Extracts dependency versions, security standards, and key paths to ensure all agents have a consistent technical context.
last_updated: 2026-04-24
status: active
---

# 📂 Skill: Project Details Generator (SSOT Maintenance)

## Goal
This skill is responsible for the creation and continuous maintenance of the `project-details.md` file in the root directory. It ensures that any agent or subagent can immediately understand the technical environment (Angular version, testing tools, security guardrails) without performing a full repository scan.

## Instructions

### 1. Environmental Analysis
Scan the repository to extract the following critical data:
*   **Dependencies**: Identify Angular version (v20/v21+), and testing frameworks (Vitest vs Jasmine) from `package.json`.
*   **Architecture**: Confirm if the project is in a Signals-first migration or using legacy patterns.
*   **Key Paths**: Map the location of the context hub (`.agents/context/`) and the agents directory.

### 2. SSOT Generation/Update
Create or update `project-details.md` with the following mandatory sections:

#### A. Technical Stack
*   **Framework**: Angular Version (e.g., v21.x).
*   **Reactivity**: Signals-first (Mandatory for new code).
*   **Testing**: Primary framework (e.g., Vitest) and secondary (Jasmine/Karma).

#### B. Security & Guardrails
*   **Commit Policy**: NO automatic commits allowed.
*   **Branch Protection**: Standards for PR reviews.
*   **Prohibited Patterns**: Strict ban on `setTimeout` and massive library imports.

#### C. Operational Paths
*   **Context Hub**: `.agents/context/`
*   **Skills Index**: `.agents/skills/SKILLS_INDEX.md`
*   **Orchestrator**: `.agents/workflows/orchestrate.md`

### 3. Verification Rules
*   **Sync Check**: If `package.json` or `AGENTS.md` changes, this skill must be triggered to keep the SSOT in sync.
*   **No Redundancy**: Avoid prose; use tables and lists for technical metadata.

## Output Format
A summary of the changes made to the SSOT:
*   **File Status**: [Created / Updated]
*   **Key Updates**: List of detected version changes or new paths.
*   **Readiness**: Confirmation that the environment is ready for subagent consumption.

## Constraints
- **MANDATORY**: Do not overwrite `project-details.md` without verifying if critical data has changed.
- **PROHIBITED**: Including sensitive information (API keys, passwords) in the SSOT.
- **REQUIRED**: Keep the file in the root directory so all agents can locate it immediately.

## Examples

### Example: Initial Generation
**Environment**: Angular v21, Vitest, Signals-first.
**Action**: Create `project-details.md` with technical stack, guardrails, and paths.
**Output**:
*   **File Status**: Created
*   **Key Updates**: Angular v21 detected, Vitest as primary test runner.
*   **Readiness**: Environment mapped.

### Example: Dependency Update
**Trigger**: `package.json` updated Angular to v22.
**Action**: Update version in `project-details.md`.
**Output**:
*   **File Status**: Updated
*   **Key Updates**: Angular version bumped to v22.
*   **Readiness**: SSOT synced.
