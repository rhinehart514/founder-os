---
name: demand
description: "What's worth building? Discovery, JTBD analysis, four forces, value props, market research, competitive strategy, product pressure-testing — all in one skill. Replaces: /discover, /blueprint, /product, /research, /strategy. Also triggers on: 'new idea', 'what should we build', 'is this worth building', 'who wants this', 'JTBD', 'value prop', 'compete', 'position'."
argument-hint: "[idea | refine | pivot | compare | kill | jobs | forces | switch | valueprop | framing | features | tiers | research <topic> | market <space> | customer <idea> | compete <idea> | site <url> | gaps | position <idea> | stage <idea> | bet <idea> | honest | package]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch, AskUserQuestion, mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot
---

# /demand — What's Worth Building?

Demand-side product thinking. Takes raw ideas to validated business cases, runs JTBD analysis, pressure-tests assumptions, researches markets, diagnoses strategy — or kills fast. Every mode gates on "who wants this?" before proceeding.

## Folder contents (read on demand)

- `references/` — hierarchy, research-playbook, jtbd-method, four-lens, framing-angles, interview-guide, product-thinking, pressure-tests, yc-readiness, research-methods, evidence-hierarchy, strategy-frameworks, honest-diagnosis, market-2026
- `scripts/` — research-log, competitive-scan, market-scan, source-quality, product-scan, assumption-audit, stage-check, strategy-freshness
- `patterns/` — job-statements, value-props, hire-fire-triggers
- `templates/` — blueprint-output, product-brief, research-brief, market-context.json, strategy-brief, business-case

## Before any mode

1. Read `gotchas.md` — merged failure patterns from all 5 absorbed skills
2. Check `demand-cache.json` if it exists — jobs, forces, packages, evidence from prior runs
3. Read `mind/world.md` — does this make sense in 2026?

## Routing

| Input | Mode | Agents |
|-------|------|--------|
| new idea / "I want to build..." | NEW | explorer, market-analyst, customer (parallel) |
| `refine` | REFINE | targeted agent for weak dimension |
| `pivot` | PIVOT | — |
| `compare` | COMPARE | — |
| `kill` | KILL | — |
| `jobs` | JOBS | customer, market-analyst, explorer (parallel) |
| `forces` | FORCES | — |
| `switch` | SWITCH | — |
| `valueprop` | VALUEPROP | — |
| `framing` | FRAMING | — |
| `features` | FEATURES | — |
| `tiers` | TIERS | — |
| `package` | PACKAGE | — |
| `research [topic]` | RESEARCH | explorer, market-analyst |
| `market [space]` | MARKET | explorer, market-analyst (parallel) |
| `customer [idea]` | CUSTOMER | customer agent |
| `compete [idea]` | COMPETE | market-analyst |
| `site [url]` | SITE | Playwright |
| `gaps` | GAPS | — |
| `position [idea]` | POSITION | market-analyst |
| `stage [idea]` | STAGE | — |
| `bet [idea]` | BET | — |
| `honest` | HONEST | explorer |

## Key behaviors

- **Evidence labeling**: every claim tagged [observed], [stated], [market], or [inferred]
- **Demand gate**: every mode checks "who wants this?" before proceeding
- **Research playbook** (`references/research-playbook.md`): runs before any generation in NEW/JOBS/RESEARCH/MARKET modes
- **State persistence**: writes `demand-cache.json` (jobs, forces, packages, evidence) and `config/portfolio.yml` (idea specs)

## Modes

**NEW**: Kill check (5 questions) -> research playbook -> hierarchy anchor (`references/hierarchy.md`) -> 3 jobs (`references/jtbd-method.md`) -> spawn 3 agents -> pressure test (`references/pressure-tests.md`) -> synthesize to `config/portfolio.yml` + `demand-cache.json`. Output per `templates/business-case.md`.
**REFINE**: Read idea from `portfolio.yml`. Re-run research for weakest dimension. Spawn targeted agent. Update spec.
**PIVOT**: Read idea. "What's still true?" 3 bands of pivot directions. New entry linked to original.
**COMPARE**: 2+ ideas. Compare at OUTCOME level. Score market/model/moat. Recommend with reasoning.
**KILL**: Document why, what learned. Update `experiment-learnings.md`. Stage to `killed`.
**JOBS**: Parallel research -> Ulwick statements (`references/jtbd-method.md`, `patterns/job-statements.md`) -> four forces -> opportunity scores.
**FORCES**: Four forces per `references/jtbd-method.md`. Push/pull/anxiety/inertia, net switching energy.
**SWITCH**: Hire/fire triggers per `patterns/hire-fire-triggers.md`. Timeline format. Switch destination map.
**VALUEPROP**: Per job. Pressure test per `patterns/value-props.md`. Repeatable, outcome-first, peer-worthy.
**FRAMING**: 3-7 angles per `references/framing-angles.md`. Peer test. Recommend acquisition + retention frames.
**FEATURES**: 4-lens grid per `references/four-lens.md`. 3 solutions per opportunity. Kill list mandatory.
**TIERS**: 3 tiers with displacement math and price points. Moat growth over time.
**PACKAGE**: Read `demand-cache.json` jobs -> bundle into customer-facing packages -> write to `demand-cache.json`.
**RESEARCH**: Predict -> spawn explorer + market-analyst -> synthesize per `templates/research-brief.md` -> update `experiment-learnings.md`.
**MARKET**: Explorer + market-analyst parallel. `scripts/market-scan.sh`. Store in `demand-cache.json`.
**CUSTOMER**: Customer agent. Pain signals, willingness to pay, switching triggers.
**COMPETE**: Market-analyst. `scripts/competitive-scan.sh`. Strategic response playbook.
**SITE**: Playwright MCP. Product, pricing, UX, weaknesses.
**GAPS**: All ideas in `portfolio.yml`. Untested hypotheses ranked by information value (kill conditions first).
**POSITION**: Category, enemy, promise, proof, personality. `scripts/competitive-scan.sh`.
**STAGE**: Actual stage vs declared. `scripts/stage-check.sh`. Stage-appropriate actions only.
**BET**: 7 dimensions per `references/strategy-frameworks.md`. Min 2 below 5.
**HONEST**: `references/honest-diagnosis.md`. Full portfolio. Biggest risk, opportunity, blind spot. One recommendation.

## State reads/writes

**Reads**: `config/portfolio.yml`, `demand-cache.json`, `mind/world.md`, `mind/patterns.md`, `~/.claude/knowledge/experiment-learnings.md`, `~/.claude/knowledge/predictions.tsv`
**Writes**: `config/portfolio.yml`, `demand-cache.json`, `~/.claude/knowledge/predictions.tsv`, `~/.claude/knowledge/experiment-learnings.md`

## Agents

- **founder-os:explorer** — market research, timing, technology enablers
- **founder-os:market-analyst** — competitive landscape, pricing, positioning
- **founder-os:customer** — pain signals, willingness to pay, buyer profile

## System integration

Triggers: `/go` (build), `/plan` (act on diagnosis), `/ideate` (need ideas), `/money` (pricing)
Triggered by: `/plan`, `/score`, `/eval`, `/retro`, `/decide`

## Self-evaluation

Succeeded if: research ran before generation, every idea anchored to outcome + opportunity, assumptions named, evidence labeled, output ends with concrete recommendation (not a menu), prediction logged.

## What you never do

- Generate a business case from memory without searching
- Skip the research playbook or kill check
- Present parity features as insights
- Be sycophantic ("promising", "solid foundation" = banned)
- Return a flat list without a recommendation
- Give generic advice without naming the specific person
- Score all BET dimensions above 5
- Research without a prediction
- Dump raw results without synthesis

$ARGUMENTS
