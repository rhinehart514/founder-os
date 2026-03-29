---
name: founder
description: "Home base. Dashboard, onboarding, feature management, decision gates, backlog, assertions, configuration, skill management, business model analysis, workflow, context handoff, codebase mapping. Replaces: /founder, /onboard, /feature, /decide, /todo, /assert, /configure, /skill, /money, /flow, /pause, /map. Also triggers on: 'dashboard', 'where am I', 'status', 'onboard', 'feature', 'decide', 'todo', 'assert', 'configure', 'money', 'pricing'."
argument-hint: "[onboard | feature [name|new|detect] | bundle | decide [idea] | todo [add|done|promote|health] | assert [feature: text] | configure [show|agents] | skill [list|audit] | money [price|runway|unit-economics] | flow | pause [resume] | map]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion, WebSearch, WebFetch, EnterPlanMode, ExitPlanMode, mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot
---

!cat .claude/cache/product-value.json 2>/dev/null | jq '.product_model' 2>/dev/null || true

# /founder

Home screen + 12 absorbed skills. Route by first argument.

## Routing

| Input | Mode | Behavior |
|-------|------|----------|
| (none) | DASHBOARD | Portfolio + project state + demand status + one opinion |
| help | HELP | Start Here flow + 7-skill catalog |
| system | SYSTEM | Internals: version, hooks, agents |
| compare | COMPARE | Diff against previous snapshot |
| health | HEALTH | System health audit |
| progress | PROGRESS | Score trajectory, velocity |
| onboard | ONBOARD | Bootstrap any project (demand mapping first) |
| feature [args] | FEATURE | Define, view, detect, improve features (new features require system assignment) |
| bundle | BUNDLE | Map features to customer jobs, identify merge/kill/gap |
| decide [idea] | DECIDE | Go/kill/pivot gate (hierarchy-level-aware evidence thresholds) |
| todo [args] | TODO | Living backlog management |
| assert [args] | ASSERT | Manage beliefs.yml assertions |
| configure [args] | CONFIGURE | Tune founder-os settings |
| skill [args] | SKILL | Manage skills |
| money [args] | MONEY | Pricing, unit economics, runway |
| flow | FLOW | Measured GSD workflow |
| pause [resume] | PAUSE | Session handoff / context restore |
| map | MAP | Parallel codebase analysis |

**Read `gotchas.md` before rendering any view.**

## Mode dispatch

Each mode has a dedicated source SKILL.md with full protocol. Read the original on demand:

| Mode | Source for protocol | Key scripts |
|------|-------------------|-------------|
| DASHBOARD | (inline below) | `scripts/system-pulse.sh`, `scripts/skill-catalog.sh` |
| ONBOARD | `skills/onboard/SKILL.md` | `scripts/detect-project.sh`, `scripts/onboard-checklist.sh`, `scripts/first-score.sh` |
| FEATURE | `skills/feature/SKILL.md` | `scripts/feature-map.sh`, `scripts/feature-health.sh`, `scripts/dependency-graph.sh` (system-aware: groups by system, flags orphans) |
| DECIDE | `skills/decide/SKILL.md` | — (hierarchy-level-aware evidence thresholds) |
| TODO | `skills/todo/SKILL.md` | `scripts/todo-decay.sh`, `scripts/todo-promote.sh`, `scripts/todo-stats.sh` |
| ASSERT | `skills/assert/SKILL.md` | `scripts/assertion-stats.sh`, `scripts/belief-lint.sh`, `scripts/assertion-diff.sh` |
| CONFIGURE | `skills/configure/SKILL.md` | `scripts/config-diff.sh` |
| SKILL | `skills/skill/SKILL.md` | `scripts/skill-scan.sh`, `scripts/skill-quality.sh` |
| MONEY | `skills/money/SKILL.md` | `scripts/revenue-scan.sh`, `scripts/pricing-compare.sh`, `scripts/runway-calc.sh` |
| FLOW | `skills/flow/SKILL.md` | (uses bin/gsd-*.sh) |
| PAUSE | `skills/pause/SKILL.md` | — |
| MAP | `skills/map/SKILL.md` | — (spawns explorer agents) |

## DASHBOARD mode (default)

State files: `~/.founder-os/portfolio.yml`, `.claude/cache/score-cache.json`, `.claude/cache/eval-cache.json`, `config/founder.yml`, `.claude/plans/roadmap.yml`, `.claude/plans/strategy.yml`, `.claude/plans/plan.yml`, `~/.claude/knowledge/predictions.tsv`, `.claude/plans/todos.yml`

**First-run gate**: if `config/founder.yml` missing, suggest `/founder onboard`. If no eval cache, suggest `/eval`.

**Demand status** (NEW — render in dashboard):
```
◆ demand status
Jobs -> Features:
  ┌ Answer calls ─── auth ████████░░ 78
  ├ Look professional ── site █████░░░░░ 48
  └ Save time ────── billing ███░░░░░░░ 30
Packages: "Never Miss Another Call" -> auth + voice [validated]
Evidence: 3 observed · 5 stated · 2 market
```

**Rendering**: read `references/dashboard-guide.md` for full spec. Read `templates/dashboard.md` for format. Portfolio first (if exists), then project dashboard, then opinion. Save snapshot to `.claude/cache/founder-snapshots.json` (keep last 20).

**Hierarchy coverage widget** (NEW — render after demand status):
```
◆ hierarchy reach
  OUTCOME ✓ · OPPORTUNITY ✓ · SYSTEM ✗ · FEATURE ✓ · MICRO ✓ · INTERACTION ~
```
Derive from: portfolio.yml (outcome/opportunity), feature system assignments (system), eval-cache (feature), taste/flows reports (micro/interaction). Flag any level with ✗ as a blind spot. Read `skills/shared/hierarchy-lens.md` for level definitions.

**Coherence check**: cross-check strategy vs eval vs plan. Render warnings only when misaligned.

## BUNDLE mode (NEW)

Map features to customer jobs (from demand mapping). For each job:
- Which features serve it? Are they sufficient?
- Merge: features that always co-occur for one job
- Kill: features that serve no job
- Gap: jobs with no features

Output as a jobs-to-features matrix with action recommendations.

**System map** (hierarchy-aware extension): after the jobs-to-features matrix, read `skills/shared/system-thinking.md` and also produce:
- Group features by owning system (data domain)
- Flag orphan features (no system), dead systems (no active features), over-decomposed systems (1 feature)
- Flag cross-system features (coupling smell — feature spans multiple systems)
- Recommend: merge, split, kill, or leave systems as-is

## HELP mode

Show Start Here flow first, then 7-skill catalog (not old 28):
```
Start Here
  "is this good?"          -> /score
  "what should I work on?" -> /plan
  "just build it"          -> /go
  New idea? /founder decide -> /research -> /plan

7 Skills: /founder · /demand · /score · /plan · /go · /eval · /build
```

## ONBOARD mode

Starts with demand mapping — who wants this, what job, what today? Then detection, config, features, assertions, learning loop. Read `skills/onboard/SKILL.md` for full protocol. Read `references/onboarding-flow.md` for output format.

## Self-evaluation

- **DASHBOARD**: all non-empty zones rendered, snapshot saved, opinion stated
- **HELP**: Start Here shown BEFORE catalog, shows 7 skills not 28
- **BUNDLE**: jobs-to-features matrix rendered with merge/kill/gap actions + system map with ownership
- **DASHBOARD**: hierarchy coverage widget rendered with per-level status
- **All absorbed modes**: check source SKILL.md self-evaluation criteria

## What you never do

- Turn dashboard into a report — density is the design
- Recommend more than one next action
- Show zones with no data or make up numbers
- Skip reading gotchas.md before rendering

$ARGUMENTS
