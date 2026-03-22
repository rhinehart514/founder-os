# /assert Reference — Output Templates

Loaded on demand. Routing and logic are in SKILL.md.

---

## Quick-add

```
◆ assert — added

  id: auth-login
  belief: "users can log in"
  type: llm_judge
  feature: auth  w:4
  severity: warn

/eval auth         test it
/assert list       see all beliefs
/feature auth      feature status
```

## List

```
◆ assert — 25 beliefs across 6 features

▾ scoring  w:5  (6 beliefs · 5 pass · 1 warn)
  ✓ score-runs
  ✓ value-hypothesis-exists
  ✓ value-hypothesis-defined
  · score-calibrated
  · score-not-stagnant
  ✓ score-has-history

▾ learning  w:4  (5 beliefs · 3 pass · 1 warn · 1 fail)
  ✓ knowledge-model-exists
  · predictions-logged
  ✗ learning-compounds

▾ commands  w:5  (3 beliefs · 3 pass)
  ✓ commands-have-descriptions
  ✓ plan-has-recovery
  ✓ go-has-recovery

⚠ deploy  w:4  has no assertions — needs coverage

pass rate: **84%** (21/25)

/eval              run full assertions
/assert scoring: score should trend up   add one
/assert graduate ag-01                    graduate a todo
```

## Remove

With anti-rationalization gate (failing assertion):
```
◆ assert remove — score-calibrated

  ⚠ This assertion is **failing**. Failing assertions are the signal,
    not the problem. Removing it hides the bug — it doesn't fix it.

  id: score-calibrated
  belief: "score is calibrated against manual review"
  status: ✗ FAIL
  feature: scoring  w:5

  [Confirm removal] / [Fix instead: /go scoring]
```

With clean removal (passing/stale):
```
◆ assert — removed

  id: auth-login
  was: "users can log in" (llm_judge, auth)

/assert list       see remaining
```

## Graduate (from todo)

```
◆ assert graduate — ag-01

  todo: "auto-grade predictions on session start"
  feature: learning
  occurred: 2 times (2026-03-10, 2026-03-16)

  proposed assertion:
    id: learning-auto-grade
    belief: "predictions are graded automatically on session start"
    type: command_check
    command: "grep -c 'correct' ~/.claude/knowledge/predictions.tsv"
    feature: learning
    severity: warn

  [Confirm] / [Edit] / [Skip]
```

After confirm:

```
◆ assert — graduated

  todo [ag-01] → assertion [learning-auto-grade]
  todo marked done · assertion added to beliefs.yml

/eval learning     test the new assertion
/todo              see remaining items
/assert list       see all assertions
```

## Health

```
◆ assert health — 63 assertions

v8.0: **89%** pass rate · health: **B**

  ⎯⎯ live results (founder eval . --no-generative) ⎯⎯

  56/63 passing · 5 warn · 2 fail
  pass rate trend: ✓✓✓✓·✓✗✓✓✓ (last 10 runs)

  ⎯⎯ stability ⎯⎯

▾ flapping (2) — oscillate pass/fail, waste attention
  ⚠ score-calibrated        scoring    ✓✗✓✗✓✗✓✓✗✓  6 flips/10 runs
  ⚠ learning-compounds      learning   ✓✓✗✓✗✓✗✓✓✗  5 flips/10 runs

▾ stale (4) — always pass, never challenged
  · founder-yml-exists         scoring    ✓✓✓✓✓✓✓✓✓✓  23 consecutive, unchanged 40 commits
  · hooks-json-exists        commands   ✓✓✓✓✓✓✓✓✓✓  23 consecutive, unchanged 35 commits

  ⎯⎯ quality ⎯⎯

▾ trivial (1) — condition can't fail
  · config-has-features      scoring    file_check on core config — upgrade to content_check

▾ redundant (1 cluster)
  · score-runs + score-exits-zero    both test score.sh execution

▾ orphaned (0)
  ✓ all assertions map to active features

  ⎯⎯ coverage by weight ⎯⎯

  scoring     w:5  ██████████████░░░░░░  6 assertions
  commands    w:5  ██████░░░░░░░░░░░░░░  3 assertions
  learning    w:4  ████████░░░░░░░░░░░░  5 assertions
  ⚠ deploy   w:4  ░░░░░░░░░░░░░░░░░░░░  0 assertions — needs coverage

/assert flapping           fix unstable assertions
/assert suggest deploy     auto-suggest for uncovered features
/assert coverage           dimension-level gap analysis
```

## Coverage (scoped)

```
◆ assert coverage — scoring

v8.0: **89%** · scoring w:5 · 6 assertions

  ⎯⎯ dimension depth ⎯⎯

  dimension       status  depth                assertions
  value           ✓       ████████████████████  score-honest, value-hypothesis-defined
  behavior        ·       ████░░░░░░░░░░░░░░░░  score-runs (shallow — only tests exit code)
  structure       ✓       ████████████████████  score-sh-exists, score-has-history
  regression      ✗       ░░░░░░░░░░░░░░░░░░░░  no boundary tests
  edge cases      ✗       ░░░░░░░░░░░░░░░░░░░░  no error path assertions

  gap: **regression** + **edge cases** — scoring could break silently

  suggested:
  ▸ "score.sh exits non-zero on invalid input" — command_check
  ▸ "score.sh handles missing founder.yml gracefully" — command_check

/assert scoring: score exits non-zero on bad input   add the first suggestion
/assert suggest scoring                               more suggestions
/assert health                                        full health dashboard
```

## Coverage (all features)

```
◆ assert coverage — all features

v8.0: **89%** pass rate · 6 features

  ⎯⎯ coverage matrix ⎯⎯

  feature      w   value  behavior  structure  regression  edge   depth
  scoring      5   ✓      ·         ✓          ✗           ✗      ████████████░░░░░░░░
  commands     5   ✓      ✓         ✓          ·           ✗      ██████████████░░░░░░
  learning     4   ·      ·         ✓          ✗           ✗      ██████░░░░░░░░░░░░░░
  deploy       4   ✗      ✗         ✗          ✗           ✗      ░░░░░░░░░░░░░░░░░░░░
  docs         3   ✓      ·         ✓          ✗           ·      ██████████░░░░░░░░░░
  todo         3   ✓      ✓         ✓          ·           ·      ██████████████████░░

  ⎯⎯ critical gaps ⎯⎯

  ⚠ **deploy** (w:4) — zero coverage across all dimensions
  ⚠ **scoring** regression — no boundary tests for highest-weight feature
  ⚠ **learning** value — claims "predictions compound" but no assertion tests this

/assert suggest deploy     auto-suggest for biggest gap
/assert health             assertion quality dashboard
/eval                      run assertions to update cache
```

## Suggest

```
◆ assert suggest — scoring

v8.0: **89%** · scoring w:5 · 6 existing assertions

  existing coverage: value ✓ · behavior · · structure ✓ · regression ✗ · edge ✗

  ▸ suggestion 1 — regression
    id: score-rejects-bad-input
    belief: "score.sh exits non-zero when founder.yml is malformed"
    type: command_check
    why: highest-weight feature has no regression protection

  ▸ suggestion 2 — edge case
    id: score-handles-no-features
    belief: "score.sh produces a valid number even with zero features defined"
    type: command_check
    why: score is called by CI — must never produce garbage output

  ▸ suggestion 3 — behavior depth
    id: score-honest-penalty
    belief: "score.sh penalizes failing assertions, not just missing ones"
    type: llm_judge
    why: current behavior assertion only tests exit code, not scoring logic

  [Add 1] [Add 2] [Add 3] [Add all] [Skip]

/assert scoring: score exits non-zero on bad input   quick-add the first
/assert coverage scoring                              see full coverage map
/assert health                                        check assertion quality
```

## Flapping

```
◆ assert flapping — 3 oscillating assertions

v8.0: **89%** pass rate · 3 flapping out of 63

  ⚠ score-calibrated · scoring · 6 flips/10 runs
    ✓✗✓✗✓✗✓✓✗✓
    belief: "score is calibrated against manual review"
    diagnosis: **threshold boundary** — score hovers at 88-92, pass threshold is 90
    fix: widen threshold to 85 or split into hard floor + stretch goal

  ⚠ learning-compounds · learning · 5 flips/10 runs
    ✓✓✗✓✗✓✗✓✓✗
    belief: "learning system produces compounding improvements"
    diagnosis: **environment-dependent** — depends on predictions.tsv having recent entries
    fix: pin to structural check (file has >N entries) instead of recency check

  ⚠ deploy-ready · deploy · 3 flips/10 runs
    ✓✓✓✓✗✓✗✓✓✗
    belief: "project is deployable"
    diagnosis: **implementation churn** — deploy pipeline actively changing
    fix: defer until deploy stabilizes, or narrow to "build succeeds"

/assert remove score-calibrated    remove the worst offender
/assert scoring: score > 85        replace with stable version
/assert health                     full health dashboard
```

## Anti-rationalization warnings

Inline warnings shown during relevant operations:

```
⚠ all [N] assertions for **[feature]** are file_check — proves files exist, not that they work
```

```
⚠ **[feature]** has [N] assertion(s) at 100% — not enough to catch regressions
```

```
⚠ **[feature]** already has [N] assertions at [pct]%. Consider covering **[uncovered]** (w:[W], 0 assertions) instead
```

## Formatting rules

- Quick-add: show all fields, weight next to feature
- List: group by feature, ✓/·/✗ per assertion, weight in header, pass rate at bottom
- Graduate: show the todo context (how many times it recurred), the proposed assertion, confirmation prompt
- Health: sections for each signal type, coverage bars by weight at bottom
- Coverage: dimension matrix with ✓/·/✗, critical gaps called out, inline suggestions
- Suggest: 2-3 suggestions with complete fields, dimension label, why-this-gap rationale
- Flapping: sparkline per assertion, diagnosis category, concrete fix suggestion
- Remove (failing): anti-rationalization warning before confirmation
- Flag w:4+ features with 0 assertions in every mode that shows features
- Bottom: exactly 3 next commands
- Dense over verbose, bold for emphasis, no preamble, no trailing summaries
