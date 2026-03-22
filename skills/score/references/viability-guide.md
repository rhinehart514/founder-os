# Viability Scoring Guide

Viability is the only tier that uses agents to gather evidence. Code reading tells you nothing about market fit.

## The problem with code-based viability

Previous approach: LLM reads code, guesses "would this survive the market?" This produced scores of 85-92 for founder-os evaluating itself — obvious self-assessment bias. Code quality and market viability are unrelated dimensions.

## Agent-backed viability

### Step 1: Read existing intelligence

Before spawning agents, check what already exists:

1. `.claude/cache/market-context.json` — competitor landscape, table stakes, differentiation
2. `.claude/cache/customer-intel.json` — demand signals, unmet needs, churn signals
3. `.claude/plans/strategy.yml` — stage, bottleneck, competitive position
4. `config/product-spec.yml` — competitors, why_now, not_building

If all four exist and are <72h old, score from cached data. No agent spawn needed.

### Step 2: Spawn agents (when data is stale or missing)

**market-analyst agent:**
- Task: "Analyze competitive landscape for [product/feature]. Identify direct competitors, adjacent solutions, table stakes vs differentiated features. Write to .claude/cache/market-context.json"
- Background: yes
- Timeout: 5 minutes

**customer agent:**
- Task: "Gather customer signal for [product/feature]. Search GitHub issues, Reddit, HN, forums for demand signals. Write to .claude/cache/customer-intel.json"
- Background: yes
- Timeout: 5 minutes

Run both in parallel. Wait for results.

### Step 3: Score with evidence

For each feature, score four components (25 points each):

**UVP Clarity (0-25)**
- 20-25: One-sentence UVP that a stranger would understand. product-spec.yml has clear competitors + why_now.
- 10-19: UVP exists but is vague or broad. "Better than X" without specifics.
- 0-9: No UVP articulated. Building without knowing why it's different.

**Competitive Gap (0-25)**
- 20-25: market-context.json names a specific capability NO competitor has. Evidence cited.
- 10-19: Differentiated approach but competitors are close. Gap is narrow.
- 0-9: No competitive analysis done, or analysis shows no meaningful gap.

**Demand Signal (0-25)**
- 20-25: customer-intel.json shows unprompted demand — feature requests, workarounds, people building their own solutions.
- 10-19: Some signal but weak — few sources, indirect evidence.
- 0-9: No demand signal found. Building on assumption.

**Positioning (0-25)**
- 20-25: strategy.yml shows clear stage-appropriate position. Knows what stage it's at and what matters.
- 10-19: Strategy exists but is stale or misaligned with stage.
- 0-9: No strategy. Building without strategic context.

### Step 4: Write viability cache

Write to `.claude/cache/viability-cache.json`:

```json
{
  "assessed_at": "2026-03-18T...",
  "features": {
    "feature_name": {
      "viability_score": 62,
      "uvp_clarity": 20,
      "competitive_gap": 15,
      "demand_signal": 12,
      "positioning": 15,
      "evidence": {
        "uvp": "product-spec.yml: 'only tool measuring product quality inside Claude Code'",
        "competitors": "market-context.json: SonarQube measures code, not product. No direct competitor.",
        "demand": "customer-intel.json: 3 GitHub discussions asking for product-level eval in CC",
        "strategy": "strategy.yml: early stage, bottleneck is retention"
      },
      "confidence": "high"
    }
  }
}
```

## Hard rules

- Every viability claim cites a source file. No source = 0 points for that component.
- No market-context.json AND no customer-intel.json = total viability capped at 30.
- market-context.json exists but no customer-intel.json = capped at 60.
- Both exist = full range 0-100.
- Agent data older than 7 days = medium confidence. Older than 14 days = low confidence.

## When agents find nothing

Sometimes agents return empty or near-empty results. This is information:

- No competitors found = either the space is empty (good) or the search was too narrow (bad). Flag for manual review.
- No demand signal = either nobody wants this, or the product is too new for public signal. Note the stage.
- Empty results don't mean viability = 0. They mean viability_confidence = low and the score should be capped at 30 with a suggestion to run `/research` for deeper investigation.
