# General Context - Session {{SESSION_ID}}

## Session Metadata
- **Session ID**: {{SESSION_ID}}
- **Session Name**: {{SESSION_NAME}}
- **Created**: {{CREATED_AT}}
- **Human**: {{HUMAN_ID}}
- **Project**: {{PROJECT_ID}}
- **Status**: {{STATUS}} (pending | in_progress | completed | cancelled)

## Original Prompt (Verbatim)

> **Language**: {{PROMPT_LANGUAGE}}
> **Note**: This is the EXACT prompt as received from the human, in their original language.

```
{{ORIGINAL_PROMPT}}
```

## Prompt Classification
- **Type**: {{PROMPT_TYPE}} (bug | task | feature-design | update | question | other)
- **Priority**: {{PRIORITY}} (high | medium | low)
- **Complexity**: {{COMPLEXITY}} (simple | moderate | complex)

## Enhanced Description (English Translation)

> This is the English translation of the prompt, enhanced for clarity and actionability.
> Used by the Orchestrator and subagents.

{{ENHANCED_DESCRIPTION}}

## User Hints/Clues

> Additional context provided by the human, either explicitly or inferred from the prompt.

{{USER_HINTS}}

## Attachments

| Filename | Type | Size | Processing Status | Notes |
|----------|------|------|-------------------|-------|
| {{ATTACHMENT_1}} | {{TYPE_1}} | {{SIZE_1}} | {{STATUS_1}} | {{NOTES_1}} |
| {{ATTACHMENT_2}} | {{TYPE_2}} | {{SIZE_2}} | {{STATUS_2}} | {{NOTES_2}} |
| ... | ... | ... | ... | ... |

## Attachment Processing Log

> Detailed log of how each attachment was processed.

### {{ATTACHMENT_1}}
- **Type**: {{TYPE_1}}
- **Processing Method**: {{METHOD_1}}
- **Extracted Content**:
```
{{EXTRACTED_CONTENT_1}}
```
- **Memory Cost Decision**: {{MEMORY_DECISION_1}} (keep image | text only)
- **Coordination with Human**: {{COORDINATION_1}}

### {{ATTACHMENT_2}}
- **Type**: {{TYPE_2}}
- **Processing Method**: {{METHOD_2}}
- **Extracted Content**:
```
{{EXTRACTED_CONTENT_2}}
```
- **Memory Cost Decision**: {{MEMORY_DECISION_2}}
- **Coordination with Human**: {{COORDINATION_2}}

## Initial Affected Modules (Guess)

> Preliminary identification of modules that may be affected. Refined by Context Reducer.

{{AFFECTED_MODULES}}

## Session Outputs

### Enhanced Prompt (from Prompt Enhancer)
- **File**: `enhanced-prompt.md`
- **Status**: {{ENHANCED_STATUS}} (pending | completed)

### Scope (from Context Reducer)
- **File**: `scope.md`
- **Status**: {{SCOPE_STATUS}} (pending | completed)

## Communication Log

> Summary of key communications with the human.

| Timestamp | Direction | Summary |
|-----------|-----------|---------|
| {{TIMESTAMP_1}} | {{DIRECTION_1}} | {{SUMMARY_1}} |
| {{TIMESTAMP_2}} | {{DIRECTION_2}} | {{SUMMARY_2}} |
| ... | ... | ... |

## Notes
- The original prompt is preserved verbatim for audit purposes
- English translation is optimized for agent comprehension
- Attachment processing follows rules: text → transcribe, frontend image → coordinate once, diagram → describe + confirm, text screenshot → transcribe
