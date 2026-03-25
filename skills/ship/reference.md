# /ship Reference — Output Templates

Loaded on demand. Routing and mode logic are in SKILL.md.

---

## Deploy — Pre-flight output

```
◆ ship — pre-flight

  score: **92** (no regression)
  files: 7 changed, 2 new
  assertions: 57/63 passing (no block failures)
  secrets: none detected
  product: **62%** · version: **v8.0** — 43% proven
  deploy confidence: **87%** ████████████████░░░░ (assertions 90% x deploys 97%)

  ⎯⎯ features affected ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  scoring  ████████████████████ w:5  working  90 ✓
  commands ██████████████████░░ w:5  working  85 ✓
  learning ████████░░░░░░░░░░░░ w:4  building 40 ⚠

  ⚠ learning is still building — ship anyway?

/ship                deploy now
/eval                re-check assertions
/go learning         fix the warning first
```

## Deploy — Ship complete

```
◆ shipped

  `a1b2c3d` feat: eval scoring engine — sub-scores, rubrics, multi-sample median

  score: 92 → 95 ↑3
  product: **62%** · version: **v8.0** — 43% proven
  branch: main → origin/main
  deploy: vercel — building
  deploy confidence: **91%** ██████████████████░░

/ship verify [url]  confirm it's live
/ship history       deployment log
/eval               verify assertions held
```

## Release created

```
◆ shipped release — v8.1

  tag: v8.1
  title: "v8.1: Eval scoring engine upgrade"
  url: https://github.com/[owner]/[repo]/releases/tag/v8.1

  ▾ release notes (published)
    [evidence-traced content]

/ship roadmap bump   graduate the thesis if ready
/eval                verify current state
/ship history        deployment log
```

## PR created

```
◆ shipped pr — #42

  title: feat: eval scoring engine upgrade
  base: main ← feature/eval-engine
  url: https://github.com/[owner]/[repo]/pull/42

  features: scoring (↑4), eval (+sub-scores)
  advances: v8.0 evidence "first-go" (indirectly)

/ship                merge and deploy when approved
/eval                verify assertions
/ship history        deployment log
```

## Verify / Rollback / History

See `references/advanced-modes.md` for verify, rollback, and history output formats.

---

## Roadmap view

```
◆ ship roadmap

[2-3 sentence reflection — velocity, learning, honesty, shape]

arc: identity → measurement → external validation → [?]
velocity: v6→v7 in 1d, v7→v7.2 in 2d — [trend]

✓ **v7.0** [major] — "Score = value, not health"
  proven 2026-03-13

▸ **v8.0** [major] — "Someone who isn't us can complete a loop"
  version: **43%** ████████░░░░░░░░░░░░
  evidence  2/4  ██████████░░░░░░░░░░
  features  3/5 working+
  todos     8/14 done

· **v9.0** [major] — "Plugin marketplace distribution"
  planned · 3 evidence items

⚠ thesis health: [ok | stalled N days | predictions wrong]

[forward-looking question]

/ship roadmap next     diagnose what's most provable
/ship roadmap ideate   brainstorm what comes after
/ship version v7.0     what did v7.0 teach?
```

## Roadmap next

```
◆ ship roadmap next — v8.0

▾ evidence diagnosis

  ✓ install-clean — **proven**
  ~ reach-plan — **close** (one session away)
  · first-go — **blocked** by reach-plan
  · return — **unknown**

most provable: **reach-plan**

/go commands           mature the supporting feature
/ship roadmap bump     if ready to graduate
```

## Roadmap bump

```
◆ ship roadmap bump — v8.0 [major] → proven

  thesis: "..."
  tier: major
  proven: 2026-03-16

  ▾ auto-summary (edit or confirm)
  ▾ what was learned (→ experiment-learnings.md)
  ▾ predictions during v8.0 — N total, M correct (%)
  ▾ thesis → knowledge transfer

  current → **v9.0** [major]: "[next thesis]"

/ship roadmap next     see what v9.0 needs
/ship version v8.0     review what was proved
```

## Roadmap narrative

```
◆ ship roadmap narrative

  derived from: N proven theses, N Known Patterns

▾ one-liner
  "[evidence-traced one-liner]"

▾ paragraph
  [~50 words, every claim cited]

▾ positioning statement
  [For X who Y, product is Z. Unlike A, product does B.]

  [Edit] / [Approve]

written to .claude/cache/narrative.yml

/ship roadmap changelog    generate changelog
/ship copy landing         use narrative in landing page
```

## Version archaeology

```
◆ ship version v7.0

thesis: "..."
status: **proven** (date)

▾ what it proved
▾ what it taught
▾ how it shaped what came after

predictions during v7.0: N total, M correct (%)

/ship roadmap       full roadmap
/ship version v7.1  what came next
```

---

## Copy — Landing page

```
◆ ship copy landing

  for: "[specific person from demand-cache.json package]"

⎯⎯ hero ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  # [Headline — 7 words max]
  [Subhead — names person, states change]
  [CTA button]

⎯⎯ problem ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
⎯⎯ solution ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
⎯⎯ proof ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
⎯⎯ CTA ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  quality gate: ✓ names person ✓ states change ✓ differentiates ✓ slop-free
```

## Copy — Pitch

```
◆ ship copy pitch

  for: "[specific person]"

⎯⎯ elevator (10s) ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
⎯⎯ tweet (280c) ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
⎯⎯ paragraph (50w) ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  quality gate: [results]
```

## Copy — Outreach / Release / Empty states

See `templates/cold-outreach.md`, `templates/copy-release-notes.md`, and copy empty-states format in SKILL.md.

---

## Formatting rules

- Header: `◆ ship — [mode]` or `◆ shipped` or `◆ ship roadmap` or `◆ ship copy [type]`
- Deploy confidence: bold %, 20-char bar, parenthetical formula
- Versions: ✓ proven, ▸ testing, · planned — with [major]/[minor]/[patch] tier
- Evidence: indented under version, ✓/~/· prefix
- Copy quality gate: inline after every piece of copy
- Bottom: exactly 3 next commands

## Anti-slop rules (all external copy)

- No unproven claims. Every sentence traces to proven evidence or Known Pattern.
- Ban list: "streamline," "supercharge," "AI-powered," "revolutionary," "cutting-edge," "leverage," "unlock," "seamlessly," "robust"
- Specificity test: replace any noun with "thing" — still makes sense? Too generic.
- Number test: at least one specific number per paragraph.
- Honest gaps are OK. "We haven't proven X yet" beats pretending X is true.
- The founder edits. Always present via AskUserQuestion.
