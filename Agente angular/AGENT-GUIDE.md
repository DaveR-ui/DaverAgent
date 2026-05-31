# .github/ — Folder Structure & Index

This folder contains all AI agent context, workflows, and skills for this project.
The authoritative entry point is [AGENTS.md](agent-context/AGENTS.md).

## 🏗️ Structure

```
.github/
├── AGENT-GUIDE.md             # You are here (entry point)
├── agents/
│   ├── ask.agent.md           # Read-only Q&A and codebase navigation agent
│   ├── explore.agent.md       # Read-only scope discovery and evidence-mapping agent
│   ├── implementer.agent.md   # Validated-plan execution agent for code and tests
│   ├── reviewer.agent.md      # Post-implementation review and verification agent
│   ├── sdd.agent.md           # Direct coordination and bounded-slice routing agent
│   ├── supplier.agent.md      # Context packaging subagent
│   └── documentador.agent.md  # Documentation-only subagent (.github/ only)
├── agent-workflows/
│   ├── orchestrate.md         # Task routing reference for the SDD agent
│   └── removing-ngrx-store.md # ⚠️ NgRx migration guide (PRIORITY)
├── skills/
│   ├── prompt-analyzer/       # Mandatory startup prompt-clarity check
│   └── ...
└── agent-context/
    ├── project-rules.md      # Unified core standards, guards & anti-patterns
    ├── angular-reactivity/
    │   ├── index.md          # Decision guide, flowchart, tool summary
    │   ├── resource-api.md   # API patterns (rxResource standard, legacy httpResource compatibility, linkedSignal, computed)
    │   └── testing.md        # Testing rxResource, legacy httpResource, error states, computed
    ├── simple-features/
    │   ├── access-modal.md       # Access modal component flow
    │   └── discovery-wizard.md   # Discovery Wizard guide
    ├── special-components/
    │   ├── confirmation-modal.md # Confirmation / approval modal
    │   └── dropdown-components.md # All dropdown variants
    ├── launchdarkly-flags.md # LaunchDarkly flag management
    └── authviews/
        └── wizard-logic.md   # AuthView wizard state management
```

## 🔄 Maintenance

- **Last Updated**: 2026-05-12
- **Status**: Active
- All documentation follows standards defined in [skills/generate-documentation/SKILL.md](skills/generate-documentation/SKILL.md)
- The `sdd_agent` and all new subagents must start with [skills/prompt-analyzer/SKILL.md](skills/prompt-analyzer/SKILL.md) for non-trivial tasks.
- Cross-agent capability, routing, and output contracts are centralized in [agent-contracts.md](agent-workflows/agent-contracts.md).

## 🤖 Canonical Contracts

Use [agent-contracts.md](agent-workflows/agent-contracts.md) as the single cross-agent contract registry for:

1. Capability boundaries
2. Routing fast paths
3. Response section contracts
4. Freshness and drift checks

## 🧭 Routing By Intent

The canonical intent mapping lives in [agent-contracts.md](agent-workflows/agent-contracts.md#routing-fast-paths).

Use [orchestrate.md](agent-workflows/orchestrate.md) for routing procedure and [agent-contracts.md](agent-workflows/agent-contracts.md) for role boundaries.

## 📐 Shared Contract Pattern

The canonical shared shape now lives in [agent-contracts.md](agent-workflows/agent-contracts.md#shared-agent-shape).

Keep this guide focused on operator orientation, not duplicated contract tables.

## 🔭 Ecosystem Gap To Track

The current network now covers read-only Q&A, scope discovery, implementation execution, post-implementation validation, orchestration, context packaging, and documentation updates.

At this point, the core operating mesh is documented end-to-end.
