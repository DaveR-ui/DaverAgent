# Project Slang Snapshot

> **ROLE**: per-session project slang dictionary (lunfardo del proyecto).
> This is the ONLY per-session project document. It is NOT a copy of `docs/project.md`.
> The source-of-truth project info lives in `docs/project.md` and `docs/context/`.
> This snapshot is a dictionary in the same spirit as `humano.md`, but for the project domain: internal jargon, abbreviations, and how this codebase names things.

> **SOURCE PROJECT DOC**: `docs/project.md`
> **SESSION FOR**: `{human_id}/{project_id}/{session_id-keywords}`
> **LAST REVIEWED**: {{LAST_REVIEWED}}
> **NEXT REVIEW DUE**: {{NEXT_REVIEW_DUE}}
> **REVIEW CADENCE**: monthly (~30 days)

## How This File Differs From `humano.md`

| File | Scope | Subject |
|---|---|---|
| `humano.md` | How the human talks | Colloquialisms, slang, personal vocabulary in their language |
| `project.md` (this) | How the project names things | Internal jargon, abbreviations, model names, business terms |

Both files are **dictionaries for translation**, not style-matching guides. The agent does not imitate either.

## Project Slang

| Term | Meaning | Location (code) | Confidence |
|---|---|---|---|
| {{SLANG_1}} | {{MEANING_1}} | {{LOCATION_1}} | {{CONFIDENCE_1}} |
| {{SLANG_2}} | {{MEANING_2}} | {{LOCATION_2}} | {{CONFIDENCE_2}} |
| {{SLANG_3}} | {{MEANING_3}} | {{LOCATION_3}} | {{CONFIDENCE_3}} |

## How to Populate This File

1. **Infer from the codebase**: read `packages/schema/src/index.ts` and the barrel of `packages/core/src/<area>/` for canonical entity names; cross-reference `docs/project.md` (Domain Entities) and the slice READMEs under `docs/<slice>/<subslice>/README.md`.
2. **Listen to the human**: when the human uses a term that is not in this dictionary, check whether it matches a domain concept (a slice, a subslice, a V2 session term, or a feature). Add it if the human uses it more than once.
3. **Confidence levels**:
   - **High** — found in both `packages/` and used by the human consistently.
   - **Medium** — found in code only, or used by the human once.
   - **Low** — inferred from context, not yet confirmed.
4. **Update incrementally** as new terms are observed.

## Rules

- This file is per-session, but persists across sessions under `{human_id}/{project_id}/`.
- Do NOT copy `docs/project.md` here. The dictionary is for jargon, not metadata.
- If `docs/project.md` changes materially, refresh the **master** `projects/{project_id}/project.md`, not this snapshot.
- Keep the table compact: prune entries that the human no longer uses.
- When resolving ambiguous human terms, prefer canonical V2 session names from `CONTEXT.md` (e.g. "session context" -> `Session History`; "system prompt" -> `System Context`; "tool loop" -> `Session Drain`).

## Seed Examples (illustrative, to be cleared on first real use)

These illustrate the kind of opencode-specific jargon the snapshot is for. They are placeholders — replace them as the human's actual usage emerges.

| Term | Meaning | Location | Confidence |
|---|---|---|---|
| drain | one process-local execution span (Session Drain) | `packages/core/src/session/runner/` | High |
| admission | durable acceptance of a prompt before provider execution | `packages/core/src/session/v2.ts` (admit) | High |
| provider turn | one model request and the response projected from it | `packages/core/src/session/runner/llm.ts` | High |
| context epoch | span during which one rendered System Context remains the provider-cache baseline | `packages/core/src/system-context/` | High |
| HttpApi | authoritative public HTTP contract in `packages/server/src/api.ts` | `packages/server/src/api.ts` | High |
| sdk-next | in-process scoped host composing `client + core + server` | `packages/sdk-next/src/` | High |
