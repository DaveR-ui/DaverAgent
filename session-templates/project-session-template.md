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

1. **Infer from the codebase**: read the domain model files and seed data for canonical entity names.
2. **Listen to the human**: when the human uses a colloquial term, check if it matches a domain entity.
3. **Confidence levels**:
   - **High** - found in both domain models and used by the human consistently
   - **Medium** - found in code only, or used by the human once
   - **Low** - inferred from context, not yet confirmed
4. **Update incrementally** as new terms are observed.

## Rules

- This file is per-session, but persists across sessions under `{human_id}/{project_id}/`.
- Do NOT copy `docs/project.md` here. The dictionary is for jargon, not metadata.
- If `docs/project.md` changes materially, refresh the **master** `projects/{project_id}/project.md`, not this snapshot.
- Keep the table compact: prune entries that the human no longer uses.

## Example (illustrative, to be cleared on first real use)

| Term | Meaning | Location | Confidence |
|---|---|---|---|
| _example term_ | _what it means in this project_ | _path to model file_ | _High/Medium/Low_ |
