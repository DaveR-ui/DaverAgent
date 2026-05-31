---
name: doc-architect
description: Procedures for maintaining, registering, and propagating documentation changes across the AI-Ready ecosystem.
---

# Doc-Architect Skill

Use this skill when creating new documentation files, moving existing ones, or updating the project's strategic core. This ensuring the "AI-Ready" status is maintained through proper linkage and discovery.

## 1. Documentation Propagation Rule (The Triad)
Every time a new strategic file is added to `.agent/context/`, you **MUST** update the following three files to ensure the new knowledge is discoverable:

1.  **`AGENT.md`**: Add the file to the "Strategic Core" list with a brief description.
2.  **`.agent/workflows/orchestrate.md`**: Update the "Thinking Rules" if the new documentation introduces new constraints or architectural knowledge.
3.  **`.agent/context/blueprint.md`**: Link the new file in the relevant category (Infrastructure, Persistence, Vision, etc.) to maintain the master bird's-eye view.

## 2. Technical Standards
*   **Language**: **Strict English** for all content, titles, and comments.
*   **Format**: Clean Markdown with a Table of Contents if the file exceeds 50 lines.
*   **Naming**: Use kebab-case for filenames (e.g., `api-security-policy.md`).

## 3. Registration Process
When registering a new doc:
1.  **Placement**: Strategic context goes into `.agent/context/`. Operational steps go into `.agent/workflows/` or `.agent/skills/`.
2.  **Cross-Linking**: Use relative paths (e.g., `[label](./other-file.md)`) to allow agents to navigate without absolute paths.
3.  **Verbalization**: Inform the user about the propagation steps taken.

## 4. Maintenance Checklist
*   [ ] Does `AGENT.md` point to it?
*   [ ] Is it integrated into the `orchestrate.md` thinking flow?
*   [ ] Is it represented in the `blueprint.md` technical vision?
*   [ ] Are all absolute paths avoided in internal links?
