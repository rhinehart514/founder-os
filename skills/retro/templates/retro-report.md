# Retro Report Template

Use this structure for all retro output. Adapt sections based on route.

## Full retro

```
◆ retro — [N] ungraded, [M] stale

product: **[X]%** · score: [Y] · todos: [done]/[total] done · predictions: [acc]%
accuracy trend: [old]% → [mid]% → [new]% [bar] [improving/stable/declining]

  ⎯⎯ grading ⎯⎯

  ✓ "[prediction text]" → [outcome] (yes)
  · "[prediction text]" → [outcome] (partial)
    actual: [what actually happened]
  ✗ "[prediction text]" → [outcome] (no)
    model update: [what was learned]
    todo: [feature] [what needs doing]    /retro  [new]

  ⎯⎯ accuracy ⎯⎯

  **[X]%** ([N]/[M]) — [calibration assessment]
  trend: [direction] from [old]% ([assessment])

  ⎯⎯ sub-score insights ⎯⎯

  most predicted: [dimension] ([N] predictions) — [acc]% correct ([insight])
  least predicted: [dimension] ([N] prediction) — blind spot
  best calibrated: [dimension] ([N] predictions) — [acc]% correct

  ⎯⎯ learning velocity ⎯⎯

  predictions/week: [N] · model updates/week: [N] · freshness: [N] days
  velocity: [improving/stable/declining]

  ⎯⎯ stale knowledge ([N] entries) ⎯⎯

  · "[pattern]" — last evidence [N] days ago
  · "[unknown]" — in Unknown Territory for [N] days, 0 experiments

▾ pruned
  · Moved "[pattern]" to Stale Patterns ([N] days)

▾ model updates
  ▸ "[pattern]" [from zone] → [to zone] ([evidence])
  ▸ "[new pattern]" added to [zone]

▾ todos captured
  · [feature] [description]    /retro  [new]
  · kill [id] — [reason]       /retro  [kill]

▾ session logged
  · retro-log.sh: graded:[N] pruned:[M] acc:[X]%

artifact: ~/.claude/cache/last-retro.yml

/plan       apply learnings to next session
/research   explore the unknowns surfaced above
/todo decay force decisions on stale items
```

## Accuracy-only (`/retro accuracy`)

```
◆ retro accuracy

  **[X]%** ([N]/[M] graded, partials at 0.5)
  calibration: [assessment] (target: 50-70%)
  trend: [direction] from [old]% over last [N] sessions

  by domain:
    [domain] predictions: [acc]% correct ([N]/[M])
    [domain] predictions: [acc]% correct ([N]/[M]) — [flag]

/retro          full retro with grading
/plan           make predictions for next session
```

## Health dashboard (`/retro health`)

```
◆ retro health — learning system diagnostic

  ⎯⎯ prediction frequency ⎯⎯
  this week: [N] · last week: [N] · avg: [N]/week
  frequency:  [bar]  [N]/wk (target: 3-5)

  ⎯⎯ grading latency ⎯⎯
  avg: [N] days · ungraded backlog: [N] (oldest: [date])
  latency:  [bar]  [N]d (target: <3d)

  ⎯⎯ model freshness ⎯⎯
  Known: [N] · Uncertain: [N] · Unknown: [N] · Dead: [N] · Stale: [N]
  Known:Unknown ratio: [X]:1 — [assessment]
  freshness:  [bar]  updated [N] days ago (target: <7d)

  ⎯⎯ learning velocity ⎯⎯
  predictions/week: [trend]
  model updates/week: [trend]

  ⎯⎯ retro frequency ⎯⎯
  [from retro-log.sh stats output]

  ⎯⎯ warnings ⎯⎯
  · [warning text]

/retro          full retro with grading
/retro auto     auto-grade the backlog
```

## Session retro (`/retro session`)

```
◆ retro session — [date]

  scope: [feature] · mode: [mode]
  moves: [N] · kept: [N] · reverted: [N]
  score: [old] → [new] [direction][delta] · ROI: [N] points/move

▾ predictions
  [grading lines]
  session accuracy: **[X]%** — [assessment]

▾ beta features
  [speculative branching / adversarial review / grading verdicts]

▾ session learnings
  · [what was learned]

▾ comparison to previous sessions
  session   moves  kept  ROI    accuracy
  [rows]

/plan           next session
/retro stale    check knowledge freshness
```

## Formatting rules

- Header: `◆ retro — [counts]`
- Grading: ✓/✗/· prefix, quoted prediction, → outcome, (grade)
- Wrong predictions: `model update:` inline + `todo:` for follow-up
- Accuracy: bold %, parenthetical, em-dash assessment
- Todos: `[feature] description    /retro  [new|kill]`
- Bottom: 2-3 relevant next commands
- No ASCII tables in body text — use compact pulse format
