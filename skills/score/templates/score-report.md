# Score Report Templates

## Full score output

```
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  67/100  █████████████░░░░░░░  ●●●●●
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

                                    del  cra  via
  todo         60 ████████░░░░  68   58   28  ●●
  learning     64 ████████░░░░  62   67   73  ●●●●
  install      64 ████████░░░░  72   65   35  ●●●
  docs         67 ████████░░░░  72   68   51  ●●●
  scoring      68 █████████░░░  72   65   79  ●●●●●
  commands     73 █████████░░░  78   72   72  ●●●●●

  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  bottleneck  todo at 60  · /plan todo
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
```

**Rules:**
- Header: big score + 20-char bar + tier fill badge (●○)
- Table: name(12), score(colored), compact bar(12), sub-scores(colored), weight dots(●)
- Sorted worst-to-best (worst at top)
- Footer: bottleneck name + score + next command
- Show viability source when not "agents" (! for capped, ~ for intelligence)
- Color: green ≥80, yellow 50-79, red <50
- No box-drawing. No prose between rows.

## Quick mode output

```
▾ product score: [SCORE]/100  ●●○○○  (cached, [age])

  [feature]  [SCORE]  d:[D] c:[C] vi:[Vi]([source])  ●●○○○
  [feature]  [SCORE]  d:[D] c:[C] vi:[Vi]([source])  ●●○○○

  stale: [tier list]
  ▸ /score deep for fresh data
```

## Breakdown mode output

```
▾ score breakdown  ●●●●○ (4/5 tiers)

  tier 1: health
    score: [N]  cached: [age]  confidence: [level]
    structure: [N]  hygiene: [N]
    penalties: [list]

  tier 2: code eval
    cached: [age]  confidence: [level]
    [feature]: d:[D] c:[C]  gaps: [N]
    [feature]: d:[D] c:[C]  gaps: [N]

  tier 3: visual
    cached: [age]  confidence: [level]
    [dimension]: [score]  [dimension]: [score]  ...
    weakest: [dimension] at [score]

  tier 4: behavioral
    cached: [age]  confidence: [level]
    blockers: [N]  majors: [N]  minors: [N]
    converted score: [N]/100

  tier 5: viability
    source: [agents|intelligence|capped]
    cached: [age]  confidence: [level]
    [feature]: [score]  uvp:[N] gap:[N] demand:[N] position:[N]
    intelligence: market-context [age], customer-intel [age], strategy [age]
```

## Viability-only output

```
▾ viability assessment  confidence: [level]  source: [agents|intelligence|capped]

  [feature]  [SCORE]/100
    uvp clarity:      [N]/25  [one-line evidence]
    competitive gap:  [N]/25  [one-line evidence]
    demand signal:    [N]/25  [one-line evidence]
    positioning:      [N]/25  [one-line evidence]

  sources:
    market-context.json  [fresh|stale|missing]  [age]
    customer-intel.json  [fresh|stale|missing]  [age]
    strategy.yml         [fresh|stale|missing]  [age]
    product-spec.yml     [fresh|stale|missing]  [age]

  ▸ [suggestion if sources missing or stale]
```

## Feature-scoped output

Same as full score but for one feature, with additional detail:
- All evidence citations expanded (not one-line)
- Cross-tier contradictions surfaced
- Historical trend via `founder score . --trend`
- Task suggestions from weakest tier
