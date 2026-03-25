# YC Readiness Check

Read on demand when founder asks about fundraising readiness or YC specifically. Maps YC evaluation criteria to founder-os metrics. Updated for W26/S26 cycle.

## What YC Looks For (mapped to founder-os)

### 1. Do people want this?
- **founder signal**: eval score on core features (delivery dimension)
- **evidence**: customer-intel.json demand signals, assertion pass rate
- **red flag**: high health score + zero external users = "nobody has confirmed they want this"
- **minimum**: at least 1 person (not you) has used it and come back
- **2026 bar**: YC W26 companies like Cardinal had 40+ paying customers BEFORE batch started. Corvera hit $33K MRR in 4 weeks. The bar for "do people want this" is now production revenue, not user signups.

### 2. Can you build it?
- **founder signal**: health score, feature count, score delta over time
- **evidence**: git velocity, features moving from "building" to "working"
- **red flag**: 20+ commits/day with no score improvement = building in circles
- **2026 context**: "Can you build it?" is less differentiating when code is free (95% of devs use AI weekly). The question is shifting to "can you build the RIGHT thing?" — which is about judgment, not velocity.

### 3. Is the team exceptional?
- **founder signal**: prediction accuracy (are you learning?), wrong prediction → model update rate
- **evidence**: experiment-learnings.md density and recency
- **red flag**: no predictions logged = building without learning
- **2026 context**: Solo founders are normal now. YC funds them more often. "Exceptional" for a solo founder = speed of learning + context engineering skill + judgment about what matters. Not team size.

### 4. Is the market big enough?
- **founder signal**: market-context.json, strategy.yml market section
- **evidence**: /research market output, competitor landscape
- **red flag**: no market research at all = building in a vacuum
- **2026 watch**: K-shaped funding market. Hot thesis clusters (agents, physical AI, agent governance) are oversubscribed. Everything else competes for scraps. Know which cluster you're in.

### 5. What's your unfair advantage?
- **founder signal**: positioning.yml differentiator
- **evidence**: what do you do that competitors can't easily copy?
- **red flag**: "we use AI" is not an advantage in 2026. Neither is citing a specific model.
- **2026 moats that work**: proprietary data/context, workflow lock-in, network effects, "sell the work not the tool" service moat, context engineering expertise, production receipts competitors can't fake

### 6. How do you make money?
- **founder signal**: founder.yml pricing section
- **evidence**: /money output, revenue experiments
- **red flag**: 3+ working features and no pricing = revenue avoidance
- **2026 pricing**: outcome-based > usage-based > per-seat. Intercom charges $0.99/resolved ticket. "Software-like margins on delivered work" is the winning model for AI companies.

## YC W26 RFS — What They're Actively Seeking

These are the Request for Startups categories for 2026. If your idea fits one of these, say so explicitly.

1. **Cursor for Product Managers** — tools that help PMs make decisions, not just manage tasks
2. **AI-Native Hedge Funds** — inflection point similar to quant trading's emergence in the 1980s
3. **AI-Native Agencies** — deliver finished work with software margins, at 100x the price of SaaS
4. **Stablecoin Financial Services** — financial infrastructure for the stablecoin economy
5. **AI for Government** — workflow automation for government processes
6. **Modern Metal Mills** — reinventing manufacturing with AI/automation
7. **AI Guidance for Physical Work** — multimodal AI for field service, construction, repairs
8. **Large Spatial Models** — 3D/spatial intelligence as AI primitives
9. **Infra for Government Fraud Hunters** — tools for detecting fraud at scale
10. **Make LLMs Easy to Train** — post-training tooling for custom models

## The 10-Second Pitch Test

YC partners hear hundreds of pitches. Yours needs to work in 10 seconds:

```
[Product] does [specific finished work] for [specific person]
that currently [requires painful alternative].
```

**2026 update:** The pitch should frame the product as delivering work (autopilot), not providing assistance (copilot). "We evaluate your product" not "we help you evaluate your product."

Test: does your README's first line pass this? Does `/product pitch` output pass this?

## The Anti-Agent-Washing Test

In 2026, YC partners have heard "agentic" from every applicant. Stand out by:
1. **Showing receipts** — production metrics, paying customers, retention data
2. **Naming the displaced work** — what specific human work does this replace? How much did it cost before?
3. **Proving the margin** — "software-like margins" means >70% gross margin on delivered work. Can you show it?

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
- [ ] Revenue or clear path to revenue (2026: seed expects $300-500K ARR)
- [ ] Production receipts (metrics from real usage, not demos)

**0-6**: Not ready. Focus on product, not fundraising.
**7-13**: Getting there. Specific gaps to close.
**14-20**: Ready to apply. Evidence supports the story.
