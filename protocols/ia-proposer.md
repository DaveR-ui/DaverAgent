# Protocol: IA Proposer

Proposal phase: transform exploration findings into a step-by-step action plan and surface "Hot Spots" — critical decision points where the agent must pause and seek user validation before execution.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-proposer`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

After the [explorer](./ia-explorer.md) scope report and the [supplier](./ia-supplier.md) context package. The proposer converts that material into a validated execution plan. It is the **only** phase authorized to flag Hot Spots and pause the flow.

## Action plan generation

Based on the metadata from [explorer](./ia-explorer.md), draft a plan that follows the standards in `docs/context/rules.md` and the slice-specific standard patterns:

- **Step-by-step** — atomic tasks (e.g. "create service", "update template", "add unit test").
- **Source alignment** — every step maps back to the identified source of truth.

## Hot-spot detection

Flag a step as a Hot Spot and **pause** if it involves any of the following:

- **State ownership pivot** — moving state from a legacy store to a signal-based service.
- **Breaking refactor** — modifying a component that exceeds 900 lines of code.
- **Ambiguous data flow** — when multiple endpoints are involved and the reconciliation logic is not explicitly defined in the documentation.
- **Standard-supremacy violation** — the proposed change contradicts patterns in `docs/context/`.
- **Compute guard** — more than 5 files would change.
- **Security/guardrails** — implementation that requires a temporary bypass of established project rules (e.g. non-standard DI).

## Mandatory user validation (the pause)

For every Hot Spot, stop and present:

1. **The decision** — what is the critical choice.
2. **Options** — at least two approaches (e.g. "refactor to sub-component" vs "add logic to current component").
3. **Risk / benefit** — short bullets on compute cost and technical debt.
4. **Mandatory question** — a direct question the user must answer to proceed.

## Hidden assumption detection

Before presenting the plan, identify the one thing the plan takes for granted that, if wrong, breaks everything. This is not an explicit decision — it is the invisible assumption no one is questioning. Express it in one sentence.

## Decision rules

- **No validation, no execution** — never execute code changes in a "Complex" component without a prior validated action plan.
- **Standard supremacy** — if the proposed plan contradicts patterns in `docs/context/`, it must be flagged as a Hot Spot automatically.
- **Compute guard** — if a plan involves changing more than 5 files, it is a Hot Spot by default.
- **Hidden assumption is mandatory** — the routing packet from Step 0 already carries the hidden assumption; if it is load-bearing, surface it again in the plan.

## Output format

Return a Technical Proposal Report:

- **Executive summary** — high-level goal of the change.
- **Detailed action plan** — numbered list of implementation steps.
- **Hidden assumption** — the one thing this plan takes for granted that, if wrong, breaks everything.
- **HOT SPOTS**:
  - *Hot Spot #N* — description.
  - *The pivot* — the critical decision.
  - *Options* — A vs B with risk / benefit.
  - *Mandatory question* — what you need to ask the user.
- **Verification method** — how the success of this plan will be measured.

## Constraints

- **PROHIBITED**: executing code in a "Complex" component before the user validates the action plan.
- **PROHIBITED**: skipping Hot-Spot detection for plans that contradict `docs/context/rules.md`.
- **MANDATORY**: pausing and asking the user when a plan touches more than 5 files.

## Integration

In the opencode runtime, the proposer role is absorbed into **Phase 2 (Reduce)** of [prompt-pipeline.md](./prompt-pipeline.md), which the orchestrator runs after the interpreter's Step 0. Phase 2 defines a complexity level, surfaces hot spots (state ownership pivot, breaking refactor, ambiguous data flow, standard-supremacy violation, compute guard, security/guardrail bypass), captures dependencies and verification path, and **requires human validation for Alta / Muy Alta complexity before any implementation begins**. The protocol above is the detailed reference for the original Hot-Spot-driven proposal flow.
