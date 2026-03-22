# World — March 2026

What's true right now. Read this before giving strategic advice or planning work.
This isn't a think piece. These are facts with sources. Act on them.

## What Changed

**Code is free.** Claude Code (46% most-loved), Cursor, Copilot — 95% of developers use AI weekly,
75% for more than half their coding. A solo founder ships what a 5-person team shipped in 2023.
Solo-founded companies hit 36.3% of all new startups. Base44 was built solo in 6 months, sold for $80M.
Dario Amodei gives 70-80% odds the first billion-dollar single-employee company appears in 2026.

**The bottleneck moved upstream.** Everyone builds fast now. The edge is:
1. Knowing WHAT to build (validation > velocity)
2. Knowing WHETHER it still matters (audit > accumulate)
3. Learning faster than competitors (prediction accuracy > feature count)

**MCP is infrastructure.** 6,400+ registered servers. OpenAI, Anthropic, HuggingFace, Salesforce,
ServiceNow all in production. Not experimental — it's the integration standard. Build on it.

**Outcome-based pricing is winning.** Intercom charges $0.99/resolved ticket, not per seat.
The pattern: charge for outcomes, not access. Per-seat SaaS is the legacy model for AI-native tools.
Solo founder operating margins at 60-80% are the new benchmark.

**Open source closed the gap.** Llama 4, DeepSeek V3.2, Qwen — GPT-4-class at <$1/M tokens
(was $30/M in 2023). The moat of "we use the best model" erodes in 6-18 months. Model-agnostic
architecture is defensive, not over-engineering.

**Context engineering > prompt engineering.** Designing what information agents have access to
(and when) is the key solo-founder skill. This is literally what founder-os does — but say it that way.

## Tools You Must Actually Use

Don't describe capabilities. USE them every session.

| When | Do this | Tool |
|------|---------|------|
| Before any /plan | WebSearch "[market] news [competitor] launch" — has the world changed? | WebSearch |
| Before /strategy | Visit top 3 competitor sites. Screenshot. Compare pricing. | Playwright MCP |
| During /research | Pull real-time library docs instead of hallucinating | context7 MCP |
| During /retro | WebSearch "does [feature category] still matter" — audit purpose, not just predictions | WebSearch |
| After /ship | Check how the market received it. New competitors since you started? | WebSearch |
| For any /money | Check actual competitor pricing pages — don't guess from memory | Playwright MCP |
| Ongoing | Set up CronCreate to monitor competitor pricing/features weekly | CronCreate |
| Parallel research | Spawn explorer + market-analyst background agents while the founder builds | Agent (background) |

A cofounder who only reacts to what the founder asks is a bad cofounder.
A good one brings information the founder doesn't have yet.

## Externalities — Check These for Every Idea

**Platform risk.** Building on one AI provider's API? They ship products that eat their ecosystem.
The 25x price gap between cheapest and most expensive frontier model creates arbitrage risk — a competitor
on open-weight models can undercut you while matching quality.

**Regulation.** EU AI Act high-risk rules extended to December 2027, but GPAI rules apply to
foundation model providers NOW. Most dev tools don't qualify as high-risk. But if your product
handles user data + AI, check. HIPAA/SOC2 requirements for AI products are tightening.

**Distribution shifted.** Plugin ecosystems (Claude Code plugins, GPT store, MCP servers),
marketplaces, and AI-native directories are new channels. Is your product discoverable where
users already are? If not, you have a distribution problem the code can't fix.

**Agentic expectations.** The market expects agents that monitor, not just respond. "AI helps
you do things" → "AI does things and tells you what it did." If your product still requires
the user to initiate every action, you're behind 2026 expectations.

## Feature Audit Questions

Ask these during /retro audit mode. A feature that was valuable 3 weeks ago might be worthless now.

1. **Does this feature still solve a problem that exists?** Markets move. AI capabilities change weekly. What was hard last month might be a one-liner now.
2. **Is someone else doing this better/cheaper/free?** Open source moves fast. Check, don't assume.
3. **Does the pricing model still work?** If you're charging per-seat for something that should be outcome-based, you have a model problem.
4. **Has the platform you depend on changed?** API pricing, rate limits, terms of service, competing products from the same provider.
5. **Is the timing window still open?** "Why now" has an expiration date. If the timing catalyst passed, the idea may have too.
