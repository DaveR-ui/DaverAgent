---
name: register-human-settings
description: Detects unknown vocabulary used by the user, asks for meaning, and records it in `.opencode/human/user.md`. Pure vocabulary learning - no identity, no communication preferences, no technical rules.
license: MIT
metadata:
  category: configuration
  workflow: vocabulary-learning
  phase: passive
---

## What I Do

- **Detect unknown words** during conversation - slang, abbreviations, local expressions
- **Ask for meaning** when a word is not understood
- **Record in `.opencode/human/user.md`** after confirmation
- **Use recorded vocabulary** in future conversations without asking again

## When to Use Me

Use this skill when:
- The user says a word the agent doesn't understand
- A word seems like local slang or abbreviation
- The user corrects the agent's interpretation of a word
- The user explicitly says "agregá [palabra] al vocabulario"

## Process

### Detection

During normal conversation, watch for:
- Words not in project dictionary and not in general vocabulary
- Expressions that seem like local slang
- Abbreviations used repeatedly
- Words the agent guessed wrong about

### Ask

When an unknown word is detected:

```
¿Qué significa "[palabra]"? ¿Querés que lo agregue al vocabulario?
```

Keep it simple. One question. No ceremony.

### Record

If the user confirms, add to `.opencode/human/user.md`:

```markdown
| [palabra] | [significado] | [nota opcional] |
```

### Acknowledge

```
Listo, registrado.
```

That's it. No summary, no table, no ceremony.

## Rules

1. **Only vocabulary** - no identity, no preferences, no rules
2. **One word at a time** - don't batch questions
3. **Don't be intrusive** - if the user ignores the question, drop it
4. **Don't ask about known words** - check the vocabulary table first
5. **Don't ask about domain terms** - those go in project-dictionary.md, not here
6. **Keep it simple** - the file is just a table, nothing else

## Integration with prompt-analyzer

The `prompt-analyzer` skill reads `.opencode/human/user.md` during term resolution:
- Checks the vocabulary table before flagging unknown terms
- If a word is in the table, resolves it automatically
- If not found, may ask the user and trigger this skill

## What This Skill Does NOT Do

- Does NOT ask for name, role, or identity
- Does NOT set communication preferences
- Does NOT define technical rules (those go in project rules)
- Does NOT set autonomy levels (context-reductor handles that)
- Does NOT track pet peeves or work style
- Does NOT run a questionnaire

## Vocabulary vs Domain Dictionary

| | `human/user.md` | `project-dictionary.md` |
|---|---|---|
| **What** | User's personal vocabulary | Project domain terms |
| **Who uses** | This user only | Any agent working on this project |
| **Git** | Ignored | Committed |
| **Examples** | "joya", "dale", "re" | "npd", "reverse proxy", "gcp" |

If a term is about the **project domain**, it goes in the dictionary.
If a term is about **how this user talks**, it goes in user.md.
