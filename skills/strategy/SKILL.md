---
name: strategy
description: "How to compete. Positioning, timing, wedge, competitive response — where to play and how to win. Stage-appropriate advice."
argument-hint: "[idea-name | honest | position | compete | stage | gtm | bet <idea> | market <domain> | price | coherence | user]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch, AskUserQuestion, mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot
---

# /strategy — Strategic Diagnosis

You provide honest strategic analysis. Not cheerleading — diagnosis.
Stage-appropriate advice. "You're pre-PMF, stop worrying about scale."

**2026 context:** Read `mind/world.md` before every strategy session. The world changed —
outcome-based pricing is winning, open source closed the gap, MCP is infrastructure,
solo founders are the norm. Your advice must reflect what's true NOW, not 2024 playbooks.

## Before any mode

1. **WebSearch** the market space — what happened this week? New entrants? Funding rounds? Pricing changes?
2. For compete/position/market modes: **use Playwright MCP** to actually visit competitor sites, screenshot pricing pages, test their onboarding flow. Don't guess from memory.
3. Read `mind/world.md` for externalities that apply to this idea.

## Skill folder structure

This skill is a **folder**, not just this file. Read these on demand:

- `scripts/competitive-scan.sh` — outputs structured competitor data via WebSearch, checks market-context.json freshness. **Real utility — run for market/compete/position modes.**
- `scripts/strategy-freshness.sh` — checks strategy.yml age, flags staleness, shows what changed since last run
- `scripts/stage-check.sh` — infers project stage from eval-cache + config
- `references/strategy-frameworks.md` — stage-appropriate frameworks and bet scoring dimensions
- `references/honest-diagnosis.md` — how to name what the founder is avoiding. **Read before `/strategy honest`.**
- `references/market-2026.md` — current landscape, competitor positioning, what's being disrupted
- `templates/strategy-brief.md` — output template for every strategy session
- `reference.md` — detailed output examples and formatting rules
- `gotchas.md` — real failure modes. **Read before every run.**

## Routing

Parse `$ARGUMENTS`:

- **`[idea-name]`** → `FULL` mode (complete strategic assessment)
- **`honest`** → `HONEST` mode (brutally honest assessment of the portfolio)
- **`position [idea]`** → `POSITION` mode (positioning and messaging)
- **`compete [idea]`** → `COMPETE` mode (competitive response strategy)
- **`stage [idea]`** → `STAGE` mode (what stage is this, what's appropriate)
- **`gtm [idea]`** → `GTM` mode (go-to-market strategy)
- **`bet [idea]`** → `BET` mode (score a product idea on 7 dimensions, anti-sycophancy gate)
- **`market [domain]`** → `MARKET` mode (landscape dive — spawn explorer + market-analyst)
- **`price`** → `PRICE` mode (pricing intel via gtm agent)
- **`coherence`** → `COHERENCE` mode (narrative audit — code vs claims, pitch vs reality)
- **`user`** / **`journey`** → `USER` mode (user model — journey walkthrough, friction scoring)
- **No args** → `HONEST` mode

## When to use

Use /strategy when you know WHAT you're building but need to decide HOW to position it.

- Don't know what to build? → `/discover`
- Know what, need evidence? → `/research`
- Need to validate demand? → `/product`
- Need pricing/economics? → `/money`

---

## HONEST Mode (default) — "/strategy" or "/strategy honest"

The most important mode. Read `references/honest-diagnosis.md` first. Read the full portfolio and give an honest assessment.

1. Read `config/portfolio.yml` — all ideas, stages, evidence
2. Read `~/.claude/knowledge/experiment-learnings.md` — patterns
3. Read `~/.claude/knowledge/predictions.tsv` — prediction accuracy
4. Check failure patterns from mind/patterns.md

Output:
```
## Honest Assessment

**Portfolio health**: [good/scattered/stuck]
[1-2 sentences: what's really going on]

**Biggest risk**: [the thing most likely to waste the founder's time]
**Biggest opportunity**: [the idea with the strongest evidence]
**Blind spot**: [what the founder isn't seeing]

### Per-idea diagnosis
[for each active idea:]
  [name]  [stage]  [honest assessment in 1 sentence]
  ⚠ [failure pattern if detected]

→ [ONE recommendation: what to do RIGHT NOW]
```

---

## FULL Mode — "/strategy [idea-name]"

Complete strategic assessment for one idea:

### Positioning
- Who is this for? (specific, not broad)
- What category does it create or enter?
- What's the one sentence that makes someone say "I need that"?
- How is this different from the top 3 competitors?

### Timing
- What changed that makes this possible/necessary now?
- Is this early (market forming), on-time (market growing), or late (market mature)?
- What happens if you wait 6 months?

### Wedge Analysis
- Is the wedge small enough to build in weeks?
- Does the wedge lead naturally to expansion?
- Is the wedge defensible or just a feature?

### Competitive Dynamics
Spawn market-analyst if competitive data is stale:
```
Agent(subagent_type: "founder-os:market-analyst", prompt: "Competitive analysis for [idea].
Focus on: who's closest to this positioning, their trajectory, and what they'd do
if they saw this product.", run_in_background: true)
```

### Stage-Appropriate Advice
Based on idea stage, focus only on what matters NOW:
- **Raw**: Is there a customer? (nothing else matters)
- **Researching**: Is there demand? (don't think about features)
- **Validating**: Will they pay? (don't think about scale)
- **Committing**: Build the wedge, nothing more
- **Building**: Ship to first customer, measure retention

---

## POSITION Mode — "/strategy position [idea]"

Focused on messaging and positioning only:
- Category: entering existing or creating new?
- Enemy: what's the old way this replaces?
- Promise: one sentence value prop
- Proof: what evidence makes the promise credible?
- Personality: how does this brand feel? (not visual — tone, stance)

For competitive data, run `bash scripts/competitive-scan.sh`.

---

## COMPETE Mode — "/strategy compete [idea]"

Spawn market-analyst for latest competitive intel:
- Who would respond if this launched?
- How quickly could they copy the wedge?
- What do you have that they can't easily replicate?
- Competitive response playbook: what to do when they notice

---

## STAGE Mode — "/strategy stage [idea]"

Diagnose what stage this idea is actually at (not what the founder thinks):
- Check evidence against stage requirements
- Flag if founder is doing stage-inappropriate work
- Recommend stage-appropriate actions only

Run `bash scripts/stage-check.sh` for mechanical stage inference.

---

## GTM Mode — "/strategy gtm [idea]"

Spawn GTM agent:
```
Agent(subagent_type: "founder-os:gtm", prompt: "Go-to-market strategy for [idea].
Customer: [from portfolio]. Pricing benchmarks: [from portfolio].
Focus on: first 10 customers (not first 10,000). Channel, pricing, packaging.")
```

---

## BET Mode — "/strategy bet [idea]"

Score a product idea on 7 dimensions from `references/strategy-frameworks.md`. Anti-sycophancy gate: minimum 2 dimensions must score below 5. Every score needs cited evidence.

---

## MARKET Mode — "/strategy market [domain]"

Landscape dive. Spawn explorer + market-analyst in parallel:
```
Agent(subagent_type: "founder-os:explorer", prompt: "Codebase analysis for [domain] — what do we already have?", run_in_background: true)
Agent(subagent_type: "founder-os:market-analyst", prompt: "Market landscape for [domain] — players, positioning, gaps, trends.", run_in_background: true)
```

Also run `bash scripts/competitive-scan.sh` for structured data.

---

## PRICE Mode — "/strategy price"

Pricing intel via gtm agent:
```
Agent(subagent_type: "founder-os:gtm", prompt: "Pricing analysis. Current competitor pricing, value metric options, tier structure recommendations.")
```

---

## COHERENCE Mode — "/strategy coherence"

Narrative audit — does the code match the claims?
- Code reality vs README claims
- Pitch vs product state
- Feature weights vs thesis
- Strategy.yml vs eval-cache.json reality

---

## USER Mode — "/strategy user" or "/strategy journey"

User model — journey walkthrough, friction scoring:
- Walk through the full user journey (FIND → UNDERSTAND → TRY → GET VALUE → COME BACK)
- Score friction at each stage
- Identify the stage where most users would drop off

---

## State to read

Read `gotchas.md` first. Then run `bash scripts/strategy-freshness.sh` to check strategy.yml staleness.

**Stage determination** — compute from eval-cache + config:
- Read `.claude/cache/eval-cache.json` — count features by score band
- Read `config/portfolio.yml` or `config/founder.yml` — declared stage, user count
- Infer stage: no features scored = pre-product, avg < 30 = pre-product, no working+ features = stage one, users <= 10 = stage some, users <= 100 = stage many, else growth

**Additional state:** `.claude/plans/strategy.yml`, `.claude/plans/roadmap.yml`, `~/.claude/knowledge/experiment-learnings.md`, `~/.claude/knowledge/predictions.tsv`, `.claude/cache/last-research.yml`, `config/product-spec.yml`

## How to diagnose

Sort features by eval score, worst first. For worst 3, check sub-score pattern:
- delivery dragging → should this feature exist?
- craft dragging → ticking time bomb or acceptable debt?
- viability dragging → blocking adoption?

Check stage-appropriateness, work-to-impact ratio, feature sprawl, measurement health, market position.

For competitive data in market/compete/position modes, run `bash scripts/competitive-scan.sh`.

Deliver using `templates/strategy-brief.md` for output structure.
Label every claim: [observed], [stated], [market], or [inferred].

Every recommendation is a prediction. Log to `~/.claude/knowledge/predictions.tsv`.

## Task generation

For EVERY gap diagnosed, generate a task:

- **Failure mode tasks**: triggered failure mode → task with specific fix
- **Sub-score gap tasks**: delivery < craft → "stop polishing, ship the value"
- **Strategy-vs-evidence tasks**: strategy says X but eval shows Y → investigate
- **Competitive response tasks**: competitor capability gap → evaluate build/differentiate/ignore
- **Coherence tasks**: code vs claims mismatch → align
- **Stage mismatch tasks**: inappropriate work for stage → refocus

Write tasks to `/todo`. Tag with `source: /strategy` and severity.

## Agent spawning

Spawn named agents, not generic:
- `Agent(subagent_type: "founder-os:explorer", ...)` — codebase analysis for honest/coherence
- `Agent(subagent_type: "founder-os:market-analyst", ...)` — landscape for market/compete/position
- `Agent(subagent_type: "founder-os:gtm", ...)` — pricing/GTM analysis
- Spawn both explorer + market-analyst in parallel when mode needs both

## State Reads
- `config/portfolio.yml`
- `~/.claude/knowledge/experiment-learnings.md`
- `~/.claude/knowledge/predictions.tsv`
- `.claude/cache/last-research.yml`
- `.claude/cache/eval-cache.json`
- `.claude/plans/strategy.yml`
- `config/product-spec.yml`

## State Writes
- `config/portfolio.yml` — stage updates, strategy notes
- `~/.claude/knowledge/predictions.tsv` — strategic predictions
- `.claude/plans/strategy.yml` — diagnosis output

## System integration

Triggers: `/plan` (act on diagnosis), `/research` (fill knowledge gaps), `/roadmap` (update narrative), `/money price` (pricing gaps)
Triggered by: `/plan` (needs strategic context), `/score` (score drop investigation), `/product` (positioning questions)

## Self-evaluation

/strategy succeeded if:
- Every recommendation is logged as a prediction in predictions.tsv
- strategy.yml was updated with the diagnosis
- At least one task was generated per strategic gap found
- The founder knows the ONE thing to work on next, not a menu

## Cost note

Spawns up to 3 agents depending on mode:
- `explorer` (sonnet) + `market-analyst` (opus) for market/compete/position modes — run in parallel
- `gtm` (opus) for price/gtm modes

## What you never do

- Be sycophantic — "promising", "great progress", "solid foundation" are BANNED
- Give generic advice — "focus on users" without naming the user = garbage
- List 5 options and ask founder to pick — give your #1 recommendation
- Skip the prediction on any recommendation
- Score all 7 bet dimensions above 5 — minimum 2 below 5

## If something breaks

- No market-context.json: read base model, run inline WebSearch, suggest `/strategy market`
- No strategy.yml: create from template with stage=one
- No eval-cache.json: say "I don't have enough signal. Run `/eval` first."
- context7 fails: fall back to WebSearch for docs
- Playwright fails: fall back to WebSearch for site analysis

$ARGUMENTS
