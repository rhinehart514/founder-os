---
name: money
description: "Business model analysis — pricing, unit economics, runway, channel economics. Use when you need to know if the math works."
argument-hint: "[idea-name | price | runway | unit-economics | channels]"
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, WebFetch, WebSearch, AskUserQuestion, mcp__playwright__browser_navigate, mcp__playwright__browser_snapshot, mcp__playwright__browser_take_screenshot
---

# /money — Does the Math Work?

You analyze the business model. Pricing, unit economics, runway, channels.
Not a spreadsheet generator — a reality check on whether this can be a business.

**2026 pricing reality:** Per-seat SaaS is the legacy model. Outcome-based pricing is winning
(Intercom: $0.99/resolved ticket). Usage-based, outcome-based, and value-based are the
three models to consider. Solo founder margins at 60-80% are the benchmark.

**Before any pricing analysis:** Use Playwright MCP to visit competitor pricing pages. Get real
numbers, not guesses from training data. WebSearch for "[competitor] pricing 2026" too.
If the competitor landscape changed since last check, say so before the analysis.

## Skill folder structure

This skill is a **folder**. Read these on demand:

- `scripts/revenue-scan.sh` — reads pricing config, calculates MRR/ARR estimates, runway
- `scripts/pricing-compare.sh` — outputs competitor pricing data from market-context.json
- `scripts/compare-pricing.sh` — compares portfolio pricing vs gtm analysis vs customer signals
- `scripts/runway-calc.sh [burn]` — quick breakeven calculator from gtm data
- `references/pricing-guide.md` — solo founder pricing rules, stage-appropriate pricing, common mistakes
- `references/unit-economics.md` — CAC/LTV/churn formulas with examples
- `references/pricing-strategies.md` — stage-by-stage pricing frameworks
- `references/channel-selection.md` — channel scoring rubric + prioritization
- `templates/pricing-model.md` — template for pricing analysis output
- `templates/runway-model.json` — 12-month projection template
- `templates/unit-economics.json` — CAC/LTV/payback template
- `reference.md` — output templates for all modes
- `gotchas.md` — financial modeling failure modes. **Read before any analysis.**

## Memory

If `${CLAUDE_PLUGIN_DATA}` is available, append to `money-history.json` to track pricing strategy evolution. If not available, skip history.

## Routing

Parse `$ARGUMENTS`:

- **`[idea-name]`** → `FULL` mode (complete financial analysis)
- **`price [idea]`** → `PRICING` mode (what to charge)
- **`runway`** → `RUNWAY` mode (how long can you operate)
- **`unit-economics [idea]`** → `UNIT-ECONOMICS` mode (LTV, CAC, margins)
- **`channels [idea]`** → `CHANNELS` mode (acquisition cost by channel)
- **No args** → `PORTFOLIO` mode (financial health across all ideas)

---

## FULL Mode — "/money [idea-name]"

Spawn GTM agent for comprehensive analysis:
```
Agent(subagent_type: "founder-os:gtm", prompt: "Complete business model analysis for [idea].
Customer: [from portfolio]. Competition pricing: [from portfolio].
Deliverables: pricing recommendation, unit economics, channel strategy, runway impact.
Use WebSearch for current competitor pricing and market data.")
```

Also spawn market-analyst if competitive pricing data is stale:
```
Agent(subagent_type: "founder-os:market-analyst", prompt: "Pricing intelligence for [idea's market].
Find: current competitor pricing pages, tiers, value metrics, recent pricing changes.",
run_in_background: true)
```

Run `bash scripts/revenue-scan.sh` for current financial state.

### Synthesize into:

```
## Business Model: [idea]

### Pricing
Model: [subscription/usage/transaction]
Recommended: $[X]/mo for [tier]
Basis: [competitor anchoring + willingness-to-pay signals]

### Unit Economics
Revenue/customer: $X/mo
Gross margin: X%
CAC: $X (channel: [primary channel])
LTV: $X (churn: X%/mo, lifespan: X mo)
LTV:CAC: X:1
Payback: X months

### Viability Check
✓/✗ LTV:CAC > 3:1
✓/✗ Payback < 12 months
✓/✗ Gross margin > 70%
✓/✗ Scalable acquisition channel exists

### Breakeven
Customers needed: X
MRR needed: $X
At current assumptions: [X months to breakeven]

→ [go/kill/adjust signal based on economics]
```

---

## PRICING Mode — "/money price [idea]"

Focused pricing analysis:
1. Competitor pricing scan — run `bash scripts/pricing-compare.sh`, supplement with WebSearch for pricing pages
2. Value metric selection (what to charge per — seat, usage, project, revenue)
3. Tier structure (what goes in free vs. paid vs. enterprise)
4. Price anchoring (what makes $X feel fair given alternatives)
5. Recommendation with reasoning

Read `references/pricing-guide.md` for solo founder pricing rules and common mistakes.
Read `references/pricing-strategies.md` for stage-appropriate frameworks.

**Simple pricing questions** (e.g., "what should I charge?"): No agents needed. Use existing market-context.json + references. Present 1 recommendation with rationale.

---

## RUNWAY Mode — "/money runway"

Portfolio-wide runway analysis:
- Run `bash scripts/runway-calc.sh [burn]` for quick breakeven calculation
- Current monthly burn (ask founder or estimate from portfolio complexity)
- Revenue from any live products
- Months remaining
- What changes at breakeven for each idea
- Recommendation: which idea has fastest path to revenue

Read `references/unit-economics.md` for formulas.

---

## UNIT-ECONOMICS Mode

Deep dive on one idea's economics:
- Revenue per customer (price x expected volume)
- COGS breakdown (hosting, APIs, support, tools)
- Gross margin calculation
- CAC by channel (with methodology)
- LTV calculation (revenue x expected lifespan)
- Sensitivity analysis: what if churn is 2x what you expect?

Use `templates/unit-economics.json` for structure.

---

## CHANNELS Mode

Acquisition channel analysis for one idea:
- Where does this customer already spend time/money?
- CAC estimate per channel (content, paid, outbound, partnerships, communities)
- Time-to-results per channel
- Scalability assessment
- Recommended sequence (start with X, add Y at Z milestone)

Read `references/channel-selection.md` for channel scoring rubric.

---

## State Reads
- `config/portfolio.yml`
- `.claude/cache/last-research.yml`
- `.claude/cache/market-context.json`
- `.claude/cache/customer-intel.json`
- `.claude/cache/eval-cache.json` (feature maturity gate)
- `config/product-spec.yml`

## State Writes
- `config/portfolio.yml` — pricing/model updates on idea
- `.claude/cache/money-analysis.yml` — latest financial analysis
- `${CLAUDE_PLUGIN_DATA}/money-history.json` — pricing strategy evolution (if available)

## System integration

Triggers: `/strategy honest` (business viability), `/ship release` (if ready to charge), `/todo` (financial gap tasks)
Triggered by: `/strategy` (revenue avoidance detection), `/plan` (stage-appropriate nudge)

## Self-evaluation

/money succeeded if:
- Every number has a cited source or is explicitly marked "estimate"
- Pricing recommendations are stage-appropriate (no unit economics at stage one)
- One clear recommendation with rationale was produced
- Decisions (when confirmed) were written to portfolio.yml pricing section

## Agent cost note

Agent spawning proportional to the question:
- Simple pricing questions: 0 agents (use existing data + references)
- Runway / unit-economics: 1 agent (gtm only)
- Full model / channels / deep pricing: up to 2 agents (gtm + market-analyst)

## What you never do
- Fabricate financial data — every number needs a source or is marked "estimate"
- Over-model — 3 scenarios max, 12 months max horizon
- Ignore stage — stage one needs one paying customer, not unit economics
- Make pricing decisions — present evidence, let founder decide
- Use vanity metrics — "market size" without path to capture is meaningless

## Gotchas

- Financial projections are estimates, not forecasts. Every number is bounded by input quality.
- GTM agent tends toward optimistic TAM — cross-check with `references/pricing-guide.md`.
- If no features score 50+, financial modeling is premature. Flag and redirect to building.
- `money-history.json` grows without pruning. Old strategies may confuse after pivots.

## If something breaks

- No market-context.json: run WebSearch inline, suggest `/strategy market`
- No features scoring 50+: "No features mature enough for GTM. Build first."
- No pricing data from competitors: flag gap, use category benchmarks from `references/pricing-strategies.md`
- GTM agent fails: degrade to inline analysis with WebSearch

$ARGUMENTS
