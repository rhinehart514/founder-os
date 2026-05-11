---
name: model-chat
description: "Spawn Claude instances into a shared conversation room where they debate, disagree, and converge. Round-robin turns with parallel execution within each round."
user-invocable: true
allowed-tools:
  - Read
  - Agent
  - Grep
  - Glob
  - Bash
effort: default
---

# /model-chat — Multi-Model Debate

Spawn 5 Claude Sonnet instances into a shared conversation room. They debate a problem across 5 rounds using round-robin turns (all agents respond in parallel each round, see full history). A synthesizer agent then merges the debate into a final answer.

$ARGUMENTS — the topic or problem to debate.

Optional:
- `agents=X` — number of agents (default 5)
- `rounds=X` — number of debate rounds (default 5)

## Why this works

Same model, slight framing variations = systematically different failure modes. Surfacing disagreements between instances is more valuable than any single instance's confident answers. Consensus across independent runs filters hallucinations, divergences reveal judgment calls.

## How it works

1. Parse the topic into a clear debate question
2. Spawn N agents (Sonnet) in parallel for round 1
3. Each round: all agents see full history, respond in parallel
4. After final round: synthesizer agent merges debate into answer

## Agent prompt (each round)

```
You are Agent [N] in a debate room.

Topic: [QUESTION]

Conversation so far:
[FULL HISTORY]

Respond with your position. Agree, disagree, or build on others. Be direct.

Under 150 words.
```

## Synthesizer prompt

```
Here is a debate between [N] agents across [R] rounds:

[FULL DEBATE]

Synthesize into a final answer. Note where they agreed, where they diverged, and your verdict.
```

## Output

Report directly:
- Agents: N
- Rounds: R
- Final synthesis from synthesizer
- Key agreements and disagreements
