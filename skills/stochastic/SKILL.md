---
name: stochastic
description: "Stochastic multi-agent consensus. Spawns N agents with identical prompts to independently analyze a problem. Aggregates by consensus (mode), divergences (splits), and outliers (unique ideas)."
user-invocable: true
allowed-tools:
  - Read
  - Agent
  - Grep
  - Glob
  - Bash
effort: high
---

# /stochastic — Multi-Agent Consensus

Spawn N agents (default 10) with identical context and near-identical prompts. Each independently analyzes and produces a structured response. Aggregate by finding consensus (mode), divergences (splits), and outliers (unique ideas).

$ARGUMENTS — the problem, question, or decision to distribute across agents.

Optional: `n=X` — number of agents (default 10)

## Why this works

Exploits stochastic variation in LLM outputs. Like polling 10 experts instead of asking one. The mode filters out hallucinations and individual biases. Divergences reveal genuine judgment calls. Outliers surface creative ideas a single run would miss.

## How it works

1. Parse the problem into a clear question
2. Spawn N agents in parallel with identical prompts
3. Collect all responses
4. Aggregate: mode, splits, outliers

## Agent prompt template

```
Analyze this problem:
[QUESTION]

Give your conclusion with reasoning. Rate confidence (high/medium/low). Flag anything uncertain.

Under 300 words. Lead with conclusion.
```

## Aggregation

- **Consensus (mode)** — what most agents agree on
- **Divergences (splits)** — where agents disagree, revealing genuine judgment calls
- **Outliers** — unique ideas only 1-2 agents surfaced

## Output

Report directly:
- Agents polled: N
- Deduplicated ideas with frequency counts
- Total raw ideas
