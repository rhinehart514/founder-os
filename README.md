# founder-os

An AI cofounder that helps you figure out what to build — and kill what isn't working.

**Validate Demand → Ideate → Decide → Build → Measure → Ship → Learn → Repeat**

Most tools do one phase. founder-os does all of them, and the learning compounds across ventures.

## What it does

**Before you build:** Map customer jobs (functional, emotional, social). Test value props against real market evidence. Run four forces analysis — what pushes them away from the current solution, what pulls them toward yours, what anxiety slows the switch, what inertia keeps them where they are. Kill bad ideas fast with 14 failure patterns.

**When you commit:** Generate ideas with evidence weighting, research markets (live — not from training data), check competitors with Playwright, force go/kill decisions with cited evidence.

**While you build:** Find the bottleneck feature, build it autonomously in parallel waves, measure whether the product improved. Score drops → revert. Score plateaus → rethink.

**After you build:** Grade predictions, audit whether features still serve validated customer jobs, update the knowledge model. The learning compounds — kill an idea in one project, the pattern applies to every future idea.

**Proactively:** WebSearches markets before planning. Visits competitor sites before strategy sessions. Checks if the world changed while you were building.

## Install

**From the marketplace** (recommended):
```bash
# In Claude Code:
/plugin marketplace add rhinehart514/founder-os
/plugin install founder-os@founder-os-marketplace
```

**From GitHub directly:**
```bash
# CLI:
claude plugin install founder-os@founder-os-marketplace --scope user
```

**From source** (for development):
```bash
git clone https://github.com/rhinehart514/founder-os.git
cd founder-os
bash install.sh
```

Then in any project:
```bash
cd your-project
claude
# type /onboard to bootstrap
```

## Quick start

```
/discover "AI front office for local businesses"  → validate demand, map customer jobs
/blueprint                                         → JTBD analysis, value props, feature architecture
/decide ai-front-office                            → go/kill/pivot gate with evidence
```

Then build:
```
/plan              → what should I work on? finds the bottleneck
/go                → just build it (autonomous loop)
/score             → is this product good? one number
```

## Skills (7)

| Skill | Job | Key Modes |
|-------|-----|-----------|
| `/demand` | What's worth building? | new, refine, pivot, kill, jobs, forces, research, market, customer, compete, position, package |
| `/measure` | Is it good? | unified, quick, deep, feature, evidence, beliefs, flows, visual, cli, viability |
| `/build` | Build the right thing | plan, go, quick, push, --safe, --interactive |
| `/learn` | What did we learn? | grade, audit, consolidate, stale, calibrate, demand |
| `/ideate` | Generate options | topic, improve, wild, kill, deep, technique, package |
| `/ship` | Get it out | deploy, release, roadmap, copy, pitch, landing |
| `/founder` | Home base | dashboard, onboard, feature, decide, todo, assert, configure, money, flow, map |

## Agents (14)

builder, evaluator, measurer, reviewer, explorer, market-analyst, customer, grader, debugger, refactorer, consolidator, founder-coach, gtm, copywriter

## What makes it different

1. **Demand first.** Every feature traces back to a customer job. `/discover` and `/blueprint` map demand before `/go` writes code.
2. **Portfolio is global.** `~/.founder-os/portfolio.yml` follows you across projects. `/founder` shows the dashboard. Learnings compound.
3. **Proactive, not reactive.** WebSearches markets, visits competitor sites, surfaces changes before you ask.
4. **14 failure patterns** auto-checked every session. Building for nobody? Revenue avoidance? Portfolio sprawl? Named and caught.
5. **Grounded in 2026.** Outcome-based pricing, MCP as infrastructure, open source at parity, solo founders as the norm.
6. **Kill speed.** The serial entrepreneur's edge is how fast you kill bad ideas. Speed of kill > depth of analysis.

## Requirements

- [Claude Code](https://claude.ai/code) (CLI)
- [jq](https://jqlang.github.io/jq/) (for scoring and data processing)
- Node.js (optional, for `/taste` visual eval)

## License

MIT
