# /founder decide — Go/Kill/Pivot Gate

Decision gate for ideas and features. Hierarchy-level-aware: different evidence thresholds at different altitudes.

## Protocol

1. **Identify the idea/feature** from `config/portfolio.yml` or `config/founder.yml`
2. **Determine hierarchy level** — read `skills/shared/hierarchy-lens.md`:
   - Is this an outcome-level decision? (metric should move)
   - Opportunity-level? (pain/need is real)
   - System-level? (architecture choice)
   - Feature-level? (build this thing)
3. **Apply level-appropriate evidence thresholds** (see below)
4. **Score on 3 axes**: market (demand), model (economics), moat (defensibility)
5. **Verdict**: go / kill / park / pivot — with reasoning

## Evidence thresholds by hierarchy level

| Level | Go threshold | Kill threshold | Evidence type needed |
|-------|-------------|----------------|---------------------|
| **Outcome** | Named metric + baseline measurement + theory of change | No plausible path from product to metric movement | [observed] or [stated] — market data insufficient |
| **Opportunity** | Named customer + active pain + willingness to switch | Pain is theoretical, no customer confirms it, or pain is already well-served | [stated] minimum — inferred alone won't do |
| **System** | Enables 2+ features, clean boundary definable, independent evolution possible | Only serves 1 feature, or boundary is unclear, or creates coupling | Architecture review + `skills/shared/system-thinking.md` |
| **Feature** | Serves a validated job, buildable in scope, measurable with assertions | No job served, or duplicate of existing feature, or unbuildable in timeframe | [observed] or [stated] + mechanical assertions |

## Decision framework

```
GO if:
  - Evidence threshold met for this level
  - Named customer who'd pay (or named metric that moves)
  - Unit economics work (or system enables economics)
  - Wedge buildable in weeks (or system boundary definable)

KILL if:
  - Kill condition confirmed
  - No customer after 2 weeks of looking
  - Economics fundamentally broken
  - Evidence threshold impossible to meet at this level

PARK if:
  - Thesis sound but timing wrong
  - Evidence partially there, needs more data
  - Dependency on another decision resolving first

PIVOT if:
  - Customer is real but problem differs from assumption
  - Problem is real but customer differs from assumption
  - System boundary is wrong but domain is right
```

## Output format

```
◆ decide — [idea/feature name]

  level: [outcome | opportunity | system | feature]
  evidence threshold: [what's required at this level]
  evidence present: [what actually exists, by class]

  market:  [1-10] — [reasoning]
  model:   [1-10] — [reasoning]
  moat:    [1-10] — [reasoning]

  verdict: [GO | KILL | PARK | PIVOT]
  reason: [2-3 sentences]
  next: [one specific action]
```

## State

**Reads**: `config/portfolio.yml`, `config/founder.yml`, `.claude/cache/demand-cache.json`, `.claude/cache/eval-cache.json`, `~/.claude/knowledge/experiment-learnings.md`
**Writes**: `config/portfolio.yml` (stage update), `~/.claude/knowledge/experiment-learnings.md` (kill → Dead Ends)

## Self-evaluation

- Hierarchy level identified and named
- Evidence threshold for that level stated explicitly
- Evidence present labeled by class (observed/stated/market/inferred)
- Verdict is one of: go/kill/park/pivot
- Kill decisions recorded to experiment-learnings.md

## What you never do

- Apply feature-level thresholds to outcome-level decisions (too low a bar)
- Apply outcome-level thresholds to feature-level decisions (too high a bar)
- Decide without checking evidence class — [inferred] alone should never produce a GO
- Skip recording kills — every kill is learning
