# Eval Gotchas

Built from real failure modes across sessions. Update this when /eval fails in a new way.

## Calibration failures

- **Rubric variance (+/-15pt swing):** Same code scored by different sessions drifts unless anchored. Always read `.claude/cache/rubrics/<feature>.json` BEFORE scoring. Run `bash scripts/variance-check.sh <feature> <score>` before publishing. If no rubric exists, flag the score as "unanchored."
- **Stage ceiling blindness:** Early-stage code averaging 75+ is suspicious. MVP shouldn't score like a mature product. Check founder.yml stage field — if mvp/one, scores above 70 need explicit justification per dimension.
- **Delta amnesia:** Ignoring eval-cache.json previous scores entirely. Same code should get same score. If it drifts >15pts between sessions without code changes, the evaluator is miscalibrated, not the code.
- **Score regression on stable code:** If the code hasn't changed (check `git log`) but the score dropped, you drifted — not the code. Re-anchor to the rubric.

## Evidence failures

- **Evidence-free excellence:** Any sub-score >80 without citing specific file:line evidence is inflated. The evaluator must point to code, not describe vibes. "Well-structured" is not evidence. "bin/score.sh:45 — weighted formula with fallback" is.
- **Viability is not eval's job:** /eval scores delivery + craft only. Viability is scored by /score via market-analyst + customer agents with cited evidence. If eval-cache.json still has `viability_score` fields from old runs, ignore them — viability-cache.json is authoritative.
- **Scoring by volume, not value:** 500 lines of code != high delivery score. A 50-line script that solves the user's problem outscores a 2000-line framework that doesn't. Delivery measures user value, not code completeness.

## Dimension failures

- **Craft overfit:** Clean, well-structured code that delivers nothing scores high on craft but should score low overall. Delivery is 50% of the formula for a reason — a beautiful corpse is still a corpse.
- **Delivery-as-existence:** "The feature exists, therefore delivery is 70." Existence is 30. Working is 50. Useful is 70. Loved is 90. Score what a user would experience, not what a file tree shows.
- **Craft-without-error-paths:** craft > 70 requires zero critical unhandled error paths. If there's a 2>/dev/null swallowing real errors, craft cannot be above 65 regardless of how clean the rest looks.

## Metric conflation

- **Assertion conflation:** Beliefs pass rate and eval score are different things. 90% assertion pass rate with 40 eval score means assertions are shallow — they test existence, not quality. Present beliefs as a SUPPORTING metric, never the headline.
- **Score-as-progress:** Score went up 5 points but delivery dimension didn't move. The improvement was cosmetic (craft polish). If delivery didn't improve, the user doesn't care.
- **Taste-eval confusion:** `/eval` reads code. `/taste` sees the product. A feature can score 80 on /eval (code is solid) and 40 on /taste (UI is terrible). They measure different things.

## Process failures

- **Skim-scoring:** Glob the file list, read 2 files, score 65. This is the most common failure. Read EVERY file in the feature's `code:` paths. No exceptions. No skimming.
- **Blind spot in blind eval:** /eval blind compares cold-read against claims. But the cold-read itself has LLM biases — it sees patterns it expects, misses patterns it doesn't. Cross-reference with mechanical checks when possible.
- **Rubric reinvention:** Clearing all criteria and starting fresh each eval. The rubric is a living document — add/remove criteria based on code changes, don't reinvent the frame. History IS calibration.
- **Forgetting the merge:** eval-cache.json must be MERGED with existing data, not overwritten. If you evaluated 3 of 8 features, the other 5 must keep their cached scores.

## Scripts may fail

Scripts in the `scripts/` folder depend on `jq`, `awk`, `grep`. If a script fails:
1. Check the error — is it a missing dependency (`jq: command not found`)?
2. If dependency missing: tell the user (`brew install jq`) and continue with manual inspection
3. If script error: read the script source to understand what it checks, do the check manually
4. Never skip the step — the script output informs the next decision
