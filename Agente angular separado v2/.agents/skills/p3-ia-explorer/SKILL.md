---
name: scope-explorer
description: Exploration phase skill. Locates assets, analyzes task complexity, and determines if a component is "Complex" (has design docs) or "Simple" (needs doc if dense logic is found).
last_updated: 2026-04-24
status: active
---

# 🔍 Skill: Scope Explorer (Exploration Phase)

## Goal
This skill identifies the blast radius of a task by locating all related files and dependencies. It categorizes components by complexity based on the existing documentation in the `.agents/context/` hub and ensures that "dense" logic never remains undocumented.

## Instructions

### 1. Asset & Dependency Mapping
*   **Action**: Use the component name or keywords from the prompt to search the **Component Map** in [AGENTS.md](../../context/orchestration/AGENTS.md).
*   **Discovery**: Identify all related `.ts`, `.html`, `.scss`, and `.spec.ts` files, as well as services or shared utilities injected in the component.

### 2. Complexity Analysis
Evaluate the component's status using the documentation index:
*   **[COMPLEX]**: The component has a dedicated feature folder in `.agents/context/project/<feature-name>/` or a detailed "Primary Doc" in the `AGENTS.md` map.
    *   *Requirement*: You must read the specific `errors.md` or `common-errors.md` within that feature folder before proceeding.
*   **[SIMPLE]**: The component only has a basic entry or no entry in the map.
    *   *Action*: Perform a "Logic Density Check".

### 3. Logic Density Check (for Simple components)
Scan the source code for:
*   Manual subscriptions (`.subscribe()`), complex RxJS pipes, or nested `if/else` logic.
*   Lack of Signals or `rxResource` in data-heavy flows.
*   **Mandate**: If density is high, you **must** suggest the creation of a new documentation file in `.agents/context/` following the [generate-documentation](../p3-ia-docs-gen/SKILL.md) standard before starting the implementation.

## Decision Rules
*   **Folder-First**: If a feature folder exists in `.agents/context/`, it is the supreme source of truth for that scope.
*   **Doc Debt**: Treat "Simple" components with "Dense Logic" as a technical debt blocker. Recommend documentation as a pre-requisite.
*   **Reference Guard**: All links and paths must use the `.agents/` prefix. Any reference to `.github/` is a standards violation.

## Output Format
Return a Scope Report:
*   **Complexity Level**: [Simple / Complex]
*   **Identified Assets**: List of files and key dependencies.
*   **Context Location**: Path to documentation in `.agents/context/`.
*   **Common Errors**: Reference to the relevant `errors.md` if the feature is complex.
*   **Documentation Recommendation**: [None / Required] (with reasoning if logic is dense).

## Constraints
- **PROHIBITED**: Proceeding with implementation on a [COMPLEX] component without reading its feature-specific `errors.md`.
- **PROHIBITED**: Referencing paths outside `.agents/` for documentation (e.g., `.github/`).
- **MANDATORY**: Flagging high logic density in [SIMPLE] components and proposing documentation before coding.

## Examples

### Example 1: Complex Feature
**Input**: Task involves `auth-wizard` component.
**Analysis**: Folder `.agents/context/project/auth-wizard/` exists with `errors.md`.
**Output**:
*   **Complexity Level**: Complex
*   **Identified Assets**: `src/features/auth/wizard/...`
*   **Context Location**: `.agents/context/project/auth-wizard/`
*   **Common Errors**: `.agents/context/project/auth-wizard/errors.md`
*   **Documentation Recommendation**: None

### Example 2: Simple Component with Dense Logic
**Input**: Task involves `data-table` component.
**Analysis**: No feature folder. Source scan reveals manual `.subscribe()` and nested RxJS.
**Output**:
*   **Complexity Level**: Simple
*   **Identified Assets**: `src/shared/ui/data-table/...`
*   **Context Location**: N/A
*   **Common Errors**: N/A
*   **Documentation Recommendation**: Required — High logic density detected (manual subscriptions, complex pipes).
