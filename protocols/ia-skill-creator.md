# Protocol: IA Skill Creator

Meta-protocol: scaffold a new agent protocol file under `.opencode/protocols/` and register it in the index. Mirrors the original skill-creation flow but targets the opencode-protocol tree.

> Transformed on 2026-08-06 from the retired frontend skill `p3-ia-skill-creator`. Note: the opencode runtime now provides native equivalents for several of these roles (interpreter subagent ≈ analyzer, explorer subagent ≈ explorer, tester/reviewer ≈ verifier, prompt-pipeline ≈ proposer). This protocol is kept as the detailed reference for the original pipeline stage; when it conflicts with opencode native agents/protocols, the native ones win.

## When to apply

When a new agent-system convention or template needs to be codified as a protocol. The output is a single `.md` file under `.opencode/protocols/` plus a row in `.opencode/protocols/README.md`.

## Governance filter (pre-creation check)

Before creating a new protocol, validate:

1. **Deduplication scan** — search `.opencode/protocols/` for existing protocols that solve the same problem.
2. **Granularity check** — is the task large enough to justify a protocol (more than 5 steps or shared across multiple agents)? If it is a small pattern, add it to the relevant existing protocol or to `docs/context/rules.md` instead.
3. **Conflict search** — does the new protocol contradict any rule in the existing protocol set or in `docs/context/rules.md`?
4. **Governance question** — "I found [X] existing protocol(s). This new protocol is different because [Reason]. Should I proceed or update the existing one?"

## Requirements gathering

Before generating files, gather:

- **Protocol name** — lowercase-hyphenated, prefixed (e.g. `ia-analyzer`, `broad-investigation-template`).
- **Scope** — agent-system vs. project-domain. Agent-system protocols live under `.opencode/protocols/`; project-domain protocols live under `docs/protocols/`.
- **Trigger** — when exactly should this protocol be consulted.
- **Domain** — what specific problem does it solve (e.g. installation, recovery, audit, subagent authoring).

## Scaffolding generation

Create the following file structure:

- `📄 .opencode/protocols/<protocol-name>.md` — the protocol body.
- `📂 .opencode/protocols/references/<protocol-name>/` (optional) — for deep technical details (> 500 lines). Existing example: `references/p3-ia-dev/`.

## Protocol body template

Generate the content using this mandatory structure:

- **Title** — `# Protocol: <Name>`.
- **Subtitle** — one or two sentences describing the purpose (this is the "description" the README index table picks up).
- **Provenance note** — only for protocols transformed from legacy skills; see the [catalog-manager](./ia-catalog-manager.md) transformation flow.
- **When to apply** — when this protocol is consulted.
- **Process / Instructions** — numbered steps the agent should follow.
- **Decision rules** — if/then logic and safety guards.
- **Output format** — explicit definition of what the agent returns.
- **Constraints** — prohibitions and mandates.
- **Integration** — links to the native opencode subagents or protocols that overlap with this one.
- **Notes** — anything the agent should know but that does not fit the structure above.

## Automated registration

Immediately after creation, update:

- `.opencode/protocols/README.md` — add a row to the Index table (Protocol | Purpose | Who reads it) following the existing format.
- If the protocol defines a routable convention, also add a row to the relevant section in the parent doc (e.g. `agent-installer.md` if the protocol covers an installer phase).

## Decision rules

- **Reference guard** — NEVER reference legacy paths (e.g. `.github/`); all internal links must use `.opencode/` or `docs/` prefixes.
- **Deduplication** — check the index table first. If a similar protocol exists, suggest an update instead of a new creation.
- **Lean content** — keep the generated protocol under 10,000 characters where practical.
- **Folder-first** — if the protocol logic is dense, create a `references/<protocol-name>/` subfolder and link from the main file (see [ia-dev](./ia-dev.md) for an example).

## Output format

Return a Creation Report:

- **Confirmation** — list of folders and files created.
- **Registration status** — confirmation of entry in `.opencode/protocols/README.md`.
- **Next step** — invitation to the user to "review the protocol and run a test case to validate it end-to-end."

## Constraints

- **PROHIBITED**: creating a protocol without registering it in the index.
- **PROHIBITED**: referencing legacy paths (e.g. `.github/`) in any generated content.
- **MANDATORY**: including at least one practical example in the generated protocol.
- **MANDATORY**: linking the new protocol from any existing protocol that references the same role.

## Integration

This protocol is the agent-system counterpart of [ia-docs-gen](./ia-docs-gen.md) (which targets `docs/`). Use [ia-catalog-manager](./ia-catalog-manager.md) when the operation also spans multiple indexes (e.g. a rename that touches both `docs/project.md` Slices and `.opencode/protocols/README.md`).
