---
name: hot-spot-proposer
description: Proposal phase skill. Generates detailed technical action plans and identifies "Hot Spots"—critical decision points that require mandatory user validation before execution.
last_updated: 2026-04-24
status: active
---

# 🏗️ Skill: Hot Spot Proposer (Proposal Phase)

## Goal
Transform exploration findings into a step-by-step execution plan while safeguarding the project's architecture. Prevent "blind implementation" by identifying high-risk decisions (Hot Spots) where the agent must pause and seek user confirmation.

## Instructions

### 1. Action Plan Generation
Based on the metadata from `scope-explorer`, draft a plan following the "Signals-First" and "OnPush" standards found in `.github/agent-context/project-rules.md`.
*   **Step-by-Step**: Define atomic tasks (e.g., "Create service", "Update template", "Add unit test").
*   **Source Alignment**: Ensure every step maps back to the identified "Source of Truth".

### 2. Hot Spot Detection (Critical Decision Points)
You **must** flag a step as a "Hot Spot" and pause if it involves:
*   **State Ownership Pivot**: Moving state from a legacy store to a Signal-based service.
*   **Breaking Refactor**: Modifying a component that exceeds 900 lines of code.
*   **Ambiguous Data Flow**: When multiple endpoints are involved and the reconciliation logic isn't explicitly defined in the documentation.
*   **Security/Guardrails**: Any implementation that might require a temporary bypass of established project rules (e.g., non-standard DI).

### 3. Mandatory User Validation (The Pause)
For every detected Hot Spot, you must stop the flow and present:
1.  **The Decision**: What is the critical choice?
2.  **Options**: List at least two approaches (e.g., "Refactor to sub-component" vs "Add logic to current component").
3.  **Risk/Benefit**: Short bullet points on compute cost and technical debt.
4.  **Mandatory Question**: A direct A/B-style question the user must answer to proceed.
5.  Ask that question in chat with `#tool:vscode/askQuestions` / `vscode_askQuestions`, using explicit A and B options before execution continues.
6.  Mirror the chosen decision in the written plan after the user answers; the plan does not replace the chat question.

## Decision Rules
*   **No Validation, No Execution**: You are prohibited from executing code changes in a "Complex" component without a prior validated action plan.
*   **Standard Supremacy**: If the proposed plan contradicts patterns in `.github/agent-context/`, it must be flagged as a Hot Spot automatically.
*   **Compute Guard**: If a plan involves changing more than 5 files, it is a Hot Spot by default to avoid unnecessary token usage.

## Output Format
Return a Technical Proposal Report:
*   **Executive Summary**: High-level goal of the change.
*   **Detailed Action Plan**: Numbered list of implementation steps.
*   **🔥 HOT SPOTS**:
    *   *Hot Spot #1*: [Description]
    *   *The Pivot*: [The critical decision]
    *   *Mandatory Question Asked via `#tool:vscode/askQuestions`*: [The exact A/B question asked in chat]
*   **Verification Method**: How the success of this plan will be measured.

## Constraints
- **PROHIBITED**: Executing code in a "Complex" component before the user validates the action plan.
- **PROHIBITED**: Skipping Hot Spot detection for plans that contradict `.github/agent-context/project-rules.md`.
- **PROHIBITED**: Writing the Hot Spot question only in the plan without asking it in chat through `#tool:vscode/askQuestions` / `vscode_askQuestions`.
- **MANDATORY**: Pausing and asking the user when a plan touches more than 5 files.

## Examples

### Example 1: Complex Component Refactor
**Context**: `scope-explorer` flagged `client-dashboard.component.ts` as [COMPLEX] with 1200 lines.
**Action Plan**:
1. Extract data-table into standalone sub-component.
2. Move state to `ClientStore` signal service.
3. Update unit tests.

**🔥 HOT SPOT #1**:
*   *Description*: Component exceeds 900 lines. Extracting sub-components is a breaking refactor.
*   *The Pivot*: Decide which sub-component to extract first.
*   *Options*:
    - A: Extract `data-table` (touches 3 files, low risk).
    - B: Extract `filters-bar` (touches 5 files, medium risk).
*   *Risk/Benefit*:
    - A: Lower compute cost, preserves existing tests.
    - B: Higher impact, requires filter service rewrite.
*   *Mandatory Question*: "Which sub-component should we extract first, A or B?"

### Example 2: Ambiguous Data Flow
**Context**: Task involves reconciling data from `/api/invoices` and `/api/payments` without documented merge logic.
**🔥 HOT SPOT #1**:
*   *Description*: No documented source of truth for reconciled state.
*   *The Pivot*: Where should the merged state live?
*   *Options*:
    - A: Client-side computed signal in the component.
    - B: Server-side aggregation via new endpoint.
*   *Risk/Benefit*:
    - A: Faster, but duplicates logic if used elsewhere.
    - B: Slower to implement, but single source of truth.
*   *Mandatory Question*: "Should we merge data client-side (A) or request a new backend endpoint (B)?"
