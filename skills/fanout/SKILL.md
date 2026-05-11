---
name: fanout
description: "Fan-out/fan-in research. Spawns N researchers (Sonnet) in parallel to explore a question from different angles, then synthesizes findings with Opus."
user-invocable: true
allowed-tools:
  - Read
  - Agent
  - Grep
  - Glob
  - Bash
  - WebSearch
  - WebFetch
effort: high
---

# /fanout — Fan-Out/Fan-In Research

Spawn N researcher agents (default 5) in parallel using Sonnet. Each explores the research question independently. An Opus synthesizer then merges all findings into a coherent answer.

$ARGUMENTS — the research question or topic.

Optional:
- `n=X` — number of researchers (default 5)
- `model=haiku` — use Haiku instead of Sonnet for researchers

## Why this works

Parallel research catches angles a single agent misses. Each researcher has its own context window to dig deep. The Opus synthesizer sees all findings and produces higher-quality synthesis than any individual researcher.

## How it works

1. Parse the research question
2. Spawn N researcher agents (Sonnet) in parallel
3. Each researcher independently explores, searches, reads
4. Collect all research outputs
5. Opus synthesizer merges findings into final answer

## Researcher prompt

```
Research this question thoroughly:
[QUESTION]

You are one of [N] parallel researchers. Explore your own angle — don't assume others will cover what you skip.

Use available tools: WebSearch, WebFetch, Read, Grep, Glob.

Report findings in under 500 words. Lead with key insights. Cite sources.
```

## Synthesizer prompt

```
Here are findings from [N] independent researchers on:
[QUESTION]

[ALL FINDINGS]

Synthesize into a comprehensive answer:
- What the researchers agree on
- Conflicting findings (if any)
- Key insights and evidence
- Your final synthesis

Be thorough but direct.
```

## Execution

```
// Parse n from args, default 5
n = parse_arg("n") || 5
researcher_model = parse_arg("model") == "haiku" ? "haiku" : "sonnet"

// Fan out: spawn N researchers in parallel
researchers = []
for i in 1..n:
  researchers.push(Agent({
    subagent_type: "researcher",
    model: researcher_model,
    prompt: RESEARCHER_PROMPT.replace("[QUESTION]", question).replace("[N]", n),
    description: "Researcher " + i
  }))

// Collect all findings
findings = await_all(researchers)

// Fan in: Opus synthesizes
synthesis = Agent({
  subagent_type: "researcher",
  model: "opus",
  prompt: SYNTHESIZER_PROMPT.replace("[QUESTION]", question).replace("[N]", n).replace("[ALL FINDINGS]", format_findings(findings)),
  description: "Opus Synthesizer"
})
```

## Output

Report directly:
- Researchers: N (model used)
- Individual researcher summaries (1-2 lines each)
- Opus synthesis
