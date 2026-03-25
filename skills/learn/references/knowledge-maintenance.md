# Knowledge Model Maintenance

Rules for when to promote, prune, archive, and revive entries in experiment-learnings.md.

## The four zones

| Zone | Meaning | Entry criteria | Exit criteria |
|------|---------|---------------|---------------|
| Known Patterns | High confidence, exploit | 3+ experiments confirm | Contradicted by new evidence → Dead Ends |
| Uncertain Patterns | Medium confidence, test again | 1-2 experiments | 3rd confirmation → Known. Contradiction → Dead Ends. |
| Unknown Territory | Zero data, explore | New area identified | First experiment → Uncertain |
| Dead Ends | Confirmed failures | 2+ attempts failed | Conditions changed → Uncertain (zombie revival) |

## Promotion rules

### Uncertain → Known
- **Trigger:** 3+ experiments confirm the pattern
- **Evidence required:** cite the 3 prediction results by date
- **Write:** include boundary conditions (when does this pattern NOT hold?)
- **Example:** "Inline visualization > separate commands (3 experiments: 03-10 partial, 03-14 yes, 03-16 yes). Boundary: only for <20 data points; large datasets need dedicated views."

### Unknown → Uncertain
- **Trigger:** first experiment produces a result
- **Evidence required:** cite the prediction that explored this territory
- **Write:** include what was learned and what the next experiment should test
- **Example:** "Navigation patterns affect retention? First experiment (03-15): adding breadcrumbs reduced bounce by 8%. Needs: test on 2+ pages to confirm."

## Pruning rules

### Stale detection
- Known Pattern with no new evidence in 30+ days → move to `## Stale Patterns`
- Unknown Territory item with 0 experiments in 30+ days → flag as neglected
- Dead End with 0 citations in predictions.tsv in 60+ days → move to `## Archived Dead Ends`

### What "no new evidence" means
- No predictions referencing this pattern in the last 30 days
- No commits touching code related to this pattern
- No model updates citing this pattern

### Don't delete — move
Never delete entries. Move them:
1. Stale Known → `## Stale Patterns` (can be revived)
2. Archived Dead End → `## Archived Dead Ends` (can be revived)
3. Add a note: "Moved [date]: [reason]. Last evidence: [date]."

## Revival rules

### Zombie dead ends
A dead end that appears in recent predictions (last 14 days) is NOT dead.
- **Check:** does the dead end topic appear in prediction text?
- **Action:** move back to Uncertain with note "Revived [date]: conditions may have changed since [original dead date]."
- **Why this matters:** context shifts (new tools, different codebase, new stage) can make previously dead approaches viable.

### Stale pattern revival
A stale pattern that gets new evidence:
- **Action:** move back to Known (or Uncertain if the new evidence contradicts)
- **Update:** add the new evidence, reset the staleness clock

## Consolidation rules (for consolidator agent)

1. **Merge duplicates:** same mechanism described differently → combine, keep the one with more evidence
2. **Tighten boundaries:** if a Known Pattern has exceptions, add them as boundary conditions
3. **Cross-reference:** link patterns that affect each other (e.g., "see also: [related pattern]")
4. **Count check:** after consolidation, Known should have 5-15 entries, Uncertain 3-10, Unknown 3-8, Dead 2-5. If any section is >20, it needs aggressive consolidation.

## Staleness thresholds

| Zone | Threshold | Action |
|------|-----------|--------|
| Known | >30 days no evidence | → Stale Patterns |
| Uncertain | >21 days no experiment | Flag: "test or kill?" |
| Unknown | >30 days no first experiment | Flag: "neglected — highest info value" |
| Dead Ends | >60 days no citations | → Archived Dead Ends |
| Stale | >60 days after stale move | → Archived (truly abandoned) |

## Section health ratios

- Known:Unknown target = 1:1 to 3:1
  - >5:1 = exploiting too much, not exploring enough
  - <0.5:1 = not enough confirmed patterns, too much uncertainty
- Dead Ends should be 10-30% of Known count
  - If 0 dead ends: either not exploring enough or not admitting failures
  - If dead > known: model is pessimistic, check if conditions have changed
