# Score Gotchas — Real Failure Modes

Read this before every /score run.

## Tier staleness blindness

The most common failure: reading stale caches and presenting them as current. Every score MUST include a confidence level. A "92/100 (low confidence)" is more honest than "92/100" from 5-day-old data. Check `cached_at` timestamps in every cache file.

## Viability source hierarchy

Viability has three sources with caps: agent-backed (0-100), intelligence-derived (capped at 60), or no data (capped at 30). `synthesize.sh` handles this automatically. The old failure was viability scored from code reading alone — that's been removed from `/eval`. Viability only comes from external evidence now.

Watch for stale intelligence: market-context.json from 2+ weeks ago may not reflect current market. Check `analyzed_at` timestamps.

## Weight redistribution masking gaps

When visual/behavioral tiers are unavailable, their weight redistributes to code eval. This makes the score look better than reality — a product that looks terrible but has great code would score well. Always flag redistributed tiers in the output so the founder knows what's missing.

## Agent timeout

market-analyst and customer agents can take 2-5 minutes. If they timeout or return empty results, use whatever partial data exists. Don't block the entire score on one slow agent. Score with available data, flag what's missing.

## Cross-tier contradictions

eval says craft is 85, taste says visual quality is 40. Both are correct — code quality and visual quality are different things. Don't average away the contradiction. Surface it: "Code craft: 85 | Visual craft: 40 — these disagree. Trust taste for visual, eval for architecture."

## The "all green" trap

Every tier shows 80+, all confidence high. This is the moment to be most suspicious. Check: is the stage appropriate for these scores? Is there real external validation? Are the assertions testing behavior or just existence? 80+ across the board at early stage is almost certainly inflated.

## Sparkline noise from LLM variance

Score history includes LLM-evaluated scores that can vary ~5pts between runs. A sparkline showing 84→79→83 may not reflect real product change — it may be evaluation noise. Look at the trend over 5+ data points, not individual deltas. Health score (structural lint) is deterministic and safe to trust point-to-point.

## Tier badge false confidence

Showing ●●●●● (5/5 tiers) doesn't mean the score is correct — it means data exists for all tiers. The data could be stale, poorly calibrated, or contradictory. Tier fill is a completeness signal, not a quality signal. Always check staleness alongside fill rate.

## Post-commit score diff latency

The post-commit hook runs `score.sh --quiet` synchronously. If the project has many assertions, this can add 1-3 seconds to every commit. If founders report slow commits, check hook timeout settings. The score diff is health-tier only (no LLM calls) so latency should be <1s for most projects.

## Taste/flows data format

Taste reports are JSON in `.claude/evals/reports/taste-YYYY-MM-DD.json`. Flows reports are in `flows-YYYY-MM-DD.json`. Both may have varying schemas depending on when they were generated. Always handle missing fields gracefully — extract what exists, skip what doesn't.
