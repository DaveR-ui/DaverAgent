<!-- @INDEX
domain: opencode
type: guide
level: advanced
topics: skill-patterns,best-practices,skill-design
keywords: skill,pattern,design,best-practices
-->

# Skill Modular Pattern

Reference document for creating portable, self-contained skill modules in OpenCode.

## Origin

Based on the [Anthropic skill-creator](https://github.com/anthropics/skills/tree/main/skills/skill-creator) pattern, which bundles skills with agents, scripts, references, and assets in a single directory.

## Module Structure

```
module-name/
├── README.md                          ← Module documentation
├── SKILL.md                           ← Module overview skill (optional)
├── agent/
│   └── <orchestrator>.md              ← Main agent definition
├── subagents/
│   ├── <subagent-1>.md                ← Specialized subagents
│   └── <subagent-2>.md
├── skills/
│   ├── <skill-1>/
│   │   └── SKILL.md                   ← Navigator/strategy skills
│   ├── <skill-2>/
│   │   └── SKILL.md
│   └── <skill-3>/
│       ├── SKILL.md
│       └── assets/                    ← Templates, resources
│           └── template.md
├── docs/                              ← Bundled documentation
│   ├── <domain-1>/
│   └── <domain-2>/
└── install/
    └── install.bat                    ← Installation script
```

## Key Principles

### 1. Self-Contained
Everything the module needs lives inside it: agents, skills, docs, templates. No external dependencies.

### 2. Portable
Copy the entire folder to any project and run the install script. Works immediately.

### 3. Layered Discovery
- **SKILL.md** (metadata) - Always in context (~100 words)
- **SKILL.md body** - Loaded when skill triggers (<500 lines)
- **Bundled resources** - Read on demand (unlimited)

### 4. Agent-Skill Separation
- **Agents** (`.md` files) define behavior and personality
- **Skills** (`SKILL.md`) define strategy and knowledge
- Agents load skills via the `skill` tool when needed

## Creating a New Module

### Step 1: Define the Domain
What knowledge area does this module cover? (e.g., "OpenCode config", "GitHub docs", "Database migrations")

### Step 2: Create the Structure
```bash
mkdir -p module-name/{agent,subagents,skills/{skill-1,skill-2},docs,install}
```

### Step 3: Write the Agent
```markdown
---
description: Clear, actionable description
mode: subagent
model: qwen/qwen3.6-plus
temperature: 0.2
tools:
  write: true
  edit: true
  bash: true
  read: true
  skill: true
  task: true
permission:
  skill:
    skill-1: allow
    skill-2: allow
  task:
    subagent-1: allow
    subagent-2: allow
---

# Agent Name

You are a specialized [domain] agent...

## How to Work
1. Load the appropriate skill
2. Search the documentation
3. Invoke subagent if needed
```

### Step 4: Write the Skills
Each skill should contain:
- **What it does** - Clear description
- **When to use it** - Triggering contexts
- **Search strategy** - How to navigate the docs
- **Key patterns** - Common configurations
- **Rules** - Constraints and guidelines

### Step 5: Bundle Documentation
Copy all relevant docs into `docs/`. The module should work without external files.

### Step 6: Create Install Script
```batch
@echo off
set "ROOT=%~dp0.."
set "OPENCODE=%ROOT%\.opencode"

copy /Y "%ROOT%\module-name\agent\*.md" "%OPENCODE%\agents\"
copy /Y "%ROOT%\module-name\subagents\*.md" "%OPENCODE%\agents\subagents\"
xcopy /E /I /Y "%ROOT%\module-name\skills\*" "%OPENCODE%\skills\"
xcopy /E /I /Y "%ROOT%\module-name\docs\*" "%OPENCODE%\docs\"
```

## Existing Modules

### Explorer Module
- **Location**: `explorer/`
- **Purpose**: Documentation navigation for OpenCode and GitHub/VS Code
- **Agents**: `doc-explorer`, `opencode-expert`, `github-expert`
- **Skills**: `opencode-navigator`, `github-navigator`, `subagent-generator`
- **Docs**: Complete OpenCode + GitHub/VS Code documentation

## Lessons Learned

1. **Name conflicts**: Check existing agent names before creating new ones (e.g., `explorer` already existed for codebase exploration, so we used `doc-explorer`)
2. **Skill names must match directory names**: `opencode-navigator/` → `name: opencode-navigator`
3. **Keep SKILL.md under 500 lines**: Use references/ for large content
4. **Bundle docs, don't reference**: Makes the module truly portable
5. **Install script should be idempotent**: Use `/Y` flag to overwrite without prompting
