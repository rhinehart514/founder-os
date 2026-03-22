# /roadmap Reference — Output Templates & Version Completion

Loaded on demand. Routing, intelligence, and thesis logic are in SKILL.md.

---

## Output format

### Roadmap view:

```
◆ roadmap

[2-3 sentence reflection — grounded in velocity, learning, honesty, shape data]

arc: identity → measurement → external validation → [?]
velocity: v6→v7 in 1d, v7→v7.2 in 2d, v8.0 testing for 3d — [accelerating/decelerating/steady]

✓ **v6.0** [major] — "Identity + measurement > prescribed workflows"
  proven 2026-03-12 · cut 3,700 lines to ~2,000

✓ **v7.0** [major] — "Score = value, not health"
  proven 2026-03-13 · assertions are the score, features as units

✓ **v7.1** [minor] — "Every workflow needs a command"
  proven 2026-03-14 · 9 commands with cross-recommendations

✓ **v7.2** [minor] — "The loop works on itself"
  proven 2026-03-15

▸ **v8.0** [major] — "Someone who isn't us can complete a loop"
  version: **43%** ████████░░░░░░░░░░░░
  evidence  2/4  ██████████░░░░░░░░░░  (install-clean ✓, reach-plan ~, first-go ·, return ·)
  features  3/5 working+              (install ✓, commands ~, learning ←)
  todos     8/14 done                 (tagged to v8.0)
  ✓ v8.0.1 [patch] — eval fixes, cache invalidation
  ✓ v8.0.2 [patch] — product map, /product command
  ✓ v8.0.3 [patch] — honest pipeline, mechanical assertions

· **v9.0** [major] — "Plugin marketplace distribution"
  planned · 3 evidence items

⚠ thesis health: [ok | stalled N days | N/M thesis predictions wrong]

[forward-looking thought — a question, not a recommendation]

/roadmap next       diagnose what's most provable
/roadmap ideate     brainstorm what comes after
/roadmap v7.0       what did v7.0 teach?
```

### Next view (diagnostic, not a list):

```
◆ roadmap next — v8.0: "Someone who isn't us can complete a loop"

▾ evidence diagnosis

  ✓ install-clean — **proven**
    features: install (polished, w:3) — fully supports
    evidence: commander.js init worked at 80/100

  ~ reach-plan — **close** (one session away)
    features: commands (working, w:5) — cross-recommendations guide flow
    gap: no guided onboarding — user must know to type /plan
    experiment: have someone try, observe where they get stuck

  · first-go — **blocked** by reach-plan
    features: learning (building, w:4) — prediction grading incomplete
    depends on: user reaching /plan first (reach-plan must be partial+)
    experiment: after reach-plan partial, run /go on external project

  · return — **unknown** (no data, no features map to this)
    no features directly measure retention
    experiment: check if first-go user opens a second session

most provable: **reach-plan** — commands are working, just needs one external test

/go commands        mature the supporting feature
/research "onboarding flow"   investigate the gap
/plan               work toward proving reach-plan
```

### Bump (with auto-synthesis):

```
◆ roadmap bump — v8.0 [major] → proven

  thesis: "Someone who isn't us can complete a loop"
  tier: major
  proven: 2026-03-16

  ▾ auto-summary (edit or confirm)
    External users can clone, install, and run the full /plan → /go → /eval
    loop on their own projects. Install works cleanly on commander.js (80/100).
    Cross-recommendations guide the flow without docs. Learning feature is the
    weakest link — predictions log but grading is manual.

  ▾ what was learned (→ experiment-learnings.md)
    · "External validation requires install + commands, not learning" (New Known Pattern)
    · "Plugin install mode eliminates shell profile friction" (Uncertain → Known)

  ▾ predictions during v8.0
    8 total · 5 correct (63%) — well-calibrated

  ▾ thesis → knowledge transfer
    Writing to Known Patterns: "External users complete loops when install is
    clean and commands have cross-recommendations. Learning quality doesn't
    gate first-loop completion."

  current → **v9.0** [major]: "[next thesis]"

/roadmap next       see what v9.0 needs
/plan               start working toward v9.0
/retro              grade remaining predictions
```

### Version archaeology (e.g., `/roadmap v7.0`):

```
◆ roadmap — v7.0

thesis: "Score should measure value, not health"
status: **proven** (2026-03-13) · lasted 1 day

▾ what it proved
  ✓ Assertion pass rate tracks what actually matters
  ✓ Per-feature breakdown identifies real bottlenecks
  ✓ beliefs.yml with typed assertions (file_check, content_check, llm_judge)

▾ what it taught
  · "Health gate keeps infrastructure honest without dominating the score" (Known)
  · "Per-feature scores are more actionable than aggregate" (Known)
  · "LLM judges add variance — use sparingly" (Uncertain at the time, now Known)

▾ how it shaped what came after
  → v7.1: commands needed because score alone doesn't tell you what to DO
  → v8.0: internal validation proven → natural question: does it work for others?

predictions during v7.0: 4 total, 3 correct (75%)

/roadmap            full roadmap
/roadmap v7.1       what came next
/roadmap v8.0       current version
```

**Formatting rules:**
- Header: `◆ roadmap` (or `◆ roadmap next`, `◆ roadmap bump`, `◆ roadmap — v7.0`)
- Reflection: 2-3 sentences, thinking-out-loud tone, before the version list
- Arc line: summarize thesis evolution in one line (identity → measurement → ...)
- Velocity line: days between version proofs, trend assessment
- Versions: ✓ for proven, ▸ for testing, · for planned — with `[major]`, `[minor]`, or `[patch]` tier label
- Patch versions: indented under their parent major version
- Evidence items: indented under version, ✓/~/· prefix
- Thesis health: ⚠ if stalled >14 days or >50% thesis predictions wrong
- Forward thought: one sentence at the bottom — a question, not a recommendation
- Bottom: exactly 3 next commands

## Version completion and lifecycle

See `references/version-lifecycle.md` for the full version completion formulas (full mode vs standalone), three-tier lifecycle, and state relationships.

---

## Narrative output (`/roadmap narrative`)

```
◆ roadmap narrative

  derived from: 4 proven theses, 12 Known Patterns, 2 external validations

▾ one-liner
  "A Claude Code plugin that measures whether your product is actually
  getting better — not just whether the code is clean."

  evidence: v7.0 proved value > health scoring. v8.0 proved external
  users complete the loop without help.

▾ paragraph
  founder-os is a Claude Code plugin for solo founders who want honest
  product measurement. It scores your product on what matters — value
  delivery, not code health — using per-feature assertions that you
  define in plain language. Tested on 2 external projects, it runs a
  full plan→build→measure→learn loop autonomously. Unlike linters or
  CI tools, it measures whether your users get what you promised.

  claims backed by:
  ✓ "value > health scoring" — v7.0 proven
  ✓ "external loop completion" — v8.0 proven (commander.js)
  ✓ "per-feature assertions" — v7.0 proven
  ⚠ "autonomously" — /go loop untested externally (honest gap)

▾ positioning statement
  For solo founders building with Claude Code who want to know if their
  product is improving, founder-os is a measurement plugin that scores
  value delivery per feature. Unlike code linters and CI pipelines,
  founder-os measures whether you delivered what you promised.

  [Edit] / [Approve]

written to .claude/cache/narrative.yml

/roadmap changelog    generate user-facing changelog
/roadmap positioning  competitive positioning check
/ship                 deploy with this narrative
```

## Changelog output (`/roadmap changelog`)

```
◆ roadmap changelog

## v8.0 — External validation
Someone who isn't you can now install, set up, and run the full
measurement loop on their own project without help.

- Plugin install mode — one-command setup via Claude Code marketplace
- 17 slash commands with intelligent cross-recommendations
- Per-feature scoring with delivery/craft/viability breakdown
- Autonomous build loop (/go) with speculative branching [BETA]

### v8.0.3
- Fixed install paths and command versioning
- Converted 8 subjective checks to mechanical assertions

### v8.0.2
- Product map showing feature maturity and dependencies
- /product command for assumption surfacing

### v8.0.1
- Eval cache invalidation fix
- Score pipeline honesty improvements

## v7.2 — Self-measurement
The measurement system can now measure itself.

## v7.1 — Command surface
9 slash commands covering the full founder workflow.

## v7.0 — Value scoring
Score measures value delivery, not code health. Per-feature
assertions replace aggregate health metrics.

written to .claude/cache/changelog.md

/roadmap narrative    update the story
/ship                 deploy with changelog
```

## Positioning output (`/roadmap positioning`)

```
◆ roadmap positioning

▾ what we've proven (defensible)
  · Value-based scoring catches what health metrics miss (v7.0, 3 experiments)
  · External users complete the loop without help (v8.0, commander.js)
  · Per-feature measurement is more actionable than aggregate (Known Pattern)
  · Plugin install eliminates shell profile friction (Known Pattern)

▾ what we haven't proven (honest gaps)
  · Does the /go loop improve products autonomously? (untested externally)
  · Do users return for a second session? (no retention data)
  · Does the learning loop compound across sessions? (unknown)

▾ where we're different
  · No other tool measures FEATURES with LLMs — everyone measures code health
  · Prediction→grade→learn loop — no competitor does explicit learning
  · Anti-sycophancy built into scoring — most AI tools inflate

▾ where we're behind
  · No cloud/SaaS offering (Devin, Cursor have cloud agents)
  · No team collaboration (single-player only)
  · No IDE integration beyond Claude Code

  [Approve] / [Edit]

written to .claude/cache/positioning.yml

/roadmap narrative    update external story
/research market      deeper competitive analysis
/product              revisit assumptions
```

## Narrative anti-slop rules

When generating external copy:
- **No unproven claims.** Every sentence must trace to a proven evidence item or Known Pattern.
- **Ban list:** "streamline," "supercharge," "AI-powered," "revolutionary," "cutting-edge," "leverage," "unlock," "seamlessly," "robust"
- **Specificity test:** replace any noun with "thing" — if the sentence still makes sense, it's too generic. "A tool that helps you build better things" → rewrite.
- **Number test:** include at least one specific number or result per paragraph.
- **Honest gaps are OK.** "We haven't proven X yet" is better copy than pretending X is true. Founders respect honesty.
- **The founder edits.** Always present via AskUserQuestion. The narrative is a draft, not a deliverable.

For version-to-state relationships, see `references/version-lifecycle.md`.
