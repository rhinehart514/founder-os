# Rubric Guide

Rubrics are the calibration mechanism that kills score variance across sessions.

## Why rubrics exist

Without rubrics, the same code scored by different sessions swings +/-15 points. Rubrics anchor the evaluator to specific criteria so that:
- Same code = same score (within 5 points)
- Score changes are caused by code changes, not evaluator drift
- Criteria accumulate across sessions (the eval gets smarter)

## How rubrics work

Each feature gets a rubric at `.claude/cache/rubrics/<feature>.json`. The rubric stores:
- **Last score and date** — the anchor point
- **Dimension criteria** — what specifically was evaluated for delivery, craft, viability
- **Known gaps** — acknowledged weaknesses (so the same gaps aren't "discovered" every time)
- **Score history** — trend line across all evals

## When rubrics are created

- **First eval:** No rubric exists. Score from scratch. Write the rubric after scoring. Flag the score as "unanchored" — it has no calibration reference.
- **Subsequent evals:** Rubric exists. Read it BEFORE scoring. Use its criteria as the starting point. Add/remove criteria based on code changes, but don't reinvent the scoring frame.

## What makes a good rubric

**Good criteria are:**
- Specific: "health gate prevents score output when build fails" not "has error handling"
- Observable: points to a specific code behavior, not a vibe
- Stable: doesn't change unless the code changes
- Falsifiable: you can check whether the criterion is met or not

**Bad criteria:**
- "Code is clean" — too vague, different evaluators interpret differently
- "Good architecture" — not observable, not falsifiable
- "Handles errors" — which errors? Where? How?

## Updating rubrics

After every eval:
1. Compare your new criteria against the existing rubric
2. **Add** criteria for new code paths or capabilities
3. **Remove** criteria for deleted code
4. **Update** criteria that no longer match the code
5. **Append** new score to `score_history`
6. **Update** `known_gaps` — remove gaps that were fixed, add new ones

Never clear the rubric and start over. The history IS the calibration.

## Rubric structure

Use `templates/rubric-template.json` as the base. Key fields:

```json
{
  "feature": "feature-name",
  "last_score": 58,
  "last_scored": "2026-03-16T12:00:00Z",
  "delivery_criteria": ["specific observable criteria"],
  "craft_criteria": ["specific observable criteria"],
  "known_gaps": ["acknowledged weaknesses"],
  "score_history": [54, 58]
}
```

## Variance detection

Before publishing any score, run:
```bash
bash scripts/variance-check.sh <feature> <proposed_score>
```

If delta > 15 from the rubric's last score:
1. Check `git log` — has the code actually changed?
2. If code changed significantly: update rubric criteria, publish new score
3. If code barely changed: your evaluation drifted, not the code. Re-calibrate against the rubric criteria.
