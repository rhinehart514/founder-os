---
name: measure
description: "Is it good? Unified 6-tier scoring (health, delivery, craft, visual, behavioral, viability + demand), feature evaluation, visual quality, flow auditing, evidence class auditing. Replaces: /score, /eval, /taste. Also triggers on: 'score', 'eval', 'evaluate', 'taste', 'is this good', 'how's it look', 'quality check'."
argument-hint: "[quick | deep | <feature> | evidence | beliefs | health | blind | slop | flows <url> | visual <url> | cli | trend | breakdown | viability]"
allowed-tools: Read, Write, Bash, Grep, Glob, AskUserQuestion, WebSearch, WebFetch, Agent, mcp__playwright__browser_navigate, mcp__playwright__browser_take_screenshot, mcp__playwright__browser_snapshot, mcp__playwright__browser_wait_for, mcp__playwright__browser_click, mcp__playwright__browser_hover, mcp__playwright__browser_resize, mcp__playwright__browser_evaluate, mcp__playwright__browser_network_requests, mcp__playwright__browser_console_messages, mcp__playwright__browser_fill_form, mcp__playwright__browser_press_key, mcp__playwright__browser_navigate_back, mcp__playwright__browser_install
---

!command -v jq &>/dev/null && bash scripts/cache-summary.sh 2>/dev/null || true
!bash scripts/dimension-summary.sh 2>/dev/null || true
!bash scripts/flows-summary.sh 2>/dev/null || true

# /measure — Is It Good?

One skill to answer every quality question. Reads code, visits the product, checks the market, synthesizes into a single honest number with evidence. Replaces /score, /eval, and /taste.

## Folder contents (read on demand)

- `scripts/` — 14 scripts + `checks/` (JS browser checks). Run mechanically, no LLM.
- `references/` — scoring methodology, dimensions, guides, protocols. Read before scoring.
- `templates/` — output formatting for score, eval, taste, and flows reports.
- `gotchas.md` — **read before any measurement run.**

## Routing

| Input | Mode | What happens |
|-------|------|--------------|
| (none) | UNIFIED | All tiers synthesized — one number |
| `quick` | QUICK | Cached data only, no agents, flag staleness |
| `deep` | DEEP | Fresh all tiers (expensive — confirm first) |
| `<feature>` | FEATURE | Deep eval of one feature (delivery + craft + rubric) |
| `evidence` | EVIDENCE | Evidence class audit — label every claim [observed/stated/market/inferred] |
| `beliefs` | BELIEFS | Mechanical assertion checks (beliefs.yml) |
| `health` | HEALTH | Assertion coverage — type distribution, gaps per feature |
| `blind` | BLIND | Cold-read code vs claims, score alignment |
| `slop` | SLOP | LLM-generated code detection |
| `flows <url>` | FLOWS | Does frontend work? Playwright behavioral audit |
| `visual <url>` | VISUAL | Design quality — 11 dimensions, gestalt first |
| `cli` | CLI | Terminal output quality — 5 dimensions |
| `trend` | TREND | Score trajectory over time |
| `breakdown` | BREAKDOWN | Per-tier detail, no synthesis |
| `viability` | VIABILITY | Market viability only (agent-backed) |

## 6-tier scoring

See `references/scoring-methodology.md` for full details. Summary:

| Tier | Weight | Source | Cache |
|------|--------|--------|-------|
| Health | Gate (< 20 = score 0) | `bin/score.sh --json` | score-cache.json (5min) |
| Delivery | 35% | Code eval per feature | eval-cache.json (24h) |
| Craft | 20% | Code eval per feature | eval-cache.json (24h) |
| Visual | 12% | Playwright 11-dimension eval | taste-*.json (48h) |
| Behavioral | 8% | Playwright flow audit | flows-*.json (48h) |
| Viability | 10% | Agent-backed market research | viability-cache.json (72h) |
| Demand | 15% | demand-cache.json | demand-cache.json (7d) |

**Evidence enforcement:** Features with only [inferred] evidence get delivery capped at 60. Evidence class must be labeled on every claim.

**Confidence:** Each tier tagged high/medium/low based on staleness. Product confidence = min across tiers.

## Key behaviors

1. **Health gate first.** `bash bin/score.sh . --json`. Health < 20 = total 0, stop.
2. **Read demand-cache.json** for demand tier. No demand data = demand capped at 30.
3. **Parallel evaluators.** 3+ features: spawn one `founder-os:evaluator` agent per feature.
4. **Evidence class audit (NEW).** `measure evidence` labels every feature claim as [observed], [stated], [market], or [inferred]. Inferred-only features get delivery capped at 60.
5. **Caps apply.** Slop = overall cap 40. Layout/IA < 30 = overall cap 30. Stage caps enforced.
6. **Score = synthesize.sh output**, cross-checked against your own reading.

## State

**Reads:** founder.yml, product-spec.yml, eval-cache.json, score-cache.json, viability-cache.json, market-context.json, customer-intel.json, demand-cache.json, taste reports, flows reports, strategy.yml, outside-in.json, beliefs.yml, rubrics/*.json
**Writes:** `.claude/cache/score-unified.json`
**Agents:** `founder-os:evaluator` (per feature), `founder-os:market-analyst` (viability), `founder-os:customer` (demand signals)

## After measuring — what to suggest

One next command. Pick the biggest gap:
- Lowest feature -> `/plan` the bottleneck
- Visual confidence low + URL exists -> `/measure visual <url>`
- Behavioral confidence low -> `/measure flows <url>`
- Viability weakest -> `/research` or `/strategy`
- Score 65+ -> `/measure <feature>` for micro-feature ideas
- Score 80+ all tiers high -> `/ship`

## Self-evaluation

Worked if: (1) score-unified.json written, (2) every tier has confidence level, (3) evidence classes labeled, (4) next command matches weakest tier.

## What you never do

- Score without reading all available cached data first
- Invent viability scores without agent evidence
- Skip the health gate
- Present scores without confidence levels
- Edit code — measurement only
- Run expensive Playwright sessions unprompted — read caches, flag staleness

$ARGUMENTS
