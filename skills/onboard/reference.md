# /onboard Reference — Output Templates

Loaded on demand. Steps and routing are in SKILL.md.

---

## Output format

```
◆ init — [project name]

  [project name] — [one sentence description]
  for: [who]
  hypothesis: "[testable sentence]"
  stage: one · mode: build

  ✓ config/founder.yml — value hypothesis + [N] features defined
  ✓ beliefs.yml — [N] assertions across [N] features
  ✓ learning loop — predictions.tsv, experiment-learnings.md, strategy.yml, roadmap.yml
  ✓ first eval complete

▾ features detected
  ▸ [name]     w:[N]  [maturity]  [score]/100
    "[delivers]"
  ▸ [name]     w:[N]  [maturity]  [score]/100
    "[delivers]"
  ▸ [name]     w:[N]  [maturity]  [score]/100
    "[delivers]"

  eval: [N] passing · [N] failing · [N] warn
  bottleneck: **[worst feature]** — [why]

▾ what's next
  Your product has a score now. Here's how to make it better:

/plan              find the bottleneck and plan a fix
/go [feature]      autonomous build loop on the worst feature
/eval              re-measure after changes
```

## Re-init output (`--force`)

```
◆ init — [project name] (regenerated)

  [project name] — [one sentence description]
  for: [who]
  hypothesis: "[testable sentence]"
  stage: one · mode: build

  ✓ config/founder.yml — regenerated with [N] features
  ✓ beliefs.yml — [N] assertions ([M] new, [K] preserved)
  ✓ learning loop — preserved existing predictions + learnings
  ✓ eval complete

▾ features detected
  ▸ [name]     w:[N]  [maturity]  [score]/100
    "[delivers]"

  eval: [N] passing · [N] failing
  bottleneck: **[worst feature]** — [why]

/plan              find the bottleneck and plan a fix
/go [feature]      autonomous build loop on the worst feature
/eval              re-measure after changes
```

## Already initialized output

```
◆ init — already set up

  config/founder.yml exists with [N] features
  Use `--force` to regenerate.

/plan              plan work on existing features
/eval              measure current state
/founder             see the dashboard
```

## Formatting rules

- Header: `◆ init — [project name]`
- Setup checklist: `✓` prefix for each completed step
- Features: `▸` prefix with weight, maturity, score, and delivers quote
- Bottleneck: bold feature name with brief reason
- "what's next" section: 1-2 sentences of guidance, not a tutorial
- Bottom: exactly 3 next commands
- No placeholder text — everything filled from actual code analysis
- No apologizing for low scores — they're honest
