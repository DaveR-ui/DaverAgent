---
name: scope-explorer
description: Exploration phase skill. Locates assets, maps user clues to code/doc coverage, and flags undocumented dense logic.
last_updated: 2026-04-24
status: active
---

# 🔍 Skill: Scope Explorer (Exploration Phase)

## Goal
This skill identifies the blast radius of a task by locating all related files and dependencies. It starts from user-provided clues and maps them to code assets and local docs, ensuring that "dense" logic never remains undocumented.

## Instructions

### 1. Asset & Dependency Mapping
*   **Action**: Start from `sdd_agent`'s User Clue Inventory (attachments, logs, snippets, references) and use those clues to search the **Component Map** in `AGENTS.md`.
*   **Discovery**: Identify all related `.ts`, `.html`, `.scss`, and `.spec.ts` files, as well as services or shared utilities injected in the component.
*   **Traceability**: For each asset, note which clue led to it.

### 2. Complexity Analysis
Evaluate the component's status using the documentation index:
*   **[DOCUMENTED]**: The scope has a dedicated feature doc or folder in `.github/agent-context/` or a detailed "Primary Doc" in the `AGENTS.md` map.
    *   *Requirement*: You must read the specific `errors.md` or `common-errors.md` within that feature folder before proceeding.
*   **[PARTIALLY DOCUMENTED]**: Some clues map to known docs, but part of the scope remains outside documented coverage.
    *   *Action*: Perform both a "Logic Density Check" and an "Unresolved Clue Check".
*   **[UNDOCUMENTED]**: The component only has a basic entry or no entry in the map.
    *   *Action*: Perform a "Logic Density Check" and recommend documentation if density or ambiguity is high.

### 3. Logic Density Check (for partially documented or undocumented scope)
Scan the source code for:
*   Manual subscriptions (`.subscribe()`), complex RxJS pipes, or nested `if/else` logic.
*   Lack of Signals or `rxResource` in data-heavy flows.
*   **Mandate**: If density is high, you **must** suggest the creation of a new documentation file in `.github/agent-context/` following the `generate-documentation` standard before starting the implementation.

## Decision Rules
*   **Folder-First**: If a feature doc or folder exists in `.github/agent-context/`, it is the supreme source of truth for that scope.
*   **Evidence-First**: Prioritize clues backed by direct user evidence over assumptions.
*   **Doc Debt**: Treat undocumented scope with dense logic as technical debt. Recommend documentation as a pre-requisite.
*   **Reference Guard**: Documentation references must point to `.github/agent-context/` for implementation guidance and `.github/agent-workflows/orchestrate.md` for routing.

## Output Format
Return a Scope Report:
*   **Scope Surface**: [Documented / Partially Documented / Undocumented]
*   **Evidence Traceability**: Which clues mapped to which assets, plus unresolved clues.
*   **Identified Assets**: List of files and key dependencies.
*   **Context Location**: Path to documentation in `.github/agent-context/`.
*   **Common Errors**: Reference to the relevant `errors.md` if the scope is documented.
*   **Documentation Recommendation**: [None / Required] (with reasoning if logic is dense or clues are unresolved).

## Constraints
- **PROHIBITED**: Proceeding with implementation on a [DOCUMENTED] component without reading its feature-specific `errors.md`.
- **PROHIBITED**: Referencing stale documentation paths instead of `.github/agent-context/` or `.github/agent-workflows/orchestrate.md`.
- **MANDATORY**: Flagging high logic density in [PARTIALLY DOCUMENTED]/[UNDOCUMENTED] scope and proposing documentation before coding.

## Examples

### Example 1: Complex Feature
**Input**: Task involves `auth-wizard` component.
**Analysis**: A dedicated auth wizard doc exists under `.github/agent-context/authviews/`.
**Output**:
*   **Scope Surface**: Documented
*   **Evidence Traceability**: User clue "wizard navigation failure" maps to auth wizard files and docs.
*   **Identified Assets**: `src/features/auth/wizard/...`
*   **Context Location**: `.github/agent-context/authviews/wizard-logic.md`
*   **Common Errors**: `.github/agent-context/troubleshooting/common-errors.md`
*   **Documentation Recommendation**: None

### Example 2: Simple Component with Dense Logic
**Input**: Task involves `data-table` component.
**Analysis**: No feature folder. Source scan reveals manual `.subscribe()` and nested RxJS.
**Output**:
*   **Scope Surface**: Undocumented
*   **Evidence Traceability**: Stack trace points to `data-table.component.ts`; one user hint remains unresolved.
*   **Identified Assets**: `src/shared/ui/data-table/...`
*   **Context Location**: N/A
*   **Common Errors**: N/A
*   **Documentation Recommendation**: Required — High logic density detected (manual subscriptions, complex pipes).