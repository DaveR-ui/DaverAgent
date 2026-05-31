---
name: pr-analysis
description: Analyzing Pull Requests from GitHub, fetching diffs, determining file changes, and reviewing code against strict project rules. Trigger this when asked to review a PR or branch changes.
---

# 🛠️ Skill: GitKraken PR Analysis & Code Review

## 🎯 Purpose
Provides instructions and patterns for fetching branch changes from GitHub, evaluating the differences, and checking the code against architectural rules (especially for new components vs bug fixes).

## 📋 Execution Workflow

When asked to review a PR or branch changes, follow this exact sequence:

### 1. Fetch PR Changes
Use the GitHub CLI (`gh`) via your `bash` tool to get the PR information.
- See `.agents/context/orchestration/github-pr-fetch.md` for the exact commands to fetch the file list and diff.

### 2. Categorize the Changes
Look at the files changed:
- **New Component**: Are there brand new `.ts`, `.html`, or `.scss` files created for a component?
- **Old Component / Bug Fix**: Are existing files just being modified? (Rules for this will be processed differently).

### 3. Evaluate Against Rules
Apply the corresponding rule set based on the categorization:
- **For New Components**: Read and strictly apply the rules found in `.agents/skills/p2-review-analysis/references/rules-new-component.md`.
- **For Old Components / Bug fixes**: Read and strictly apply the rules found in `.agents/skills/p2-review-analysis/references/rules-bug-fix.md`.

### 4. Generate the Review Report
Respond to the user structuring your feedback strictly under these headers (in Spanish, as defined by the rules):

* **🚨 CRÍTICOS (CRITICAL)**: (Only applicable for new components) Report blockers.
* **⚠️ ADVERTENCIAS (WARNING)**: Report code smells, legacy patterns that need refactoring, or banned patterns depending on the context.
* **💡 IDEAS (RECOMMENDATIONS)**: Provide architectural and documentation suggestions.
* **📝 RESUMEN Y VALIDACIÓN**: (Always include this at the end) Provide a brief summary of what the user did and ask if it matches their assigned User Story/Task.

Ensure you clearly state whether the PR introduces new components or modifies existing ones before listing the feedback.