# founder-os

An AI cofounder for serial entrepreneurs. A Claude Code plugin.

**Ideate → Validate → Decide → Build → Measure → Ship → Learn → Repeat**

Most tools do one phase. founder-os does all of them, and the learning compounds across ventures.

## What it does

**Before you build:** Generate ideas, research markets, check competitors (live — not from training data), force go/kill decisions with evidence. 14 failure patterns catch the rationalizations before you waste months.

**While you build:** Find the bottleneck feature, build it autonomously, measure whether the product improved. Score drops → revert. Score plateaus → rethink.

**After you build:** Grade predictions, audit whether features still matter, update the knowledge model. The learning compounds — kill an idea in one project, the pattern applies to every future idea.

**Proactively:** WebSearches markets before planning. Visits competitor sites with Playwright before strategy sessions. Checks if the world changed while you were building. A cofounder who only reacts is a bad cofounder.

## Install

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

Or install as a Claude Code plugin:
```bash
claude plugin add /path/to/founder-os
```

## Quick start

```
/founder           → dashboard (portfolio + project status)
/score             → is this product good? one number
/plan              → what should I work on? finds the bottleneck
/go                → just build it (autonomous loop)
```

New idea?
```
/discover "AI front office for local businesses"
/research market "local business SaaS"
/decide ai-front-office
```

## Skills (27)

### Ideate
| Skill | What it does |
|-------|-------------|
| `/discover` | Raw idea → validated business case |
| `/ideate` | Evidence-weighted brainstorming, kill lists, 11+ techniques |
| `/portfolio` | Cross-venture dashboard — ideas, stages, patterns |

### Validate
| Skill | What it does |
|-------|-------------|
| `/research` | Market intelligence, competitor teardowns, live site analysis |
| `/strategy` | Honest diagnosis — visits competitor sites, checks real pricing |
| `/product` | Pressure-test: is anyone going to want this? |
| `/money` | Pricing, unit economics, runway — does the math work? |
| `/decide` | Go/kill/pivot gate with explicit evidence |

### Build
| Skill | What it does |
|-------|-------------|
| `/build` | Scaffold from validated idea → working project |
| `/onboard` | Bootstrap any repo — detects features, generates config |
| `/plan` | Checks the market, finds the bottleneck, proposes work |
| `/go` | Autonomous build loop — code, measure, learn, repeat |
| `/push` | Push a feature toward a target score |
| `/feature` | Define, detect, track features |
| `/todo` | Living backlog |

### Measure
| Skill | What it does |
|-------|-------------|
| `/score` | One honest number — health + features + design + market |
| `/eval` | Per-feature scoring: does each feature deliver? |
| `/taste` | Visual product intelligence — 11 design dimensions |
| `/assert` | Manage what must be true about this product |

### Ship
| Skill | What it does |
|-------|-------------|
| `/ship` | Deploy measured work |
| `/roadmap` | Version theses and evidence tracking |
| `/copy` | Product copy — landing, pitch, onboarding |

### Learn
| Skill | What it does |
|-------|-------------|
| `/retro` | Grade predictions, audit feature purpose, update knowledge |
| `/retro audit` | Does each feature still matter? Has the market shifted? |

## Agents (14)

builder, evaluator, measurer, reviewer, explorer, market-analyst, customer, grader, debugger, refactorer, consolidator, founder-coach, gtm, copywriter

## What makes it different

1. **Portfolio is global.** `~/.founder-os/portfolio.yml` follows you across projects. Learnings compound.
2. **Proactive, not reactive.** WebSearches markets, visits competitor sites, surfaces changes before you ask.
3. **14 failure patterns** auto-checked every session. Building for nobody? Revenue avoidance? Portfolio sprawl? Named and caught.
4. **Grounded in 2026.** Outcome-based pricing, MCP as infrastructure, open source at parity, solo founders as the norm. Not 2024 playbooks.
5. **Features first.** Everything talks about what features deliver to customers, not about internal architecture.
6. **Kill speed.** The serial entrepreneur's edge is how fast you kill bad ideas. Speed of kill > depth of analysis.

## Requirements

- [Claude Code](https://claude.ai/code) (CLI)
- [jq](https://jqlang.github.io/jq/) (for scoring and data processing)
- Node.js (optional, for `/taste` visual eval)

## License

MIT
