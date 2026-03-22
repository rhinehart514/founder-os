# /todo Reference — Output Templates

Loaded on demand. Routing and logic are in SKILL.md.

---

## Default view (`/todo`)

Includes decay check and smart promote suggestion.

```
◆ todo — 8 items (2 active, 1 stale)

▸ active
  ▸ [learning] auto-grade predictions on session start          [ag-01]
  ▸ [scoring] add trend sparkline to score output               [ts-02]

· backlog
  · [commands] output formatting consistency             v8.0   [of-03]
  · [learning] knowledge model pruning                   v8.0   [km-04]
  · fix install script for fish shell                           [fi-05]
  ⚠ [eval] reduce LLM judge variance                    18d    [lj-06]

▾ decay
  ⚠ lj-06 — 18 days in backlog, no action. Promote, kill, or /research?

▾ smart promote
  Promoting **km-04** would target **learning**'s craft_score (40) — your weakest dimension.

/todo promote km-04    activate the suggestion
/todo done ag-01       mark complete
/plan                  turn active todos into moves
```

## After add (with auto-tag)

```
◆ captured — "fix error handling in score.sh"

  id: eh-08 · status: backlog
  auto-tagged: [scoring] (score.sh is in scoring's code paths)

/todo tag eh-08 v8.0    connect to version
/todo promote eh-08     activate for session
/go scoring             build it now
```

## After done (with graduation suggestion)

```
◆ done — [ag-01] "auto-grade predictions on session start"

  was: active · feature: learning
  completed in 2 days (learning avg: 3.1 days)

▾ graduation check
  ⚠ This is the 2nd time a learning error-handling todo was completed.
  Previous: "fix prediction grading edge case" (done 2026-03-10)
  Graduate to assertion?
    → learning: prediction grading handles empty predictions.tsv gracefully

  [Graduate] / [Skip]

/retro             close the learning loop
/todo              see remaining items
```

## After done (no graduation)

```
◆ done — [ts-02] "add trend sparkline to score output"

  was: active · feature: scoring
  completed in 1 day (scoring avg: 1.4 days)

/retro             close the learning loop
/todo              see remaining items
```

## Health report (`/todo health`)

```
◆ todo health

  items: 8 total · 2 active · 5 backlog · 1 done
  done rate: **12%** (1/8)
  stale: 1 item >14 days

▾ velocity
  backlog → active:  avg 4.2 days
  active → done:     avg 2.1 days
  total lifecycle:   avg 6.3 days

▾ by feature
  scoring    2 items  avg 1.4d to done   healthy
  learning   3 items  avg 3.1d to done   slow — feature is hard or unclear
  commands   1 item   12d in backlog     ⚠ stale
  untagged   2 items                     ⚠ tag or kill

▾ signals
  ✓ all active items are tagged to features
  ⚠ 2 untagged items in backlog
  ⚠ 1 item >14 days without action
  · 0 items graduated to assertions this session

/todo decay        force stale item decisions
/todo tag fi-05 install   tag an untagged item
/feature           check which features need todos
```

## Decay check (`/todo decay`)

```
◆ todo decay — 3 items need decisions

  ⚠ [lj-06] "reduce LLM judge variance"  18 days
    feature: eval · never promoted
    → Promote / Kill / Convert to /research question?

  ⚠ [fi-05] "fix install script for fish shell"  22 days
    untagged · never promoted
    → Promote / Kill / Tag first?

  ⚠ [xx-09] "redesign dashboard layout"  35 days
    feature: commands · never promoted
    → This has been sitting for 35 days. Kill it?

/todo promote lj-06    activate
/todo done fi-05       if already fixed
```

## Version filter (`/todo version v8.0`)

```
◆ todo — v8.0 (4 items, 1 done)

▸ active
  ▸ [learning] auto-grade predictions                           [ag-01]

· backlog
  · [commands] output formatting consistency                    [of-03]
  · [learning] knowledge model pruning                          [km-04]

✓ done
  ✓ [scoring] calibration fix                                   [cf-07]

/todo promote of-03    activate
/roadmap               check thesis progress
```

## Feature filter (`/todo feature learning`)

```
◆ todo — learning (3 items, 1 active)

  eval: 48/100 (d:55 c:40 v:48) — craft_score is weakest

▸ active
  ▸ auto-grade predictions on session start                     [ag-01]

· backlog
  · knowledge model pruning                              v8.0   [km-04]

/go learning           build active items
/eval learning         check current state
```

## Cross-skill + agent capture format

When skills or agents write todos:

```yaml
# in todos.yml
- id: pl-10
  title: "investigate alternative approach to learning"
  status: backlog
  feature: learning
  source: /go plateau
  created_at: 2026-03-16

- id: rv-11
  title: "unhandled error path at eval.sh:720"
  status: backlog
  feature: eval
  source: /go reviewer
  created_at: 2026-03-16

- id: ms-12
  title: "learning stuck at 48 — 3 evals without improvement"
  status: backlog
  feature: learning
  source: /eval measurer
  created_at: 2026-03-16

- id: ex-13
  title: "research: does multi-lens composition work?"
  status: backlog
  source: /research explorer
  created_at: 2026-03-16
```

Shown in list:

```
· backlog
  · [learning] investigate alternative approach         /go         [pl-10]
  · [eval] unhandled error path at eval.sh:720          /go rvw     [rv-11]
  · [learning] stuck at 48 — 3 evals w/o improvement   /eval       [ms-12]
  · research: does multi-lens composition work?         /research   [ex-13]
```

Source tags show origin. Priority boost for:
- `/go plateau` items (the build loop hit a wall)
- `/eval measurer` regression items (something got worse)
- `/go reviewer` items (known issues in kept code)

## Empty state

```
◆ todo — empty

  No items in backlog. Good or bad — depends on whether you're capturing.

/todo add "title"    capture something
/ideate              brainstorm ideas to capture
/eval                find gaps that need todos
```

## Formatting rules

- Active: `▸` prefix
- Backlog: `·` prefix
- Done: `✓` prefix (only in `all` or `version` views)
- Stale: `⚠` prefix with age in days
- Feature tags in brackets: `[learning]`
- Version tags after title: `v8.0`
- Source tags after title: `/go`, `/eval` (for cross-skill captures)
- IDs right-aligned in brackets: `[ag-01]`
- Decay section only shown when stale items exist
- Smart promote only shown when 0 active items
- Feature filter shows eval sub-scores for that feature
- Bottom: exactly 3 next commands
