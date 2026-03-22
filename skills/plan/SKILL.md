---
name: plan
description: "Use when starting a work session, finding the bottleneck, or capturing a task. Pulls live market signals before planning — a proactive cofounder, not a task manager."
argument-hint: "[feature...|brainstorm|critique|task text]"
allowed-tools: Read, Bash, Grep, Glob, Agent, EnterPlanMode, ExitPlanMode, AskUserQuestion, TaskCreate, TaskList, WebSearch
---

!command -v jq &>/dev/null && cat .claude/cache/eval-cache.json 2>/dev/null | jq 'to_entries | map({key, score: .value.score, d: .value.delivery_score, c: .value.craft_score, v: .value.viability_score, delta: .value.delta}) | from_entries' 2>/dev/null || echo "no eval cache (jq missing or cache empty)"
!command -v jq &>/dev/null && cat .claude/cache/product-value.json 2>/dev/null | jq '{model: .product_model, loop: .value_loop[:5], journey_balance: [.journey_funnel | to_entries[] | "\(.key):\(.value.count)"]}' 2>/dev/null || echo "no product-value cache (jq missing or cache empty)"
!cat .claude/plans/plan.yml 2>/dev/null | head -20 || echo "no plan"
!cat ~/.claude/knowledge/experiment-learnings.md 2>/dev/null | head -60 || echo "no knowledge model"

# /plan

A cofounder planning the next move. Not a task manager — a strategist who checks the outside world before looking at code.

## Step 0: World Check (before reading any project state)

Before touching eval-cache or plan.yml, spend 30 seconds on the outside world:

1. **WebSearch** for the product's market/competitors — any launches, pricing changes, or news since last session?
2. Read `mind/world.md` for externalities that might affect priorities
3. If portfolio.yml exists, check if any idea's timing assumption changed

If something shifted: surface it FIRST in the plan output, before the bottleneck. "Before we look at features — [competitor] launched a free tier yesterday. This changes priorities."

If nothing shifted: proceed to bottleneck diagnosis. Don't mention the check.

## Skill folder

- `scripts/` — `session-context.sh`, `bottleneck-report.sh`, `opportunity-scan.sh`, `startup-check.sh`, `plan-progress.sh`, `intelligence-query.sh`. Use to VERIFY your diagnosis, not replace it.
- `references/tier-routing.md` — what to recommend at each maturity tier
- `references/prioritization-guide.md` — how to rank moves (bottleneck-first, information value, stage-appropriate)
- `references/startup-patterns-quick.md` — condensed failure mode reference
- `templates/plan-output.md` — output formatting reference
- `templates/plan-template.yml` — valid plan.yml structure
- `templates/move-brief.md` — move structure and quality checks
- `gotchas.md` — real failure modes. **Read before generating moves.**

## Routing

Parse `$ARGUMENTS`:

| Argument | Mode |
|----------|------|
| (none) | Full planning — bottleneck diagnosis, thesis-aware moves |
| `[feature]` | Scoped to one feature |
| `[feature] [feature]` | Cross-feature, grouped moves |
| `brainstorm` | Skip bottleneck, propose 5 high-information directions |
| `critique` | Product walkthrough: first contact, core loop, edge cases, 3 worst things |
| Any other text | Quick capture as task or assertion |

**Quick capture**: if `$ARGUMENTS` looks like a task, capture it directly. Contains "must"/"should"/"always"/"never" -> assertion in beliefs.yml. Otherwise -> TaskCreate. Output: `Captured: [text]` — done.

## How planning works

Call EnterPlanMode. All reads, no writes until plan is approved.

### Read state

Read these in parallel — form your own picture:

**Core:** `config/founder.yml` (features, weights, mode, stage), `.claude/cache/eval-cache.json` (per-feature scores + sub-dimensions), `.claude/plans/roadmap.yml` (thesis, evidence), `.claude/plans/strategy.yml` (stage, bottleneck), `~/.claude/knowledge/predictions.tsv`, `.claude/plans/plan.yml` (previous plan), `.claude/plans/todos.yml`

**On demand:** `~/.claude/knowledge/experiment-learnings.md`, `.claude/cache/customer-intel.json`, `.claude/cache/market-context.json`, `config/product-spec.yml`, `git log --oneline -10`

**Score data:** Read health via `bash bin/score.sh . --json --quiet`. Read eval-cache.json for feature scores. The bottleneck is the lowest-scoring feature with highest weight.

**First-run**: If no features in founder.yml or no eval-cache: skip tier routing. Show 3 steps: (1) `/score` for baseline, (2) define features in founder.yml, (3) `/plan` again. One next command.

### Diagnose the bottleneck

This is YOUR reasoning, not a script's. Think through:

1. **Which feature matters most?** Highest weight + lowest score, adjusted by thesis relevance.
2. **Which sub-score is weakest?** The bottleneck is the lowest sub-score (delivery/craft) on the priority feature. Not the average.
3. **Journey position?** Entry features below 60 delivery block ALL users. Entry > core > leaf at equal scores.
4. **Did the last plan work?** Tasks done but score flat = wrong diagnosis. Change the angle.
5. **What patterns apply?** Check experiment-learnings for relevant known/uncertain/unknown patterns.
6. **Startup failure modes?** Run `bash scripts/startup-check.sh` to verify. Include triggered warnings.

Verify with `bash scripts/bottleneck-report.sh` — if it disagrees, reconcile explicitly.

### Tier-aware recommendations

Read `references/tier-routing.md` for tier-appropriate recommendations. The tier determines whether to suggest build tasks, research, ideation, or strategy.

### Surface opportunities

Run `bash scripts/opportunity-scan.sh` — unknowns, wrong predictions, market signals, stale strategy, unused capabilities. Present top 2-3 alongside your bottleneck diagnosis.

### Generate moves (1-2)

Each move uses the structure in `templates/move-brief.md`. Moves must target the weakest sub-score, connect to a roadmap evidence item, include a falsifiable prediction, and cite evidence or declare exploration. Read `references/prioritization-guide.md` for tiebreaking.

### Align and write

Present diagnosis + moves via AskUserQuestion. Include "Looks right — proceed" as first option. Then: TaskCreate for each move, write `.claude/plans/plan.yml` (use `templates/plan-template.yml`), promote matching todos, ExitPlanMode.

## Output

See `templates/plan-output.md` for formatting reference. Dense, scannable, opinionated. Also see `../OUTPUT_FORMAT.md` and `../STATE_MANIFEST.md`.

## Agent usage

- **founder-os:grader** — grade ungraded predictions before planning (~10s)
- **founder-os:explorer** — if bottleneck is in Unknown Territory (~30s, background)

## What you never do

- Plan for more than 10 minutes when the bottleneck is clear
- Propose the same stalled approach with different words
- Skip the prediction on any move
- Generate 3-5 tasks when 1-2 moves cover it
- Ignore startup pattern warnings without naming the tradeoff
- Delegate diagnosis to a script — scripts verify, you reason

## System integration

Reads: founder.yml, eval-cache.json, roadmap.yml, strategy.yml, predictions.tsv, plan.yml, todos.yml, experiment-learnings.md, topology.json, product-value.json, customer-intel.json, market-context.json, product-spec.yml
Writes: plan.yml, tasks (via TaskCreate)
Triggers: /go (build), /research (unknowns), /eval (stale scores)
Triggered by: session start, /founder, founder asking "what should I work on?"

## If something breaks

- No score cache: run `founder score .` first
- All zeros: project may not be onboarded — run `/onboard`
- startup-check.sh fails with "no founder.yml": run `/onboard`
- maturity-tier.sh returns wrong tier: check eval-cache.json freshness

$ARGUMENTS
