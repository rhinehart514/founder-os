# Output Format
```
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  The ONE canonical spec for all founder-os output.
  Every skill follows this. No exceptions.
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
```

## Visual Vocabulary

Every character used across founder-os output, organized by purpose.

### Structure

| Glyph | Name           | Purpose                                    |
|-------|----------------|--------------------------------------------|
| `◆`   | diamond        | Header marker. Starts every command output. |
| `⎯`   | thin rule      | Horizontal divider. 40 chars wide.         |
| ` — ` | em-dash        | Separator in headers: `◆ plan — auth`      |
| ` · ` | middle dot     | Inline separator: `v8.0 · stage: one`      |
| `←`   | left arrow     | Bottleneck marker on feature rows          |

### Status

| Glyph | Name           | Purpose                                    |
|-------|----------------|--------------------------------------------|
| `✓`   | checkmark      | Pass, done, resolved, proven               |
| `✗`   | cross          | Fail, wrong, disproven                     |
| `⚠`   | warning        | Attention needed, degraded                 |
| `◐`   | half-circle    | Partial, in-progress evidence              |

### Sections

| Glyph | Name           | Purpose                                    |
|-------|----------------|--------------------------------------------|
| `▾`   | down-triangle  | Collapsible heading, detail section        |
| `▸`   | right-triangle | Action, move, active item, recommendation  |
| `·`   | bullet dot     | Pending, backlog, unresolved, list item    |

### Bars

| Glyph | Name           | Purpose                                    |
|-------|----------------|--------------------------------------------|
| `█`   | filled block   | Progress filled portion                    |
| `░`   | light block    | Progress empty portion                     |

### Deltas

| Glyph | Name           | Purpose                                    |
|-------|----------------|--------------------------------------------|
| `↑`   | up arrow       | Score improved                             |
| `↓`   | down arrow     | Score regressed                            |
| `—`   | em-dash        | No change                                  |

---

## Header

```
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  ◆ [command] — [scope]
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
```

- Command name without slash prefix: `◆ plan — auth`, not `◆ /plan`
- Scope is optional: `◆ retro — 3 ungraded, 2 stale` or just `◆ shipped`
- Em-dash with spaces: ` — ` (not `—` or `-` or `:`)
- Dashboard-style commands (/founder, /product) use the thin divider above AND below the header
- Standard commands use the header line only (no dividers) unless the output has multiple zones

---

## State Bar

One line, immediately after header:

```
v[X.Y]: **[pct]%** · product: **[pct]%** · score: [N]
```

- Version completion bold, product completion bold, score plain
- Separated by ` · ` (space-dot-space)
- Only show what's available — skip missing signals, don't show placeholders

---

## Thesis

Always on its own line when shown:

```
thesis: "[text]"
```

Quoted, lowercase key.

---

## Dividers

Two patterns, both using the thin rule character `⎯`:

**Full divider** — 40 characters, separates major zones:
```
  ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
```

**Labeled divider** — label embedded in the rule, separates subsections:
```
  ⎯⎯ features ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
```

Label is lowercase, no bold. Two `⎯` before label, rest fills to 40 chars.

---

## Score Display

Scores render as a big number with a 20-char bar and supporting dimensions:

```
  score       **95**/100  ███████████████████░
              assertions 57/63  ·  health 85
              value 62  ·  quality 52  ·  ux 59
```

- Primary score is bold with `/100` suffix
- Bar is 20 characters: `█` for filled, `░` for empty
- Supporting dimensions on indented lines below
- Dimensions separated by ` · `

**Inline score** (for compact contexts):
```
  58  ████████████░░░░░░░░
```

**Percentage bar**:
```
  **64%**  █████████████░░░░░░░
```

---

## Feature Map

Standard feature row format for product maps and dashboards:

```
  scoring    ████████████████████  w:5  58  d:62 c:50 v:60  ↑4
  commands   ████████████░░░░░░░░  w:5  70  d:75 c:65 v:68  ↑2
  learning   ██████░░░░░░░░░░░░░░  w:4  48  d:55 c:40 v:48  ↓3  ←
  install    ████████████████████  w:3  68  d:70 c:60 v:72  —
  docs       ████████████░░░░░░░░  w:3
```

**Anatomy of a feature row:**
```
  [name]     [bar 20ch]  w:[weight]  [score]  [v:N q:N u:N]  [delta]  [marker]
```

- Name left-aligned, padded to longest name
- Bar: 20 `█`/`░` characters, proportional to maturity (planned=0%, building=33%, working=66%, polished=100%)
- `w:N` — feature weight (1-5)
- Score — composite number when eval-cache exists
- `d:N c:N v:N` — delivery/craft/viability sub-dimensions (optional, only when eval-cache has them)
- Delta: `↑N` / `↓N` / `—`
- `←` marks the bottleneck (lowest maturity x highest weight)
- Features without eval data show name + bar + weight only

---

## Section Markers

```
▾  collapsible heading (detail section)
▸  action / move / active item / recommendation
·  pending / backlog / unresolved
✓  pass / done / resolved / proven
✗  fail / wrong / disproven
⚠  warning / attention needed
◐  partial / in-progress
```

---

## Compact Pulse

For quick status output — single-zone, no dividers, no state bar. Used by fast checks, agent status messages, and brief confirmations.

```
◆ [command] — [scope]

[2-5 lines of dense content]

/next1       description
/next2       description
/next3       description
```

**Examples:**

```
◆ assert — +1 belief

✓ "commands produce consistent output" planted in commands
57/63 assertions passing

/eval            check it
/assert list     see all
/go              keep building
```

```
◆ todo — done

✓ fix flapping assertions (id:t-041)
3 active · 7 backlog · 0 stale

/todo            see backlog
/go              keep building
/plan            what's next
```

---

## Bottom Commands

Exactly 3 next commands. Always at the very end. No more, no fewer.

```
/command1       brief description
/command2       brief description
/command3       brief description
```

Left-aligned command, tab-indented description. No bullets, no numbers.

---

## Sparklines

Text-based trend indicators for time-series data. 10 characters, most recent on right:

```
  ✓✓✓✗✓✓✗✓✓✓   stable (80% pass)
  ✗✗✓✗✓✓✓✓✓✓   improving
  ✓✓✓✓✓✗✗✗✗✗   regressing
  ✓✗✓✗✓✗✓✗✓✗   flapping ⚠
```

Use for assertion stability, prediction accuracy trends, deploy success history.

---

## Comparison Dashboard

For before/after or side-by-side analysis (used by /calibrate verify, /clone verify, /founder compare):

```
  ⎯⎯ comparison ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  dimension        before    after    delta
  hierarchy          45        62     +17  ↑
  breathing_room     38        41      +3  ↑
  contrast           72        70      -2  ↓
  polish             55        55       —
```

- Column-aligned, monospace-friendly
- Deltas with `↑`/`↓`/`—` indicators
- Bold the dimensions that moved most

---

## Screenshot References

When skills capture screenshots via Playwright, show file paths:

```
  ▾ screenshots
    desktop (1440px)  .claude/cache/clone-screenshots/source-desktop.png
    mobile (390px)    .claude/cache/clone-screenshots/source-mobile.png
```

The user can view these with the Read tool or their file browser.

---

## Confidence Indicators

For auto-graded predictions, research findings, and other uncertain assessments:

```
  ✓ HIGH    mechanical match (score 58→62, predicted 60+)
  ◐ MEDIUM  directional match (predicted improvement, score went up)
  · LOW     qualitative assessment (subjective interpretation)
```

---

## Tool-Driven Interactivity

Skills use Claude Code tools to fill templates with live data, not static text:

- **Bash** (`founder eval .`, `founder score .`, `git log`) — live project data
- **Read** (state files: score-cache.json, eval-cache.json, roadmap.yml) — direct state reads, no script intermediary needed
- **Playwright** (`browser_take_screenshot`, `browser_resize`) — visual captures for /clone, /taste, /calibrate
- **WebFetch** — verify deployed URLs, measure response times
- **AskUserQuestion** — interactive flows (component selection, interview questions, confirmation gates)
- **Vercel MCP** — real deploy status, build logs, runtime logs for /ship

The output template is the SHAPE. The tools fill it with REAL DATA. Skills should read state files directly when the data is JSON/YAML — scripts are for computation, not for reading caches.

---

## General Rules

- Dense over verbose — every line earns its place
- Bold for emphasis: **feature names**, **percentages**, **verdicts**
- No trailing summaries — the output IS the summary
- No preamble — start with the header, not "Here's what I found"
- No emoji beyond the visual vocabulary above
- Two-space indent for all content lines (matches the divider indent)
- Skip zones with no data — don't show empty state or placeholders
- Labeled dividers for subsections, full dividers for major zone breaks
- Sparklines for trends, bars for quantities, comparison tables for before/after
- Screenshot paths when visual evidence is captured
- Confidence indicators when assessments are uncertain
