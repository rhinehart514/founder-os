# Reading the Dashboard

What each number means and how to interpret the signals.

## Portfolio Summary (top zone)

Only appears when `~/.founder-os/portfolio.yml` exists. Shows where you stand across all ideas.

**[N] ideas / [N] active / [N] killed** — Your portfolio at a glance. Active ideas are being worked. Killed ideas have learnings attached. A healthy portfolio has more killed ideas than active ones — it means you're validating fast and cutting losers.

**accuracy [X]%** — Prediction accuracy across all ideas. Target 50-70%. Below 40% means the model is broken. Above 80% means predictions are too safe.

## Score (the anchor)

**score N/100** — Composite of assertion pass rate (value) and structural health. This is the single number that answers "is the product getting better?"

- 0-29: Pre-product. Claims don't match code. Focus on delivery.
- 30-49: Building. Some things work. Gaps are obvious.
- 50-69: Working. Core value delivered. Craft and viability lag.
- 70-89: Polished. Quality is real. Viability questions remain.
- 90+: Proven. Assertions pass, health is clean, features deliver.

**assertions pass/total** — How many beliefs about the product are true. This is the value signal. Assertions failing = the product doesn't do what it claims.

**health N** — Structural lint score. Build passes, files are organized, hygiene is clean. High health + low score = clean code that doesn't deliver value. Low health + high score = working product with tech debt.

**delivery / craft / viability** — The three dimensions from /eval. Delivery = does it work? Craft = is it well-made? Viability = can it succeed? A product with d:80 c:30 v:50 works but looks rough and has uncertain viability.

## Thesis

**thesis "text" N%** — The current version's hypothesis. Version completion = evidence proven / total evidence. This answers "are we learning what we set out to learn?"

- Evidence at 0% after 7+ days = thesis avoidance or wrong thesis
- Evidence at 80%+ = ready to bump version

## Features

**product: N%** — Weighted average of all feature scores. Features with higher weights pull this number more.

**w:N** — Feature weight (1-5). Higher = more important to the value hypothesis. The bottleneck is the lowest-scoring highest-weight feature.

**delta** — Change since last eval. ↑ = improving. ↓ = regressing. Regressions on high-weight features are urgent.

**`<-` marker** — The bottleneck. This is the single feature holding the product back. /go should target this.

## Signals

**predictions: N% accurate** — Model calibration. 50-70% = well-calibrated (making informative, non-trivial predictions). Below 40% = model is broken. Above 80% = predictions are too safe.

**ungraded** — Predictions logged but never checked. Ungraded predictions = learning loop leak. More than 5 ungraded = /retro needed.

**todos** — Backlog health. Active = being worked on. Backlog = queued. Stale = older than 14 days with no progress. A growing stale count means the backlog is a graveyard.

## Opinion

The single bold sentence at the bottom. This is /founder's judgment call about what matters most right now. It follows a decision tree (version completion -> bottleneck score -> assertion state -> backlog health) but pattern detection can override it when meta-patterns emerge across snapshots.

The three commands below the opinion are the recommended next actions, ordered by priority.

## When to worry

- Score dropped between snapshots without intentional changes
- Bottleneck hasn't changed in 3+ snapshots (stagnation)
- Score improving but product completion flat (optimizing the thermometer)
- No predictions logged in 7+ days (blind building)
- Thesis evidence stalled for 3+ snapshots (avoiding the hard question)
- Portfolio has 0 killed ideas (not validating hard enough)
- Portfolio accuracy below 40% (model is broken — recalibrate)
