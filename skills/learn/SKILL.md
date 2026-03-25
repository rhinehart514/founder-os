---
name: learn
description: "What did we learn? Grade predictions, audit demand hypotheses, update knowledge model, detect stale patterns, calibrate measurement tools. Replaces: /retro, /calibrate. Also triggers on: 'retro', 'what did we learn', 'grade predictions', 'calibrate', 'stale knowledge'."
argument-hint: "[grade | audit | consolidate | stale | accuracy | health | dimensions | calibrate | demand | profile | design-system | anti-slop | market]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebSearch, WebFetch, AskUserQuestion, mcp__playwright__browser_navigate, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_snapshot, mcp__playwright__browser_install
---

# /learn — Close the Loop, Sharpen the Lens

Two jobs unified: grade what happened (retro) and calibrate what measures it (calibrate).
The skill that makes serial entrepreneurs' judgment compound.

## Skill folder structure

- `scripts/retro-log.sh` — persistent retro session log
- `scripts/prediction-stats.sh` — accuracy, calibration, domain breakdown
- `scripts/learning-velocity.sh` — model updates per week, prediction frequency, accuracy trend
- `scripts/stale-knowledge.sh` — scans experiment-learnings.md for stale entries
- `scripts/extract-design-system.sh` — mechanical token extraction from codebase
- `scripts/freshness-check.sh` — age of all calibration artifacts
- `references/grading-guide.md` — how to grade predictions. **Read before grading.**
- `references/knowledge-maintenance.md` — promotion rules, pruning rules, staleness thresholds
- `references/interview-protocol.md` — founder taste interview protocol
- `references/slop-taxonomy.md` — slop categories with detection rules
- `templates/retro-report.md` — output template for retro sessions
- `reference.md` — full output templates for all routes
- `gotchas.md` — real failure modes. **Read before grading or calibrating.**

## Routing

| Input | Mode | What |
|-------|------|------|
| (none) | FULL | grade + consolidate + stale + audit |
| grade | GRADE | Grade ungraded predictions only |
| audit | AUDIT | Does each feature still serve validated jobs? Includes four forces re-check |
| consolidate | CONSOLIDATE | Maintain knowledge model only |
| stale | STALE | Find outdated patterns |
| accuracy | ACCURACY | Just the number |
| health | HEALTH | Dashboard of learning system health |
| dimensions | DIMENSIONS | By-topic accuracy breakdown |
| calibrate | CALIBRATE | Full calibration (profile + design-system + anti-slop + market) |
| demand | DEMAND | Present jobs/forces to founder, adjust demand_tier |
| profile | PROFILE | Founder taste interview |
| design-system | DESIGN-SYSTEM | Extract tokens from code |
| anti-slop | ANTI-SLOP | Build category-specific slop profile |
| market | MARKET | Competitive visual landscape |

## FULL mode (default)

1. **Grade** ungraded predictions in `~/.claude/knowledge/predictions.tsv`. For each: check outcome, grade yes/no/partial, write model_update if wrong. Read `references/grading-guide.md` first.
2. **Consolidate** `~/.claude/knowledge/experiment-learnings.md`: promote uncertain patterns with 3+ confirmations, add boundary conditions to wrong Known patterns, track new territory.
3. **Audit** each active feature against its original customer job. WebSearch domain. Check four forces: has push/pull changed? New anxiety or inertia factors? Check why_now, competition, pricing model, platform risk. Output: still matters / needs pivot / audit failed.
4. **Stale check**: run `bash scripts/stale-knowledge.sh`. Flag Known >30d unreferenced, Dead Ends >6mo, Uncertain >14d unresolved. Evidence staleness: observed 90d, stated 60d, market 30d, inferred 7d.
5. **Output** with evidence quality stats. Log via `bash scripts/retro-log.sh`. Write `~/.claude/cache/last-retro.yml`.

## GRADE mode — Read `references/grading-guide.md` first. Grade ungraded only.

## AUDIT mode — Four forces re-check per feature. WebSearch domain. Check functional/emotional/social jobs still hold. Killed jobs record to `experiment-learnings.md`.

## CONSOLIDATE mode — Merge duplicates, promote 3+ confirmed, flag stale per `references/knowledge-maintenance.md`.

## STALE mode — Run `bash scripts/stale-knowledge.sh`. Evidence staleness thresholds: observed 90d, stated 60d, market 30d, inferred 7d.

## ACCURACY mode — One line: `(correct + partial * 0.5) / graded * 100`. Calibration verdict.

## HEALTH mode — Read-only dashboard via `bash scripts/learning-velocity.sh`. Prediction frequency, grading latency, model freshness, section balance, accuracy trend.

## DIMENSIONS mode — By-topic accuracy. Flag domains 3+ graded <40% as overconfident, 0 predictions as blind spots.

## CALIBRATE mode — Full calibration: profile + design-system + anti-slop + market in sequence. Run `bash scripts/freshness-check.sh` first.

## DEMAND mode — Read `demand-cache.json`. Present jobs/forces to founder via `AskUserQuestion`. Adjust demand_tier based on responses. Killed jobs record to `experiment-learnings.md` with four forces snapshot.

## PROFILE mode — Read `references/interview-protocol.md`. Interview founder via `AskUserQuestion`. Write `~/.claude/knowledge/founder-taste.md` with specifics: loves, hates, dimension weights, anti-slop triggers.

## DESIGN-SYSTEM mode — Run `bash scripts/extract-design-system.sh`. Write `.claude/design-system.md` with color tokens, spacing, typography, radius/shadow, component patterns.

## ANTI-SLOP mode — Read `references/slop-taxonomy.md`. WebSearch category slop. Write `.claude/cache/anti-slop.md` with category-specific detection rules.

## MARKET mode — WebSearch top 5 competitors + trends. Playwright screenshot 2-3 sites. Write `.claude/cache/taste-market.json` + `.claude/cache/market-snapshot.md`.

## Quality gates

- Model updates MUST include mechanism words ("because", "discovered that")
- Reject tautologies. Wrong predictions MUST explain WHY.
- Promotions require 3+ independent data points
- Evidence quality stats in all output: count by class (observed/stated/market/inferred)
- Evidence staleness flags: observed 90d, stated 60d, market 30d, inferred 7d

## State reads
`~/.claude/knowledge/predictions.tsv`, `~/.claude/knowledge/experiment-learnings.md`, `config/portfolio.yml`, `.claude/cache/eval-cache.json`, `.claude/cache/score-cache.json`, `demand-cache.json`, `~/.claude/knowledge/founder-taste.md`, `.claude/design-system.md`

## State writes
`~/.claude/knowledge/predictions.tsv`, `~/.claude/knowledge/experiment-learnings.md`, `~/.claude/cache/last-retro.yml`, `~/.claude/knowledge/founder-taste.md`, `.claude/design-system.md`, `.claude/cache/anti-slop.md`, `.claude/cache/taste-market.json`, `.claude/cache/market-snapshot.md`, `.claude/cache/calibration-history.json`

## System integration
Triggers: `/plan`, `/research`, `/eval`, `/taste`
Triggered by: `/go` (post-session), `/plan` (health check), `/taste` (when calibration stale)

## What you never do
- Skip grading because "not enough evidence" — make your best call
- Grade `yes` when outcome differs from prediction text
- Delete predictions — they're training signal
- Calibrate to inflate scores — calibration makes taste honest
- Use generic trend articles without checking dates
- Grade everything as "partial" to avoid committing

$ARGUMENTS
