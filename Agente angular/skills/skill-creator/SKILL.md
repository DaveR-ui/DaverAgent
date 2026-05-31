---
name: skill-creator
description: Create new skills, explain the skill system, modify and improve existing skills, and measure skill performance. Use this when the user asks how to create a skill, what a skill is, or how the skill system works in this repository.
---

# 🛠️ Skill Creator & Guide

**Core loop:** Draft skill → run test cases → user reviews → improve → repeat.

If the user is asking **what a skill is** or **how to create one**, act as the guide for the repository's Skill System. 

---

## 🧭 Explaining the Skill System to Humans

If the user asks "How do I create a skill?", "What is a skill?", or "How does this work?", explain the following concepts clearly:

1. **What is a Skill?** A skill is a self-contained module of knowledge (rules, templates, scripts) that the AI loads on-demand to perform specific tasks without overwhelming its context window.
2. **How are they structured?** Skills live in `.github/skills/<skill-name>/`. Every skill MUST have a `SKILL.md` file acting as its brain.
3. **How to create one?** Tell the user they can just ask *you* (the AI) to create it by providing the rules/context, or they can do it manually by creating the folder, the `SKILL.md` file, and registering it in `.github/skills/SKILLS_INDEX.md`.

---

## 1. Writing the SKILL.md

**Structure:**
```
skill-name/
├── SKILL.md              ← YAML frontmatter + instructions (<500 lines)
└── (optional)
    ├── scripts/          ← reusable executable helpers
    ├── references/       ← docs loaded on demand
    └── assets/           ← templates, icons, etc.
```

**Frontmatter fields:**
- `name` — skill identifier
- `description` — the primary trigger: what it does AND when to use it. Make it slightly "pushy" so Claude doesn't undertrigger.

**Registration:**
After creating a new skill, ALWAYS add it to the table in `.github/skills/SKILLS_INDEX.md` so it is officially registered.

**Clarify before writing:** What should it do? When should it trigger? What's the output? Does it need test cases?

**Writing tips:**
- Use imperative form. Explain *why*, not just what.
- Generalize; don't overfit to examples.
- If the SKILL.md approaches 500 lines, move detail into `references/` and link to it.
- Bundle reusable scripts in `scripts/`.

---

## 2. Running test cases

Come up with 2-3 realistic test prompts, confirm with the user, then run them. Save results in `<skill-name>-workspace/iteration-<N>/`.

For each eval, spawn **two subagents in the same turn** — one with the skill, one without (new skill) or against the old snapshot (improving). Don't stagger them.

Save `eval_metadata.json` per eval:
```json
{ "eval_id": 0, "eval_name": "descriptive-name", "prompt": "...", "assertions": [] }
```

**While runs are in progress**, draft verifiable assertions and explain them to the user. Update `evals/evals.json` and `eval_metadata.json`.

When runs finish, capture `total_tokens` / `duration_ms` from the task notification immediately into `timing.json` — it won't be available later.

---

## 3. Grading and viewing results

1. **Grade** — evaluate assertions against outputs, save `grading.json` with fields `text`/`passed`/`evidence`.
2. **Aggregate** — `python -m scripts.aggregate_benchmark <workspace>/iteration-N --skill-name <name>`
3. **Launch viewer:**
   ```bash
   python <skill-creator-path>/eval-viewer/generate_review.py \
     <workspace>/iteration-N --skill-name "my-skill" \
     --benchmark <workspace>/iteration-N/benchmark.json
   ```
   No display? Add `--static <output_path>` to write a standalone HTML file instead.
   Iteration 2+? Add `--previous-workspace <workspace>/iteration-<N-1>`.

Tell the user to review and submit feedback. Read `feedback.json` when they're done — empty feedback = looks good.

---

## 4. Improving the skill

- **Generalize** from feedback — avoid overfitting to specific examples.
- **Stay lean** — remove instructions that waste tokens without adding value.
- **Bundle repeated work** — if every test run independently wrote the same script, add it to `scripts/`.
- Rerun into `iteration-<N+1>/`, launch viewer with `--previous-workspace`, repeat.

Stop when the user is happy, feedback is empty, or progress stalls.

---

## 5. Description optimization (optional, Claude Code only)

After the skill is stable, offer to optimize its `description` for better triggering:

1. Generate 20 trigger eval queries (10 should-trigger, 10 should-not). Focus on tricky near-misses, not obvious cases. Review with the user before running.
2. Run the optimization loop:
   ```bash
   python -m scripts.run_loop \
     --eval-set <trigger-eval.json> --skill-path <skill> \
     --model <current-model-id> --max-iterations 5 --verbose
   ```
3. Apply `best_description` from the output to the SKILL.md frontmatter.

---

## 6. Package (if `present_files` available)

```bash
python -m scripts.package_skill <path/to/skill-folder>
```

