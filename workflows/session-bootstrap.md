---
description: Session management workflow - bootstrap, sync, and session creation
---

# Session Bootstrap Workflow

Instructions for preparing the session infrastructure before task execution.

## Purpose

This workflow handles all session-related setup:
- Verify/create the opencode home structure
- Sync human and project contexts
- Decide if a session is needed
- Create session structure if applicable

The delivery agent launches this workflow in parallel with prompt analysis, then combines results for routing.

## Inputs

1. **Human ID** - from environment or delivery handoff
2. **Project ID** - from environment or delivery handoff
3. **Prompt summary** - brief description for session naming (if session needed)
4. **Complexity estimate** - from delivery's initial assessment (Baja/Media/Media-Alta/Alta/Muy Alta)

## Process

### Phase 0: Bootstrap Check

**Goal**: Ensure the opencode home structure exists and is valid.

1. Run verification:
   ```powershell
   & ".\.opencode\scripts\bootstrap-opencode-structure.ps1" -VerifyOnly
   ```

2. If missing items detected:
   ```powershell
   & ".\.opencode\scripts\bootstrap-opencode-structure.ps1"
   ```

3. Verify critical paths exist:
   - `~/.config/opencode/humans/{human_id}/humano.md`
   - `~/.config/opencode/projects/{project_id}/project.md`
   - `~/.config/opencode/sessions/{human_id}/`

**Output**:
```markdown
### Phase 0 Result
- Structure status: OK | BOOTSTRAPPED | FAILED
- Missing items: [list if any]
- Bootstrap executed: yes | no
```

### Phase 1: Context Sync

**Goal**: Ensure human and project contexts are up-to-date.

1. **Sync humano.md**:
   ```powershell
   & ".\.opencode\scripts\sync-humano.ps1"
   ```
   - Source: `humans/{human_id}/humano.md`
   - Target: `sessions/{human_id}/humano.md`

2. **Sync project.md source**:
   ```powershell
   & ".\.opencode\scripts\sync-project.ps1"
   ```
   - Source: `docs/project.md` (repo)
   - Target: `projects/{project_id}/project.md` (opencode home)

3. **Verify session slang snapshot**:
   - Check if `sessions/{human_id}/{project_id}/project.md` exists
   - If missing, create from template (this is the project slang dictionary, NOT a copy of docs/)

4. **Load contexts**:
   - Read `sessions/{human_id}/humano.md` → extract slang terms count
   - Read `sessions/{human_id}/{project_id}/project.md` → extract project slang terms count

**Output**:
```markdown
### Phase 1 Result
- Human context: loaded (N slang terms)
- Project source: synced
- Project slang: loaded (M terms)
- Sync warnings: [if any]
```

### Phase 2: Session Decision

**Goal**: Determine if a session folder is needed for this task.

**Decision rules**:
- **Create session** if complexity is Media, Media-Alta, Alta, or Muy Alta
- **Skip session** if complexity is Baja (simple task, no need for artifacts)

**If creating session**:
1. Generate session ID: `DDMMYYYY-keywords`
   - Date: today's date in DDMMYYYY format
   - Keywords: 2-4 kebab-case words from prompt summary
   - Example: `26062026-session-workflow`

2. Check if session already exists:
   ```powershell
   Test-Path -LiteralPath "sessions/{human_id}/{project_id}/{session_id}"
   ```

3. If exists, append timestamp or ask delivery for alternative name

**Output**:
```markdown
### Phase 2 Result
- Session needed: yes | no
- Session ID: {session_id} | N/A
- Reason: [why session is/isn't needed]
```

### Phase 3: Session Creation (if applicable)

**Goal**: Create the session folder structure and initialize artifacts.

**If session needed**:

1. Create session directory:
   ```powershell
   & ".\.opencode\scripts\new-session.ps1" -SessionName "{session_id}"
   ```

2. Verify structure created:
   - `sessions/{human_id}/{project_id}/{session_id}/general-context.md`
   - `sessions/{human_id}/{project_id}/{session_id}/assets/`

3. Initialize agent manifest:
   ```markdown
   # Agent Manifest
   
   Session: {session_id}
   Created: {timestamp}
   
   ## Agent Outputs
   
   (will be populated as agents complete their work)
   ```
   Save to: `sessions/{human_id}/{project_id}/{session_id}/agents/manifest.md`

4. Process attachments (if any provided by delivery):
   - Copy to `sessions/{human_id}/{project_id}/{session_id}/assets/`
   - List in `general-context.md`

**If session NOT needed**:
- Skip this phase
- Report that task will proceed without session artifacts

**Output**:
```markdown
### Phase 3 Result
- Session path: {full_path} | N/A
- Files created: [list]
- Manifest initialized: yes | no
- Attachments processed: [list] | none
```

## Final Output

Combine all phase results into a structured report:

```markdown
# Session Bootstrap Report

## Status
OK | PARTIAL | FAILED

## Summary
- Structure: OK | BOOTSTRAPPED | FAILED
- Human context: loaded (N terms)
- Project slang: loaded (M terms)
- Session needed: yes | no
- Session path: {path} | N/A

## Phase Results

### Phase 0: Bootstrap Check
{phase 0 output}

### Phase 1: Context Sync
{phase 1 output}

### Phase 2: Session Decision
{phase 2 output}

### Phase 3: Session Creation
{phase 3 output}

## Warnings
- [any warnings from any phase]

## Ready for Handoff
- Session path: {path}
- Contexts loaded: yes
- Manifest ready: yes | N/A
```

## Error Handling

### Bootstrap fails
- Report FAILED status
- List missing items
- Suggest manual intervention or retry

### Sync fails
- Report PARTIAL status
- List which syncs succeeded/failed
- Continue with available contexts

### Session creation fails
- Report PARTIAL status
- List created files
- Suggest alternative session name or manual creation

## Integration

This workflow is executed by the `session-manager` subagent.

The delivery agent:
1. Launches `session-manager` with this workflow
2. Simultaneously runs `canonical-prompter` + `context-reductor`
3. Waits for both to complete
4. Combines results:
   - Session path + contexts (from session-manager)
   - Analysis + scope + complexity (from prompt analysis)
5. Makes routing decision based on combined data

## Notes

- This workflow is I/O-bound, not reasoning-heavy
- Use Gemini 3.5 Flash (cheap, fast) for the session-manager subagent
- All scripts are idempotent and non-destructive by default
- Session naming should be descriptive but concise (2-4 keywords max)
- The session slang snapshot is NOT a copy of docs/project.md; it's a per-human dictionary of project jargon
