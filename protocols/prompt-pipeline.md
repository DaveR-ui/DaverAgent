# Protocol: Prompt Pipeline

Two-stage analysis convention with a deterministic pre-pass for the Delivery agent. **Every prompt** passes through the pre-pass (Step 0a) and Step 0 (Interpret) before any handling or delegation — no prompt skips the interpreter. The trivial/non-trivial verdict is an output of the interpreter's routing packet: trivial prompts (single-line fixes, factual lookups, unambiguous doc edits) are handled directly by Delivery AFTER Step 0, without Phase 2.

This protocol defines the pre-pass and the two stages conceptually; the executor of each step may vary:

- **Step 0a: Pre-process** (deterministic, zero LLM cost) is executed by the [`extract-keywords.sh`](../scripts/extract-keywords.sh) script. It extracts candidate terms from the raw prompt and greps them against `docs/project.md` and `docs/context/README.md`, producing a keyword packet. See [`prompt-preprocessor.md`](./prompt-preprocessor.md).
- **Step 0: Interpret** is executed by the [`interpreter`](../agents/subagents/interpreter.md) subagent. The interpreter starts from the Step 0a keyword packet, reconciles vocabulary, captures constraints, and may ask the human one batch of clarifying questions.
- **Phase 2: Reduce** (this protocol) is executed by `delivery` for trivial scopes, or by `orchestrator` for multi-step work.

## When to apply

Always. Step 0a (pre-process) and Step 0 (Interpret) run on **every prompt** — they are the entry point of the delivery turn, not an opt-in for complex work. Delivery never pre-classifies a prompt to skip the interpreter; that deliberation is the failure mode the hard gate removes.

The only branch happens AFTER Step 0, based on the interpreter's routing packet:

- **Packet says trivial** (single-line fix, factual lookup, "how do I...", pure doc edit with unambiguous scope) -> Delivery handles it directly per its Delegation table; Phase 2 is skipped.
- **Packet says non-trivial** -> Phase 2 (Reduce) runs, then delegation per the Integration section below.

## Step 0a: Pre-process (deterministic)

Before the interpreter LLM runs, the `delivery` agent executes:

```bash
echo "<raw prompt>" | bash .opencode/scripts/extract-keywords.sh
```

The script emits a keyword packet (JSON): extracted terms, first-pass `grep` matches against `docs/project.md` and `docs/context/README.md`, and candidate slice ids from the Slices table. It always exits 0 and costs zero LLM tokens. The full contract lives in [`.opencode/protocols/prompt-preprocessor.md`](./prompt-preprocessor.md).

Delivery passes the raw prompt AND the keyword packet to the interpreter. If the script is unavailable, Step 0a is skipped and the interpreter reconciles vocabulary on its own.

## Step 0: Interpret (executed by the `interpreter` subagent)

The `delivery` agent invokes the `interpreter` subagent with the raw prompt. The interpreter:

1. Reads the prompt verbatim (keeps the human's language).
2. Normalizes vocabulary and aliases against the codebase (`grep`) and `docs/project.md`.
3. Captures hard constraints and explicit non-goals.
4. Identifies the smallest actionable slice, the hidden assumption, and expected output.
5. Optionally calls the `question` tool ONCE, with a batch of all blocking questions, if the route would materially change based on the answer.
6. Returns a compact routing packet (see [`interpreter.md`](../agents/subagents/interpreter.md) for the full shape).

The full process and the routing packet schema are defined in [`.opencode/agents/subagents/interpreter.md`](../agents/subagents/interpreter.md). Do not duplicate it here.

## Phase 2: Reduce

**Goal:** turn the routing packet from Step 0 into a concrete scope, complexity level, hot-spot map, and verification path — the minimum a subagent needs to start work.

### Inputs

1. Routing packet from Step 0 (produced by the `interpreter` subagent).
2. Project context from `docs/project.md` and relevant `docs/context/*.md` (read on demand via the `docs-context` reference, or directly).

### Process

1. **Module scope** — declare which modules are IN and which are OUT. A module is IN if: directly mentioned, functional dependency, data dependency, UI/UX boundary, or API boundary.
2. **Inputs / outputs / state** — for each in-scope module: what flows in, what flows out, what state changes, what side effects, where the source of truth lives.
3. **Complexity level** — pick the lowest level that matches:
   - **Baja** — single file, isolated logic, no dependencies.
   - **Media** — 2-3 files cross-module, known patterns, clear boundaries.
   - **Media-Alta** — conditional branching by env/type, state changes.
   - **Alta** — multi-environment behavior, external integrations, shared state.
   - **Muy Alta** — data migration, schema changes, breaking changes.
4. **Hot spots** — flag any critical decision point. Each hot spot needs: the decision, two approaches with risk/benefit, a mandatory A/B question.
   - State ownership pivot.
   - Breaking refactor (>900 lines touched).
   - Ambiguous data flow.
   - Standard supremacy violation (plan contradicts project rules).
   - Compute guard (>5 files with logic changes).
   - Security/guardrail bypass.
5. **Dependencies** — upstream (what this depends on) and downstream (what depends on this).
6. **Boundaries** — explicit OUT-of-scope list with reasons. Be specific with module names and file paths.
7. **Verification path** — how success is measured. Tests that should pass. Observable behavior that proves completion.

### Output (scope + plan)

```markdown
## Scope

**Complexity:** <Baja|Media|Media-Alta|Alta|Muy Alta>
**Hot spots:** <count> (<one-line summary each>)

**In scope:**
- <module> — <why>

**Out of scope (explicit):**
- <module> — <why excluded>

**Key files:**
- <path> — <purpose> — <read|modify|create>

**Verification path:**
- <how success is measured>
- <tests that should pass>
- <observable behavior>
```

## Decision Rules

- **No validation, no execution** — for Alta / Muy Alta complexity, the plan MUST be validated by the human before any implementation begins.
- **Standard supremacy** — if the proposed scope contradicts established project rules, flag it as a hot spot automatically.
- **Compute guard** — plans touching >5 files are hot spots by default.
- **Hidden assumption is mandatory** — the routing packet from Step 0 already carries the hidden assumption. If the assumption feels load-bearing, surface it again in the scope.
- **Hot spots are cumulative** — multiple hot spots bump the complexity level.
- **One question block** — never ask the human 5 questions across 5 turns. Group all clarifications into a single message. The interpreter already follows this rule for Step 0; Phase 2 must follow it too.

## Integration

The Delivery agent runs the two stages in sequence:

```
Raw prompt -> Step 0a (extract-keywords.sh) -> keyword packet -> Step 0 (interpreter subagent) -> routing packet -> Phase 2 (Reduce) -> scope + plan -> delegate
```

The Delivery's system prompt is small on purpose. Sections in the system prompt that say "see prompt-pipeline.md" or "call interpreter first" are anchors into this protocol. This file is the source of truth.

After Phase 2, Delivery picks the delegation target:

- **Trivial** (post-Step 0) -> handle directly (doc edit, simple lookup).
- **1-2 file change** (post-Phase 2) -> delegate to `coder` directly.
- **3+ files or multi-step** -> delegate to `orchestrator` with the routing packet + scope as the handoff.

## Notes

- The interpreter runs on `minimax-m3` (cheap). Phase 2 runs on the model's tier assigned to `delivery` or `orchestrator`. Do not move Phase 2 onto a cheaper tier for cost reasons; it requires the reasoning quality the assigned tier has.
- Edge cases are practical, not theoretical.
- Acceptance criteria are testable, not vague.
- The hidden assumption is the most important thing Step 0 surfaces — it is what nobody is thinking about. Phase 2 must carry it forward.
