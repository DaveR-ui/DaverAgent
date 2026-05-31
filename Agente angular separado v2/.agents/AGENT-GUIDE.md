# .agents/ — Folder Structure & Index

This folder contains all AI agent context, workflows, and skills for this repository.
Agents are defined in `.opencode/agents/` (OpenCode native).
The authoritative entry point for OpenCode is `.opencode/agents/`.

## OpenCode Native Tool Mapping

| VSCode Tool | OpenCode Native | Usage |
| --- | --- | --- |
| `vscode/askQuestions` | Direct chat | Ask questions naturally in conversation |
| `vscode/memory` | `write` | Persist plans to `.agents/cache-session/<session-id>/session-plan.md` |
| `execute` | `bash` | Run commands via shell |
| `github.vscode-pull-request-github/*` | `bash` + `gh` CLI | Use `gh pr view`, `gh pr diff`, etc. |
| `agent` | `task` | Invoke subagents via the task tool |

## Agent Invocation in OpenCode

- **Primary agents**: Use **Tab** to cycle during a session
- **Subagents**: Invoke by **@ mentioning** them (e.g., `@sdd_agent plan this feature`)
- **Automatic**: Primary agents can invoke subagents via the `task` tool based on descriptions

## 🏗️ Structure

```
.agents/
├── AGENT-GUIDE.md             # You are here (entry point)
├── copilot-instructions.md    # Primary directive for GitHub Copilot
├── workflows/                 # Workflow definitions
│   ├── orchestrate.md         # Task routing reference
│   ├── new-feature.md         # Feature implementation steps
│   └── storybook.md           # Storybook setup guide
├── skills/                    # Skill definitions (35 skills)
│   ├── SKILLS_INDEX.md        # Master skill registry
│   ├── p1-framework-angular-component/
│   ├── p1-framework-angular-developer/
│   ├── p1-framework-angular-di/
│   ├── p1-framework-angular-directives/
│   ├── p1-framework-angular-testing/
│   ├── p1-framework-angular-tooling/
│   ├── p1-lang-typescript/
│   ├── p1-ref-compiler-cli/
│   ├── p1-ref-core/
│   ├── p1-ref-signal-forms/
│   ├── p1-review-angular/
│   ├── p1-test-playwright/
│   ├── p1-test-vitest/
│   ├── p2-design-frontend/
│   ├── p2-design-tailwind/
│   ├── p2-design-web/
│   ├── p2-docs-writing/
│   ├── p2-proj-details-gen/
│   ├── p2-proj-navigator/
│   ├── p2-quality-a11y/
│   ├── p2-quality-seo/
│   ├── p2-review-analysis/
│   ├── p2-ui-modal/
│   ├── p3-ia-analyzer/
│   ├── p3-ia-dev/
│   ├── p3-ia-docs-gen/
│   ├── p3-ia-explorer/
│   ├── p3-ia-learner/
│   ├── p3-ia-proposer/
│   ├── p3-ia-search/
│   ├── p3-ia-skill-creator/
│   ├── p3-ia-supplier/
│   ├── p3-ia-sync-checker/
│   └── p3-ia-verifier/
├── context/                   # Context documentation (4 subfolders)
│   ├── orchestration/         # Entry point docs
    │   │   ├── AGENTS.md          # Component-to-doc map (PRIMARY ENTRY)
    │   │   ├── _TAG-INDEX.md      # Routes to pillar tag dictionaries
    │   │   ├── tags-p1.md         # P1: Language & Framework tags
    │   │   ├── tags-p2.md         # P2: Project & SafeGuard tags
    │   │   ├── tags-p3.md         # P3: IA Orchestration tags
    │   │   ├── flow.md            # 5-phase pipeline diagram
    │   │   ├── github-pr-fetch.md # PR fetching commands
    │   │   └── persona.md         # IA mental model & communication
│   ├── project/               # Project-specific rules & design
│   │   ├── rules.md           # Standards, guardrails, anti-patterns
│   │   ├── architecture.md    # Angular architecture
│   │   ├── api-strategy.md    # API connection & proxy strategy
│   │   ├── deployment.md      # Docker setup
│   │   ├── modal-creation.md  # Modal patterns
│   │   ├── project-details.md # Technical stack SSOT
│   │   ├── api-contracts.md   # API contracts index
│   │   ├── api-contracts/     # Feature-specific contracts
│   │   ├── domain-logic.md    # Business terms and logic
│   │   ├── architecture-standards/ # SDD architecture docs
│   │   ├── design/            # SafeGuard identity, tokens, rules
│   │   └── special-components/ # Dropdowns, tooltips, confirmation modals
│   ├── standards/             # Language & framework standards
│   │   ├── coding-conventions.md  # Angular v21+ conventions
│   │   └── angular-reactivity/    # Signals, rxResource, testing
│   └── memory/                # Session continuity & backlog
│       ├── task-memory.md     # Recent milestones
│       ├── todo.md            # Backlog
│       └── troubleshooting/   # Common errors
├── cache-session/             # Session-specific cache (plans, memory)
│   └── <session-id>/          # Isolated folder per session
└── utils/
    └── notebooklm-context.ts  # NotebookLM context generator
```

## 🔄 Maintenance

- **Last Updated**: 2026-05-09
- **Status**: Active — OpenCode native agents in `.opencode/agents/`
- All documentation follows standards defined in [p3-ia-docs-gen/SKILL.md](skills/p3-ia-docs-gen/SKILL.md)
- The orchestrator and all new subagents must start with [skills/p3-ia-analyzer/SKILL.md](skills/p3-ia-analyzer/SKILL.md) for non-trivial tasks.
- OpenCode agents use native tools: `read`, `write`, `edit`, `bash`, `search`, `webfetch`, `task`

## 🔭 Ecosystem Gap To Track

The current network now covers read-only Q&A, scope discovery, post-implementation validation, orchestration, context packaging, documentation updates, and PR review — all using OpenCode native tools.

At this point, the core operating mesh is documented end-to-end and migrated from VSCode extensions to OpenCode native tooling.
