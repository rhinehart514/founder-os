# /founder Reference — Output Templates

Merged from: founder, onboard, feature, todo, assert, configure, skill, money.
Each section loaded on demand per mode. Routing is in SKILL.md.

---

## DASHBOARD mode

See `references/dashboard-guide.md` for full rendering spec and `templates/dashboard.md` for canonical format.

## ONBOARD mode

See `skills/onboard/reference.md` for output templates:
- Init output, re-init output, already-initialized output
- Formatting rules: `◆ init`, `✓` checklist, `▸` features, exactly 3 next commands

## FEATURE mode

See `skills/feature/reference.md` for output templates:
- List all features: sorted worst-to-best, sub-scores `(d:N c:N v:N)`, delta arrows
- Single feature detail: sub-score bars, verdict, rubric
- New feature: baseline pending display
- Detect results: scanned modules with add/skip prompt
- Feature ideate: gap diagnosis, prescriptions with predicted impact, kill list
- Status transition display

Sub-score display rules:
- Always show `(d:N c:N v:N)` when eval-cache has sub-scores
- Delta arrows: `↑N` improved, `↓N` regressed, `—` same (within ±3)
- Name weakest sub-score in bottleneck opinion

## TODO mode

See `skills/todo/reference.md` for output templates:
- Default view with decay check and smart promote
- After add (with auto-tag)
- After done (with/without graduation suggestion)
- Health report: velocity, by-feature, signals
- Decay check: force decisions on stale items
- Version filter

## ASSERT mode

See `skills/assert/reference.md` for output templates:
- Quick-add confirmation
- List by feature with type + pass/fail
- Health: type distribution, mechanical ratio, coverage gaps
- Coverage matrix: 5 dimensions per feature
- Suggest: generated assertions for gaps
- Diff: what changed since last eval

## CONFIGURE mode

See `skills/configure/reference.md` for output templates:
- Show: current settings with source (preferences vs defaults)
- Agent/output/go interview flows
- Reset confirmation

## SKILL mode

See `skills/skill/reference.md` for output templates:
- List: all skills with maturity + pass rates
- Health: tier classification (thick/thin/stub/dead)
- Audit: 16-check quality matrix
- Create: evidence gate + overlap check

## MONEY mode

See `skills/money/reference.md` for output templates:
- Full model: pricing + unit economics + viability check + breakeven
- Pricing: competitor scan + tier structure + recommendation
- Runway: burn + revenue + months remaining
- Unit economics: CAC/LTV/margin with sensitivity
- Channels: per-channel CAC + time-to-results + sequence

## BUNDLE mode (NEW)

```
◆ bundle — jobs to features

  ┌ [Job 1: "Answer calls"]
  │  auth ████████░░ 78  voice ██████░░░░ 55
  │  status: [sufficient | gap | over-served]
  │
  ├ [Job 2: "Look professional"]
  │  site █████░░░░░ 48
  │  status: gap — needs [feature]
  │
  └ [Job 3: "Save time"]
     billing ███░░░░░░░ 30
     status: gap — core job, weakest delivery

▾ actions
  merge: [features] always co-occur for [job]
  kill: [feature] serves no validated job
  gap: [job] needs [feature type]

/founder feature [name]   drill into a feature
/founder decide [idea]    gate a new feature idea
```

## Formatting conventions (all modes)

- Header: `◆ [mode] — [summary]`
- Active items: `▸` prefix
- Inactive/background: `·` prefix
- Expandable sections: `▾` prefix
- Warnings: `⚠` prefix
- Bars: `█` filled, `░` empty, 10-char width
- Bottom: exactly 3 next commands
- No placeholder text — every field filled from real data
