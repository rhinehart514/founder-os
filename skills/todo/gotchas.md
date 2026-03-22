# Todo Gotchas

Real failure modes. Update when /todo fails in a new way.

## Capture failures
- **Todo as procrastination**: Capturing todos feels productive. A growing backlog with nothing completed is avoidance. Check done rate — below 20% means you're hoarding, not managing.
- **Vague titles**: "fix auth" is not actionable. "Fix auth redirect loop when session expires" is. If you can't describe the done state, the todo isn't ready.
- **Duplicate capture**: Check existing todos before adding. Same problem phrased differently creates noise. Grep for keywords first.

## Decay failures
- **Never running decay**: If `todo-decay.sh` isn't running on show, stale items accumulate silently. The default `/todo` view must always include decay output.
- **Threshold mismatch**: 7/14/30 day thresholds assume weekly engagement. Projects with monthly cadence need different thresholds. But most projects claiming monthly cadence are actually avoiding decisions.
- **Decay without decisions**: Seeing the decay warnings and doing nothing is worse than not seeing them. Each stale flag demands one of: promote, kill, or convert to /research.

## Promotion failures
- **Smart promote mis-ranking**: Bottleneck-based suggestion ignores effort. A 2-hour fix on a non-bottleneck may deliver more than a 2-week project on the bottleneck. Use smart promote as signal, not directive.
- **Promoting without capacity**: 5+ active items means nothing is really active. Active should be 1-3 items, max. If more are active, some should go back to backlog.
- **Source-blind promotion**: A todo from `/eval measurer` (regression) deserves faster promotion than one from `/ideate` (speculative). Check the source field.

## Graduation failures
- **Keyword false positives**: "Fixed auth bug" and "Fixed auth redirect" share "auth" but are different problems. Graduation check uses fuzzy match — founder must confirm the pattern is real.
- **Graduating to bad assertions**: An assertion should be mechanically verifiable when possible. "Auth works" is a bad assertion. "Auth redirect returns 302 to /dashboard" is good. Prefer `file_check`/`content_check` over `llm_judge`.
- **Never graduating**: If todos keep recurring without graduation, the measurement system has a gap. That gap is the real problem.

## Backlog health failures
- **Never killing**: Some todos should die. 60+ days with nobody caring = delete. The kill is information — it means this wasn't important.
- **All items same feature**: If 5+ todos are on one feature, the feature needs a plan, not more todos. Run `/plan` on that feature.
- **Zero items**: Either you're not capturing (bad) or everything is done (good). Check if `/eval` has gaps, `/go` had findings, or predictions were wrong. Those should be todos.
