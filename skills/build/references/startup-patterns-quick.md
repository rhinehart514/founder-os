# Startup Failure Modes — Quick Reference

8 patterns, mechanically checked by `scripts/startup-check.sh`. This is the condensed version — for full interventions, see `mind/startup-patterns.md`.

## The patterns

| # | Pattern | What to check | Severity |
|---|---------|--------------|----------|
| 1 | **Building Without a Named Person** | founder.yml `user:` is empty or generic | Critical always |
| 2 | **Polishing Before Delivering** | Any feature where craft > delivery + 15 | Critical at stage one |
| 3 | **Feature Sprawl** | 3+ features scoring 30-60 simultaneously | Warning (critical if >5) |
| 4 | **Prediction Starvation** | <3 predictions in 7 days | Warning |
| 5 | **Strategy Avoidance** | strategy.yml missing or >14 days stale | Warning (critical at some+) |
| 6 | **Thesis Drift** | Roadmap evidence unchanged >14 days | Warning |
| 7 | **Revenue Avoidance** | No pricing + 3 features scoring 50+ | None at mvp, warning at some |
| 8 | **Burnout Signals** | >15 commits/day for 3+ consecutive days | Warning |

## Stage expectations

| Stage | Score range | Focus | OK to skip |
|-------|-----------|-------|------------|
| Pre-product | N/A | Validate demand assumption | Everything technical |
| Stage one (0 users) | 30-60 | First loop: discover -> value -> return | Craft, growth, pricing |
| Stage some (1-10) | 50-75 | Retention: do they come back? | Some feature gaps |
| Stage many (10-100) | 65-85 | Distribution: how do new users find this? | Minor UX issues |
| Growth (100+) | 75-95 | Unit economics: does the business work? | Edge cases |

## Common rationalizations

When you see the excuse, name it:

- "I need variety" -> avoiding the hard part of feature #1
- "I know my market" -> market moves, run /strategy
- "Predictions slow me down" -> avoiding accountability
- "First impressions matter" -> first impressions of WHAT?
- "Users want flexibility" -> you don't know what users want
- "Tech debt will slow us down" -> you have zero users, debt to whom?
