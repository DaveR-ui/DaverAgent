# Protocol: IA Analyzer

Mandatory first stage of the IA orchestration pipeline: validate that a prompt is actionable, extract the technical environment (language, version, frameworks, cited files), and identify reproduction steps and success criteria before any implementation begins.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-analyzer`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

Any non-trivial task. The analyzer is the **mandatory first step** before orchestrator or subagent handoff: it confirms the prompt is actionable, identifies the technical environment, and ensures a clear path to verification exists. It also collects supporting evidence (images, logs, snippets) into a session-scoped cache before implementation begins.

## Language normalization

1. **Detect language** of the incoming prompt.
2. **Translate to English** if the prompt is not in English, so external documentation searches, web research, and framework references (Angular, RxJS, TypeScript docs are primarily in English) can run against the working version.
3. **Preserve the original** for reference; the English version becomes the working prompt for all downstream phases.

## Metadata and versioning

Before analyzing the request, identify the technical context:

- Locate the project's single source of truth (canonical entry point for stack and slice routing — in this workspace: [`docs/project.md`](../../docs/project.md)).
- If the canonical entry point is missing or stale, request a regeneration (see [ia-docs-gen](./ia-docs-gen.md) and [documenter](../agents/subagents/documenter.md)).
- Once confirmed, read it and identify the files cited in the prompt. Cross-reference those files with the **Slices** table and `docs/context/` to validate scope and existence.

## Analysis criteria

Evaluate the incoming prompt against five pillars:

1. **Problem statement** — what is broken or missing. Identify the user-visible symptom.
2. **Reproduction steps** — how to reproduce the error (mandatory for bug fixes).
3. **Source of truth** — which file, service, or endpoint is the authoritative state owner.
4. **Constraints** — technical restrictions (e.g., "no `setTimeout`", "use `rxResource`").
5. **Success criteria** — explicitly define what must be true for the task to be considered solved.

## Complexity triage

Before proceeding, classify the task into a flow:

| Flow | When | Path | Optimization |
|---|---|---|---|
| **Quick** | Documentation queries, single-file clarifications, trivial fixes (<5 lines) | Analyzer → Supplier → Execution | Skip Explorer and Proposer |
| **Deep** | New features, architectural changes, complex debugging | Analyzer → Explorer → Proposer → Execution → Verifier | Full context discovery required |

The mapping to the opencode native pipeline is: Quick ≈ trivial routing packet (Delivery handles directly); Deep ≈ non-trivial (Delivery delegates to `orchestrator`, which runs Phase 2 Reduce — see [prompt-pipeline.md](./prompt-pipeline.md)).

## Decision rules

- **Stop and ask** if the prompt is missing reproduction steps or success criteria that would change the architecture.
- **Proceed (Quick)** if the task is purely informational or trivial.
- **Proceed (Deep)** if the task requires multi-file coordination or new logic.
- **Metadata sync** — all implementation must follow the framework version found in the canonical entry point.

## LLM reasoning analysis guidelines

Use the following rules when refining prompts or analyzing LLM-generated reasoning traces, to reduce post-hoc rationalization and improve signal quality.

### Ask for local states, not global explanations

- Avoid: "Explain exactly why you decided this." — forces a coherent post-hoc narrative.
- Prefer: "List only the immediate signals that seemed relevant at this step." or "List partial hypotheses without attempting to unify them."

### Request explicit uncertainty

LLMs tend to sound confident even when they are not. Always request:

- Confidence levels per claim.
- Alternative interpretations.
- Ambiguities and missing information.
- Format: "Indicate which parts are strong observations and which are weak inferences," or separate into:
  ```
  - Observed signals
  - Hypotheses
  - Speculation
  ```

### Multi-sample comparison

Consistent patterns across runs are more reliable than single-generation details:

- Generate multiple passes when analyzing complex reasoning.
- Compare repeated patterns across seeds, prompts, or reformulations.
- Ignore overly specific details that appear in only one run.
- **Rule**: a pattern that appears across different seeds/prompts is more likely a real reasoning feature.

### Request incremental traces

Instead of "explain the entire decision," force structured reasoning:

```
Before responding:
- Identify relevant signals
- Then constraints
- Then candidates
- Then final decision
```

### Avoid teleological questions

These are dangerous because the model fills causal gaps:

- "What were you trying to do?"
- "What was your hidden goal?"
- "Why did you choose X?"

Prefer: "What input patterns seem to correlate with this output?" — targets observable local correlations.

### Enforce textual grounding

Always require explicit references back to the input:

- "Cite exactly which parts of the prompt influenced this decision."
- "Do not invent motivations not supported by the text."

### Request competing hypotheses

Break the model's tendency to collapse to a single coherent story:

- "Give 3 possible explanations and why each could be wrong."

### Separate observation from interpretation

The most critical technique. LLMs naturally mix all three:

```
OBSERVATIONS:
- ...

INTERPRETATIONS:
- ...

ASSUMPTIONS:
- ...
```

**Rule**: never allow observations and interpretations to be merged in the same bullet.

### Don't ask for "honesty" — ask for calibration

"Be honest" is ineffective. Prefer:

- "Do not fill in missing gaps. If you cannot infer something directly, say so explicitly."
- "Prefer responding 'insufficient information' over speculating."

### Understand the fundamental limit

An LLM does not have perfect introspective access to "why it did something":

- Outputs are emergent, distributed, non-verbal, and partially implicit.
- Any textual explanation is always: compression, approximation, semantic reconstruction.
- **Never** treat it as "direct mind reading."
- **Key insight from research**: despite being imperfect, this reconstruction still contains surprisingly useful causal information — use it as a signal, not as truth.

## Output format

Return a short readiness summary:

- **Original prompt** — text in source language.
- **English translation** — translated prompt; this is the working version for all downstream phases.
- **Prompt clarity** — `Clear` or `Needs Clarification`.
- **Metadata** — language/version, testing framework, cited files.
- **Success criteria** — short bullet points.
- **Reproduction path** — concrete steps to verify the issue.
- **Refined prompt** (optional) — a more precise English version of the request with file references.
- **Reasoning trace** (when analyzing LLM-generated content):
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

- **PROHIBITED**: proceeding to implementation without confirming reproduction steps for bug fixes.
- **PROHIBITED**: ignoring the canonical entry point if it exists; its standards are absolute.
- **MANDATORY**: cross-reference all cited files with the Slices table and `docs/context/` to validate scope and existence.

## Integration

The analyzer is the human-language front door to the orchestrator. In the opencode runtime, the **same role is performed by the [interpreter subagent](../agents/subagents/interpreter.md)** as Step 0 of [prompt-pipeline.md](./prompt-pipeline.md) — it normalizes vocabulary, captures constraints, and returns a routing packet. The protocol above remains the detailed reference for the original prompt analysis pipeline, including the LLM-reasoning quality techniques, which the interpreter does not duplicate.

## Notes

- The reasoning-analysis guidelines (sections 6.1–6.10) are the durable value of this protocol — they apply whenever an agent debugs another agent's output, not just during prompt intake.
- The Quick vs Deep triage maps directly onto the trivial / non-trivial split used by Delivery after Step 0.
