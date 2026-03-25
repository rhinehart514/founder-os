# Move Brief Template

Every proposed move uses this structure. Don't skip fields — empty fields mean the move isn't ready.

```
▸ move N — [title]
  feature: [name]
  dimension: [delivery | craft | viability]
  advances: [roadmap evidence item ID, or "maintenance"]
  informed_by: [cite experiment-learnings pattern, or "Exploring: [what this teaches]"]
  predict: [raise METRIC from X to Y]
  wrong_if: [falsification condition — what would prove this move was wrong]
  accept: [specific acceptance criteria — assertion IDs, observable outcomes]
  touch: [files likely modified]
```

## Quality checks

- If `informed_by` is empty -> you're guessing. Cite evidence or declare exploration.
- If `predict` has no numbers -> ungradable. Force a specific target.
- If `wrong_if` is missing -> you haven't thought about failure. Every move can fail.
- If `accept` is vague -> how will you know it worked? Name the assertion or the observable change.
- If `dimension` doesn't match the sub-score diagnosis -> you're solving the wrong problem.
- If `advances` is empty AND this isn't maintenance -> disconnect from thesis. Either connect it or question the thesis.

## When to propose 1 move vs 2

**1 move**: the bottleneck is clear, the approach is obvious, the work is >2 hours.
**2 moves**: the first move is quick (<1 hour) and unblocks the second, OR two different dimensions need attention on the same feature.

Never propose 3+ moves. That's task management, not strategy.
