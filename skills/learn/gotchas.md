# Learn Gotchas

Real failure modes from retro and calibration sessions. Read before every `/learn` run.

## Grading

### Grading own predictions leniently
The #1 failure mode. "It was close enough" becomes `yes` when it should be `partial`. "The spirit was right" becomes `partial` when it should be `no`. Grade against the literal text of the prediction, not what you meant.

**Fix:** Run anti-rationalization checks from `references/grading-guide.md` after every grading pass. If accuracy jumps >20% in one session, something is wrong.

### Partial as a hedge
When >50% of grades are `partial`, you're hedging. Partial means genuinely split outcomes (e.g., two targets, one hit, one missed). Not "I'm not sure." For each partial, ask: would rounding to yes or no change the model update? If yes, round.

### Qualitative predictions can't be auto-graded
"Improve error handling" has no numeric target. The grader agent will try to grade it anyway and produce confident-sounding garbage. Qualitative predictions need a proxy metric OR founder confirmation. Mark `[proposed]` and present.

### Stale predictions are hard to grade
Predictions >14 days old lose context. You'll reconstruct a plausible story instead of grading accurately. Grade weekly. Check `scripts/prediction-stats.sh` for the ungraded backlog — if it's >5, run `/learn grade` immediately.

## Knowledge model

### Dead ends that aren't dead
A "dead end" that keeps appearing in recent predictions has unresolved energy. Don't archive it — conditions may have changed (new tools, different stage, more knowledge). Move it to Uncertain with a revival note.

### Model updates without citing evidence
Every model update in experiment-learnings.md must point to a specific graded prediction. "I updated the model because it felt right" is rationalization, not learning. The prediction -> grade -> update chain is the entire point.

### Knowledge model bloat
experiment-learnings.md grows but never shrinks. After 20+ entries in any section, consolidation is overdue. The consolidator agent helps but check its work — it may merge entries that are subtly different.

### Confirmation bias in accuracy assessment
50-70% "well-calibrated" assumes uniform difficulty. A run of easy correct predictions doesn't mean the model is good — check WHAT was predicted. Five "the sun will rise" predictions at 100% accuracy tell you nothing.

### Forgetting to log the retro session
After grading, run `scripts/retro-log.sh add [route] [graded] [pruned] [accuracy] [updates] "[notes]"`. Without logging, you can't track retro frequency or spot patterns across sessions.

### Consolidator merging different patterns
The consolidator agent aggressively merges entries that look similar. Two patterns with the same keywords but different boundary conditions are NOT duplicates. Review consolidator output before committing.

## Calibration

### Founder gives vibes instead of specifics
"I like clean design" is not calibration data. It's noise. If the founder can't name a specific product and a specific element they admire, the interview hasn't worked yet. Push harder — show them screenshots of 3 products and ask which they prefer and why. Specifics or nothing.

### Design system extracted from defaults
If the codebase uses shadcn/Tailwind with zero customization, the "design system" is just framework defaults. That's still useful information — it means the product has no design system, and taste should penalize accordingly. Don't pretend defaults are intentional choices.

### Anti-slop profile is too broad
"Gradient heroes are slop" is true for most products but wrong for a creative tool or a gaming site. The anti-slop profile must be category-specific. Always check the product category before writing rules.

### Market research finds 2024 articles
Search results for "design trends" return content from 1-2 years ago. Add the current year to every search query. Verify article dates before citing them.

### Playwright can't reach competitor sites
Some sites block headless browsers. Fall back to WebSearch for design analysis. Don't skip the competitor entirely — note it as "screenshot failed, analyzed from web results."

### Calibration inflates scores
If founder preferences match the product, calibration makes dimension scores higher. But the product might still have bad execution. Calibration weights dimensions, it doesn't override evidence.

### Stale calibration is worse than no calibration
A 60-day-old anti-slop profile references patterns that are no longer generic. A 90-day-old market snapshot describes a shifted landscape. Stale calibration creates false confidence. Respect freshness-check.sh warnings.

### Over-calibrating after every eval
Calibration should be stable for weeks. If someone runs `/learn calibrate` after every `/taste` eval, they're gaming the score. Calibrate when: founder taste changes, market shifts, or product pivots.
