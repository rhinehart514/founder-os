# Plan Output Template

Dense, scannable, opinionated. This is a reference — adapt to the situation, don't fill in blanks mechanically.

## Full planning output

```
◆ plan — [feature name or "full product"]

v8.0: **43%** · product: **64%** · score: 92 · predictions: 63%
thesis: "Someone who isn't us can complete a loop without help"
evidence: install-clean ◐ · reach-plan ◐ · first-go · · return ·

▾ product map
  scoring    ████████████████████  polished  w:5  58 (d:62 c:50 v:60) ↑4
  commands   ████████████░░░░░░░░  working   w:5  70 (d:75 c:65 v:68) ↑2
  learning   ██████░░░░░░░░░░░░░░  building  w:4  48 (d:55 c:40 v:48) ↓3  ← bottleneck
  install    ████████████████████  polished  w:3  68 (d:70 c:60 v:72) —

▾ signals
  assertions 26/37  ·  todos 8/14 done  ·  plan 3/5 tasks
  previous plan: "Structured Plans + Todos" — all tasks done
  last 3 commits: [hash] [msg], [hash] [msg], [hash] [msg]

▾ graded predictions
  ✓ "trend_for() will raise scoring to 60+" → 58 (partial)
  ✗ "auto-grade will work without API" → not implemented (wrong)
    model update: auto-grading needs explicit build, not emergent

◆ bottleneck: **learning** · weakest: **craft_score 40** ↓3

  The learning feature claims "a model that gets smarter every session"
  but predictions.tsv has 16 entries with only 8 auto-graded.
  craft_score is the weakest dimension — error handling and edge cases.

▸ move 1 — auto-grade predictions on session start
  feature: learning · dimension: quality
  advances: first-go (thesis evidence: does /go produce improvement?)
  informed_by: "Predictions log but never grade" (Known — self.md)
  predict: grading predictions mechanically will raise craft_score from 40 to 55
  accept: session_start hook grades predictions with filled result columns
  touch: hooks/session_start.sh, bin/self.sh

▸ move 2 — knowledge model pruning
  feature: learning · dimension: quality
  informed_by: "Knowledge model is append-only" (Known — self.md)
  predict: adding a staleness check will raise craft_score to 60
  accept: experiment-learnings.md entries older than 30 days get flagged

/go learning         start building
/go learning --safe  start building (sequential only)
/research learning   explore unknowns first
```

## Formatting conventions

- Header: `◆ plan — [scope]`
- State bar: version completion, product completion, score, prediction accuracy — one line
- Thesis: current thesis quoted, evidence items with status markers (● = proven, ◐ = partial, · = todo)
- Product map: maturity bars + weight + score with sub-scores `(d:N c:N v:N)` + delta arrow
- Signals: collapsed, 4-5 lines max
- Graded predictions: ✓/✗ prefix, quoted prediction, outcome. `model update:` on wrong predictions.
- Bottleneck: `◆ bottleneck: **[name]** · weakest: **[dimension] [score]**`
- If version completion >80%: `◆ thesis nearly proven — recommend /roadmap bump` before moves
- Moves: `▸ move N — [title]` with feature/dimension/informed_by/predict/accept/touch
- Bottom: 2-3 relevant next commands

## Sub-score bottleneck rules

- Bottleneck = lowest sub-score among highest-weight features
- If two features tie on weight, worse delta gets priority
- Low delivery → "code doesn't deliver what the claim promises"
- Low craft → "error handling, edge cases, robustness"
- Low viability → "output clarity, user feedback, progressive disclosure"

## Quick capture format

```
◆ captured — "[task text]"
  feature: [auto-detected or unscoped]
  type: task (TaskCreate) | assertion (beliefs.yml)
```

## Brainstorm format

```
◆ plan brainstorm

v8.0: **43%** · product: **64%**

▾ 5 high-information directions
  1. [direction] — Exploring: [what this teaches]
     feature: [name] · predicted impact: [sub-score] +N
     risk: [what could go wrong]
  ...
```

## Critique format

```
◆ plan critique

▾ first contact — what a stranger sees, time to value, friction
▾ core loop — what works, what breaks
▾ edge cases — 3-5 specific failure scenarios
▾ 3 worst things — with evidence
```

## Research override

When `~/.claude/cache/last-research.yml` exists and is <24h old, insert between signals and bottleneck:
```
▾ research — [topic] (N hours ago)
  [key findings, 2-3 lines]
  suggested: [task from research]
```
