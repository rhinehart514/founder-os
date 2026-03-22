# /ship Reference — Output Templates

Loaded on demand. Flow logic and routing are in SKILL.md.

---

## Pre-flight output

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

## Ship complete output

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

## Release created output

```
◆ shipped release — v8.1

  tag: v8.1
  title: "v8.1: Eval scoring engine upgrade"
  url: https://github.com/[owner]/[repo]/releases/tag/v8.1

  ▾ release notes (published)
    ## Eval scoring engine upgrade
    Multi-sample median scoring, decomposed sub-scores (delivery/craft/viability),
    per-feature rubrics, and structured output via API.

    ### What's new
    - 3-sample median reduces eval variance from ±15 to ±5 points
    - Sub-scores break down value delivery, code quality, and UX separately

    ### Known limitations
    - /go loop untested on external projects

/roadmap bump        graduate the thesis if ready
/eval                verify current state
/ship history        deployment log
```

## PR created output

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

## Verify output

```
◆ ship verify — [url]

  status: **pass**

  ⎯⎯ response ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  status:    200 OK
  time:      320ms  ██████░░░░░░░░░░░░░░ (target <500ms)
  ssl:       valid, expires 2026-12-01

  ⎯⎯ content checks ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  ✓ title tag present: "[page title]"
  ✓ headline found: "[product name or heading]"
  ✓ no error markers (500, Application Error, Not Found)

  ⎯⎯ assertions (live) ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  ✓ 56/63 passing on deployed version
  ⚠ response time regression: 320ms vs 180ms last deploy (+78%)

  deploy confidence: **87%** ████████████████░░░░

/ship rollback     revert if broken
/eval              full assertion check
/go [feature]      fix the failure
```

## Rollback output

```
◆ ship rollback

  reverted: [commit hash] → [previous hash]
  pushed: origin/[branch]
  deploy: [rebuilding/manual]

  severity: ██████████████████░░ HIGH — assertion regression in production

  ⚠ investigation required
  · what broke: [from deploy-history]
  · affected features: [feature list with weights]
  · todo created: "[feature]: investigate rollback — [reason]"

/eval              check current state
/retro             grade the prediction
/go [feature]      fix the root cause
```

## History output

```
◆ ship history — [N] deploys

  success rate: **92%** ██████████████████░░ ([M]/[N])
  avg score delta: +3
  rollback rate (last 5): 1/5

  ⎯⎯ recent deploys ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  date        commit   score   target  status
  2026-03-16  a1b2c3d  92→95   vercel  ✓ verified   320ms
  2026-03-15  d4e5f6g  88→92   vercel  ✓ verified   280ms
  2026-03-14  g7h8i9j  85→82   vercel  ✗ rolled back — assertion regression

  ⎯⎯ trends ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  scores:     ██████████████████░░ improving across last 5 deploys
  stability:  ████████████████████ no rollbacks in last 3 deploys
  confidence: 72% → 87% → 91% ████████████████████ trending up

/ship              deploy now
/ship dry          pre-flight check
/eval              verify assertions
```

## Formatting rules

- Header: `◆ ship — pre-flight` or `◆ shipped` or `◆ ship verify — [url]` etc.
- Deploy confidence: bold %, 20-char bar, parenthetical formula
- Features affected: standard feature row with ✓/⚠ status suffix
- Commit display: backtick-wrapped short hash + conventional commit message
- Anti-rationalization warnings inline: `⚠ [feature] is still building — ship anyway?`
- History: tabular format for deploys, bars for trends
- Rollback: severity bar, mandatory investigation section
- Bottom: exactly 3 next commands
