# Configuration Reference

All configurable values, their defaults, and what they do. Read on demand when /configure needs to explain a setting.

## agents.cost

Controls which Claude model each agent uses.

| Value | Description |
|-------|-------------|
| `economy` | haiku/sonnet for everything. Cheapest. Good for exploration and low-stakes iteration. |
| `balanced` | **(default)** opus for hard work (builder, evaluator, market-analyst), sonnet for research (explorer, grader, debugger, refactorer), haiku for measurement (measurer, reviewer). |
| `premium` | opus/sonnet for everything. Most capable. Use when quality matters more than cost. |

### Agent model mapping

| Agent | economy | balanced | premium |
|-------|---------|----------|---------|
| builder | sonnet | opus | opus |
| evaluator | sonnet | opus | opus |
| market-analyst | sonnet | opus | opus |
| founder-coach | sonnet | opus | opus |
| copywriter | sonnet | opus | opus |
| gtm | sonnet | opus | opus |
| explorer | haiku | sonnet | opus |
| grader | haiku | sonnet | opus |
| debugger | haiku | sonnet | opus |
| refactorer | haiku | sonnet | opus |
| customer | haiku | sonnet | opus |
| consolidator | haiku | sonnet | opus |
| measurer | haiku | haiku | sonnet |
| reviewer | haiku | haiku | sonnet |

## agents.autonomy

Controls how much /go can do without asking.

| Value | Description |
|-------|-------------|
| `supervised` | **(default)** /go requires approval before each move. Safer. |
| `autonomous` | /go presents the plan but builds immediately. Still reports results. |
| `full-auto` | /go runs silently until plateau or completion. Summary at end. |

## output.verbosity

Controls how much detail skill output includes.

| Value | Description |
|-------|-------------|
| `quiet` | Headers + scores + bottom commands only. No section details. |
| `normal` | **(default)** Standard output templates as documented in each skill's reference.md. |
| `verbose` | Full details, all sections expanded, all evidence shown. |

## go.hard_gate

Whether /go must wait for approval before each build move.

| Value | Description |
|-------|-------------|
| `true` | **(default)** Must approve each move. Prevents runaway builds. |
| `false` | Presents the plan but builds immediately. Faster iteration. |

## go.plateau_threshold

How many consecutive flat-score moves before /go stops automatically.

| Value | Description |
|-------|-------------|
| `3` | **(default)** Three flat moves = current approach exhausted. |
| `1-2` | Stop early. Good for exploring — try something, see if it moves the score, pivot fast. |
| `4-10` | Keep going longer. Good for complex features where improvement is gradual. |

## File locations

| File | Purpose | Who writes |
|------|---------|-----------|
| `~/.claude/preferences.yml` | User preferences (all settings above) | /configure |
| `config/founder.yml` | Project config (stage, mode, features, value hypothesis) | /onboard, user |
| `.claude/plans/strategy.yml` | Strategic state (stage, bottleneck) | /strategy, /plan |

## Precedence

1. `~/.claude/preferences.yml` — user overrides (highest priority)
2. `config/founder.yml` — project-level settings
3. Hardcoded defaults — balanced/supervised/normal/true/3
