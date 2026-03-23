---
name: founder
description: "Use when the user asks for project status, dashboard, 'where am I?', or wants the home screen — shows portfolio state, current project signals, and the one thing that matters right now"
argument-hint: "[help|system|compare|health|progress]"
allowed-tools: Read, Bash, Grep, Glob
user-invocable: false
---

<!-- INTERNAL: This skill is the founder-os home screen. -->

!cat .claude/cache/product-value.json 2>/dev/null | jq '.product_model' 2>/dev/null || true

# /founder

The home screen. Everything the founder needs, nothing they don't.

## Skill folder structure

This skill is a **folder**, not just this file. Read on demand:

- `templates/dashboard.md` — canonical rendering format: zone structure, bar math, conditional rules
- `references/dashboard-guide.md` — section meanings, conditional rendering, snapshot protocol, opinion decision tree, pattern detection
- `references/reading-guide.md` — what each number means. For founders who ask "what does this mean?"
- `gotchas.md` — real failure modes. **Read before rendering any view.**

Scripts (`system-pulse.sh`, `skill-catalog.sh`) exist as verification — run to cross-check your synthesis, not as the primary path.

## State

Read these directly — you are the synthesizer, not scripts:

| File | What it tells you |
|------|-------------------|
| `~/.founder-os/portfolio.yml` | Portfolio of ideas: stages, hypotheses, kill conditions, evidence |
| `.claude/cache/score-cache.json` | Health score, structure, hygiene. The cached `founder score .` result |
| `.claude/cache/eval-cache.json` | Per-feature scores: delivery/craft/viability sub-scores, deltas, timestamps, weights |
| `config/founder.yml` | Feature definitions, value hypothesis, user, mode, weights, dependencies |
| `config/product-spec.yml` | What the product claims to do — show spec completion alongside score |
| `.claude/plans/roadmap.yml` | Current version thesis, evidence items (proven/partial/todo/disproven) |
| `.claude/plans/strategy.yml` | Strategic diagnosis, bottleneck. Check freshness (>7d = stale) |
| `.claude/plans/plan.yml` | Active plan: tasks, bottleneck_feature. Check freshness (>24h = defer to own heuristic) |
| `~/.claude/knowledge/predictions.tsv` | Prediction log: accuracy, graded/ungraded counts |
| `.claude/plans/todos.yml` | Backlog: active/backlog/stale/done counts |
| `config/portfolio.yml` | Local portfolio config (if present, links to global portfolio) |
| `.claude/cache/founder-snapshots.json` | Dashboard history — last 20 snapshots for compare/pattern detection (R+W) |

**Bottleneck**: compute from eval-cache + founder.yml weights. Lowest `score * weight` among active features. If `plan.yml` exists and is <24h old, use its `bottleneck_feature` instead.

**Product completion**: `sum(eval_score * weight) / sum(weight * 100)` across active features.

**Version completion**: `proven / total` from roadmap.yml evidence items.

## Routing

Parse `$ARGUMENTS`:

| Argument | Action |
|----------|--------|
| (none) | Portfolio summary (if exists) + project dashboard → save snapshot → state one opinion |
| `help` | Show "Start Here" flow first, then skill catalog grouped by phase |
| `system` | Internals: version, hooks, agents, skills, calibration |
| `compare` | Load last snapshot from `.claude/cache/founder-snapshots.json` → diff against current state |
| `health` | System health audit: hooks, agents, skills coverage, learning loop → letter grade |
| `progress` | The arc: score trajectory, feature maturity, prediction accuracy, assertions, velocity |

## First-run gate

If `config/founder.yml` is missing or `.claude/cache/eval-cache.json` doesn't exist:
- Show: "Welcome to founder-os. Your project has no scores yet."
- Suggest `/onboard` (no founder.yml) or `/score` (no cache yet)
- Skip the full dashboard — stop here

## Portfolio-first rendering

When `~/.founder-os/portfolio.yml` exists, the default view leads with a portfolio summary before the current project dashboard.

### Portfolio summary zone (renders FIRST)

```
  ◆ portfolio  ·  [N] ideas  ·  [N] active  ·  [N] killed
  accuracy     [X]%  ([N]/[M] graded)  ·  target: 50-70%

  [idea name]     [stage]     [days]     [one-line status]
  [idea name]     [stage]     [days]     [one-line status]
  ...

  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
```

Read `~/.founder-os/portfolio.yml` for all ideas. Show:
- Total count, active count, killed count
- Prediction accuracy from `~/.claude/knowledge/predictions.tsv`
- Each active idea: name, stage, days in stage, one-line status (latest hypothesis status or next action)
- Recently killed ideas (last 3): name, kill date, learning

After the portfolio summary, render the current project dashboard (same as no-portfolio view).

### No portfolio

When `~/.founder-os/portfolio.yml` does NOT exist, skip the portfolio zone entirely. Render only the project dashboard.

## Rendering

Read `gotchas.md` before rendering any view. Read `references/dashboard-guide.md` for the full rendering spec — templates, conditional rules, opinion decision tree, pattern detection, anti-rationalization checks.

**Help view** — show this FIRST before the skill catalog:

```
Start Here
  "is this good?"          → /score   (the oracle — unified quality number)
  "what should I work on?" → /plan    (the strategist — finds the bottleneck)
  "just build it"          → /go      (the builder — autonomous loop)

  The flow: /score → /plan → /go → /score (repeat)

  New idea?
  /decide → /research → /plan
  Brainstorm, gather evidence, then decide what to build.
```

Then render the skill catalog grouped by phase. For each skill, extract its `argument-hint` from frontmatter and display it inline:

```
Skill Catalog

  Ideate
    /decide [new "idea"|refine|pivot|vs|systems|wild|invert] — feature/idea discovery
    /ideate [feature|wild|kill|deep|technique-name|"constraint"] — evidence-weighted ideas

  Validate
    /research [feature|docs <lib>|site <url>|competitor <name>|market|history|gaps|"topic"] — gather evidence
    /strategy [bet|market|position|price|gtm|compete|honest|coherence|user|research|docs|site] — strategic diagnosis
    /product [user|assumptions|why|pitch|focus|signals|delight|market|coherence|refine|pivot|"..."] — product thinking
    /money [price|runway|unit-economics|channels|model] — pricing and revenue

  Build
    /plan [feature...|brainstorm|critique|task text]    — find the bottleneck, propose work
    /go [feature...] [--safe] [--speculate N]           — autonomous build loop
    /push [feature] [extract] [target-score]            — push a feature to a target score
    /todo [add "title"|done <id>|promote <id>|active|health|decay] — living backlog

  Measure
    /score [feature|quick|deep|viability|breakdown]     — unified quality number
    /eval [feature|beliefs|add-belief|health|blind|coverage|trend|slop] — code eval per feature
    /taste <url> [flows|mobile|vs <url>|deep|trend] | cli [feature] — visual product intelligence

  Ship
    /ship [release [tag]]                               — deploy + releases + PRs
    /roadmap [next|bump|ideate|narrative|changelog|positioning|add|done|new|v<X.Y>] — version theses
    /copy [landing|pitch|outreach|release|onboard|empty-states|"..."] — product copy

  Learn
    /retro [accuracy|stale|session|health|dimensions|auto] — audit predictions + knowledge model

  System
    /onboard [--force] [--dry]                          — bootstrap any project
    /founder [help|system|compare|health|progress]      — this dashboard
    /feature [name|new|detect] [name]                   — manage features
    /calibrate [profile|design-system|anti-slop|market|refresh|verify|drift] — ground taste eval
    /skill [list|create|install|remove|info|health|audit|overlap] — manage skills
    /configure [show|agents|output|go|reset]            — configure settings
```

Show ALL modes for each skill. The argument hints come from each skill's `argument-hint` frontmatter field.

**Default view** — after rendering, save current state to `.claude/cache/founder-snapshots.json`. Keep last 20 snapshots, trim oldest on append.

## Task generation — dashboard alerts become tasks

**For EVERY alert or stale signal on the dashboard, generate a task:**

### Staleness tasks
- Strategy >7d old → task: "Strategy [N]d stale — run /strategy honest"
- Eval-cache >7d old → task: "Eval data [N]d stale — run /eval"
- Market-context >14d old → task: "Market data [N]d stale — run /strategy market"
- Predictions.tsv no entries in 7d → task: "No predictions in [N]d — learning loop starved"
- Roadmap evidence no movement in 14d → task: "Thesis stalled [N]d — run /roadmap next"

### Score alert tasks
- Score dropped since last snapshot → task: "Score dropped from [X] to [Y] — diagnose via /eval"
- Assertion pass rate dropped → task: "Assertions regressed: [N] newly failing — fix via /go"
- Feature score dropped → task: "Feature [X] regressed from [old] to [new] — investigate"

### Prediction health tasks
- Ungraded predictions exist → task: "Grade [N] ungraded predictions — run /retro"
- Prediction accuracy outside 50-70% → task: "Prediction accuracy at [N]% — recalibrate via /retro"
- No predictions in 7d → task: "No predictions logged — enforce on next /go session"

### Backlog health tasks
- >10 stale todos (>14d) → task: "Backlog has [N] stale items — run /todo decay"
- 0 active todos → task: "No active work — run /plan to pick next move"
- Todos with no feature tag → task: "Orphan todos — run /todo to tag them"

### System health tasks (for /founder health mode)
- Missing state files (no strategy.yml, no roadmap.yml) → task per missing file
- Hooks not installed → task: "Install hooks via /configure"
- Skills without assertions → task: "Skill [X] unmeasured — run /skill health"

Tag with `source: /founder` and alert type (stale/score/prediction/backlog/system). Priority: score regressions first, then staleness.

## System coherence

Cross-check alignment between strategy, eval, and plan yourself. Render warnings between signals and opinion when mismatched:

```
  coherence   ⚠ strategy says [X] but eval says [Y] is the bottleneck
              ⚠ plan targets [X] but weakest feature is [Y]
              ⚠ [feature] is weakest but has 0 todos — nothing is working on it
```

If coherence is aligned, skip the section (no data = no zone). Mismatches mean the skills are pointing in different directions — the opinion should name this: "Skills are misaligned. Run /plan to re-diagnose."

## System integration

/founder is the home screen — the hub that routes to everything else.

- **/score** wrote `score-cache.json` and `eval-cache.json` — /founder reads both
- **/plan** wrote `plan.yml` with `bottleneck_feature` — /founder defers to it when fresh (<24h)
- **/strategy** wrote `strategy.yml` — /founder checks freshness and coherence against eval
- **/roadmap** wrote `roadmap.yml` — /founder renders thesis + evidence completion
- **/todo** wrote `todos.yml` — /founder counts active/backlog/stale
- **/retro** graded `predictions.tsv` — /founder reports accuracy and ungraded count
- **/eval** wrote `eval-cache.json` feature scores — /founder computes product completion and bottleneck from these
- **/founder** reads `~/.founder-os/portfolio.yml` for portfolio summary and writes `founder-snapshots.json` — consumed by `/founder compare` and pattern detection

The opinion defers to /plan for bottleneck diagnosis when plan.yml is fresh. Otherwise, /founder computes its own from eval data and flags the opinion as heuristic-based.

## Self-evaluation

The skill worked if:
- **Default**: portfolio summary (if applicable) + dashboard rendered with all non-empty zones, snapshot was saved, opinion was stated
- **Help**: "Start Here" flow was shown BEFORE skill catalog, not after
- **Compare**: delta against previous snapshot was computed and rendered
- **Health**: letter grade was assigned with justification
- **All modes**: tasks were generated for every stale signal or alert

## What you never do
- Turn this into a long report — density is the design
- Recommend more than one next action
- Skip the opinion
- Show zones with no data — skip them
- Make up numbers

## If something breaks

- system-pulse.sh returns mostly empty: the project is not onboarded — run `/onboard` to generate config, features, and assertions
- Snapshot comparison shows no previous snapshot: `.claude/cache/founder-snapshots.json` is missing or empty — run `/founder` once to create the first snapshot
- skill-catalog.sh lists zero skills: the plugin may not be installed correctly — check that `CLAUDE_PLUGIN_ROOT` is set or skills are symlinked
- Dashboard shows stale data everywhere: score-cache and eval-cache are old — run `founder score .` and `/eval` to refresh
- Portfolio file missing: skip portfolio zone, render project-only dashboard

$ARGUMENTS
