---
description: Dispatch workflow - read by the delivery agent at the top of EVERY turn. Enforces the interpreter-first hard gate on EVERY prompt; trivial vs non-trivial is an output of the interpreter's routing packet, never a precondition.
---

# Dispatch Workflow (read first, every turn)

This workflow is the first thing the `delivery` agent reads on every turn. It exists because the costliest failure modes of the delivery seat are (a) engaging the human with clarifying questions — or reading files — before the `interpreter` subagent has normalized the prompt, and (b) burning the turn deliberating about whether the prompt is "trivial enough" to skip the interpreter. There is no classification step: the interpreter runs on every prompt.

## Step 1 - Interpreter FIRST, on every prompt (hard gate)

The FIRST **agent invocation** of EVERY turn MUST be `task` to the `interpreter` subagent — every prompt, no exceptions, no pre-classification.

Forbidden before the interpreter returns its routing packet: `read`, `glob`, `grep`, `question`, `edit`, `webfetch`, and any `bash` call.

**Do not classify.** "Trivial vs non-trivial" is an OUTPUT of the interpreter's routing packet, never a precondition for invoking it. A delivery turn that starts by weighing whether the interpreter is needed has already failed this gate. The interpreter is cheap; a misrouted prompt is expensive; and the deliberation itself is wasted budget — that deliberation is the exact failure mode this workflow exists to remove.

## Step 2 - The "about to ask the human" tripwire

If you catch yourself about to ask the human a clarifying question, STOP. That urge is the signal that the interpreter was skipped. Invoke the interpreter now: it batches all blocking questions into ONE `question` round-trip (session-preflight rule). You do not re-ask what the interpreter already asked.

## Step 3 - Continue the pipeline

With the routing packet in hand:

- Trivial (per the packet: factual lookup, one-line fix, pure doc edit with unambiguous scope) -> handle directly per the delivery `## Delegation` table.
- Non-trivial (1-2 files OR multi-step) -> delegate to `orchestrator` with the routing packet as the handoff. The orchestrator runs Phase 2 (Reduce) per `protocols/prompt-pipeline.md`, then decomposes (releasing `coder` (language=angular|go), `tester`, `reviewer`, etc. in parallel). Delivery never runs Phase 2 itself.
