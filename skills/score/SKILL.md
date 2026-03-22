---
name: score
description: "Is this product good? One honest number that tells you if your product improved. Checks code health, feature delivery, visual quality, user flows, and market viability — synthesized into a single score."
argument-hint: "[feature|quick|deep|viability|breakdown]"
allowed-tools: Read, Write, Bash, Grep, Glob, AskUserQuestion, WebFetch, WebSearch, Agent
user-invocable: false
---

<!-- INTERNAL: This skill is infrastructure for other skills, not marketplace distribution. -->

!command -v jq &>/dev/null && bash scripts/cache-summary.sh 2>/dev/null || echo "no cached scores (jq missing or cache empty)"

# /score — Unified Product Quality

You are the final judge. The question is always: **does the user get it?**

Not "is the code clean" or "does it build" — does a real human encounter this product, understand what it does, get value, and want to come back? Every tier measures a facet of that question. Health checks the foundation. Delivery checks whether the user cares. Craft checks whether the experience is well-made. Visual checks whether it looks/feels right. Behavioral checks whether it actually works. Viability checks whether the market cares.

This applies to any product — web, CLI, API, library, docs. The evidence sources change. The question doesn't.

## Skill folder structure

This skill is a **folder**. Read on demand:

- `scripts/cache-summary.sh` — reads all tier caches, shows staleness + confidence (zero context cost)
- `scripts/synthesize.sh [feature]` — computes unified score from cached tier data
- `scripts/viability-assess.sh [feature]` — checks viability cache freshness
- `references/scoring-methodology.md` — tier weights, confidence rules, staleness thresholds
- `references/viability-guide.md` — how viability scoring works with agents
- `templates/score-report.md` — output formatting for all modes
- `gotchas.md` — real failure modes. **Read before scoring.**

## Routing

| Argument | Mode |
|----------|------|
| (none) | Score all active features — full orchestration |
| `<feature>` | Deep unified score for one feature |
| `quick` | Read cached data only — no agent spawns, no fresh evals |
| `deep` | Force fresh data from ALL tiers (expensive, slow) |
| `viability` | Run viability assessment only (agent-backed) |
| `breakdown` | Show per-tier detail for all features |

## The five tiers

Each tier is independently runnable and independently cached. /score reads them all and synthesizes.

### Tier 1: Health (instant, free)

**Source:** `founder score .` (bin/score.sh)
**Cache:** `.claude/cache/score-cache.json` (5min TTL)
**What it measures:** Build passes, structure lint, hygiene. Pass/fail gate.
**Weight in final score:** Gate only — health < 20 = total score 0.

Run: `bash bin/score.sh . --json`

### Tier 2: Code Eval (LLM, moderate cost)

**Source:** `/eval` (bin/eval.sh + evaluator agents)
**Cache:** `.claude/cache/eval-cache.json`
**What it measures:** Delivery (does code deliver value?) + Craft (is code well-made?). Per feature.
**Weight in final score:** delivery 40%, craft 25%
**Staleness:** >24h or score changed >15pts since last run.

If stale: run `founder eval . --fresh` or spawn evaluator agents per feature.

### Tier 3: Visual Quality (Playwright, expensive)

**Source:** `/taste <url>` (taste reports)
**Cache:** `.claude/evals/reports/taste-*.json`
**What it measures:** 11 visual dimensions (layout, typography, color, spacing, etc). 0-100 per dimension.
**Weight in final score:** 15% (averaged across dimensions, applied to craft composite)
**Staleness:** >48h or code changed significantly since last taste run.

If stale: flag `visual_confidence: low` — don't penalize, but note the gap.
If no URL configured: skip tier, redistribute weight to code eval craft.

### Tier 4: Behavioral (Playwright, moderate)

**Source:** `/taste <url> flows` (flow audit reports)
**Cache:** `.claude/evals/reports/flows-*.json`
**What it measures:** Does the frontend actually work? Issue list by severity (blocker/major/minor).
**Weight in final score:** 10% (converted: 0 blockers + 0 majors = 100, each blocker = -25, each major = -10, each minor = -3)
**Staleness:** >48h or code changed significantly since last flows run.

If stale: flag `behavioral_confidence: low`.
If no URL configured: skip tier, redistribute weight to code eval delivery.

### Tier 5: Viability (intelligence-first, agent-refreshed)

**Source:** viability-cache.json (agent-backed) > market-context.json + customer-intel.json (intelligence-derived) > capped at 30
**Cache:** `.claude/cache/viability-cache.json`
**What it measures:** Market position, competitive differentiation, demand signals, UVP strength.
**Weight in final score:** 10%
**Staleness:** >72h or strategy/market context changed.

**Viability scoring priority:**
1. **Agent-backed** (viability-cache.json exists and fresh): full range 0-100. Authoritative.
2. **Intelligence-derived** (market-context.json + customer-intel.json exist): capped at 60. Uses accumulated intelligence without spawning agents.
3. **Partial intelligence** (one of market/customer exists): capped at 45.
4. **No data**: capped at 30. Honest unknown territory.

Agents are the REFRESH mechanism, not the only path. `synthesize.sh` reads intelligence files directly for scoring. Only spawn agents when intelligence is stale (>7 days) or missing entirely.

## How scoring works

Read `gotchas.md` before any scoring run.

### Health gate

`bash bin/score.sh . --json` is the crown jewel — an immutable, mechanical health check. Run it first, always. Health < 20 = total score 0, stop there. This script checks build state, structure lint, and hygiene. You don't replicate what it does — you run it and interpret the result.

### Tier assembly

Read all state files in parallel. For each tier, assess: is data present? Is it fresh? Assign confidence (high/medium/low) based on staleness thresholds. Then synthesize — weighted average across tiers, redistributing weight from missing tiers to present ones.

Run `bash scripts/synthesize.sh` to compute the unified score. Cross-check against your own reading of the tier data.

Product total = weighted average across features (by `weight:` field in founder.yml). Per-feature score = weighted sum across tiers (delivery 40%, craft 25%, visual 15%, behavioral 10%, viability 10%), with weight redistributed when tiers are missing.

### Mode-specific behavior

**Full (no arguments):** Read all caches, run health gate, synthesize. Spawn evaluator agents only if eval data is stale (>24h). Flag visual/behavioral gaps as low confidence — don't run expensive Playwright sessions unprompted.

**Quick:** Caches only. No fresh runs. No agents. Flag staleness. Fastest answer.

**Deep:** Fill ALL tiers. Health gate first. Then eval, visual, behavioral, viability — each only if stale or missing. Warn about cost (~$2-5, 10+ min) before starting. Use `AskUserQuestion` to confirm if not explicitly requested.

**Viability:** Only tier 5. Read existing intelligence first (market-context.json, customer-intel.json). Spawn agents only if intelligence is stale (>7d) or missing.

**Breakdown:** Per-tier raw data. No synthesis. Just the evidence.

### Viability mode

Only run tier 5. Spawn agents, gather evidence, score viability. Useful when you want to pressure-test market position without re-running everything.

### Breakdown mode

Show per-tier detail: each tier's raw scores, staleness, confidence level, evidence citations. No synthesis — just the data.

## Viability scoring

Read `references/viability-guide.md` for the full protocol. Four dimensions, 25 points each:

- **UVP clarity** — Can you name what's unique in one sentence?
- **Competitive gap** — Does market-context.json show something no competitor has?
- **Demand signal** — Does customer-intel.json show people wanting this?
- **Positioning** — Does strategy.yml show a clear stage-appropriate position?

Every claim must cite a source. No source = no points.

**Caps:** No external data = max 30. One intelligence file = max 45. Both = max 60. Agent-backed (viability-cache.json, fresh) = full 0-100. viability > 75 requires BOTH market context AND customer signal.

Agents (market-analyst, customer) are the REFRESH mechanism. Read intelligence files first. Only spawn agents when intelligence is stale (>7d) or missing entirely.

## Confidence levels

Each tier gets a confidence tag based on data freshness and completeness:

- **high** — fresh data (<24h for eval, <48h for taste/flows, <72h for viability)
- **medium** — cached data within 2x staleness threshold
- **low** — stale data beyond 2x threshold, or tier data missing entirely

Product-level confidence = minimum confidence across all tiers. One `low` tier = `low` overall.

## State

Read these directly — synthesize, don't delegate:

| File | What it tells you |
|------|-------------------|
| `config/founder.yml` | Feature list, weights, stage, URL, code paths |
| `config/product-spec.yml` | What the product claims to do — score against this |
| `.claude/cache/eval-cache.json` | Per-feature delivery/craft/viability sub-scores, deltas, timestamps |
| `.claude/cache/score-cache.json` | Last health score (5min TTL) |
| `.claude/cache/viability-cache.json` | Agent-backed viability scores |
| `.claude/cache/market-context.json` | Competitive landscape, market signals |
| `.claude/cache/customer-intel.json` | Demand signals, user feedback |
| `.claude/evals/reports/taste-*.json` | Visual quality scores (latest only) |
| `.claude/evals/reports/flows-*.json` | Behavioral audit results (latest only) |
| `.claude/plans/strategy.yml` | Current strategic focus |
| `.claude/cache/outside-in.json` | Journey gaps, unmet needs (if present) |

Scripts `cache-summary.sh` and `synthesize.sh` exist as verification — run them to cross-check your synthesis, not as the primary source.

## Presenting scores

Always present the unified score number FIRST, then supporting detail. Don't bury the answer. The raw `score.sh` output places the score line after several sections of gate/health status — when presenting to the founder, lead with the number from `synthesize.sh`, then show tier breakdowns as supporting evidence.

## After scoring — what to suggest

### Surface eval recommendations

After computing the unified score, check eval-cache.json for a `recommendations` field per feature. If present, surface the highest-priority recommendation alongside each feature's score. This turns /score from "here's a number" into "here's a number and what to do about it."

### Next command — maturity-gated

One next command. Pick the one that fills the biggest gap:
- Lowest-scoring feature → `/plan` to target the bottleneck
- Visual confidence low + URL exists → `/taste <url>`
- Behavioral confidence low → `/taste <url> flows`
- Viability is the weakest dimension → `/research` or `/strategy`
- Journey gaps or unmet needs in outside-in.json → `/ideate`
- Unified score 65+ → suggest `/eval` for micro-feature ideas, not just gap-fixing
- Unified score 80+ → suggest `/ideate` for micro-system thinking (features are mature enough that the next lever is new capabilities, not polish)
- All tiers high confidence + score > 80 → `/ship`

## System integration

**Reads:** founder.yml, product-spec.yml, eval-cache.json, score-cache.json, viability-cache.json, market-context.json, customer-intel.json, taste reports, flows reports, strategy.yml, outside-in.json
**Writes:** `.claude/cache/score-unified.json`
**Triggers:** /plan (bottleneck), /taste (visual/behavioral gaps), /research (viability gaps), /ideate (journey gaps), /ship (high confidence + high score)
**Triggered by:** "is this good?", "product quality", "unified score", start of /go loop, post-build verification

## Agents

- **founder-os:evaluator** — per feature, for fresh code eval (when eval cache stale)
- **founder-os:market-analyst** — viability tier, competitive landscape (background)
- **founder-os:customer** — viability tier, demand signals (background)

## Self-evaluation

This skill worked if: (1) score-unified.json was written with all active features, (2) every tier has an explicit confidence level, (3) the tier fill badge reflects actual data (not assumptions), and (4) the next command suggestion matches the weakest tier.

## What you never do

- Score without checking all available cached data first
- Invent viability scores without agent evidence
- Skip the health gate
- Present a score without confidence levels
- Edit code — /score is measurement only
- Run taste/flows without being asked (expensive) — read caches, flag staleness

## If something breaks

- No features in founder.yml: "No features defined. `/feature new [name]`"
- No eval cache: run quick eval, establish baseline
- No taste/flows data: flag low confidence, score without those tiers
- No viability data: cap viability at 30, suggest `/score viability` or `/research`
- Agent spawn fails: score with available data, flag viability as `low` confidence

$ARGUMENTS
