---
description: Dispatch workflow - read by the delivery agent at the top of EVERY turn. Classifies the prompt as trivial vs non-trivial and enforces the interpreter-first hard gate for non-trivial prompts.
---

# Dispatch Workflow (read first, every turn)

This workflow is the first thing the `delivery` agent reads on every turn. It exists because the costliest failure mode of the delivery seat is engaging the human with clarifying questions — or reading files — before the `interpreter` subagent has normalized the prompt.

## Step 1 - Classify the prompt

**Trivial** prompts:

- Single-line fix with an explicit file, symbol, or line reference.
- Factual lookup answerable in one read ("what is X?").
- "How do I..." answered by pointing at one doc.
- Pure doc edit with unambiguous scope.

**Non-trivial** prompts: everything else, including:

- Typo-ridden, misspelled, or fragmented prompts (e.g. "arreglar lost est").
- Vague scope, multi-step work, multi-slice requests.
- References to prior chat or implicit context.
- Any prompt that needs vocabulary mapping onto the repo's slices, components, modules, or feature flags.

**When in doubt, classify as NON-TRIVIAL.** The interpreter is cheap; a misrouted prompt is expensive.

## Step 2 - Non-trivial: interpreter FIRST (hard gate)

For a non-trivial prompt, the FIRST tool call of the turn MUST be `task` to the `interpreter` subagent.

Forbidden before the interpreter returns its routing packet: `read`, `glob`, `grep`, `question`, `edit`, `webfetch`, and any `bash` call other than the Step 0a pre-processor.

Single allowed exception: running the deterministic Step 0a pre-processor (`bash .opencode/scripts/extract-keywords.sh`) to produce the keyword packet that accompanies the raw prompt into the interpreter. See `.opencode/protocols/prompt-preprocessor.md`.

## Step 3 - The "about to ask the human" tripwire

If you catch yourself about to ask the human a clarifying question, STOP. That urge is the signal that the interpreter was skipped. Invoke the interpreter now: it batches all blocking questions into ONE `question` round-trip (session-preflight rule). You do not re-ask what the interpreter already asked.

## Step 4 - Continue the pipeline

With the routing packet in hand, run Phase 2 (Reduce) per `.opencode/protocols/prompt-pipeline.md`, then delegate:

- Trivial (post-Step 0) -> handle directly.
- 1-2 file change -> `coder` with the routing packet + scope.
- 3+ files or multi-step -> `orchestrator` with the routing packet + scope as the handoff.
