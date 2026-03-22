---
name: onboard
description: "Use when a new repo needs to be set up with founder-os, or when a stranger/new team member runs their first command. Triggers on 'onboard', 'set this up', 'bootstrap', 'initialize', 'new here', 'what is this project?'."
argument-hint: "[--force] [--dry]"
allowed-tools: Read, Bash, Grep, Glob, Edit, Write, AskUserQuestion
---

# /onboard

**This is the first thing a stranger does.** If this doesn't work, nothing else matters. One command, zero placeholders. Detect what the project is, understand what it does, and make the full system work.

The goal is **time to first value**. Stranger goes from `/onboard` to seeing a real score with real features in under 2 minutes.

## Skill folder structure

This skill is a **folder**, not just this file. Read these on demand:

- `scripts/detect-project.sh` — detects language, framework, key files, source structure
- `scripts/onboard-checklist.sh` — checks what's already set up (founder.yml? beliefs? features? scores?)
- `scripts/first-score.sh` — runs first score and explains what each number means
- `references/onboarding-flow.md` — the step-by-step flow with what happens at each step
- `templates/founder-yml-template.yml` — skeleton config with comments explaining each field
- `gotchas.md` — real failure modes. **Read before generating config.**

## Dry-run mode

`/onboard --dry` shows what WOULD be generated without writing any files. Use this to let users catch mis-detections before committing.

In dry-run mode: run detection, show proposed founder.yml + features + assertions + strategy, then stop. Print "Run `/onboard` to apply." No files written.

## When to ask

Use `AskUserQuestion` when detection is uncertain. Don't guess on high-impact decisions:

- **Monorepo structure** — multiple package.json or app directories detected, unclear which is the product
- **Custom framework** — no recognizable framework but substantial source code exists
- **Stage assessment** — code quality doesn't indicate maturity, ask about users/deployment
- **Feature weights** — if the value hypothesis is ambiguous, ask which features matter most
- **Value hypothesis** — if README + code don't make the user/value clear, ask directly

Prefer asking one well-formed question over generating wrong config that needs manual fixing.

## The protocol

### Step 1: Detect and check

Run in parallel:
```bash
bash scripts/detect-project.sh
bash scripts/onboard-checklist.sh
```

If checklist shows already initialized and `--force` not set: show what exists, suggest `--force` to regenerate.

### Step 2: Understand the product

Read the codebase to form an opinion. Read in parallel:
- README.md, package.json / pyproject.toml / go.mod / Cargo.toml
- Landing page or main layout (app/page.tsx, src/App.tsx, pages/index.*)
- Route structure (app/ or pages/ tree)
- 3-5 key source files from the main source directory
- Test files and CI config if they exist

Determine: **What is this?** (one sentence), **Who uses it?** (a person), **What value?** (what changes), **Current state?** (working/broken/half-built)

### Step 3: Write real config

Read `templates/founder-yml-template.yml` for structure. Edit `config/founder.yml` — replace every placeholder with real content from code analysis. No brackets, no TODO.

### Step 4: Generate features (3-7)

Detect from route directories, source modules, CLI commands, package scripts. Each feature gets: delivers, for, code paths, weight (1-5), maturity (planned/building/working/polished).

### Step 5: Generate assertions (2-3 per feature)

Mechanical assertions in beliefs.yml. At least one file_check, one command_check or content_check per feature. Prefer mechanical over llm_judge.

### Step 6: Start the learning loop

Create: predictions.tsv (header), experiment-learnings.md (template), strategy.yml, roadmap.yml. Every downstream command works immediately.

### Step 7: First eval

```bash
bash scripts/first-score.sh
```

Also run `founder eval .` and write output to `.claude/cache/eval-cache.json`.

### Step 8: Present results and 3 next steps

Use output template from `references/onboarding-flow.md`. Show what was set up, features detected with scores.

**Generate exactly 3 tasks:**

1. **"Review generated config in config/founder.yml"** — verify features, weights, and value hypothesis match reality
2. **"Run /plan to find the bottleneck"** — picks the first move based on scores and strategy
3. **"Run /eval to get your first scores"** — establishes baseline eval scores per feature

That's it. No 15-task backlog. The founder needs a clear path, not a wall of todos.

## System integration

Reads: README.md, package.json / pyproject.toml / go.mod / Cargo.toml, route structure, source files, test/CI config
Writes: `config/founder.yml` (features, value hypothesis), `config/beliefs.yml` (assertions), `.claude/plans/roadmap.yml`, `.claude/plans/strategy.yml`, `.claude/cache/eval-cache.json`, `~/.claude/knowledge/predictions.tsv` (header), `~/.claude/knowledge/experiment-learnings.md` (template)
Triggers: `/eval` (establish baseline), `/plan` (pick first move)
Triggered by: first use of any founder-os command on uninitialized repo, manual ("set this up", "bootstrap", "new here")

## Self-evaluation

/onboard succeeded if:
- `founder score .` returns a non-zero score
- `founder eval .` runs without errors and writes eval-cache.json
- Every generated feature has at least one mechanical assertion (not llm_judge)
- Zero placeholder text remains in founder.yml or beliefs.yml
- The 3 next steps are clear and actionable

## What you never do

- Leave placeholder text — fill everything from the code
- Make up features that don't exist in the codebase
- Run /plan or /go automatically — let the stranger see what was set up first
- Create more than 7 features — start focused
- Create only llm_judge assertions — mechanical first
- Skip the learning loop setup
- Apologize for low scores

## If something breaks

- detect-project.sh returns "unknown": use AskUserQuestion to ask about language and framework
- first-score.sh fails with "no features": founder.yml features section is empty — re-run with `--force` or manually add features
- beliefs.yml assertions all fail on first eval: check if `npm run build` or equivalent succeeds first
- "Already initialized" but config is stale: use `/onboard --force` to regenerate everything from scratch

$ARGUMENTS
