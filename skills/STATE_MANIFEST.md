# State Manifest — What Actually Exists

Skills read project state directly via the Read tool. This manifest documents what state files exist on disk right now, what creates them, and what reads them. Files that don't exist yet are marked explicitly.

## Existing State Files

### Config (project-level, checked into git)

| File | Purpose | Written by | Read by |
|------|---------|------------|---------|
| `config/founder.yml` | Value hypothesis, features (weight/depends_on), mode, stage | /onboard, /feature, manual | Nearly everything — /plan, /eval, /go, /score, /strategy, etc. |
| `config/founder.yml.template` | Template for new projects | Static | /onboard |
| `config/portfolio.yml` | Multi-project portfolio config | /discover, /ideate, manual | /ideate, /decide, /founder |

### Measurement Cache (user-level, `~/.claude/cache/`)

All files here are at `~/.claude/cache/`, not project-level `.claude/cache/` (that directory doesn't exist).

| File | Size | Purpose | Written by | Read by |
|------|------|---------|------------|---------|
| `score-cache.json` | 240B | Per-feature scores, overall score, assertion counts | /score | /plan, /go, /eval, /push, /founder, quality-check hook |
| `market-context.json` | 14.6KB | Market/competitive analysis | /research, /strategy | /eval, /plan, /product, /money, /copy |
| `customer-intel.json` | 12KB | Customer signal synthesis | /product, /discover | /eval, /copy, /ideate |
| `last-research.yml` | 2.3KB | Most recent research findings + suggested tasks | /research | /plan, /go |
| `last-retro.yml` | 883B | Most recent retro results + model updates | /retro | /plan |
| `last-discovery.yml` | 1.8KB | Most recent discovery session output | /discover | /plan |
| `changelog.md` | 148KB | Accumulated changelog | /ship | /retro |
| `agency-landscape-research.json` | 14KB | Research artifact (agency landscape) | /research | on-demand |
| `smb-research.json` | 19KB | Research artifact (SMB market) | /research | on-demand |
| `wellness-web-research.json` | 20KB | Research artifact (wellness web) | /research | on-demand |

### Knowledge (user-level, `~/.claude/knowledge/`)

Persistent across projects. Not project-scoped.

| File | Size | Purpose | Written by | Read by |
|------|------|---------|------------|---------|
| `predictions.tsv` | 25KB | All predictions with outcomes and model updates | Every skill that predicts | /retro, /plan |
| `experiment-learnings.md` | 5.1KB | Causal model: known/uncertain/unknown/dead patterns | /retro (consolidator agent) | /plan, /go, /strategy, identity.md instructs checking it |
| `founder-taste.md` | 3.4KB | Founder aesthetic preferences | /taste calibrate | /taste, /copy |
| `patterns.tsv` | — | Pattern tracking | /retro | /plan |
| `taste.jsonl` | — | Taste evaluation history | /taste | /taste |
| `landscape.json` | — | Market landscape data | /research | /strategy |
| `portfolio.json` | — | Portfolio-level tracking | /founder | /founder |
| `product-playbook.md` | — | Product patterns learned | /product | /product |

### Session Plans (`~/.claude/plans/`)

There are 92 session plan files here. They are auto-named markdown files (e.g., `abstract-imagining-fountain.md`), not a single `plan.yml`. Each file is a snapshot of one session's plan created by Claude Code's native planning feature.

**What this means in practice:** There is no single `plan.yml` that /plan reads and writes. /plan creates a new session plan each time. The plans directory is a graveyard of past sessions, not an active planning system.

### Project-level `.claude/`

The only thing in `.claude/` at the project level is a `sessions/` directory. There is no `.claude/cache/`, `.claude/plans/`, `.claude/scores/`, or `.claude/evals/` at the project level. All caches live at the user level (`~/.claude/cache/`).

## Files That Don't Exist

These were documented in the previous manifest but have never been generated. They represent intended but unimplemented state.

### Critical Missing Piece

| File | Intended purpose | Would be written by | Impact |
|------|-----------------|---------------------|--------|
| **`eval-cache.json`** | Per-feature eval scores (delivery/craft), feature maturity | /eval | Without this, /plan has no feature-level quality data. The maturity threshold rubric at the bottom of this file is real — but there's no cache to read maturity FROM. /eval must be run against a real project to generate this. |

### Removed — Never Existed

These were listed in the old manifest but don't exist and have no mechanism to create them:

- `.claude/cache/viability-cache.json` — viability is part of /score, not a separate cache
- `.claude/plans/plan.yml` — session plans are markdown files, not YAML
- `.claude/plans/strategy.yml` — /strategy doesn't write a persistent file
- `.claude/plans/todos.yml` — /todo doesn't write YAML; todos live in session plans or task lists
- `.claude/plans/roadmap.yml` — /roadmap doesn't write YAML; roadmap lives in founder.yml or session output
- `config/product-spec.yml` — product spec lives in founder.yml
- `config/beliefs.yml` — assertions are not persisted as a separate file
- `~/.claude/preferences.yml` — /configure doesn't write this; no user preferences file exists
- `.claude/cache/anti-slop.md` — /calibrate doesn't write this
- `.claude/cache/taste-market.json` — /taste doesn't write this
- `.claude/cache/narrative.yml` — /roadmap doesn't write this
- `.claude/cache/calibration-history.json` — /calibrate doesn't write this
- `.claude/cache/skill-health.json` — /skill doesn't write this
- `.claude/scores/history.tsv` — no score history tracking exists
- `.claude/evals/taste-history.tsv` — taste history is at `~/.claude/knowledge/taste.jsonl` instead
- `.claude/design-system.md` — generated on demand by /taste for web projects, not persisted here

## Read/Write Matrix (Actual)

Only listing skills with confirmed read/write behavior against files that exist.

| Skill | Reads | Writes |
|-------|-------|--------|
| /score | founder.yml, score-cache.json | score-cache.json |
| /eval | founder.yml, score-cache.json, customer-intel.json | eval-cache.json (when run against a project) |
| /taste | founder.yml, founder-taste.md | taste.jsonl, founder-taste.md (calibrate mode) |
| /plan | founder.yml, score-cache.json, predictions.tsv, experiment-learnings.md, last-research.yml, last-retro.yml | Session plan (markdown in ~/.claude/plans/) |
| /go | founder.yml, score-cache.json, experiment-learnings.md | Via builder/measurer/grader agents |
| /strategy | founder.yml, market-context.json, experiment-learnings.md | Session output (no persistent file) |
| /research | founder.yml, last-research.yml | last-research.yml, market-context.json, ad-hoc research JSONs |
| /founder | founder.yml, score-cache.json | Nothing (read-only dashboard) |
| /feature | founder.yml | founder.yml (features section) |
| /todo | Session plans, TaskList | Session-scoped tasks |
| /retro | predictions.tsv, experiment-learnings.md | last-retro.yml, experiment-learnings.md, predictions.tsv (grading) |
| /roadmap | founder.yml | Session output |
| /ship | founder.yml, score-cache.json | Deployment artifacts, changelog.md |
| /onboard | Codebase analysis | founder.yml, score-cache.json |
| /copy | founder.yml, customer-intel.json, founder-taste.md | Copy files |
| /money | founder.yml, market-context.json | Session output |
| /product | founder.yml, customer-intel.json | customer-intel.json |
| /ideate | founder.yml, customer-intel.json | Session output |
| /discover | founder.yml, market-context.json | customer-intel.json, last-discovery.yml |

## Maturity Threshold Rubric

Feature maturity is computed from eval scores. This rubric is real — but requires eval-cache.json to exist (generated by running /eval against a project with code).

| Eval Score | Maturity | Meaning |
|------------|----------|---------|
| 0-29 | planned | Does not exist or fundamentally broken |
| 30-49 | building | Half-built, skeleton is there |
| 50-69 | working | It works, delivers on claim |
| 70-89 | polished | Solid, ships and works well |
| 90+ | proven | Genuinely excellent, externally validated |

**Current state:** founder-os is a plugin/framework — it has no application code to eval. eval-cache.json will only exist when /eval is run against a project that uses founder-os (like the commander.js test at 80/100). The maturity rubric applies to those target projects, not to founder-os itself.
