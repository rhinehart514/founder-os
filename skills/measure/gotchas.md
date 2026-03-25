# Measure Gotchas — Real Failure Modes

Read before any /measure run. Merged from score, eval, and taste gotchas.

---

## Scoring & synthesis

### Tier staleness blindness
The most common failure: reading stale caches and presenting them as current. Every score MUST include a confidence level. A "92/100 (low confidence)" is more honest than "92/100" from 5-day-old data. Check `cached_at` timestamps in every cache file.

### Weight redistribution masking gaps
When visual/behavioral tiers are unavailable, their weight redistributes to code eval. This makes the score look better than reality. Always flag redistributed tiers in the output so the founder knows what's missing.

### Viability source hierarchy
Three sources with caps: agent-backed (0-100), intelligence-derived (capped at 60), no data (capped at 30). `synthesize.sh` handles this. Watch for stale intelligence: market-context.json from 2+ weeks ago may not reflect current market.

### Cross-tier contradictions
eval says craft is 85, taste says visual quality is 40. Both are correct — code quality and visual quality are different things. Don't average away the contradiction. Surface it explicitly.

### The "all green" trap
Every tier shows 80+, all confidence high. Check: is the stage appropriate? Is there real external validation? Are assertions testing behavior or just existence? 80+ across the board at early stage is almost certainly inflated.

### Sparkline noise from LLM variance
Score history includes LLM-evaluated scores that can vary ~5pts between runs. Look at trends over 5+ data points, not individual deltas. Health score (structural lint) is deterministic and safe to trust point-to-point.

### Tier badge false confidence
Showing 5/5 tiers doesn't mean the score is correct — it means data exists. Data could be stale, poorly calibrated, or contradictory. Always check staleness alongside fill rate.

### Post-commit score diff latency
Post-commit hook runs `score.sh --quiet` synchronously. If slow (>1s), check hook timeout settings.

---

## Code eval

### Rubric variance (+/-15pt swing)
Same code scored by different sessions drifts unless anchored. Always read `.claude/cache/rubrics/<feature>.json` BEFORE scoring. Run `bash scripts/variance-check.sh <feature> <score>` before publishing.

### Stage ceiling blindness
Early-stage code averaging 75+ is suspicious. MVP shouldn't score like a mature product. Check founder.yml stage field.

### Delta amnesia
Same code should get same score. If it drifts >15pts between sessions without code changes, the evaluator is miscalibrated, not the code. Re-anchor to the rubric.

### Evidence-free excellence
Any sub-score >80 without citing specific file:line evidence is inflated. "Well-structured" is not evidence. "bin/score.sh:45 — weighted formula with fallback" is.

### Scoring by volume, not value
500 lines of code != high delivery score. Delivery measures user value, not code completeness.

### Delivery-as-existence
"The feature exists, therefore delivery is 70." Existence is 30. Working is 50. Useful is 70. Loved is 90.

### Craft overfit
Clean, well-structured code that delivers nothing scores high on craft but should score low overall.

### Craft-without-error-paths
craft > 70 requires zero critical unhandled error paths. If 2>/dev/null swallows real errors, craft cannot be above 65.

### Assertion conflation
Beliefs pass rate and eval score are different things. Present beliefs as SUPPORTING metric, never the headline.

### Skim-scoring
Read EVERY file in the feature's `code:` paths. No skimming. No exceptions.

### Forgetting the merge
eval-cache.json must be MERGED with existing data, not overwritten.

---

## Visual eval

### Screenshot captures loading state
Playwright screenshots fire after wait but SPAs may take longer. If screenshot shows spinner/skeleton, wait longer. Do NOT score a loading state.

### Scoring the framework, not the product
shadcn/Tailwind defaults describe half the internet. 80+ requires craft beyond framework defaults — intentional layout, motion, or interaction choices.

### Static pages cap at 75 for polish and scroll
No motion library in codebase -> polish and scroll_experience cap at 75.

### Dimension subjectivity produces session variance
"Emotional tone" and "distinctiveness" vary 10-15 points across sessions. Without founder-taste.md, weight these lower and note "uncalibrated."

### Generous scoring on first eval
LLMs default polite. If avg > 60 on an early-stage product, re-check each dimension against anchors.

### Slop check false positives
Mechanical slop-check can't see whether defaults were customized. If visual inspection shows genuine craft, override with specific explanation.

### Prescriptions that say "add more whitespace"
Prescriptions must reference specific DOM element, CSS property, and target value. Generic advice is useless.

### Code reading misses dynamic content
Score what the user sees, not what the code can do. A route with no nav link scores differently than one with prominent navigation.

### Gate rule punishes intentional unconventionality
layout_coherence < 30 caps overall at 30. If unconventionality is intentional, flag the tension but still enforce the cap.

### Anti-inflation over-correction
Don't force genuinely strong dimensions down because the product is "early." Flag the tension, don't lie.

---

## Flows mode

### Auth-gated pages kill the flow audit
Playwright can't test authenticated experience without credentials. Test public pages or ask for test URL/token.

### Mechanical checks produce false positives on SPAs
If browser_evaluate returns suspiciously few elements, wait longer for hydration. Don't report "no interactive elements" on a React app.

### Core flow testing assumes you know the core flow
If product-spec.yml is missing and no obvious CTA, test the most prominent action. No clear action = a finding.

### Empty state testing requires knowing the empty URL
If you can't test empty state, note "untested" rather than guessing.

### Mobile responsive checks miss CSS media query bugs
Report responsive findings as "viewport-based" not "mobile-verified."

### Don't mix flows and visual findings
Flows reports functionality issues only. Note visual problems for the visual eval separately.

---

## Agent & script failures

### Agent timeout
market-analyst and customer agents can take 2-5 minutes. If they timeout, score with available data, flag what's missing.

### Scripts depend on jq
If a script fails with `jq: command not found`: tell the user (`brew install jq`), continue manually. Never skip the step.

### Comparing across different URLs
Past evals for a different URL make deltas misleading. Check URL matches before computing deltas.

### Taste/flows data format variance
Both taste and flows reports may have varying schemas. Handle missing fields gracefully.
