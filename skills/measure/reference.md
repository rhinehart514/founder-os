# /measure Reference — Architecture & Memory

Loaded on demand. Output templates are in `templates/`. Dimensions are in `references/dimensions.md`.

---

## Architecture

The `/measure` skill uses Claude Code natively — Playwright MCP for screenshots, Claude Vision for evaluation, evaluator agents for parallel code scoring. No subprocess, no `claude -p`. Claude IS the runtime AND the evaluator.

## Key Files

| File | Purpose |
|------|---------|
| `skills/measure/SKILL.md` | Skill definition, routing, all modes |
| `skills/measure/scripts/cache-summary.sh` | Reads all tier caches, shows staleness + confidence |
| `skills/measure/scripts/synthesize.sh` | Computes unified score from cached tier data |
| `skills/measure/scripts/viability-assess.sh` | Checks viability cache freshness |
| `skills/measure/scripts/quick-eval.sh` | Mechanical assertion score, no LLM |
| `skills/measure/scripts/variance-check.sh` | Catch score drift vs rubric |
| `skills/measure/scripts/rubric-status.sh` | Which features have rubrics, last scores, gaps |
| `skills/measure/scripts/eval-history.sh` | Score trends over time |
| `skills/measure/scripts/dimension-summary.sh` | Latest visual scores, weakest/strongest |
| `skills/measure/scripts/taste-history.sh` | Visual score trends per dimension |
| `skills/measure/scripts/calibration-check.sh` | Calibration state check |
| `skills/measure/scripts/slop-check.sh` | Mechanical slop detection |
| `skills/measure/scripts/append-history.sh` | Append visual eval results to taste-history.tsv |
| `skills/measure/scripts/cli-taste.sh` | CLI output capture and evaluation |
| `skills/measure/scripts/flows-summary.sh` | Latest flows report summary |
| `skills/measure/scripts/checks/` | 7 JS checks for browser_evaluate |
| `skills/measure/references/scoring-methodology.md` | Tier weights, confidence rules, staleness |
| `skills/measure/references/viability-guide.md` | Viability scoring protocol |
| `skills/measure/references/scoring-guide.md` | Eval dimensions, scale, anti-inflation |
| `skills/measure/references/rubric-guide.md` | How rubrics work |
| `skills/measure/references/dimensions.md` | 11 visual dimensions with scoring anchors |
| `skills/measure/references/evaluation-voice.md` | How to see and talk during visual eval |
| `skills/measure/references/flows-protocol.md` | Full behavioral audit protocol |
| `skills/measure/references/flow-checklist.md` | 6-layer behavioral checklist |
| `skills/measure/references/cli-dimensions.md` | 5 CLI dimensions with anchors |
| `skills/measure/references/cli-patterns-2026.md` | CLI UX patterns reference |

## Data Files (per-project)

| File | Purpose |
|------|---------|
| `.claude/cache/score-cache.json` | Last health score (5min TTL) |
| `.claude/cache/eval-cache.json` | Per-feature delivery/craft scores, deltas, timestamps |
| `.claude/cache/viability-cache.json` | Agent-backed viability scores |
| `.claude/cache/market-context.json` | Competitive landscape, market signals |
| `.claude/cache/customer-intel.json` | Demand signals, user feedback |
| `.claude/cache/demand-cache.json` | Demand tier data |
| `.claude/cache/score-unified.json` | Final synthesized score |
| `.claude/cache/rubrics/<feature>.json` | Per-feature anchoring rubrics |
| `.claude/evals/reports/taste-*.json` | Full visual evaluation reports |
| `.claude/evals/reports/flows-*.json` | Flow audit reports |
| `.claude/evals/reports/cli-taste-*.json` | CLI taste reports |
| `.claude/evals/taste-history.tsv` | Score history (append-only) |
| `.claude/evals/taste-learnings.md` | Accumulated visual intelligence |
| `.claude/evals/taste-market.json` | Cached market research |
| `~/.claude/knowledge/founder-taste.md` | Founder preferences (from calibrate) |
| `.claude/design-system.md` | Project visual rules |
| `.claude/cache/calibration-history.json` | Calibration tracking |

## Measurement Stack

```
Health (score.sh)     -> Does the code compile and pass lint?
Flows (measure flows) -> Does the frontend actually work as a product?
Craft (measure visual)-> Is the frontend well-designed?
Value (measure eval)  -> Does the product deliver on its claims?
Viability (agents)    -> Does the market care?
Demand (cache)        -> Is there evidence of demand?
```

## Score Mapping

- 0-100 natively (no conversion from 1-5 scale)
- Visual `overall` = mean(all 11 dimensions)
- Gate dimensions (layout_coherence, information_architecture) cap overall at 30 when either < 30
- Product total = weighted average across features (by `weight:` in founder.yml)

## Memory Architecture

```
taste-learnings.md    -> knowledge model (updated after each eval, max 5 entries)
taste-history.tsv     -> score timeline (append-only)
taste-*.json          -> full reports (one per eval date)
taste-market.json     -> what "great" looks like (refreshed on calibrate)
eval-cache.json       -> code eval scores and deltas
score-unified.json    -> final synthesized product score
```

## Calibration State

Run `scripts/calibration-check.sh` to see current state. Three independent sources:

1. **Founder profile** (`~/.claude/knowledge/founder-taste.md`) — weights dimensions by preference
2. **Design system** (`.claude/design-system.md`) — flags deviations as bugs
3. **Dimension knowledge** (`lens/product/eval/knowledge/*.md`) — per-dimension research rubrics

Partial calibration is better than none.
