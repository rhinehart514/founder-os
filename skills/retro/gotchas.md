# Retro Gotchas

Real failure modes from retro sessions. Read before every `/retro` run.

## Grading own predictions leniently

The #1 failure mode. "It was close enough" becomes `yes` when it should be `partial`. "The spirit was right" becomes `partial` when it should be `no`. Grade against the literal text of the prediction, not what you meant.

**Fix:** Run anti-rationalization checks from `references/grading-guide.md` after every grading pass. If accuracy jumps >20% in one session, something is wrong.

## Partial as a hedge

When >50% of grades are `partial`, you're hedging. Partial means genuinely split outcomes (e.g., two targets, one hit, one missed). Not "I'm not sure." For each partial, ask: would rounding to yes or no change the model update? If yes, round.

## Qualitative predictions can't be auto-graded

"Improve error handling" has no numeric target. The grader agent will try to grade it anyway and produce confident-sounding garbage. Qualitative predictions need a proxy metric OR founder confirmation. Mark `[proposed]` and present.

## Stale predictions are hard to grade

Predictions >14 days old lose context. You'll reconstruct a plausible story instead of grading accurately. Grade weekly. Check `scripts/prediction-stats.sh` for the ungraded backlog — if it's >5, run `/retro auto` immediately.

## Dead ends that aren't dead

A "dead end" that keeps appearing in recent predictions has unresolved energy. Don't archive it — conditions may have changed (new tools, different stage, more knowledge). Move it to Uncertain with a revival note.

## Model updates without citing evidence

Every model update in experiment-learnings.md must point to a specific graded prediction. "I updated the model because it felt right" is rationalization, not learning. The prediction → grade → update chain is the entire point.

## Knowledge model bloat

experiment-learnings.md grows but never shrinks. After 20+ entries in any section, consolidation is overdue. The consolidator agent helps but check its work — it may merge entries that are subtly different.

## Confirmation bias in accuracy assessment

50-70% "well-calibrated" assumes uniform difficulty. A run of easy correct predictions doesn't mean the model is good — check WHAT was predicted. Five "the sun will rise" predictions at 100% accuracy tell you nothing. Five "craft_score will hit 70 after this refactor" predictions at 60% accuracy tell you a lot.

## Forgetting to log the retro session

After grading, run `scripts/retro-log.sh add [route] [graded] [pruned] [accuracy] [updates] "[notes]"`. Without logging, you can't track retro frequency or spot patterns across sessions. The log is how `/retro health` knows when you last ran a retro.

## Consolidator merging different patterns

The consolidator agent aggressively merges entries that look similar. Two patterns with the same keywords but different boundary conditions are NOT duplicates. Review consolidator output before committing — check that merged entries preserve boundary conditions from both originals.
