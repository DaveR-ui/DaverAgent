# Protocol: IA Explorer

Exploration phase: locate all assets and dependencies for a task, classify components as Complex (has authoritative docs) or Simple (no docs), and run a logic-density check on Simple components to surface documentation debt before coding.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-explorer`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

Between [analyzer](./ia-analyzer.md) (or Step 0 in [prompt-pipeline.md](./prompt-pipeline.md)) and [proposer](./ia-proposer.md) (or Phase 2 Reduce). The explorer identifies the **blast radius** of a task by locating all related files and dependencies, then categorizes the component by complexity against the documentation hub.

## Asset and dependency mapping

- Use the component name or keywords from the prompt to search the relevant index — in this workspace, [`docs/project.md`](../../docs/project.md) (Slices table) and the per-slice docs under `docs/context/`.
- Identify all related source files, services, and shared utilities injected in the component.

## Complexity analysis

Evaluate the component's status using the documentation index:

| Status | Criteria | Required action |
|---|---|---|
| **[COMPLEX]** | Has a dedicated feature folder in `docs/context/project/<feature>/` or a detailed entry in the slices table. | Read the feature's `errors.md` or `common-errors.md` (or its equivalent in the canonical docs) before proceeding. |
| **[SIMPLE]** | Only has a basic entry or no entry. | Run a **Logic Density Check** (see below). |

## Logic density check (for Simple components)

Scan the source code for:

- Manual subscriptions (`.subscribe()`), complex RxJS pipes, or nested `if/else` logic.
- Lack of signals or `rxResource` in data-heavy flows.
- Hidden state outside the documented source of truth.

**Mandate**: if density is high, recommend creation of a new documentation file in `docs/context/` following the [ia-docs-gen](./ia-docs-gen.md) standard **before** starting the implementation.

## Decision rules

- **Folder-first**: if a feature folder exists in `docs/context/`, it is the supreme source of truth for that scope.
- **Doc debt**: treat "Simple" components with "Dense Logic" as a technical-debt blocker. Recommend documentation as a prerequisite.
- **Reference guard**: all links and paths must use the canonical project-relative prefixes. References to legacy paths (e.g. `.github/`) are a standards violation.

## Output format

Return a Scope Report:

- **Complexity level** — `Simple` or `Complex`.
- **Identified assets** — list of files and key dependencies.
- **Context location** — path to documentation in `docs/context/`.
- **Common errors** — reference to the relevant `errors.md` if the feature is complex.
- **Documentation recommendation** — `None` or `Required` (with reasoning if logic is dense).

## Constraints

- **PROHIBITED**: proceeding with implementation on a [COMPLEX] component without reading its feature-specific `errors.md`.
- **PROHIBITED**: referencing paths outside the canonical doc tree for documentation.
- **MANDATORY**: flagging high logic density in [SIMPLE] components and proposing documentation before coding.

## Integration

In the opencode runtime, the [explorer subagent](../agents/subagents/explorer.md) covers this role for most prompts. Use the protocol above when:

- The task is "Deep" (per the [analyzer](./ia-analyzer.md) triage) and the orchestrator wants the full Component Map treatment.
- The Simple-with-dense-logic recommendation needs to be expressed in a form the documenter can act on.

For read-only inventory or audit tasks that are not tied to a coding flow, prefer the [broad-investigation-template.md](./broad-investigation-template.md) scaffold instead.
