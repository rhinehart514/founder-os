# Prioritization Guide

How to rank moves. Read this before proposing tasks.

## The bottleneck rule

The bottleneck is NOT the lowest-scoring feature. It's the lowest sub-score of the highest-weight feature that's blocking the current thesis.

Example: scoring at 32 (w:5) with delivery=28, craft=35, viability=33. The bottleneck is scoring/delivery — the feature doesn't deliver what its claims promise. Not "scoring needs work" — "scoring's delivery needs work."

## Sub-score diagnosis

What each dragging dimension tells you to build:

| Pattern | Meaning | Task type |
|---------|---------|-----------|
| `d < c and d < v` | Delivery dragging | Complete the implementation. Don't polish. |
| `c < d and c < v` | Craft dragging | Error handling, edge cases, robustness. At stage one, this may be acceptable. |
| `v < d and v < c` | Viability dragging | Differentiation, competitive positioning, output clarity. |
| All roughly equal | Balanced weakness | Pick the dimension the thesis cares about most. |

## Tiebreaking (when multiple features compete)

1. **Thesis alignment** — does one feature directly advance an unproven roadmap evidence item? That one wins.
2. **Delta direction** — features trending `worse` get priority over stable features at the same score.
3. **Uncertainty** — pick the feature where the model is most uncertain (Unknown Territory in experiment-learnings). That's where you learn the most.
4. **Weight** — higher weight wins if all else is equal.
5. **Dependencies** — if feature A depends on feature B, and B is the bottleneck, fix B first.

## Maturity tier routing

Run `bash ../../bin/maturity-tier.sh` — the tier overrides default prioritization:

| Tier | What to prioritize | What to avoid |
|------|-------------------|---------------|
| **fix** (<50) | Failing assertions, health issues | Ideation, research, strategy, shipping |
| **deepen** (50-70) | Eval-driven tasks, assertion coverage | Ideation, shipping, pricing |
| **strengthen** (70-85) | Weakest sub-scores, research unknowns | Broad ideation, shipping without thesis |
| **expand** (85+, eval<70) | Deep feature work, targeted research | New features before existing score 70+ |
| **mature** (85+, eval 70+) | Expansion skills: /ideate, /research, /strategy, /taste, /product, /money | Grinding on features already at 80+, building without user signal |

**At mature tier:** The bottleneck is no longer "what's broken" — it's "what's missing." Prioritize:
1. Unknown territory experiments (highest learning value)
2. Skills the founder hasn't used (/ideate, /strategy, /product, /money)
3. Feature gaps identified by /ideate or /research
4. Visual quality (/taste) if web-facing

**The tier gates ideation.** Don't suggest /ideate at `fix` or `deepen`. It's earned by getting features to a solid state first. At `mature`, ideation becomes the primary recommendation.

## Stage-appropriate work

Read `startup-patterns-quick.md` for the full table, but the core rule:

- **mvp/one**: One feature, full depth. Don't spread across 3 features.
- **early/some**: Retention over acquisition. Polish existing over building new.
- **growth/many**: Distribution and onboarding. Features are secondary.
- **mature**: Unit economics. Revenue avoidance is the failure mode.

## Research-before-build gate

If the bottleneck feature has entries in Unknown Territory (experiment-learnings.md), research first. Building on an unvalidated model wastes cycles.

Exception: if the unknown is cheap to test by building (< 1 hour), skip research and build the experiment directly.

## Assertion gate

Failing `block` severity assertions = FIRST tasks, no exceptions. These are regressions — things that used to work and now don't.

## Cross-reference checklist

Before finalizing moves, cross-reference:
1. **strategy.yml bottleneck** — does it match eval bottleneck? If not, name the disconnect.
2. **last-discovery.yml** (if <7 days old) — does discovery align with eval?
3. **last-research.yml** (if <24h old) — research findings override bottleneck diagnosis (fresher evidence).
4. **todos.yml** — any backlog items that match the proposed move? Promote, don't duplicate.

## Anti-patterns

- **Comfort zone building**: Working on the feature you understand best instead of the one that matters most. Check: is this the highest-weight bottleneck, or just the most familiar?
- **Score chasing**: Picking the task that moves a number fastest instead of the task that delivers the most value. Check: would a user notice this improvement?
- **Infinite planning**: Reading a 9th data source when the bottleneck is already clear. Cap at 10 minutes.
- **Same plan, different words**: Proposing the same approach that stalled last session with slightly different framing. If it didn't work, change the approach or the angle.
- **Task inflation**: 3-5 tasks when 1-2 moves would cover it. More tasks = less focus = slower progress.
