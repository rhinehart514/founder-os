# /demand Reference — Output Templates

Loaded on demand. Routing and modes are in SKILL.md.

---

## New idea / business case

```
◆ demand — "I want to build a CLI tool that measures product quality for solo founders"

▾ what I heard
  [1-2 sentences restating the idea in customer language]

▾ market reality (WebSearch, 90 seconds)
  · exists: [what already does this — label as parity]
  · adjacent: [related products targeting different slice]
  · failed: [attempts that died and why]
  · complaints: [pain signals from forums, reviews]

  verdict: [validated gap / saturated / unclear]
  differentiator: [what's actually different]

▾ the person
  "[Specific person description — role + situation, not a segment]"
  Is this specific enough? [Yes, continue] / [Let me refine]

▾ jobs (Ulwick format)
  functional: "When [situation], I want to [verb], so I can [outcome]"
  emotional: "When [situation], I want to [verb], so I can [outcome]"
  social: "When [situation], I want to [verb], so I can [outcome]"

▾ four forces
  push: [what pushes away from current solution] — strength: [0-10]
  pull: [what pulls toward this product] — strength: [0-10]
  anxiety: [what slows the switch] — strength: [0-10]
  habit: [what keeps them where they are] — strength: [0-10]
  net switching energy: [push + pull - anxiety - habit]

▾ assumptions (ranked by risk × ignorance)
  1. **[assumption]** — risk:N × ign:N = **score**
     evidence: [what we know]
     test: [how to validate]

▾ value hypothesis (draft)
  hypothesis: "[one sentence]"
  user: "[specific person]"
  signals: [what would prove this works]

⎯⎯ verdict ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  [Opinionated paragraph. Name the biggest risk. Cite evidence.]

→ next: [ONE action]
```

## Product pressure test (existing product)

```
◆ demand — [project name]

  product: **N%** · score: N · stage: **[stage]**
  thesis: "[current thesis]"

⎯⎯ who ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  entry: [how they find it]
  friction: [scored stages]
  drop-off: **[where most users leave]**

⎯⎯ assumptions ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  ⚠ [high-risk assumptions with evidence]
  · [lower-risk assumptions]

⎯⎯ coherence ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  ✓ [aligned pairs]
  ⚠ [disconnects with evidence]

⎯⎯ verdict ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  [Opinionated paragraph. Evidence-backed.]

[3 next commands]
```

## Strategic diagnosis

```
◆ demand honest

  stage: **[stage]** — "[thesis]"

  ▾ the honest take
    [3-5 sentences, no hedging. At least one "you're avoiding..."]

  ▾ failure mode: **[named pattern]**
    [Evidence from state files]

  ▾ leverage analysis
    #1 move: **[specific action]**
      impact: [what it proves/disproves]
      confidence: [high/medium/low]
      effort: [time estimate]

  ▾ what to stop
    · [at least one thing]

  opinion: **[one bold sentence]**

[2-3 next commands]
```

## Research findings

```
◆ demand research — [topic]

  **Prediction**: I predicted [X] because [Y].

  ▾ findings
    · [finding] — source: [url/source], strength: [strong/moderate/weak], evidence: [observed/stated/market/inferred]

  ▾ surprises
    · [things that challenge assumptions]

  ▾ gaps (still unknown)
    · [gap] — research method: [how to find out]

  ▾ model update
    · [what this changes about our understanding]

  verdict: [✓/✗/—] [explanation]

→ next: [one action]
```

## Multi-source protocol

### Source selection
- **docs** (context7): libraries, frameworks, APIs. Real-time accurate.
- **web** (WebSearch + WebFetch): blog posts, discussions, industry knowledge.
- **site** (Playwright): visual/structural analysis of live products.
- **codebase** (Grep/Glob/Read): internal patterns, existing implementations.
- **knowledge** (experiment-learnings.md): avoid re-researching known patterns.

### Cross-referencing
Findings from one source feed queries to another. Web reveals pattern -> check codebase -> pull docs.

### Research artifact
Write `demand-cache.json` with findings, suggested tasks, model updates.

## Formatting rules

- Header: `◆ demand [mode] — [topic]`
- Evidence labels on every claim: [observed], [stated], [market], [inferred]
- Assumptions ranked by risk x ignorance, highest first
- Coherence: ✓ aligned / ⚠ disconnect
- Anti-sycophancy: no "promising", "great progress", "solid foundation"
- Every claim cites evidence
- Bottom: 1-3 next commands, highest-leverage first
- Opinion is mandatory — never end with a menu

## Anti-sycophancy checklist

Before outputting, verify:
- [ ] At least one uncomfortable truth backed by a specific number
- [ ] Named failure mode with evidence (if applicable)
- [ ] ONE highest-leverage recommendation (not a menu)
- [ ] No banned phrases
- [ ] Every claim cites evidence from state files or research
