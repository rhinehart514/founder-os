# founder-os

Multi-agent primitives for Claude Code.

Claude Code gives you one answer. `founder-os` lets you ask multiple agents, compare consensus, surface disagreement, and synthesize the useful part.

```bash
claude plugin install rhinehart514/founder-os
```

Try this first:

```text
/founder-os:stochastic n=10 Should we use Postgres or SQLite for this project?
```

It polls 10 agents with the same prompt, then aggregates consensus, divergences, and outliers.

## What you get

Instead of one confident answer, `/stochastic` gives you a quick read on where independent Claude Code runs agree, where they split, and what unusual ideas only one or two runs noticed.

```text
Consensus
- Postgres is the safer default if the app needs concurrent users, hosted backups, or analytics.
- SQLite is better for a local-first prototype or single-user desktop workflow.

Divergences
- 6/10 agents preferred Postgres immediately.
- 3/10 agents preferred SQLite until there is real multi-user pressure.
- 1/10 suggested starting SQLite with a planned migration boundary.

Outliers
- Add a tiny repository layer now so the storage decision stays reversible.
- Use the first paying/team user as the migration trigger, not an abstract scale guess.
```

Use it for architecture calls, launch plans, debugging hypotheses, API design, research questions, or any moment where a single pass feels too smooth.

## The primitives

| Skill | What it does |
|-------|--------------|
| `/stochastic` | Poll N agents (default 10) with identical prompts. Aggregate by consensus, divergences, outliers. |
| `/model-chat` | Spawn 5 agents into a debate room. Round-robin turns, shared history, synthesizer merges. |
| `/fanout` | Fan-out N researchers (Sonnet) in parallel, fan-in with Opus synthesis. |
| `/skillbuilder` | Build flawless Claude Code skills. Studies existing skills as reference, ensures correct format, pushes for genuine intelligence. |
| `/autoresearch` | Autonomous hill-climb. Read code, generate mutations, measure, keep-or-revert, repeat. |

## Install

### Plugin install

```bash
claude plugin install rhinehart514/founder-os
```

Skills become `/founder-os:stochastic`, `/founder-os:model-chat`, `/founder-os:fanout`, `/founder-os:skillbuilder`, `/founder-os:autoresearch`.

### Marketplace install

```bash
claude plugin marketplace add rhinehart514/founder-os
claude plugin install founder-os@founder-os
```

### Direct install (short skill names)

```bash
npm i -g @rhinehart514/founder-os
```

Or from source:

```bash
git clone https://github.com/rhinehart514/founder-os.git
cd founder-os && bash bin/install.sh
```

Skills become `/stochastic`, `/model-chat`, `/fanout`, `/skillbuilder`, `/autoresearch`.

Restart Claude Code after installing.

## Usage

```
/stochastic Should we use Postgres or SQLite for this use case?
/stochastic n=5 What's the best approach to rate limiting here?

/model-chat Is this API design good?
/model-chat agents=3 rounds=3 Should we ship this feature?

/fanout What are the tradeoffs of server components vs client components?
/fanout n=3 model=haiku Research authentication patterns for this stack

/skillbuilder Create a skill for code review with verification gates
/skillbuilder audit /stochastic

/autoresearch Optimize the Lighthouse score
/autoresearch Shrink the bundle size
```

## Why this works

Same model, different runs = systematically different outputs. Polling multiple agents filters hallucinations (consensus), surfaces genuine judgment calls (divergences), and catches ideas a single pass misses (outliers).

## What's included

```
skills/
  stochastic/SKILL.md
  model-chat/SKILL.md
  fanout/SKILL.md
  skillbuilder/SKILL.md
  autoresearch/SKILL.md
  autoresearch/templates/   # hill-climb runner, dashboard, config
agents/
  parent.md      # orchestrator
  qa.md          # quality checker
  researcher.md  # research agent
```

## License

MIT
