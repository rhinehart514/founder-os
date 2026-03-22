# Improvement Brief Template

For feature improvement mode. Not abstract ideas — specific product prescriptions. Every field is required.

```
▸ **[Improvement Name]** — [element being changed]

  see: [What exists right now. Name the element, its current state, what the user experiences.]

  problem: [Why this is a problem. Cite the score, the taste dimension, the flow issue,
  the dead end, the user confusion. Be specific — "empty state shows nothing" not
  "UX could be better."]

  rx: [The prescription. Name the specific change. 2+ options when possible.]
      Option 1: [approach] — [tradeoff] → [dimension] +[N]pts
      Option 2: [approach] — [tradeoff] → [dimension] +[N]pts

  reference: [What best-in-class products do for this. Name the product and the specific
  pattern. "Linear shows a project overview with status bars and recent activity.
  Notion shows a gallery of templates." Not "other products do it better."]

  impact: [Which sub-score moves? delivery or craft? By how much? Which assertion
  passes or gets created?]

  cost: [Rough implementation effort. "2 hours — new component + route" or
  "1 session — requires refactoring the data layer."]

  builds on: [Existing backlog items, past prescriptions, or partial work this connects to.
  "Extends todo [XX-03] which already identified this gap" or "Implements taste rx
  from 2026-03-15 eval."]
```

## Quality checks
- If `see` is empty → you haven't looked at the feature
- If `problem` doesn't cite a score or evidence → you're guessing
- If `rx` says "improve" or "better" without specifics → too vague
- If `reference` is empty → check competitor products first
- If `impact` has no number → not measurable
- If `builds on` is empty → check backlog and past evals first

## vs idea-brief.md

Idea briefs are for NEW things to build. Improvement briefs are for making EXISTING things better.

| Field | Idea brief | Improvement brief |
|-------|-----------|-------------------|
| evidence | Why build this | see + problem (what exists, why it's wrong) |
| what | Behavioral change | rx (specific change with options) |
| who | Named person | (implicit — user of this feature) |
| changes | Metric movement | impact (sub-score + assertion) |
| costs | What gets deprioritized | cost (implementation effort) |
| kills it | Cheapest disproof | (N/A — improvement, not hypothesis) |
| — | — | reference (best-in-class comparison) |
| — | — | builds on (existing work this extends) |
