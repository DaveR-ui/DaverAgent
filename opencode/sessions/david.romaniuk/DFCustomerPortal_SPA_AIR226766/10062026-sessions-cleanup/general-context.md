# General Context - Session 10062026-sessions-cleanup

## Session Metadata
- **Session ID**: 10062026-sessions-cleanup
- **Session Name**: 10062026-sessions-cleanup
- **Created**: 2026-06-10
- **Human**: david.romaniuk
- **Project**: DFCustomerPortal_SPA_AIR226766
- **Status**: completed (pending | in_progress | completed | cancelled)

## Original Prompt (Verbatim)

> **Language**: es-AR
> **Note**: This is the EXACT prompt as received from the human, in their original language.

```
revisar la ruta de .config, donde se guardan las sessiones, humano.md, y project.md. Revisar la estructura y checkear q sea consistente. Si se le puede meter alguna mejora, genial.
```

## Prompt Classification
- **Type**: task (bug | task | feature-design | update | question | other)
- **Priority**: medium (high | medium | low)
- **Complexity**: moderate (simple | moderate | complex)

## Enhanced Description (English Translation)

> This is the English translation of the prompt, enhanced for clarity and actionability.
> Used by the Orchestrator and subagents.

Review the ~/.config/opencode/sessions/ directory structure for consistency. Check that humano.md, project.md, and session folders follow the documented conventions. Identify and fix any inconsistencies, drift, or missing files. Apply improvements where possible.

## User Hints/Clues

> Additional context provided by the human, either explicitly or inferred from the prompt.

The human wants a full audit and cleanup pass. Improvements are welcome ("si se le puede meter alguna mejora, genial").

## Attachments

| Filename | Type | Size | Processing Status | Notes |
|----------|------|------|-------------------|-------|

## Initial Affected Modules (Guess)

> Preliminary identification of modules that may be affected. Refined by Context Reducer.

- `~/.config/opencode/humans/` - Human profile folders
- `~/.config/opencode/projects/` - Project context folders
- `~/.config/opencode/sessions/` - Session structure, templates, README

## Session Outputs

### Enhanced Prompt (from Prompt Enhancer)
- **File**: `enhanced-prompt.md`
- **Status**: completed (pending | completed)

### Scope (from Context Reducer)
- **File**: `scope.md`
- **Status**: completed (pending | completed)

## Communication Log

> Summary of key communications with the human.

| Timestamp | Direction | Summary |
|-----------|-----------|---------|
| 2026-06-10 | Human → Agent | Request to review and fix sessions directory consistency |
| 2026-06-10 | Agent → Human | Plan: rename folders, merge humano.md, update project.md, fix README, create scripts, add test session |

## Notes
- The original prompt is preserved verbatim for audit purposes
- English translation is optimized for agent comprehension
- Attachment processing follows rules: text → transcribe, frontend image → coordinate once, diagram → describe + confirm, text screenshot → transcribe
