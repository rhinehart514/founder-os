# /retro Reference — Output Templates

Loaded on demand. Steps and routing are in SKILL.md.

---

## Full retro output

```
◆ retro — 3 ungraded, 2 stale

product: **64%** · score: 58 · todos: 8/14 done · predictions: 63%
accuracy trend: 45% → 55% → 63% ████████████░░░░░░░░ improving

  ⎯⎯ grading ⎯⎯

  ✓ "error boundary hardening will raise craft_score from 50 to 65" → craft_score 58 (partial)
    actual: +8 not +15. Subprocess paths still open.

  ✗ "auto-grade will work via session_start hook" → hook too fragile, reverted (no)
    model update: session_start hook confirmed fragile → Known Pattern
    todo: [learning] rethink auto-grade approach (not via hooks)    /retro  [new]

  · "trend visualization will raise delivery_score 62→72" → delivery_score 68 (partial)
    actual: +6 not +10. Inline sparkline helped but less than expected.

  ⎯⎯ accuracy ⎯⎯

  **63%** (10/16) — well-calibrated
  trend: ↑ from 55% (improving)

  ⎯⎯ sub-score insights ⎯⎯

  most predicted: craft_score (5 predictions) — 40% correct (too optimistic about error handling)
  least predicted: viability_score (1 prediction) — blind spot
  best calibrated: delivery_score (3 predictions) — 67% correct

  ⎯⎯ stale knowledge (2 entries) ⎯⎯

  · "copy changes have 80% keep rate" — last evidence 45 days ago
  · "navigation patterns are unknown" — in Unknown Territory for 38 days, 0 experiments

▾ pruned
  · Moved "copy changes have 80% keep rate" to Stale Patterns (45 days)

▾ score updates (proposed)
  · scoring: 58 — craft_score still <60
  · commands: 70 — stable but not all assertions passing

▾ model updates
  ▸ "session_start hook is fragile" Uncertain → Known (2 experiments now confirm)
  ▸ "inline visualization > separate commands" added to Uncertain
  ▸ "craft_score optimism" added to Known: predictions about craft_score overshoot by ~40%

▾ todos captured
  · [learning] rethink auto-grade approach (not via hooks)           /retro  [new]
  · [learning] investigate alternative to session_start for grading  /retro  [new]
  · kill [xx-09] — research confirms dashboard redesign is dead end  /retro  [kill]

artifact: ~/.claude/cache/last-retro.yml

/plan       apply learnings to next session
/research   explore the unknowns surfaced above
/todo decay force decisions on stale items
```

## Session retro output (`/retro session`)

```
◆ retro session — 2026-03-16 02:30

  scope: scoring · mode: beta
  moves: 3 · kept: 2 · reverted: 1
  score: 58 → 66 ↑8 · ROI: 2.7 points/move

▾ predictions
  ✓ "error boundary hardening will raise craft_score +15" → +8 (partial)
  ✓ "sparkline will raise delivery_score +10" → +6 (partial)
  ✗ "auto-grade via hook" → reverted (no)

  session accuracy: **33%** (1/3) — below target, predictions too aggressive

▾ beta features
  speculative branching: 1 move
    branch A won by +3 over branch B
    verdict: **useful** — winner wouldn't have been obvious up front

  adversarial review: 1 catch
    caught hook fragility that measurement missed
    verdict: **useful** — real problem, not noise

  prediction grading: 3/3 graded ✓
    verdict: **working** — all predictions graded before next move

▾ session learnings
  · craft_score predictions overshoot by ~40% (3 experiments now)
  · speculative branching helps when approaches are genuinely different
  · adversarial review catches fragility that assertion pass/fail misses

▾ comparison to previous sessions
  session   moves  kept  ROI    accuracy
  03-16     3      2     2.7    33%
  03-15     4      3     1.5    50%
  03-14     2      2     3.0    100%

  trend: ROI stable, accuracy declining (predictions getting more ambitious)

/plan           next session
/go scoring     continue where we left off
/retro stale    check knowledge freshness
```

## Accuracy-only output (`/retro accuracy`)

```
◆ retro accuracy

  **63%** (10/16 graded, partials at 0.5)
  calibration: well-calibrated (target: 50-70%)
  trend: ↑ from 55% over last 5 sessions

  by dimension:
    delivery_score predictions:   67% correct (3/4.5)
    craft_score predictions: 40% correct (2/5) — too optimistic
    viability_score predictions:      100% (1/1) — insufficient data

/retro          full retro with grading
/plan           make predictions for next session
```

## Stale check output (`/retro stale`)

```
◆ retro stale — 3 entries need attention

  ⚠ Known: "copy changes have 80% keep rate" — 45 days, no new evidence
    → move to Stale Patterns? [Yes / Re-test / Keep]

  ⚠ Unknown: "navigation patterns" — 38 days, 0 experiments
    → this has been unknown for over a month. Research or archive?
    todo: research: navigation patterns                              /retro  [new]

  ⚠ Dead End: "auto-generated assertions from code" — 62 days, 0 citations
    → archive? (nobody references this anymore)

/research [topic]    explore a stale unknown
/retro               full retro
```

## Health dashboard output (`/retro health`)

```
◆ retro health — learning system diagnostic

  ⎯⎯ prediction frequency ⎯⎯

  this week: 4 predictions · last week: 2 · avg: 3.2/week
  trend: **stable**
  frequency:  ████████████████░░░░  3.2/wk (target: 3-5)

  ⎯⎯ grading latency ⎯⎯

  avg: **2.5 days** · median: 2 days · worst: 8 days
  latency:    ████████████░░░░░░░░  2.5d (target: <3d)
  ungraded backlog: 3 predictions (oldest: 2026-03-10)

  ⎯⎯ model freshness ⎯⎯

  Known: 8 · Uncertain: 4 · Unknown: 6 · Dead: 3 · Stale: 1
  Known:Unknown ratio: **1.3:1** — healthy (target: 1:1 to 3:1)
  freshness:  ██████████████████░░  updated 2 days ago (target: <7d)
  updates: 1.2/week (last: 2 days ago)

  ⎯⎯ prediction types ⎯⎯

  score:    ██████████████░░░░░░  5 (33%)
  feature:  ████████░░░░░░░░░░░░  3 (20%)
  approach: ██████████░░░░░░░░░░  4 (27%)
  meta:     ██░░░░░░░░░░░░░░░░░░  1 (7%)
  other:    ████░░░░░░░░░░░░░░░░  2 (13%)
  ⚠ no meta predictions in 2 weeks — not predicting about the system itself

  ⎯⎯ warnings ⎯⎯

  · grading backlog: 3 predictions ungraded
  · model update last 2 days ago — on track

artifact: .claude/cache/retro-health.json

/retro          full retro with grading
/retro auto     auto-grade the backlog
/retro dimensions  accuracy by topic
```

## Dimensions output (`/retro dimensions`)

```
◆ retro dimensions — accuracy by topic

  ⎯⎯ by feature ⎯⎯

  **scoring**:     40% (2/5)  ████████░░░░░░░░░░░░  too optimistic
  **commands**:    67% (2/3)  █████████████░░░░░░░░  well-calibrated
  **learning**:    50% (1/2)  ██████████░░░░░░░░░░░  insufficient data
  **docs**:        —  (0/0)   ░░░░░░░░░░░░░░░░░░░░  blind spot

  ⎯⎯ by dimension ⎯⎯

  delivery_score:     67% (3/4.5)  █████████████░░░░░░░░  well-calibrated
  craft_score:   40% (2/5)    ████████░░░░░░░░░░░░░  **overconfident** — overshoot ~40%
  viability_score:        100% (1/1)   ████████████████████░  insufficient data
  approach:        50% (2/4)    ██████████░░░░░░░░░░░  well-calibrated
  maturity:        —  (0/0)     ░░░░░░░░░░░░░░░░░░░░  blind spot

  ⎯⎯ insights ⎯⎯

  worst: **craft_score** at 40% (5 predictions) — systematically overestimate improvements
  best: **delivery_score** at 67% (4 predictions) — good model of value delivery
  blind spots: **docs**, **viability_score**, **maturity** — zero predictions, unknown accuracy

/retro          full retro with grading
/retro auto     auto-grade the backlog
/retro health   learning system health
```

## Auto-grade output (`/retro auto`)

```
◆ retro auto — 6 ungraded, attempting auto-grade

  ⎯⎯ grade.sh results ⎯⎯

  ran: bash bin/grade.sh
  mechanical grades: 2 applied · 0 conflicts

  ⎯⎯ mechanical (high confidence) ⎯⎯

  ✓ "raise scoring from 32 to 45" → score-cache: 48 (yes)
  · "craft_score will improve +10" → eval-delta: +6 (partial)

  ⎯⎯ proposed (needs review) ⎯⎯

  · "speculative branching helps on unfamiliar territory" → 2 sessions used it, winner by +3 avg
    proposed: **yes** [HIGH confidence] — evidence: session logs show consistent winner margin

  · "adversarial review catches fragility" → 1 catch in 3 sessions
    proposed: **partial** [MEDIUM confidence] — evidence: catches are real but infrequent

  ⎯⎯ skipped (no evidence) ⎯⎯

  · "navigation patterns will affect retention" — no nav data, no experiments
    [LOW confidence] → remains ungraded. Run `/research navigation` to build evidence.

⚠ anti-rationalization: 0 warnings

applied: 2 mechanical · awaiting: 2 proposed · skipped: 1

/retro          review proposed grades + full retro
/retro dimensions  see accuracy by topic after grading
/retro health   check system health
```

## Formatting rules

- Header: `◆ retro — [counts]`
- Grading: ✓/✗/· prefix, quoted prediction, → outcome, (grade)
- Wrong predictions show `model update:` inline AND `todo:` for follow-up work
- Sub-score insights: which dimensions are over/under-predicted
- Accuracy: bold %, parenthetical, em-dash assessment
- Session retro: beta feature verdicts (useful/not useful/working), session comparison table
- Todos captured: list of items written to todos.yml + kill suggestions
- Stale: ⚠ prefix, age, actionable question
- Bottom: 2-3 relevant next commands

## Retro artifact format

Written to `~/.claude/cache/last-retro.yml`:

```yaml
date: YYYY-MM-DD
product_completion: 64
accuracy: 63
accuracy_trend: improving
graded_count: 3
accuracy_by_level:  # hierarchy-level accuracy breakdown
  outcome: { graded: 2, correct: 1, accuracy: 50 }
  opportunity: { graded: 3, correct: 2, accuracy: 67 }
  system: { graded: 0, correct: 0, accuracy: null }  # blind spot
  feature: { graded: 8, correct: 5, accuracy: 63 }
  micro_feature: { graded: 1, correct: 1, accuracy: 100 }
  interaction: { graded: 0, correct: 0, accuracy: null }  # blind spot
hierarchy_blind_spots: [system, interaction]  # levels with 0 predictions
wrong_predictions:
  - prediction: "auto-grade via hook"
    feature: learning
    dimension: craft_score
    hierarchy_level: feature  # which level this prediction operated at
    todo_created: "rethink auto-grade approach"
stale_patterns:
  - "copy changes have 80% keep rate — 45 days"
dead_ends_archived: 1
model_updates:
  - "session_start hook fragility → Known"
  - "craft_score predictions overshoot 40% → Known"
unknowns_surfaced:
  - "navigation patterns still untested"
score_proposals:
  - feature: scoring
    score: 58
    reason: "craft_score still <60"
todos_created: 2
todos_killed: 1
```
