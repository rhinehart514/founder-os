---
name: portfolio
description: "Dashboard for serial entrepreneurs. Shows all ideas, stages, evidence, patterns, prediction accuracy. The home screen. Use when you want to see where things stand."
argument-hint: "[idea-name | patterns | accuracy | timeline]"
allowed-tools: Read, Bash, Grep, Glob
---

# /portfolio — The Dashboard

You are the home screen. Show the founder where they are across all ventures.

## Routing

- **No args** → `DASHBOARD` mode (full portfolio view)
- **`[idea-name]`** → `DETAIL` mode (deep view of one idea)
- **`patterns`** → `PATTERNS` mode (what patterns have we learned)
- **`accuracy`** → `ACCURACY` mode (prediction tracking)
- **`timeline`** → `TIMELINE` mode (decision history)

---

## DASHBOARD Mode (default)

Read all state and render:

```
  ◆ founder-os  ·  [founder name]
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  portfolio    [N] ideas  ·  [N] active  ·  [N] killed  ·  [N] shipped
  accuracy     [X]%  ([N]/[M] graded)  ·  target: 50-70%
  patterns     [N] known  ·  [N] uncertain  ·  [N] dead ends
  ventures     [N] total  ·  [N] successful

  ACTIVE IDEAS
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  [idea name]          [stage]     [days in stage]
  market  [████████░░]  model  [████░░░░░░]  moat  [██░░░░░░░░]
  ⚠ [pattern if detected]
  → [one next action]

  [idea name]          [stage]     [days in stage]
  market  [██████████]  model  [████████░░]  moat  [██████░░░░]
  → [one next action]

  RECENTLY KILLED
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  [idea name]     killed [date]     learning: [one sentence]

  → [ONE recommendation: what to work on next and why]
```

### Priority Logic
Recommend the idea that:
1. Has the most evidence AND an untested kill condition (validate fast)
2. Or: has been in "researching" too long (force a decision)
3. Or: matches the founder's strongest known patterns (highest win probability)

---

## DETAIL Mode — "/portfolio [idea-name]"

Deep view of one idea:
- Full spec from portfolio.yml
- All hypotheses with status
- All related predictions with outcomes
- Related patterns from experiment-learnings.md
- Timeline of activity
- Failure pattern check
- Recommended next action

---

## PATTERNS Mode — "/portfolio patterns"

Read `~/.claude/knowledge/experiment-learnings.md` and display:
- Known patterns (high confidence, exploit these)
- Uncertain patterns (worth testing)
- Dead ends (avoid these)
- Unknown territory (highest learning value)

Format as a usable reference, not a dump.

---

## ACCURACY Mode — "/portfolio accuracy"

Read `~/.claude/knowledge/predictions.tsv` and display:
- Overall accuracy rate
- Accuracy by type (market, model, customer, strategy)
- Recent trend (improving or declining)
- Most valuable wrong predictions (biggest model updates)
- Calibration: are you predicting at 70% confidence and right 70% of the time?

---

## TIMELINE Mode — "/portfolio timeline"

Chronological view:
- When each idea was created
- Key evidence milestones
- Decisions (go/kill/park/pivot) with dates
- Predictions and their outcomes
- Pattern discoveries

---

## State Reads (read-only — this skill never writes)
- `config/portfolio.yml`
- `~/.claude/knowledge/experiment-learnings.md`
- `~/.claude/knowledge/predictions.tsv`
- `.claude/cache/last-research.yml`
- `.claude/cache/money-analysis.yml`
