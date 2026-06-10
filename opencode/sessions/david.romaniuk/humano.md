# Human Profile

> **SOURCE FILE**: This is the master copy. Edit here, then sync to sessions.
> **Location**: `~/.config/opencode/humans/david.romaniuk/humano.md`

## Identity
- **ID**: david.romaniuk
- **Name**: David Romaniuk
- **Language**: es-AR (Spanish - Argentina)
- **OS Username**: david.romaniuk

## Communication Preferences
- **Detail Level**: summary
- **Show Thinking**: false
- **Preferred Tone**: Neutral/Professional (agent does NOT imitate human's colloquialisms)

## Session Naming Rules
- **Format**: DDMMYYYY-keywords
- **Keywords Style**: kebab-case
- **Max Keywords**: 2-4

## Translation Dictionary

> **IMPORTANT**: This dictionary is used ONLY for accurate translation between es-AR and English.
> The agent does NOT use these terms when speaking to the human. The agent speaks in neutral/professional es-AR.

### Slang/Colloquialisms (es-AR) → English Translation

| Term (es-AR) | Standard Meaning | English Translation | Context/Notes |
|---------------|------------------|---------------------|---------------|
| che | (interjection) | (no translation) | Used to get attention, very common in Argentina |
| no anda | doesn't work | is failing / doesn't work | Common way to say something is broken |
| tira | throws/returns | returns / throws | Used for HTTP responses or errors |
| raro | unusual | unusual / unexpected | When something behaves unexpectedly |
| laburar | to work | to work | Colloquial verb for "to work" |
| quilombo | mess/problem | mess / complicated situation | Very informal, means a big problem |
| barbaridad | amazing/terrible | (depends on context) | Can be positive or negative depending on tone |
| boludo | dude/idiot | (depends on context) | Very informal, can be friendly or offensive |
| posta | truth | truth / really | "La posta" = the truth |
| cheto | fancy/premium | fancy / premium | Used for high-quality or expensive things |
| tema | issue/topic | issue/topic | Generic reference to a problem or subject |
| no deberia | should not happen | should not | Expected behavior mismatch |
| te deja entrar | allows access | lets you enter | Access/auth behavior |

### Technical Terms (Project-Specific)

| Term | Meaning | English Translation | Confidence |
|------|---------|---------------------|------------|
| login | inicio de sesión/autenticación | login/authentication | high |
| administracion | área administrativa protegida | administration area | high |
| refresca la pagina | recarga/navegación posterior al bootstrap | page refresh / post-bootstrap reload | medium |

## Dictionary Health

| Metric | Value | Status |
|--------|-------|--------|
| Total Slang Terms | 13 | OK (Compact) |
| Total Tech Terms | 3 | OK (Compact) |
| Last Updated | 2026-06-10 | - |

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
- All communication to the human is in neutral/professional es-AR
- Slang terms are specific to Argentina (es-AR), may not apply to other Spanish variants
- This dictionary is ONLY for translation, not for style matching
