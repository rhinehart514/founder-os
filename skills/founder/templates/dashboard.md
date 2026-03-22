# Dashboard Output Template

The canonical rendering format for `/founder` (default view). All zones are defined here with exact structure.

## Full template (with portfolio)

When `~/.founder-os/portfolio.yml` exists, lead with portfolio summary:

```
  ◆ founder-os  ·  [founder name]
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  portfolio    [N] ideas  ·  [N] active  ·  [N] killed  ·  [N] shipped
  accuracy     [X]%  ([N]/[M] graded)  ·  target: 50-70%

  [idea name]     [stage]     [days in stage]     [one-line status]
  [idea name]     [stage]     [days in stage]     [one-line status]
  ...

  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
```

Then the project dashboard:

```
  [PROJECT NAME]  ·  v[X.Y]  ·  [N] skills  ·  [mode] mode

  "[value hypothesis]"
  for [specific user]

  score       **[N]**/100  [bar 20 chars]
              assertions [pass]/[total]  ·  health [N]
              delivery [N]  ·  craft [N]  ·  viability [N]

  thesis      "[thesis text]"  **[N]%**
              [evidence list: checkmark/partial/dot per item]

  features    product: **[N]%**

              [name]     [bar]  w:[N]  [score]  d:[N] c:[N] v:[N]  [delta]  [bottleneck marker]
              ...

  signals     predictions: [N]% accurate ([graded]/[total])  ·  [N] ungraded
              todos: [N] active · [N] backlog · [N] stale
              last commit: [hash] [msg] · [time ago]

  [opinion — one bold sentence]

  /[cmd1]      [why]
  /[cmd2]      [why]
  /[cmd3]      [why]
```

## No-portfolio template

Skip the portfolio zone. Start directly with the project dashboard section above.

## Zone rendering rules

### Score bar
Map score 0-100 to 20 characters. Fill = `█`, empty = `░`.
```
chars_filled = round(score / 100 * 20)
```

### Feature bars
Same mapping. Sort by weight descending, then score ascending. Mark bottleneck with `<-`.

### Evidence markers
- `✓` = status: proven
- `◐` = status: partial
- `·` = status: todo
- `✗` = status: disproven

### Delta arrows
- Score increased: `↑N`
- Score decreased: `↓N`
- No change: `—`

### Conditional zones
- No portfolio.yml → skip portfolio zone entirely
- No eval-cache → skip sub-scores, show assertion pass rates only
- No roadmap.yml → skip thesis zone entirely
- No predictions → show "no predictions yet — /plan to start"
- No features → "no features — /onboard to start"
- No sessions/commits → skip "last commit" line
- Score zone always renders — it anchors the view

### Coherence warnings
Insert between signals and opinion when system-pulse.sh reports mismatches:
- Strategy bottleneck != eval bottleneck → "⚠ strategy says [X] but eval says [Y] is the bottleneck"
- Plan target != eval bottleneck → "⚠ plan targets [X] but weakest feature is [Y]"
- Weakest feature has 0 todos → "⚠ [feature] is weakest but has 0 todos"
If coherence is aligned, skip this zone entirely.

### Anti-rationalization warnings
Insert between signals and opinion when triggered:
- Score +15 between snapshots without feature maturity change → "Score jumped without feature progress"
- >3 features at eval 30-49 for 3+ snapshots → "Feature sprawl: [N] features half-built"
- No predictions in 7+ days → "Learning loop silent for [N]d"
- >10 backlog items, <20% completion → "Backlog graveyard: [N] items, [M]% done"
