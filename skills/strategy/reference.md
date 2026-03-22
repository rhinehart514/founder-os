# /strategy Reference — Output Templates

Loaded on demand. Strategic lens and steps are in SKILL.md.

---

## Full strategic diagnosis

```
◆ strategy

  stage: **one** — "core loop works for one person"
  thesis: "Someone who isn't us can complete a loop without help"

  ▾ the honest take

    You've spent the last 4 sessions on eval engine improvements. The eval
    engine is now sophisticated — multi-sample median, sub-scores, rubrics,
    structured output. Score is 95/100. Assertions are 57/63 passing.

    **None of this matters yet.** You're at stage one. The only question
    is: can someone who isn't you get value from this? And the answer is:
    untested. commander.js got init→score working. Nobody has run the
    full /go loop externally.

    You're avoiding the hard thing: giving this to a stranger and watching
    what breaks. The eval engine can score at 100 and it means nothing if
    nobody uses it.

  ▾ failure mode: **measurement theater**
    Predictions logged, assertions passing, scores high — but the product
    hasn't been used by anyone outside the development loop. This is the
    classic stage-one death: perfecting the instrument while the patient
    is unexamined.

  ▾ leverage analysis
    #1 move: **test the full loop externally** (bottleneck: first_loop 1/5)
      impact: directly proves/disproves the v8.0 thesis
      confidence: high (init→score already proven on commander.js)
      effort: 1 session
      → this one move is worth more than 10 sessions of eval improvements

  ▾ what to stop
    · Stop improving the eval engine until someone uses the product
    · Stop adding assertions — 57 is enough for stage one
    · Stop polishing commands — they work, they just need a user

  ▾ product map
    scoring     w:5  ██████░░░░  working     58 (d:62 c:50 v:60) ↑4
    commands    w:5  ██████░░░░  working     70 (d:75 c:65 v:68) ↑2
    learning    w:4  ███░░░░░░░  building    48 (d:55 c:40 v:48) ↓3
    install     w:3  ██████████  polished    68 — but only tested once
    docs        w:3  ██████░░░░  working
    self-diag   w:2  ██████░░░░  working
    todo        w:2  ██████░░░░  working

    feature sprawl: **7 features, 0 polished+proven** — too wide, not deep enough

  ▾ loop health
    install:    ███░░  3/5
    setup:      ██░░░  2/5
    first_loop: █░░░░  1/5  ← bottleneck
    value:      █░░░░  1/5
    return:     █░░░░  1/5

  ▾ learning health
    predictions: 63% accuracy (10/16) — well-calibrated
    grading: 6 ungraded — loop is leaking
    velocity: 2.1 pts/move (last 3 sessions) — stable
    knowledge model: 3 stale patterns, 2 unexplored unknowns

  ▾ graduation criteria (one → some)
    ✓ 10+ predictions logged
    ✓ 3+ experiment learnings
    · 2/3 unknowns resolved (1/3)
    · first_loop >= 3/5 (currently 1/5)
    · 1 external user completes full loop

  opinion: **test externally. everything else is avoidance.**

/go --safe         run the proven loop on an external project
/research          explore the unknowns
/retro             grade the 6 ungraded predictions
```

## Honest mode (`/strategy honest`)

```
◆ strategy honest

  If I'm being completely honest:

  You're building a measurement system for products, but you haven't
  measured whether anyone wants a measurement system. The score is 95
  but that number measures internal consistency, not external value.

  The one thing that matters: **put this in someone else's hands.**
  Not to validate the product — to find out what breaks, what confuses,
  and what they actually use vs ignore.

  What you're avoiding: the possibility that the answer is "this is
  too complex" or "I don't need this." That's the highest-information
  experiment available, and you've been deferring it for 4 sessions.

  The real risk isn't that the code is bad. It's that the code is
  good and nobody cares.

/init [external-project]   bootstrap on something real
/research "who needs this"  find the person
/product                    revisit assumptions
```

## Refresh output (abbreviated)

```
◆ strategy refresh

  updated strategy.yml

  changes:
    bottleneck: first-loop (unchanged)
    loop health: install 3→3, setup 2→2, first_loop 1→1
    feature sprawl: 7 features (was 7) — no new features, good
    stale patterns: 3 (was 2) — "copy changes" moved to stale

  diagnosis unchanged: external testing is still the bottleneck.

/strategy          full diagnosis
/plan              plan the external test
```

## Formatting rules

- Header: `◆ strategy`
- **The honest take** comes FIRST — before any numbers. 3-5 sentences, no hedging.
- **Failure mode** named explicitly with evidence
- **Leverage analysis** — ONE move, with impact/confidence/effort
- **What to stop** — at least one thing. This is mandatory.
- Product map: sub-scores + deltas, feature sprawl diagnosis
- Loop health: bar graph, bottleneck marked
- Learning health: prediction accuracy, grading gaps, velocity trend
- Graduation criteria: ✓ met, · not met
- **Opinion** — one bold sentence at the end. The takeaway.
- Bottom: 2-3 next commands, starting with the highest-leverage move

## Anti-sycophancy checklist

Before outputting, verify the output contains:
- [ ] At least one "you're avoiding..." or "stop..."
- [ ] Named failure mode with evidence
- [ ] ONE highest-leverage move (not a menu)
- [ ] No sentences containing "promising", "great progress", "solid foundation"
- [ ] No generic advice ("focus on users", "ship fast", "iterate")
- [ ] Every claim cites evidence from the state files

If any box is unchecked, rewrite before outputting.
