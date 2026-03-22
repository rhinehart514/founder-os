# Version Lifecycle — Detailed Reference

## The Version Completion Cycle

Product completion % is **per-version**, not global. Each version defines what done looks like.

```
v8.0 starts → completion: 15%
  work happens, features mature, evidence collected
v8.0 proven → completion hit ~80%, /roadmap bump
  ─────────────────────────────────────────────
v9.0 starts → completion: 10% (new thesis, new requirements)
  new features planned, new evidence needed
  climb again
```

### Full mode (roadmap.yml + eval-cache)

1. **Evidence completion** (50% weight): proven evidence items / total evidence items
2. **Feature readiness** (30% weight): for features relevant to this version's thesis, compute weighted maturity average. Identify relevant features by checking which features' `delivers:` text relates to the thesis question, or by explicit `version:` tags.
3. **Todo clearance** (20% weight): todos tagged to this version done / total tagged

### Standalone mode (roadmap.yml only)

Version completion = proven evidence items / total evidence items. No eval-cache dependency.

### Bump behavior

When version completion crosses 80%, surface: "v[X] is nearing proven. `/roadmap bump` when ready."

When `/roadmap bump` confirms:
- Current version → `proven`
- Completion for next version recalculates (drops because new thesis)
- Todos not tagged to the new version carry forward
- Features retain their maturity (they don't reset — the product keeps growing)
- But the QUESTION changes, so what matters changes
- Proven thesis → Known Pattern in experiment-learnings.md
- Disproven evidence → Dead End in experiment-learnings.md

## Three-tier version lifecycle

| Tier | Example | When | Resets completion? | Evidence items |
|------|---------|------|--------------------|----------------|
| **Major** | v10.0 | New thesis. Big question. | Yes — fully | 3-5 items, weeks to prove |
| **Minor** | v9.4 | Significant improvement within thesis. | Partially | 2-3 items, days to weeks |
| **Patch** | v9.3.01 | Bug fix, polish, incremental. No new question. | No | 0-1 items, hours to days |

## How versions relate to other state

- **roadmap.yml** = theses being tested (months-level thinking)
- **strategy.yml** = current bottleneck (weeks-level thinking)
- **plan.yml** = current session tasks (hours-level thinking)
- **todos.yml** = backlog items, taggable to versions (cross-session)
- **experiment-learnings.md** = the causal model (permanent)
- **narrative.yml** = external story derived from proven theses
- **changelog.md** = user-facing version history
- **positioning.yml** = competitive positioning derived from evidence

Proven theses feed into experiment-learnings.md as Known Patterns. Disproven theses become Dead Ends.
