# Prediction Grading Guide

Read this before grading. These rules exist because LLMs grade their own predictions leniently by default.

## Grade definitions

| Grade | Meaning | Score |
|-------|---------|-------|
| `yes` | Prediction matched outcome. Direction correct, magnitude within 30%. | 1.0 |
| `partial` | Direction correct but magnitude off >30%, or correct on some dimensions but not all. | 0.5 |
| `no` | Wrong direction, wrong mechanism, or outcome contradicts the prediction. | 0.0 |

## Numeric predictions

These are the easiest to grade mechanically.

- "Raise X from 42 to 55" → check eval-cache/score-cache
  - Hit target (>=55): `yes`
  - Right direction, within 70% of target delta (>=51): `partial`
  - Wrong direction or below 70% of target delta (<51): `no`
- "Assertions will increase by N" → check assertion count delta
- "Score will improve by >5" → check history.tsv delta

**Rule: grade against what was written, not what was meant.** "Raise to 55" that reaches 48 is `partial`, not `yes`.

## Directional predictions

- "X will improve" → check eval-deltas for direction
  - Improved: `yes`
  - Flat (within noise, +/-2): `partial`
  - Declined: `no`

## Approach predictions

- "This approach will work because [mechanism]" → check if:
  - Code was committed and kept + assertions passed: `yes`
  - Code was committed but assertions flat: `partial`
  - Code was reverted: `no`

**The mechanism matters.** If the prediction said "X because Y" and X happened but for reason Z, grade based on whether the mechanism (Y) was correct. Lucky outcomes from wrong models are `partial` at best.

## Qualitative predictions

Can't be mechanically graded. For each:
1. Find the best measurable proxy
2. Propose a grade with evidence
3. Mark `[proposed]` in the result column
4. Present to founder for confirmation

Never auto-commit qualitative grades.

## Partial credit rules

Partial is tempting because it avoids committing. Use these constraints:

1. **Would rounding to yes or no change the model update?** If yes, round.
2. **Is the prediction genuinely split?** Example: "raise delivery from 40 to 60 AND craft from 30 to 50" — delivery hit, craft didn't. That's legitimately partial.
3. **If >50% of grades in a session are partial**, push harder. Something is wrong — either the predictions are too vague or the grading is too hedged.

## What makes a good model update

When a prediction is wrong, the model update column answers: "What was the mechanism I got wrong?"

**Good model updates:**
- "Overshoot: craft_score predictions consistently +40% too optimistic. Boundary: improvements >10pts in one move are rare."
- "Wrong mechanism: assumed hook reliability, actual failure was context loss on compaction."
- "Dead end confirmed: auto-generated assertions from code produce low-signal tests (3rd attempt)."

**Bad model updates:**
- "Will try harder next time" (no mechanism)
- "This was expected" (then why was it graded wrong?)
- "" (empty — every wrong prediction should update the model)

## Anti-rationalization checkpoints

Run these AFTER grading, BEFORE committing:

1. **All correct?** Last 5 all `yes` → predictions are confirmatory, not informative. Push into Unknown Territory.
2. **Accuracy jump?** >20% increase in single retro → review for leniency. Compare evidence quality.
3. **Model update without evidence?** Every update must cite a graded prediction. No "it felt right."
4. **Zombie dead end?** Dead end with recent prediction citations is not dead. Move to Uncertain.
5. **Partial avalanche?** >50% partial → push for yes/no. Partial is the hedge.
6. **"Right in spirit"?** Grade against text, not intent. Prediction said 55, hit 48 = partial, not yes.
7. **Stale grades?** Predictions >14 days old are harder to grade accurately. Acknowledge reduced confidence.
8. **Model stagnation?** No model updates in 3+ retro sessions → model is dead. Force an update.
