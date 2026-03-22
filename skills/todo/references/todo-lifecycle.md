# Todo Lifecycle

## States

```
captured → tagged → prioritized → promoted → done → (graduated | archived)
                                          ↘ killed
```

**captured**: Item enters backlog via `/todo add`, cross-skill capture, or agent `todo:add`. Has title, source, created_at. May lack feature tag.

**tagged**: Feature and/or version assigned. Auto-tagging attempts on capture; manual via `/todo tag`.

**prioritized**: Matched to eval-cache bottleneck by `todo-promote.sh`. Not a stored status — computed on display.

**promoted (active)**: Founder activates for current session via `/todo promote`. Visible in `/plan` as available work.

**done**: Completed via `/todo done`. Triggers graduation check.

**graduated**: Recurring pattern promoted to assertion in `beliefs.yml`. The todo is deleted — assertions are permanent.

**killed**: Founder decides item is not worth doing. Removed from backlog. No trace except idea-log if it came from `/ideate`.

## Decay rules

Decay runs on every `/todo` display. Never auto-deletes — surfaces and forces a decision.

| Age | Condition | Flag |
|-----|-----------|------|
| >7d | Untagged | `⚠ untagged — tag or kill` |
| >14d | Any status except done | `⚠ stale — promote, kill, or /research?` |
| >30d | Any status except done | `⚠ 30+ days — kill it, promote it, or convert to research` |

Decay is computed from `created_at`. If missing, item is flagged as `⚠ no date — fix or kill`.

A backlog with 0 stale items = healthy. 5+ stale items = capturing without deciding.

## Graduation criteria

A todo graduates to an assertion when:

1. **Recurrence**: A todo with similar text has been completed before (fuzzy keyword match on title, same feature). Two completions of the same pattern = assertion candidate.

2. **Regression**: The feature's eval score dropped after the todo was last completed. The fix didn't stick — make it permanent.

3. **Founder request**: `/todo done <id>` with explicit "graduate this" intent.

Graduation writes to `lens/product/eval/beliefs.yml`:
- `type: file_check` or `content_check` if mechanically verifiable
- `type: llm_judge` if it needs judgment
- `feature:` from the todo's tag
- The todo is then deleted from `todos.yml`

## Velocity tracking

Each item tracks timestamps:
- `created_at` — when captured
- `promoted_at` — when activated (null if never)
- `done_at` — when completed (null if not done)

`/todo health` computes:
- Avg days backlog → active (how long items sit)
- Avg days active → done (how long active work takes)
- Per-feature velocity (which features have slow todos)
- Done rate: done / total
