# YC Readiness Check

Read on demand when founder asks about fundraising readiness or YC specifically. Maps YC evaluation criteria to founder-os metrics.

## What YC Looks For (mapped to founder-os)

### 1. Do people want this?
- **founder signal**: eval score on core features (delivery dimension)
- **evidence**: customer-intel.json demand signals, assertion pass rate
- **red flag**: high health score + zero external users = "nobody has confirmed they want this"
- **minimum**: at least 1 person (not you) has used it and come back

### 2. Can you build it?
- **founder signal**: health score, feature count, score delta over time
- **evidence**: git velocity, features moving from "building" to "working"
- **red flag**: 20+ commits/day with no score improvement = building in circles

### 3. Is the team exceptional?
- **founder signal**: prediction accuracy (are you learning?), wrong prediction → model update rate
- **evidence**: experiment-learnings.md density and recency
- **red flag**: no predictions logged = building without learning

### 4. Is the market big enough?
- **founder signal**: market-context.json, strategy.yml market section
- **evidence**: /research market output, competitor landscape
- **red flag**: no market research at all = building in a vacuum

### 5. What's your unfair advantage?
- **founder signal**: positioning.yml differentiator
- **evidence**: what do you do that competitors can't easily copy?
- **red flag**: "we use AI" is not an advantage in 2026

### 6. How do you make money?
- **founder signal**: founder.yml pricing section
- **evidence**: /money output, revenue experiments
- **red flag**: 3+ working features and no pricing = revenue avoidance

## The 10-Second Pitch Test

YC partners hear hundreds of pitches. Yours needs to work in 10 seconds:

```
[Product] helps [specific person] [do specific thing]
that currently [requires painful alternative].
```

Test: does your README's first line pass this? Does `/product pitch` output pass this?

## Readiness Checklist

Score each 0-2 (0=missing, 1=exists but weak, 2=strong):

- [ ] Named user who wants this (not a category)
- [ ] At least 1 external user (not you)
- [ ] Core feature delivery score > 60
- [ ] Can explain what you do in one sentence
- [ ] Know your top competitor and why you're different
- [ ] Have a pricing hypothesis (even if untested)
- [ ] Learning loop running (predictions being graded)
- [ ] Market size estimate with evidence

**0-6**: Not ready. Focus on product, not fundraising.
**7-11**: Getting there. Specific gaps to close.
**12-16**: Ready to apply. Evidence supports the story.
