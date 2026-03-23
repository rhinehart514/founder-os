# World — March 2026

What's true right now. Read this before giving strategic advice or planning work.
This isn't a think piece. These are facts with sources. Act on them.

## What Changed

**Code is free.** Claude Code dominates small startups (75% usage vs 35% Copilot). 95% of devs
use AI weekly, 56% do 70%+ of work with AI. Solo-founded companies hit 36.3% of startups.
Base44 was built solo in 6 months, sold for $80M. Dario Amodei gives 70-80% odds the first
billion-dollar single-employee company appears in 2026.

**The bottleneck moved upstream.** Everyone builds fast now. The edge is:
1. Knowing WHAT to build (validation > velocity)
2. Knowing WHETHER it still matters (audit > accumulate)
3. Learning faster than competitors (prediction accuracy > feature count)

**Sell the work, not the tool.** Sequoia's defining frame: "If you sell the tool, you're in a
race against the model. If you sell the work, every improvement in the model makes your service
faster, cheaper, and harder to compete with." The next trillion-dollar company will be a software
company masquerading as a services firm. Copilots are 2023. Autopilots are 2026.

**MCP is infrastructure.** 1,000+ community servers. OpenAI adopted it in 2025, making it the
de facto standard for agent-tool interop. Not experimental — it's the integration standard.

**Outcome-based pricing is winning.** Intercom charges $0.99/resolved ticket, not per seat.
The pattern: charge for outcomes, not access. Per-seat SaaS is the legacy model for AI-native tools.
Solo founder operating margins at 60-80% are the new benchmark.

**Open source closed the gap.** Llama 4, DeepSeek V3.2, Qwen — GPT-4-class at <$1/M tokens
(was $30/M in 2023). The moat of "we use the best model" erodes in 6-18 months. Model-agnostic
architecture is defensive, not over-engineering.

**Context engineering > prompt engineering.** Designing what information agents have access to
(and when) is the key solo-founder skill. "Context engineering" is the emerging serious technical
discipline of 2026 — building the minimal but complete information layer agents need to function.
If 2024 was RAG, 2025 was agentic, 2026 is context engines.

**Agents are colleagues, not assistants.** Sequoia: "The AI applications of 2026 and 2027 will be
doers. They will feel like colleagues. Usage will go from a few times a day to all-day, every day,
with multiple instances running in parallel." Multi-agent system inquiries surged 1,445% from
Q1 2024 to Q2 2025. 144 non-human identities per human employee in average enterprise.

**40% of AI startups are dead.** 14,000+ AI startups launched in 2024. 40% dead within 24 months —
including companies that raised $2-50M. Jasper acquired for parts, Copy.ai merged. The survivors
have production receipts and paying customers, not demos and decks.

**The traction bar moved.** Seed investors now expect $300-500K ARR before writing a check.
AI startups captured 41% of $128B VC on Carta. But the market is K-shaped: hot thesis clusters
are oversubscribed, everything else competes for scraps.

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

## The 2024→2026 Language Shift

| Dead (2024) | Current (2026) |
|---|---|
| "We use AI to help you..." | "We do the work. You review the result." |
| AI co-pilot / assistant | Autopilot / colleague |
| 10x productivity claims | Revenue per employee, software margins |
| "AI-powered [SaaS category]" | Agent-native workflows |
| "Powered by GPT-4" | Outcome + production receipts |
| Demo → fundraise | $300-500K ARR → seed |
| "Disruptive" | Evidence of displaced work |
| "Agentic" (without receipts) | Agent washing — only ~130 of thousands are real |

**What's cringe now:** "AI-powered" anything (table stakes), citing specific models as differentiator
(models are commoditizing), "10x productivity" without unit economics, copilot framing for tasks
that are now fully automatable, "we use AI to..." as a lead.

**What's working:** "Sell the work, not the tool" (Sequoia), "bounded autonomy" (enterprise trust
signal), "context engineering" (technical credibility), "software-like margins" (business model signal),
naming the specific workflow replaced not the AI capability.

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

**Agent washing is everywhere.** Only ~130 of thousands of claimed "AI agent" vendors are
genuinely agentic. "2025 was the year every vendor slapped 'agentic' on their homepage. 2026
is the year customers expect receipts." If you claim agentic, show production evidence.

**Rescue engineering is emerging.** Thousands of vibe-coded products can't support real usage.
CodeScene research: AI coding assistants increase defect risk by 30%+ in projects with poor code
health. The opportunity: quality/verification tools for the aftermath of the vibe-coding wave.

## Feature Audit Questions

Ask these during /retro audit mode. A feature that was valuable 3 weeks ago might be worthless now.

1. **Does this feature still solve a problem that exists?** Markets move. AI capabilities change weekly. What was hard last month might be a one-liner now.
2. **Is someone else doing this better/cheaper/free?** Open source moves fast. Check, don't assume.
3. **Does the pricing model still work?** If you're charging per-seat for something that should be outcome-based, you have a model problem.
4. **Has the platform you depend on changed?** API pricing, rate limits, terms of service, competing products from the same provider.
5. **Is the timing window still open?** "Why now" has an expiration date. If the timing catalyst passed, the idea may have too.
