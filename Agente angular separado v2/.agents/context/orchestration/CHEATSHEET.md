---
last_updated: 2026-05-09
status: ACTIVE
purpose: "Day 1 onboarding guide for new agents"
tags: [cheatsheet, quick-reference, routing, decision-tree, onboarding]
---

# Day 1 Onboarding — Agent Quick Start

## 5-Phase Pipeline
1. **Initiation** (`p3-ia-analyzer`) — Extract metadata, clues, success criteria.
2. **Exploration** (`p3-ia-explorer`) — Map affected files, identify complex components.
3. **Context Supply** (`p3-ia-supplier`) — Filter docs to minimize token usage.
4. **Proposal** (`p3-ia-proposer`) — Create implementation plan with Hot Spots.
5. **Verification** (`p3-ia-verifier`) — Run tests, validate, extract lessons.

### Fast Paths
| Intent | Route | When |
|---|---|---|
| Read-only question | `Ask` agent | No file changes |
| Scope discovery | `Explore` agent | Locate files/deps |
| PR review | `pr-reviewer` agent | Diff assessment |
| Doc-only update | `Documentador` agent | No build/test/lint gate |

---

## Top 5 Anti-Patterns (NEVER)
| Anti-Pattern | Use Instead |
|---|---|
| `setTimeout` in components | RxJS timers or Signals |
| Manual `.subscribe()` | `toSignal()` or `rxResource()` |
| Constructor injection | `inject()` |
| Massive library imports | Specific imports only |
| Components >900 lines | Decompose |

### Angular v21+ Quick Reference
- **Inputs**: `input<T>()` / `input.required<T>()`
- **Outputs**: `output<T>()` over `EventEmitter`
- **DI**: `inject(Service)` not constructor
- **Async**: `rxResource` over Promises/manual subscriptions

Full rules: [rules.md](../project/rules.md) · [coding-conventions.md](../standards/coding-conventions.md)

---

## Doc Pillars
| Pillar | Folder | Purpose |
|---|---|---|
| **Orchestration** | `context/orchestration/` | Entry points, routing, persona, flow |
| **Project** | `context/project/` | SafeGuard rules, design, architecture, API |
| **Standards** | `context/standards/` | Angular v21+ conventions, reactivity, testing |
| **Memory** | `context/memory/` | Task history, patterns, troubleshooting, backlog |

## Key Entry Points
- **Component Map**: [AGENTS.md](AGENTS.md)
- **Tag Lookup**: [_TAG-INDEX.md](_TAG-INDEX.md) → [P1](tags-p1.md) · [P2](tags-p2.md) · [P3](tags-p3.md)
- **Skills Index**: [SKILLS_INDEX.md](../../skills/SKILLS_INDEX.md)
- **Routing**: [orchestrate.md](../../workflows/orchestrate.md)
- **Common Errors**: [common-errors.md](../memory/troubleshooting/common-errors.md)

---

## Decision Tree: "What does the user want?"
| User intent | File | Skill |
|---|---|---|
| "Where is X?" / "Explain Y" | [AGENTS.md](AGENTS.md) → Component Map | `Ask` |
| Fix a bug / error | [orchestrate.md](../../workflows/orchestrate.md) | `p3-ia-analyzer` |
| Build a new feature | [new-feature.md](../../workflows/new-feature.md) | `SDD Agent` |
| Write/update docs | [AGENTS.md](AGENTS.md) → Maintenance | `Documentador` + `p3-ia-docs-gen` |
| Review a PR / branch | [github-pr-fetch.md](github-pr-fetch.md) | `pr-reviewer` + `p2-review-analysis` |
| Verify existing code | [rules.md](../project/rules.md) | `Reviewer` + `p3-ia-verifier` |
| Look up by keyword | [_TAG-INDEX.md](_TAG-INDEX.md) | — |
| External API / docs | — | `WebSearch` + `p3-ia-search` |

## Before Any Task
1. [ ] Check [AGENTS.md](AGENTS.md) → Component Map
2. [ ] If no doc, check tag dictionary: [tags-p1](tags-p1.md) / [tags-p2](tags-p2.md) / [tags-p3](tags-p3.md)
3. [ ] Load `p3-ia-analyzer` for prompt clarity
4. [ ] Apply [rules.md](../project/rules.md) guardrails
5. [ ] Route via [orchestrate.md](../../workflows/orchestrate.md)
