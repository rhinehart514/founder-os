# Strategy Gotchas

Real failure modes from past sessions. Read before every `/strategy` run.

## Sycophantic diagnosis

The most common failure. The model produces a "strategy" that's actually encouragement: "Your product shows promise, the eval scores are improving, here are 5 things you could do." This is worthless. Every diagnosis must contain at least one uncomfortable truth backed by a specific number. Run `scripts/strategy-freshness.sh` first — the data makes sycophancy harder.

## Strategy as storytelling

A compelling narrative doesn't make it true. "You're building the future of product intelligence" sounds great and means nothing. Every strategic claim needs evidence from eval scores, customer signal, or market data. If you can't cite a number or a quote, you're narrating, not strategizing.

## Stale diagnosis

Strategy.yml sitting unchanged for a week while 20 commits land means the diagnosis is disconnected from reality. Run `scripts/strategy-freshness.sh` — it shows exactly what changed since the last strategy session. If the bottleneck shifted and the strategy didn't update, the strategy is wrong.

## Stage ceiling confusion

An MVP scoring 95 has a broken score, not a great product. Stage determines score ceiling. Don't congratulate a high score at an early stage — interrogate the scoring instead. Run `scripts/stage-check.sh` to mechanically verify stage.

## Competition obsession

Researching competitors for hours produces no value unless it changes a build decision. Run `scripts/competitive-scan.sh` to check market freshness. If it's recent, don't research — diagnose. If competitive research doesn't result in "build X differently because Y," it was procrastination.

## Work-to-impact invisibility

5 sessions of commits with flat score = wrong approach. But the strategy diagnosis doesn't always surface this because it reads eval-cache at a point in time. Run `scripts/work-impact.sh` to make the ratio visible. High effort + low impact is the signal to rethink, not work harder.

## Feature sprawl normalization

3+ features at "building" stage is a red flag. Founders rationalize it as "necessary breadth." At stage one, depth beats breadth every time. The stage-check script counts this mechanically — trust the count over the feeling.

## Market data hallucination

WebSearch for "market size" and competitive landscape produces SEO content, not reliable data. "The market is $4.2B" from a random blog post is noise. Use specific competitor evidence: pricing pages, user counts, GitHub stars, job postings. Read `references/market-2026.md` for verified signals before searching for more.

## Honest mode avoidance

`/strategy honest` exists but founders rarely run it because it hurts. The most valuable mode is the least used. If the founder hasn't run honest mode in 3+ sessions, suggest it. Read `references/honest-diagnosis.md` before running honest mode.

## Generic recommendations

"Focus on retention" is not a strategy. "Fix the onboarding flow because 3/5 test users dropped at the API key step, and your eval shows delivery at 40 while craft is at 70" is a strategy. Every recommendation needs: what, why (with evidence), and what it unblocks.

## Options instead of conviction

Presenting 5 options and asking the founder to pick is abdication, not strategy. The model has all the data. Give the #1 recommendation with confidence level and evidence. If genuinely uncertain, say "I don't have enough signal" and suggest what data would resolve it.
