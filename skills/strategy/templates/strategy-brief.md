# Strategy Brief Template

Use this structure for every strategy session output. Fill sections based on available data.

```
-- strategy -----------------------------------------------

  stage: [one/some/many/growth] ([evidence])
  thesis: "[current version thesis from roadmap.yml]"

  . the honest take

    [3-5 sentences. No hedging. Lead with the hard truth.
     Name what the founder is avoiding. Cite the eval score.
     This paragraph is the most important part of the output.]

  . failure mode: **[named failure mode]**
    [Evidence. What the scores say will break. Why this matters
     at this specific stage.]

  . eval reality
    worst:  [feature] at [score] -- [d/c/v drag] -- [why]
    best:   [feature] at [score] -- [strength]
    trend:  [improving/flat/declining] over last [N] sessions
    sprawl: [N] features in building range [note if >3]

  . leverage analysis
    #1 move: **[the one thing]**
      impact: [what it unblocks]
      confidence: [high/medium/low] ([why])
      effort: [time estimate]

  . what to stop
    * [thing 1 -- why it's premature or wasteful]
    * [thing 2 -- cite stage or score]

  . market position
    category: [where you sit]
    saturation: [low/medium/high]
    competitors:
      [name] -- [threat level] -- [one-line why]
    window: [timing assessment]

  . learning health
    predictions: [accuracy]% ([N graded])
    ungraded: [N]
    velocity: [trend]

  opinion: **[one bold sentence. the takeaway.]**

  /[highest-leverage command]   [why]
  /[second command]             [why]
```

## Section rules

- **the honest take** comes FIRST. Before any numbers.
- **failure mode** is named explicitly with evidence, not "things could go wrong."
- **leverage analysis** is ONE move. Not a menu. Not options.
- **what to stop** is mandatory. At least one thing.
- **opinion** is one sentence, bold, at the end.
- Bottom commands start with the highest-leverage move.

## Anti-sycophancy checklist

Before outputting, verify:
- [ ] At least one "you're avoiding..." or "stop..."
- [ ] Named failure mode with evidence (eval score, git history, or stage)
- [ ] ONE highest-leverage move
- [ ] No "promising", "great progress", "solid foundation"
- [ ] No generic advice ("focus on users", "ship fast", "iterate")
- [ ] Every claim cites evidence from state files

If any box is unchecked, rewrite before outputting.
