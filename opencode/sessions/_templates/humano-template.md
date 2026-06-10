# Human Profile

> **SOURCE**: This file is COPIED from `~/.config/opencode/humans/{{HUMAN_ID}}/humano.md`
> **SYNC**: Changes to this file should be made in the source, then synced here.

## Identity
- **ID**: {{HUMAN_ID}}
- **Name**: {{HUMAN_NAME}}
- **Language**: {{LANGUAGE}}
- **OS Username**: {{OS_USERNAME}}

## Communication Preferences
- **Detail Level**: {{DETAIL_LEVEL}} (summary | full)
- **Show Thinking**: {{SHOW_THINKING}} (true | false)
- **Preferred Tone**: Neutral/Professional (agent does NOT imitate human's colloquialisms)

## Session Naming Rules
- **Format**: {{SESSION_NAME_FORMAT}} (e.g., DDMMYYYY-keywords)
- **Keywords Style**: {{KEYWORDS_STYLE}} (e.g., kebab-case)
- **Max Keywords**: {{MAX_KEYWORDS}} (e.g., 2-4)

## Translation Dictionary

> **IMPORTANT**: This dictionary is used ONLY for accurate translation between the human's language and English.
> The agent does NOT use these terms when speaking to the human. The agent speaks in neutral/professional {{LANGUAGE}}.

### Slang/Colloquialisms → Standard Translation

| Term (Human's Language) | Standard Meaning | English Translation | Context/Notes |
|-------------------------|------------------|---------------------|---------------|
| {{SLANG_TERM_1}} | {{STANDARD_MEANING_1}} | {{ENGLISH_TRANSLATION_1}} | {{CONTEXT_1}} |
| {{SLANG_TERM_2}} | {{STANDARD_MEANING_2}} | {{ENGLISH_TRANSLATION_2}} | {{CONTEXT_2}} |
| ... | ... | ... | ... |

### Technical Terms (Project-Specific)

| Term | Meaning | English Translation | Confidence |
|------|---------|---------------------|------------|
| {{TECH_TERM_1}} | {{TECH_MEANING_1}} | {{TECH_ENGLISH_1}} | {{CONFIDENCE_1}} (high/medium/low) |
| {{TECH_TERM_2}} | {{TECH_MEANING_2}} | {{TECH_ENGLISH_2}} | {{CONFIDENCE_2}} (high/medium/low) |
| ... | ... | ... | ... |

## Dictionary Health

| Metric | Value | Status |
|--------|-------|--------|
| Total Slang Terms | {{SLANG_COUNT}} | {{SLANG_STATUS}} (OK/Growing/Large) |
| Total Tech Terms | {{TECH_COUNT}} | {{TECH_STATUS}} (OK/Growing/Large) |
| Last Updated | {{LAST_UPDATED}} | - |

### Health Thresholds
- **0-50 terms**: Compact (OK) - Continue adding
- **51-100 terms**: Growing - Be selective
- **101+ terms**: Large - Alert human, suggest pruning

## Vocabulary vs Domain Dictionary

> **Important distinction**: This file contains the human's personal vocabulary for translation purposes.
> Domain-specific technical terms should be documented in `project.md` under "Project Slang".

| | `humano.md` (this file) | `project.md` |
|---|---|---|
| **What** | Human's personal vocabulary for translation | Project domain terms |
| **Who uses** | This human only | Any agent working on this project |
| **Git** | Ignored (personal) | Committed (shared) |
| **Examples** | "che", "no anda", "laburar" | "rxResource", "OnPush", "standalone" |

If a term is about the **project domain**, it goes in `project.md`.
If a term is about **how this human talks**, it goes in `humano.md`.

## Notes
- The dictionary is updated incrementally when new recurrent/ambiguous terms are detected
- The agent NEVER imitates the human's speaking style
- All communication to the human is in neutral/professional {{LANGUAGE}}
- This dictionary is ONLY for translation, not for style matching
