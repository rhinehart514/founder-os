# /skill Reference — Output Templates

Loaded on demand. Routing and lifecycle logic are in SKILL.md.

---

## List output

```
◆ skill — 18 skills

  ⎯⎯ measured (feature in founder.yml) ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  /eval          ████████████░░░░░░░░  working   w:5  58 (d:62 c:50 v:60)
  /plan          ████████████░░░░░░░░  working   w:5
  /go            ██████░░░░░░░░░░░░░░  building  w:4  BETA
  /feature       ████████████░░░░░░░░  working   w:5

  ⎯⎯ unmeasured (no feature entry) ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  /clone         no assertions · no feature entry
  /openclaw      no assertions · no feature entry

  ⎯⎯ context (auto-loaded) ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  founder-mind     loaded every session
  product-lens   loaded for product eval

/skill create <name>    create a measured skill
/skill info <name>      inspect one
/skill health           tier breakdown
```

## Create output

```
◆ skill create — [name]

  emerged from: "[the pattern they described]"

  ✓ skills/[name]/SKILL.md
  ✓ skills/[name]/reference.md
  ✓ config/founder.yml — feature entry (w:[N], planned)
  ✓ beliefs.yml — 3 assertions seeded
  ✓ overlap check — [N]% overlap (clear)
  ✓ baseline eval: PARTIAL — [N] passing

  This skill is now measured. It has a score, assertions, and maturity
  tracking. When it reaches working maturity, it becomes a defensible
  claim in /roadmap narrative.

/go [name]         build it to working
/eval [name]       check current state
/feature [name]    see the full breakdown
```

## Info output

```
◆ skill info — [name]

  description: "[skill description]"
  routes: [route1] · [route2] · [route3]
  tier: [thick|thin|stub|dead] ([N] lines, [N] routes, [N] assertions, reference.md)
  allowed-tools: [tool list]

  ⎯⎯ measurement ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  feature: [name] (w:[N], [maturity])
  score: [N]/100 (d:[N] c:[N] v:[N]) [delta]
  assertions: [N]/[M] passing
  rubric: .claude/cache/rubrics/[name].json ([fresh|stale])

  ⎯⎯ quality checks ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  ✓ output format compliant
  ✓ state artifacts declared
  ✓ anti-rationalization section
  ✓ degraded modes documented
  ✗ no prediction logging references

  ⎯⎯ files ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯

  skills/[name]/SKILL.md      ([N] lines)
  skills/[name]/reference.md  ([N] lines)

/[name]              run it
/feature [name]      see the feature
/go [name]           improve it
```

## Health output

```
◆ skill health — [N] skills

  thick: [N]  thin: [N]  stub: [N]  dead: [N]

  ▾ thick (gold standard)
    /eval       382 lines  9 routes  11 assertions  58/100
    /strategy   453 lines  12 routes  8 assertions   —
    /taste      484 lines  5 routes   6 assertions   72/100

  ▾ thin (needs work)
    /clone      114 lines  1 route   0 assertions   ⚠ no measurement
    /openclaw   178 lines  5 routes  0 assertions   ⚠ unmeasured 15d

  ▾ stub (build or kill)
    /example    61 lines   2 routes  0 assertions   ⚠ no reference.md

  ▾ dead (kill candidates)
    /old        45 lines   0 assertions  ⚠ unmeasured 30d+

/skill audit        full quality check
/skill create       add a new measured skill
/assert             add assertions to thin skills
```

## Audit output

```
◆ skill audit — [N]% compliant

  ▾ output format
    ✓ 12/18 skills have proper header (◆ name — scope)
    ✗ 6 skills missing state bar after header
    ✓ 15/18 skills end with 3 bottom commands

  ▾ state artifacts
    ✓ 8/18 skills declare state artifacts table
    ✗ 10 skills have no artifact declarations

  ▾ anti-rationalization
    ✓ 5/18 skills have anti-rationalization section
    ✗ 13 skills lack self-deception checks

  ▾ degraded modes
    ✓ 14/18 skills have "if something breaks" section
    ✗ 4 skills fail silently on missing data

  ▾ worst offenders
    /clone        1/5 checks passing  ⚠ stub
    /openclaw     2/5 checks passing  ⚠ thin

/skill health       per-skill breakdown
/go [weakest]       improve the weakest skill
/assert             add missing assertions
```

## Overlap output (blocked)

```
◆ skill overlap — [proposed name]

  checking against [N] existing skills...

  ⚠ 65% overlap with /eval
    shared routes: deep analysis, scoring, sub-scores
    unique to proposed: [what's different]

  recommendation: add a route to /eval instead of creating /[name]

/eval               the skill that already covers this
/skill info eval    see its current routes
/skill create       proceed anyway (not recommended)
```

## Overlap output (clear)

```
◆ skill overlap — [proposed name]

  checking against [N] existing skills...

  ✓ no significant overlap detected
    closest: /eval at 15% (shared keyword: "analysis")

  clear to create.

/skill create [name]    proceed with creation
/skill list             see all existing skills
/skill health           check system quality
```

## Formatting rules

- Header: `◆ skill — [N] skills` or `◆ skill create — [name]` etc.
- List: grouped by measured/unmeasured/context, standard feature rows for measured skills
- Create: `✓` checklist for each setup step
- Info: labeled dividers for measurement, quality checks, files
- Health: grouped by tier, line/route/assertion counts per skill
- Audit: `✓`/`✗` per compliance check, worst offenders section
- Overlap: `⚠` for blocked, `✓` for clear, with percentage and shared routes
- Tier labels always shown: thick/thin/stub/dead
- Bottom: exactly 3 next commands
