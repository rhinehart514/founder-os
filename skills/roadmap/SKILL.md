---
name: roadmap
description: "Use when the user asks about versions, theses, progress, release narrative, changelogs, or project history. Also triggers on 'what's next', 'roadmap', 'bump version', 'what did we prove'."
argument-hint: "[next|bump|ideate|narrative|changelog|positioning|add|done|new|v<X.Y>]"
allowed-tools: Read, Bash, Grep, Edit, AskUserQuestion, WebSearch, Agent
---

# /roadmap

Two jobs. One command.

**Internal**: Versions are theses, not releases. Each one asks a question. You test it. It's proven, disproven, or abandoned. Future versions emerge from what you learn, not what you imagine.

**External**: Every proven thesis is a story worth telling. The roadmap is the source of truth for marketing copy, changelogs, positioning, and the "why now" narrative.

## Standalone check

Two modes based on project state:

- **Full mode** (default when `config/founder.yml` + `.claude/cache/eval-cache.json` exist): version completion uses evidence (50%) + feature readiness from eval scores (30%) + todo clearance (20%).
- **Standalone mode** (no founder.yml or no eval-cache): version completion = proven evidence items / total evidence items. No eval-cache dependency. Evidence items are manually marked proven/todo.

## Skill folder structure

This skill is a **folder**, not just this file. Read these on demand:

- `scripts/version-history.sh` — all past versions with thesis/status — **real utility for version archaeology** (`/roadmap v7.0`)
- `references/version-guide.md` — major/minor/patch rules, when to bump, thesis design
- `references/version-lifecycle.md` — detailed version completion cycle, three-tier lifecycle, state relationships
- `references/changelog-guide.md` — how to write good changelogs, what to include
- `templates/roadmap-template.yml` — template for a version entry
- `templates/changelog-template.md` — changelog format
- `reference.md` — output formatting templates and narrative anti-slop rules
- `gotchas.md` — real failure modes. **Read before generating output.**

Scripts `scripts/version-progress.sh` and `scripts/evidence-tracker.sh` exist for verification — run to cross-check your analysis.

## Mode awareness

Read `project.mode` from `config/founder.yml` (when available):
- **build mode** (default): no shipping pressure. The roadmap is a lab notebook, not a release schedule.
- **ship mode**: full pipeline. Shipping language, deadlines, deploy verification.

## State to read (parallel)

Every route reads these first:
1. `.claude/plans/roadmap.yml` — theses, evidence, version history
2. `config/founder.yml` — features, mode, value hypothesis (optional — standalone works without)
3. `.claude/knowledge/predictions.tsv` (fall back to `~/.claude/knowledge/`) — predictions mentioning the thesis
4. `.claude/knowledge/experiment-learnings.md` (fall back to `~/.claude/knowledge/`) — known/uncertain/unknown/dead patterns
5. `git log --oneline -20` — recent work
6. `.claude/cache/eval-cache.json` — per-feature sub-scores (optional — standalone uses evidence-only completion)

Additional state when available: `config/product-spec.yml`, `.claude/plans/strategy.yml`, `.claude/cache/narrative.yml`.

## The Reflection (always comes first)

Before showing the version list, write 2-3 sentences of honest reflection from specific data:

| Dimension | Source | What to say |
|-----------|--------|-------------|
| **Velocity** | Git log + evidence status | "Evidence proving at N/week" or "Nothing moved in N days" |
| **Learning** | predictions.tsv accuracy | "Thesis predictions N% accurate" |
| **Honesty** | Evidence status vs actual | Any `partial` that should be `todo`? Any `proven` without evidence? |
| **Shape** | Cross-version pattern | Recurring themes, what keeps being hard |

## Routing

Parse `$ARGUMENTS`:

**If ambiguous:** exact route keyword wins → version string match → free-form topic. Never ask "did you mean?"

### No arguments → reflection + roadmap
Run `scripts/version-progress.sh` and `scripts/version-history.sh`. Write reflection, show version list, one forward-looking thought.

### `next` → diagnose what's most provable
Run `scripts/evidence-tracker.sh`. For each evidence item, map to features (when available), score provability (`ready`/`close`/`blocked`/`unknown`). Recommend the first experiment.

### `ideate` → brainstorm future theses
Check 4 sources: proven evidence patterns, dead ends, unknown territory, gap between proven and aspirational. Generate 3-4 candidate theses with question, why now, evidence items, and disproven value. Present with AskUserQuestion. **Note:** This is thesis-level brainstorming (where the project goes next). For deep feature-level ideation, use `/ideate` or `/ideate [feature]` instead.

### `narrative` → generate the external story
Derive from proven evidence. Generate: one-liner, paragraph, positioning statement. Every claim traces to evidence. Present via AskUserQuestion. Write to `.claude/cache/narrative.yml`.

### `changelog` → version-by-version external changelog
Read `references/changelog-guide.md` and `templates/changelog-template.md`. Translate internal language to external. Write to `.claude/cache/changelog.md`.

### `positioning` → competitive positioning check
Proven claims, honest gaps, differentiators, where behind. Present via AskUserQuestion. Write to `.claude/cache/positioning.yml`.

### Version string (e.g., `v7.0`) → version archaeology
Run `scripts/version-history.sh v7.0`. Show thesis, what it proved, what it taught, how it shaped what came after.

### `bump` → prove/graduate with auto-synthesis
Read `references/version-guide.md` for tier rules. Auto-detect tier: MAJOR (thesis changed, big new question), MINOR (new features/evidence within current thesis), PATCH (fixes, polish, incremental). Auto-synthesize summary from evidence + predictions + git log. Present via AskUserQuestion. Transfer thesis → Known Pattern in experiment-learnings.md.

### `add [version] [milestone]` → add evidence needed
### `done [milestone-id]` → mark evidence as proven
### `new [version] [thesis]` → create a new thesis

Use `templates/roadmap-template.yml` when creating new version entries.

## Thesis Health Monitor

Run on every invocation:
- **Contradiction**: >50% thesis predictions wrong → surface warning, suggest `/roadmap ideate`
- **Stall**: no evidence movement in >14 days → diagnose why
- **Disproven**: check `if_disproven:` field, write to experiment-learnings.md as Dead End

For version completion formulas and the full lifecycle: `references/version-lifecycle.md`
For output templates and narrative anti-slop rules: `reference.md`

## Agent usage — `founder-os:explorer` for thesis research when evidence sources are insufficient.

## Self-evaluation

/roadmap succeeded if:
- roadmap.yml was read and updated (or created if missing)
- The reflection cites specific data (git log, evidence status, prediction accuracy), not vibes
- The founder has a clear answer to "what should we prove next?"

## What you never do
- Auto-bump without asking — graduating a thesis is a founder decision
- Create versions with more than 5 evidence items — thesis is too broad
- Invent future versions without evidence — only `/roadmap ideate` creates them
- Write a reflection that sounds like a status update — it should sound like thinking
- In build mode: mention shipping, deploying, releasing, or deadlines
- Mark evidence as `proven` without citing specific evidence
- Ignore disproven evidence — it's the most valuable signal

## If something breaks
- No roadmap.yml → create from git log. Missing ID → list available. Missing predictions → skip, note it.
- No founder.yml → standalone mode (evidence-only completion)
- No eval-cache → standalone completion formula (proven/total evidence)

$ARGUMENTS
