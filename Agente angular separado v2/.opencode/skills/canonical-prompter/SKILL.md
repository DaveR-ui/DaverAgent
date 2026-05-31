---
name: canonical-prompter
description: Transforms raw prompts into structured, actionable prompts with clear classification, acceptance criteria, and development context. Use when a prompt needs to be analyzed, classified, and enhanced before development work begins.
license: MIT
metadata:
  audience: developers
  workflow: prompt-enhancement
---

## What I Do

- **Classify prompts** into one of four types: `bug`, `task`, `feature-design`, `update`
- **Enhance prompts** by adding missing context, acceptance criteria, and edge cases
- **Preserve the original prompt** verbatim for traceability
- **Output a canonical prompt** that is clear, actionable, and ready for development

## When to Use Me

Use this skill when:
- A raw prompt arrives that needs to be structured before development
- You need to classify what type of work is being requested
- The prompt is vague and needs clarification and expansion
- You want consistent prompt formatting across all development tasks

## Classification Rules

### `bug`
- Something is broken, not working as expected, or causing errors
- Keywords: error, crash, broken, not working, fails, issue, fix
- Output includes: reproduction steps, expected vs actual behavior, error logs

### `task`
- A specific piece of work that needs to be done
- Keywords: add, remove, change, update, refactor, clean, migrate
- Output includes: clear steps, success criteria, constraints

### `feature-design`
- A new capability or functionality to be designed
- Keywords: new, create, design, implement, build, feature
- Output includes: user stories, acceptance criteria, design considerations

### `update`
- An existing feature or component needs modification or improvement
- Keywords: improve, optimize, enhance, modify, adjust, upgrade
- Output includes: current state, desired state, migration path

## Prompt Enhancement Template

```markdown
## Canonical Prompt

### Type
[bug | task | feature-design | update]

### Original Prompt
[Exact original text - preserved verbatim]

### Enhanced Prompt
[Clear, detailed description of what needs to be done]

### Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

### Context
- Project: [from project.md]
- Relevant areas: [identified from prompt]

### Edge Cases to Consider
- [Edge case 1]
- [Edge case 2]

### Constraints
- [Any technical or business constraints]
```

## Process

1. **Receive input**: Original prompt + project context (from project.md)
2. **Classify**: Determine the prompt type based on content and intent
3. **Analyze gaps**: Identify missing information, unclear requirements, or edge cases
4. **Enhance**: Fill in gaps with reasonable assumptions or ask clarifying questions
5. **Output**: Return the structured canonical prompt

## Clarification Protocol

If the prompt is too vague or missing critical information:
1. List the specific clarifications needed
2. Provide examples of what information would help
3. Do NOT proceed with enhancement until clarifications are resolved

## Examples

### Input
```
"Fix the login page"
```

### Output
```markdown
## Canonical Prompt

### Type
bug

### Original Prompt
Fix the login page

### Enhanced Prompt
Investigate and resolve the issue preventing users from successfully logging in through the login page. Identify the root cause, implement a fix, and verify the login flow works correctly.

### Acceptance Criteria
- [ ] User can log in with valid credentials
- [ ] User sees appropriate error with invalid credentials
- [ ] Session is properly established after login
- [ ] No console errors in browser dev tools

### Context
- Project: [from project.md]
- Relevant areas: Authentication module, Login page component, Session management

### Edge Cases to Consider
- Network timeout during login
- Expired session tokens
- Special characters in credentials
- Concurrent login attempts

### Constraints
- Must not break existing session management
- Must maintain backward compatibility with existing users
```
