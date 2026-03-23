# /quick Gotchas

Real failure modes. Read before starting any quick task.

## 1. Scope creep disguised as "quick"

The task sounds small but touches 8 files across 3 features. If you're touching more
than one feature boundary, this isn't quick — route to /go.

**Heuristic:** If the plan has 4+ tasks or touches 3+ features, stop and suggest /go.

## 2. Skipping prediction because "it's obvious"

"Obviously this will work" is the prediction that teaches nothing. The prediction
isn't about difficulty — it's about what you expect to happen. Log it.

## 3. No baseline, no comparison

You make the change, it "looks good," you move on. Then next /eval shows a 10-point
drop and you don't know which quick task caused it. Always snapshot before.

## 4. Inline when you should delegate

Complex tasks executed inline lose worktree isolation. If the task could break the
working tree (refactors, dependency changes, build config), use the builder agent.

## 5. Over-discussing small tasks

--discuss is for tasks with genuine ambiguity. "Fix the typo in README" doesn't need
gray area analysis. Skip --discuss when the task is unambiguous.

## 6. Research rabbit hole

--research on a well-understood task wastes tokens. Use --research when you genuinely
don't know the best approach, not as a safety blanket.

## 7. Forgetting to grade

The prediction is worthless if you don't grade it. Step 9 is not optional. Wrong
predictions are the most valuable — they update the model.
