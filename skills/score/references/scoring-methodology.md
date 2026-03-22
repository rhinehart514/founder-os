# Scoring Methodology

## The Question Every Tier Must Answer

**Does the user get it?**

Every tier — health, delivery, craft, visual, behavioral, viability — exists to answer one question from a different angle: does the person using this product understand what it does, get value from it, and want to come back?

A product with perfect code that confuses users scores low. A product with rough code that delights users scores higher. The tiers measure different facets of user value delivery, not different aspects of code quality.

This applies universally — web UI, CLI output, API responses, documentation, notifications. Whatever surface the user touches IS the product.

## Tier Weights

Default weights (all tiers available):

| Tier | Weight | Source | What it measures |
|------|--------|--------|-----------------|
| Health | gate | `/score` (bin/score.sh) | Build passes, structure, hygiene. < 20 = score 0. |
| Delivery | 40% | `/eval` | Does the user get real value? (includes user understanding, not just code completeness) |
| Craft | 25% | `/eval` | Is the experience well-made? (code craft + product surface craft) |
| Visual | 15% | `/taste` | Does the product surface look/feel exceptional? (web: screenshots, CLI: output formatting, API: response design) |
| Behavioral | 10% | `/taste flows` | Does the product actually work end-to-end? |
| Viability | 10% | agents/intelligence | Would this survive the market? |

**Formula:** `delivery*0.40 + craft*0.25 + visual*0.15 + behavioral*0.10 + viability*0.10`

### Product-type adaptation

The tiers apply to every product type, but the evidence sources change:

| Product type | Visual source | Behavioral source | Delivery evidence |
|-------------|--------------|-------------------|-------------------|
| Web app | Playwright screenshots + taste dimensions | Playwright flow audit | UI communicates purpose, CTA obvious, value in <3 clicks |
| CLI tool | Command output formatting, voice.md compliance, scanability | Command sequences complete tasks | Output scannable in 2s, next action named, errors actionable |
| API/SDK | Response shape consistency, error format, docs | Integration test flows | Consumer understands response, errors guide fix, docs match reality |
| Library | API surface design, type signatures, examples | Test suite + usage examples | User can accomplish task from README alone |
| Docs site | Page layout, navigation, search | Reader can follow a tutorial end-to-end | Reader knows what to do after reading, not just what exists |

## Weight Redistribution

When tiers are unavailable, redistribute — but note that "unavailable" means different things for different product types:

**Web products without URL:** Visual and behavioral tiers skip — this is legitimate redistribution.
**CLI/API/library products:** Visual tier evaluates output/response design (not screenshots). Behavioral tier evaluates command/call sequences. These tiers are NEVER truly unavailable — the evidence source changes, not the question.

| Missing | Redistribution |
|---------|---------------|
| Visual only | delivery 45%, craft 30%, behavioral 10%, viability 15% |
| Behavioral only | delivery 45%, craft 25%, visual 15%, viability 15% |
| Visual + Behavioral | delivery 50%, craft 30%, viability 20% |
| Viability only | delivery 45%, craft 30%, visual 15%, behavioral 10% |

Always flag redistributed tiers in output. If visual+behavioral are skipped for a CLI product, flag this as a gap — those tiers should be evaluating output quality, not being skipped.

## Staleness Thresholds

| Tier | Fresh | Acceptable | Stale |
|------|-------|-----------|-------|
| Health | < 5min | < 30min | > 30min |
| Code eval | < 24h | < 48h | > 48h |
| Visual | < 48h | < 96h | > 96h |
| Behavioral | < 48h | < 96h | > 96h |
| Viability | < 72h | < 144h | > 144h |

Fresh = high confidence. Acceptable = medium confidence. Stale = low confidence.

## Confidence Computation

Per-tier confidence: high/medium/low based on staleness table above.
Product confidence: minimum across all available tiers.
Missing tier: always counts as low confidence.

## Behavioral Score Conversion

Flows reports produce issue lists, not scores. Convert:

```
behavioral_score = 100 - (blockers * 25) - (majors * 10) - (minors * 3)
```

Floor at 0. A single blocker drops behavioral to 75. Two blockers = 50.

## Viability Score Components

Four sub-dimensions, 25 points each:

| Component | What it measures | Evidence source |
|-----------|-----------------|----------------|
| UVP clarity | Can you state what's unique in one sentence? | product-spec.yml |
| Competitive gap | Something no competitor has? | market-context.json |
| Demand signal | People actually want this? | customer-intel.json |
| Positioning | Clear stage-appropriate position? | strategy.yml |

**Viability source hierarchy:**
1. **Agent-backed** (viability-cache.json): full range 0-100. Authoritative.
2. **Both intelligence files** (market-context.json + customer-intel.json): capped at 60.
3. **One intelligence file**: capped at 45.
4. **No data**: capped at 30.

Agents are the refresh mechanism, not the only path. `synthesize.sh` reads intelligence files directly. Only spawn agents when viability-cache.json is stale (>72h) AND intelligence files are missing or stale (>7d).

## Per-Feature vs Product Score

Each feature gets its own unified score across all tiers.
Product score = weighted average of feature scores (using `weight:` from founder.yml).

```
product_score = sum(feature_score * feature_weight) / sum(feature_weight)
```

Only active features are included.

## Score-to-Recommendation Pipeline

Eval produces recommendations gated by feature maturity. As scores rise, the question evolves:

| Maturity | Score range | Question | Recommendation type |
|----------|-----------|----------|-------------------|
| planned | 0-29 | What's broken? | Missing foundations — code paths, assertions, basic structure |
| building | 30-49 | What's rough? | Delivery gaps — incomplete flows, missing error handling, dead ends |
| working | 50-69 | What's missing? | Craft gaps — UX polish, edge cases, empty states, loading states |
| polished | 70-89 | What's next? | Micro-features — small additions that compound value |
| proven | 90+ | What could this become? | Micro-systems — new capabilities that emerge from the feature's foundation |

`/score` surfaces the highest-priority recommendation per feature alongside the score (from eval-cache.json `recommendations` field, if present). This creates a natural pipeline:

1. `/score` shows the number + top recommendation per feature
2. Founder runs `/eval` for detailed recommendations per dimension
3. At higher maturities, `/eval` suggests `/ideate [feature]` for deeper exploration

The pipeline flow: **score → eval → ideate → plan → go**. Each skill hands off to the next when the current tool's depth is exhausted.

## Stage Ceilings

From founder.yml integrity settings:

| Stage | Score ceiling | Justification required above |
|-------|--------------|----------------------------|
| mvp | 65 | Any score above needs external validation |
| early | 80 | Scores 75+ need named evidence |
| growth | 90 | Near-perfect needs user data |
| mature | 95 | Only external proof breaks 90 |
