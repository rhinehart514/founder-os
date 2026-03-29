# Demand Gotchas

Merged from discover, blueprint, product, research, strategy. Check before every run.

## Discovery & ideation

1. **Presenting known things as insights.** Search before generating. If the first 3 results already list your idea, it's parity. Label it or don't surface it.
2. **Staying at the feature tier.** Always name the hierarchy tier. Surface at least one observation above and below the requested tier.
3. **Confusing outputs with outcomes.** "Build a dashboard" is an output. "Help the user make faster decisions about X" is an outcome. Name the outcome first.
4. **AI as add-on, not default.** Summarization, categorization, draft generation are inference calls, not features. Ask: is this a UI problem or an inference problem?
5. **Generating "different" ideas that aren't different.** A truly different mechanism changes who does the work, when it happens, or what the trigger is — not the view.
6. **Skipping the kill check.** Always run the 5-question kill check before research. Excitement is not evidence.

## System-level demand

7. **Ignoring system-level jobs.** "We need a payments system" is a system-level job, not a feature. System-level demand exists when multiple features need a shared domain. If you're grouping features by system and one system has zero features — that's a system-level demand gap.
8. **Cross-system features as normal.** A feature that spans multiple systems is a coupling smell. Either split the feature, merge the systems, or redraw boundaries. Don't normalize it.
9. **Micro-feature demand is invisible until absent.** Users won't say "I need undo." They'll say "I accidentally deleted something and couldn't get it back." Translate complaints into micro-feature jobs.

## Jobs & value props

10. **Founder language, not customer language.** "AI front office" is founder. "Answer my phone when I'm on a job" is customer. Test: would the customer say this exact sentence?
11. **Too many jobs.** 12 jobs = haven't merged. Most products: 4-6 real jobs. Merge by switching trigger.
12. **Jobs without dollars.** "Look professional" can't be priced. "$45K/year lost to missed calls" can.
13. **Tasks as jobs.** "Update my website" = task. "Look credible when Googled" = job. Jobs = progress, not actions.
14. **Missing job types.** Only listing functional jobs. Emotional and social jobs drive switching too.
15. **Feature-first value props.** "GBP-to-site in 15 minutes" = feature. "Website that stays current without you touching it" = value prop. Strip buzzwords.
16. **Can't be repeated.** >1 sentence = not a value prop. 10-second peer test.
17. **One solution per opportunity.** Torres rule: always generate 3 candidate solutions. Prevents premature convergence.

## Framing & positioning

18. **Inside-out framing.** Describing what it IS vs what it DOES for the customer.
19. **Category creation too early.** New categories need millions in marketing. Anchor to known concepts first.
20. **One frame for all contexts.** Acquisition framing differs from retention framing.

## Assumptions & coherence

21. **Not naming assumptions.** Every idea embeds assumptions. Name the 1-2 it depends on. One sentence each.
22. **Citing your own prediction as evidence.** Predictions are hypotheses. Evidence is what HAPPENED.
23. **"I would use this."** You are not your user. Name the specific person who isn't you.
24. **Market research as validation.** Competitors prove demand, not your solution.
25. **Narrative drift.** README says one thing, code does another. Run coherence checks regularly.
26. **Aspirational assertions.** If the assertion always passes, it might be testing nothing.

## Sycophancy & opinion

27. **Sycophantic diagnosis.** "Promising" and "solid foundation" are banned. Every diagnosis needs at least one uncomfortable truth with a specific number.
28. **Flat output with no opinion.** 5 equally-weighted options = cognitive burden on the founder. End with a concrete recommendation.
29. **Options instead of conviction.** Give your #1 recommendation with confidence level and evidence. If uncertain, say why.
30. **Generic recommendations.** "Focus on retention" is not strategy. Name the specific user, the specific drop-off, and the specific fix.

## Research discipline

31. **Research as procrastination.** If last research has unbuilt tasks for the bottleneck, the answer is `/go`, not more research.
32. **Confirmation bias in search.** Always include a disconfirming query. "Why X fails" alongside "evidence that X works."
33. **Source quality blindness.** SEO farms rank by optimization, not truth. Run `scripts/source-quality.sh`. A single T1 source outweighs five T4.
34. **Topic repetition without action.** Same topic 3+ times = something is wrong. Either the question is too vague or findings aren't actionable.
32. **Dump without synthesis.** After every 5 findings, pause and write the pattern. If no pattern after 10, the question is too broad.
33. **Market data hallucination.** "Series B with 50 employees" tells you more than "$4.2B TAM" from a blog post. Use specific competitor evidence.
34. **Vendor data as gospel.** Revenue loss numbers come from companies selling the fix. Note incentive.

## Stage discipline

35. **Confusing portfolio stage with evidence quality.** Stage is a lifecycle marker, not a quality signal. Assess evidence directly.
36. **Polishing at stage one.** Craft score > delivery score + 15 = polishing something that doesn't work yet.
37. **Feature sprawl.** 3+ features at "building" stage is a red flag at stage one. Depth beats breadth.
38. **Stale diagnosis.** Strategy unchanged for a week while commits land = disconnected from reality.
39. **MVP too big.** 8 features is not an MVP. 3-5 features, ONE job.
40. **Tier 1 doesn't match headline.** Framing says "we answer your phone" but tier 1 is a website builder = disconnect.
