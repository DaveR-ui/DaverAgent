---
name: prompt-analyzer
description: First filter of the system. Analyzes the initial prompt to extract critical metadata (language, version, frameworks, files), identifies reproduction steps, and establishes success criteria.
last_updated: 2026-04-24
status: active
---

# 🧠 Skill: Prompt Analyzer (Initiation Phase)

## Goal
This skill is the **mandatory first step** for any non-trivial task. It validates that a prompt is actionable, identifies the technical environment, and ensures a clear path to verification exists. All supporting evidence (images, logs, snippets) must be collected in `.agents/cache-session/<session-id>/` before implementation begins.

## Instructions

### 1. Language Normalization (Mandatory First Step)
*   **Detect Language**: Identify the language of the incoming prompt.
*   **Translate to English**: If the prompt is NOT in English, produce an English translation before any further analysis. This ensures compatibility with external documentation searches, web research, and framework references (Angular, RxJS, TypeScript docs are primarily in English).
*   **Preserve Original**: Keep the original prompt text for reference. The English version becomes the working prompt for all downstream phases.

### 2. Metadata & Versioning Extraction
Before analyzing the user request, identify the technical context:
*   **Action**: Locate `project-details.md` in the root directory.
*   **Creation Rule**: If `project-details.md` does not exist, **invoke the `project-details-generator` skill** to create it.
*   **Sync Rule**: If the environment has changed (e.g., `package.json` or `AGENTS.md` modified), **invoke the `project-details-generator` skill** to update the SSOT before proceeding.
*   **Extraction**: Once the SSOT is confirmed, read `project-details.md` and identify files cited in prompt. Cross-reference them with the **Component Map** in `AGENTS.md`.

### 3. Prompt Analysis Criteria
Evaluate the incoming prompt against these five pillars:
1.  **Problem Statement**: What is broken or missing? Identify the user-visible symptom.
2.  **Reproduction Steps**: How do we reproduce the error? (Mandatory for bug fixes).
3.  **Source of Truth**: Which file, service, or endpoint is the authoritative state owner?
4.  **Constraints**: Technical restrictions (e.g., "No setTimeout", "Use rxResource").
5.  **Success Criteria**: Explicitly define what must be true for the task to be considered solved.

### 4. Complexity Triage (Efficiency Rule)
Before proceeding to the full orchestration, classify the task:
*   **Quick Flow (Q)**: Use for documentation queries, single-file clarifications, or trivial fixes (< 5 lines).
    - **Path**: Analyzer -> Supplier -> Execution.
    - **Optimization**: Skip `Explorer` and `Proposer` phases.
*   **Deep Flow (C)**: Use for new features, architectural changes, or complex debugging.
    - **Path**: Analyzer -> Explorer -> Proposer -> Execution -> Verifier.
    - **Optimization**: Full context discovery required.

### 5. Decision Rules
*   **STOP and Ask**: If the prompt is missing reproduction steps or success criteria that would change the architecture.
*   **PROCEED (Quick)**: If the task is purely informational or trivial.
*   **PROCEED (Deep)**: If the task requires multi-file coordination or new logic.
*   **Metadata Sync**: Ensure all implementation follows the framework version found in `project-details.md`.

### 6. LLM Reasoning Analysis Guidelines (Mandatory for Prompt Refinement)

When refining prompts or analyzing LLM-generated reasoning traces, apply these rules to reduce post-hoc rationalization and improve signal quality:

#### 6.1 Ask for Local States, Not Global Explanations
- **Avoid**: "Explain exactly why you decided this." — forces a coherent post-hoc narrative.
- **Prefer**: "List only the immediate signals that seemed relevant at this step." or "List partial hypotheses without attempting to unify them."
- **Effect**: Reduces narrative pressure and fabricated coherence.

#### 6.2 Request Explicit Uncertainty
LLMs tend to sound confident even when they are not. Always request:
- Confidence levels per claim.
- Alternative interpretations.
- Ambiguities and missing information.
- **Format**: "Indicate which parts are strong observations and which are weak inferences." or separate into:
  ```
  - Observed signals
  - Hypotheses
  - Speculation
  ```

#### 6.3 Multi-Sample Comparison
Consistent patterns across runs are more reliable than single-generation details:
- Generate multiple passes when analyzing complex reasoning.
- Compare repeated patterns across seeds, prompts, or reformulations.
- Ignore overly specific details that appear in only one run.
- **Rule**: If a pattern appears across different seeds/prompts, it is more likely a real reasoning feature.

#### 6.4 Request Incremental Traces
Instead of "explain the entire decision," force structured reasoning:
  ```
  Before responding:
  - Identify relevant signals
  - Then constraints
  - Then candidates
  - Then final decision
  ```
- **Effect**: Forces stepwise reasoning instead of retrospective storytelling.

#### 6.5 Avoid Teleological Questions
These are dangerous because the model fills causal gaps:
- "What were you trying to do?"
- "What was your hidden goal?"
- "Why did you choose X?"
- **Prefer**: "What input patterns seem to correlate with this output?" — targets observable local correlations.

#### 6.6 Enforce Textual Grounding
Always require explicit references back to the input:
- "Cite exactly which parts of the prompt influenced this decision."
- "Do not invent motivations not supported by the text."
- **Effect**: Without grounding, the model drifts into free narrative.

#### 6.7 Request Competing Hypotheses
Break the model's tendency to collapse to a single coherent story:
- "Give 3 possible explanations and why each could be wrong."
- **Effect**: Forces consideration of alternatives and reduces confirmation bias.

#### 6.8 Separate Observation from Interpretation
This is the most critical technique. LLMs naturally mix all three:
  ```
  OBSERVATIONS:
  - ...
  
  INTERPRETATIONS:
  - ...
  
  ASSUMPTIONS:
  - ...
  ```
- **Rule**: Never allow observations and interpretations to be merged in the same bullet.

#### 6.9 Don't Ask for "Honesty" — Ask for Calibration
"Sé honesto" (be honest) is ineffective. Prefer:
- "Do not fill in missing gaps. If you cannot infer something directly, say so explicitly."
- "Prefer responding 'insufficient information' over speculating."
- **Effect**: Calibrates the model's output confidence to actual evidence strength.

#### 6.10 Understand the Fundamental Limit
An LLM does not have perfect introspective access to "why it did something":
- Outputs are emergent, distributed, non-verbal, and partially implicit.
- Any textual explanation is always: compression, approximation, semantic reconstruction.
- **Never** treat it as "direct mind reading."
- **Key insight from research**: Despite being imperfect, this reconstruction still contains surprisingly useful causal information — use it as a signal, not as truth.

## Output Format
Return a short readiness summary:
*   **Original Prompt**: [Original text in source language]
*   **English Translation**: [Translated prompt — this is the working version for all downstream phases]
*   **Prompt Clarity**: [Clear / Needs Clarification]
*   **Metadata**: Language/Version, Testing Framework, Cited Files.
*   **Success Criteria**: Short bullet points.
*   **Reproduction Path**: Concrete steps to verify the issue.
*   **Refined Prompt**: (Optional) A more precise English version of the request with file references.
*   **Reasoning Trace** (when analyzing LLM-generated content):
    ```
    OBSERVATIONS:
    - [Direct evidence from input only]
    
    INTERPRETATIONS:
    - [Inferences drawn from observations]
    
    ASSUMPTIONS:
    - [Unverified premises that could be wrong]
    
    CONFIDENCE: [High/Medium/Low per major claim]
    COMPETING HYPOTHESES: [At least 2 alternative explanations]
    GROUNDING: [Exact input text that supports each claim]
    ```

## Constraints
- **PROHIBITED**: Proceeding to implementation without confirming reproduction steps for bug fixes.
- **PROHIBITED**: Ignoring `project-details.md` if it exists; its standards are absolute.
- **MANDATORY**: Cross-reference all cited files with `AGENTS.md` to validate scope and existence.

## Examples

### Input Prompt (Bug Fix)
"El boton de guardar no funciona en la pagina de clientes."

### Analysis Output
*   **Original Prompt**: "El boton de guardar no funciona en la pagina de clientes."
*   **English Translation**: "The save button does not work on the clients page."
*   **Prompt Clarity**: Needs Clarification
*   **Metadata**: Angular v21, Vitest, `src/features/client/page/client-page.component.ts`
*   **Success Criteria**: 
    - [ ] Save button triggers the save method.
    - [ ] Corresponding HTTP call is dispatched.
*   **Reproduction Path**: 
    1. Navigate to `/clientes`.
    2. Fill out the form.
    3. Click "Guardar" (Save).
*   **Refined Prompt**: "On the clients page (`src/features/client/page/`), the save button does not fire the click event. Verify the click binding and service injection."

### Input Prompt (Feature)
"Crear un nuevo componente de alerta reutilizable en shared."

### Analysis Output
*   **Original Prompt**: "Crear un nuevo componente de alerta reutilizable en shared."
*   **English Translation**: "Create a new reusable alert component in shared."
*   **Prompt Clarity**: Clear
*   **Metadata**: Angular v21, Signals, OnPush
*   **Success Criteria**: 
    - [ ] Component located in `src/shared/ui/alert/`.
    - [ ] Accepts type and message inputs via signals.
    - [ ] Has unit tests with Vitest.
*   **Reproduction Path**: 
    1. Import `AlertComponent` into a feature.
    2. Verify conditional rendering.
*   **Refined Prompt**: (N/A - Original is sufficient)
