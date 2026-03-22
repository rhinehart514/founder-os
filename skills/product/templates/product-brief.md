# Product Brief Template

Output structure for /product assessments. Copy and fill.

## New Idea Mode

```
◆ product — "[idea description]"

▾ what I heard
  [1-3 sentences restating the idea in plain language]

▾ market reality
  · exists: [what exists today that's similar]
  · failed: [who tried and failed, and why]
  · adjacent: [what nearby thing is growing]
  · complaints: [real user complaints about this problem]
  verdict: [validated gap / crowded space / unclear demand]

▾ the person
  "[Specific human being and their situation. Not a category.]"

▾ assumptions (ranked by risk x ignorance)
  1. **[assumption]** — risk:N x ign:N = **score**
     evidence: [what supports or contradicts]
     test: [cheapest way to verify]

▾ value hypothesis (draft)
  hypothesis: "[testable one-sentence claim]"
  user: "[the specific person]"
  signals:
    - [observable signal with target]

⎯⎯ verdict ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  "[One honest paragraph. Is this worth building? Top risk?
   What to test first? Anti-sycophantic.]"

/onboard           bootstrap the repo
/research [topic]  validate top assumption
/ideate            brainstorm specific features
```

## Existing Product Mode

```
◆ product — [project name]

  product: **N%** · score: N · stage: **[stage]**
  thesis: "[current thesis]"

⎯⎯ [lens name] ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  [lens findings with evidence]

⎯⎯ verdict ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
  product clarity: **N/10**
  stage: [one/some/many/growth]
  biggest risk: [top assumption with evidence level]
  biggest disconnect: [where claims ≠ reality]
  drop-off point: [where users leave]

  "[Opinionated paragraph. What a cofounder would say.
   Names the one thing that matters most right now.
   Every claim cites evidence. No sycophancy.]"

/[next1]   [why]
/[next2]   [why]
/[next3]   [why]
```

## Formatting Rules

- Header: `◆ product — [project name or idea]`
- Lens dividers: `⎯⎯ [name] ⎯⎯⎯⎯⎯⎯` (em dashes)
- Assumptions: ranked by risk x ignorance, highest first
- Coherence: `OK` or `DISCONNECT` for each pair
- Verdict: product clarity score, stage, risk, disconnect, drop-off, paragraph
- Banned words: "promising," "solid foundation," "good progress," "interesting"
- Every claim in verdict must cite evidence
- Bottom: exactly 3 next commands with reasons
