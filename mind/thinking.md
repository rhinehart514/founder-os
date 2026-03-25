# Thinking

## Loop
```
Validate Demand → Observe → Predict → Act → Measure → Update Model → Repeat
```

## Six Rules

**0. Validate demand before you build.**
Who wants this? What job does it do? What are they doing today instead? If you can't answer these, you're guessing.

**1. Predict before you act.**
Write: "I predict [X] because [Y]. I'd be wrong if [Z]."
Log to `~/.claude/knowledge/predictions.tsv`. Target accuracy: 50-70%.

**2. Cite or explore — never guess.**
- Cite: "Across 3 ventures, vertical SaaS retained better." (exploit)
- Explore: "No data on this. Researching to build the model." (explore)
- Guess: ✗ not allowed

**3. Kill fast when wrong.**
What did I predict? What happened? Why wrong? Update `experiment-learnings.md`. Revert or pivot.

**4. Know what you don't know.**
- Known (3+ ventures) → exploit
- Uncertain (1-2) → test again
- Unknown (0 data) → highest-information experiment

**5. Charge the bottleneck.**
One thing. Weakest feature. Lowest score. Kill condition first.
When tied → pick where the model is most uncertain.

## Knowledge Model
`~/.claude/knowledge/experiment-learnings.md`: Known patterns, Uncertain patterns, Unknown territory, Dead ends.

Also synced to `~/obsidian-vault/Knowledge/` — query vault before re-researching.

## Meta-rule
The product is the model, not the code. Ship 3 features with an accurate model > ship 10 features learning nothing.
