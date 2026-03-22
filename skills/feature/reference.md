# /feature Reference — Output Templates

Loaded on demand. Routing and core logic are in SKILL.md.

---

## Output format

### List all features:

Only show `active` and `proven` features by default. Suffix proven features with `(proven)`. Omit `killed` and `archived` unless the user explicitly requests them.

```
◆ features

v8.0: **43%** · product: **62%** · assertions: 57/63

▸ learning        ████░░░░░░  **48**/100  w:4  building   ← bottleneck
  (d:55 c:40 v:48) ↓3
  "a model that gets smarter every session"
  for: the system itself · depends on: scoring

▸ scoring         █████░░░░░  **58**/100  w:5  working
  (d:62 c:50 v:60) ↑4
  "honest number that tells a founder if their product improved"
  for: solo founder who just made changes

· self-diagnostic ██████░░░░  **68**/100  w:2  working  (proven)
  (d:70 c:65 v:68) —
  "system health check — measures calibration, staleness, learning loop"
  for: solo founder · depends on: scoring, learning

· install         ██████░░░░  **68**/100  w:3  polished
  (d:70 c:60 v:72) —
  "one-command setup — clone, run install.sh, everything works"
  for: new user trying founder-os for the first time

· commands        ███████░░░  **70**/100  w:5  working
  (d:75 c:65 v:68) ↑2
  "slash commands that route founder intent to the right action"
  for: solo founder working in Claude Code

product completion: **62%**
bottleneck: **learning** (w:4, building) — craft_score 40 is weakest dimension

/feature [name]       deep dive into one
/feature new [name]   define a new feature
/feature detect       scan codebase for undeclared features
```

**Formatting rules:**
- Header includes version completion + product completion + assertion count
- Features sorted worst-to-best by total score
- Sub-scores shown on second line: `(d:N c:N v:N)` with delta arrow
- Bar graphs: █ for passing proportion, ░ for failing
- Bottleneck opinion names the weakest sub-score dimension, not just the total
- Bottom: exactly 3 next commands

### Single feature detail:

```
◆ feature — scoring

  **58**/100  █████░░░░░
  eval:58  w:5
  depends on: (none)
  depended on by: learning, self-diagnostic

  delivers: "honest number that tells a founder if their product improved"
  for: solo founder who just made changes
  code: bin/score.sh, bin/eval.sh, bin/lib/config.sh

▾ sub-scores
  delivery  ██████████████░░░░░░  62/100  ↑4
  craft     ████████████░░░░░░░░  50/100  —
  viability ████████████████░░░░  60/100  ↑2

▾ verdict
  DELIVERS: score.sh computes honest number with health gate
  DELIVERS: per-feature breakdown identifies real bottlenecks
  PARTIAL: trend visualization exists but not surfaced in output
  MISSING: onboarding guidance for new projects is generic

▾ rubric (if .claude/cache/rubrics/scoring.json exists)
  spec_alignment: check score formula matches docs
  integrity: 4 unhandled I/O paths
  ux: output clear but no next-step guidance
  anti_slop: 82% human-quality

/go scoring           fix the gaps
/eval deep scoring    full evaluation with rubric
/eval scoring         measure current state
```

### New feature created:

```
◆ feature new — [name]

  defined in config/founder.yml
  delivers: "[what]"
  for: "[who]"
  code: [files]
  weight: [N]  eval: pending
  depends on: [features or none]

  baseline:
  delivery  ░░░░░░░░░░░░░░░░░░░░  --/100
  craft     ░░░░░░░░░░░░░░░░░░░░  --/100
  viability ░░░░░░░░░░░░░░░░░░░░  --/100
  verdict: **PARTIAL** — 2 delivers, 1 partial, 1 missing

/go [name]      build what's missing
/eval [name]    measure in detail
/plan [name]    plan the build
```

### Detect results:

```
◆ feature detect

  scanned: 12 modules · 3 already declared · 4 new

  ▸ auth (new)
    code: src/auth/, src/middleware/auth.ts
    delivers: "user authentication and session management"
    for: end users
    weight: 4 (supports core flow)

  ▸ api (new)
    code: src/api/, src/routes/
    delivers: "REST API for client consumption"
    for: frontend clients
    weight: 3 (supports core flow)

  · utils (new, low weight)
    code: src/utils/
    delivers: "shared utility functions"
    for: developers
    weight: 1 (peripheral)

  · logging (new)
    code: src/logger.ts, src/middleware/logger.ts
    delivers: "structured request logging"
    for: developers/ops
    weight: 2

  already declared: scoring, commands, learning (skipped)

Add all 4 / Pick specific ones / Skip?

/feature new [name]   define manually instead
/eval                 measure what exists
```

### Feature ideate:

```
◆ feature ideate — scoring

  current: **58**/100 (d:62 c:50 v:60)
  gap: **craft** at 50 is dragging — delivery works but output quality is rough
  context: 3 backlog items, 1 wrong prediction, last taste: 55/100

  ▸ 1. **score explanation mode** — score output

    see: score.sh outputs a number and penalty list. User sees "-10 console.log"
    but doesn't understand WHY that's penalized or how to fix it.

    problem: craft_score 50 — output is functional but not helpful. No
    guidance, no context. 2 backlog items reference this gap.

    rx: Option 1: add `--explain` flag with inline guidance per penalty → craft +10
        Option 2: always show one-line fix hint per penalty → craft +12, delivery +3

    reference: ESLint shows rule name + docs link. Biome shows auto-fix suggestion.

    impact: craft_score 50 → 62. Creates assertion: "score output includes fix hints"

    cost: 1-2 hours — modify score.sh output formatting

    builds on: todo [SC-04] "score output needs actionable guidance"

  ▸ 2. **guided first-run experience** — score.sh first run

    see: new project runs `founder score .` and gets a wall of penalties with
    no context about what to fix first or why these matter.

    problem: viability_score 60 — first-time users don't know where to start.
    5-second test fails: stranger can't understand priority order.

    rx: Option 1: detect first run → show "start here" section → viability +8
        Option 2: progressive output — show top 3 issues only, `--all` for rest → viability +10, craft +5

    reference: Next.js CLI shows "1 issue to fix" with clear next step.

    impact: viability 60 → 70. delivery 62 → 65.

    cost: 2 hours — add first-run detection + progressive output

    builds on: (new — no existing work)

  · 3. **trend sparkline** — score output footer

    see: score outputs current number. No history, no direction.

    problem: delivery_score 62 — "did the product improve?" requires running
    git log and comparing. Score should answer this directly.

    rx: Option 1: last-5-runs sparkline in footer → delivery +5
        Option 2: delta arrow + "↑4 from last run" one-liner → delivery +3

    reference: GitHub Actions shows build time trends inline.

    impact: delivery 62 → 67

    cost: 1 hour — persist scores to cache, format in output

    builds on: taste rx from 2026-03-15 "add trend context"

▾ kill list
  · `--verbose` flag in score.sh — unused, no one has ever run it. Delete.
  · 3 penalty categories with <1% trigger rate — remove or merge.

Which improvements? (1-3, kill, or skip)
```

### Feature status transition:

```
◆ feature — scoring → proven

  was: working
  now: proven
  criteria met: 3+ sessions without regression, external validation (commander.js)

/feature             see all features
/roadmap             check thesis progress
```

## Sub-score display rules

When eval-cache.json has sub-scores for a feature:
- Always show `(d:N c:N v:N)` after the total score
- Show delta arrow: `↑N` (improved), `↓N` (regressed), `—` (same, within ±3)
- In detail view, show sub-score bars with individual deltas
- Name the weakest sub-score in bottleneck opinion
- In ideate, focus ideas on the weakest sub-score dimension

When eval-cache.json has NO sub-scores (legacy cache):
- Show total score only, no parenthetical
- Note: "run `founder eval . --fresh` for sub-score breakdown"

## Prediction auto-grading

After presenting feature status, check `.claude/knowledge/predictions.tsv` for ungraded predictions mentioning this feature. If found, grade them inline:

```
▾ predictions graded
  ✓ "scoring will reach 65+" → 58 (no, still below)
    model update: craft_score is the bottleneck, not value delivery
```
