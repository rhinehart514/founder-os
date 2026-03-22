# Research Gotchas

Built from real failure modes. Update when /research fails in a new way.

## Research as procrastination
Previous research produced actionable findings that haven't been built. Check `scripts/research-log.sh` for unacted-on sessions before starting. If last-research.yml exists, is <24h old, and has unbuilt tasks for the bottleneck feature, the answer is `/go`, not more research.

## Confirmation bias in search queries
"Evidence that X works" finds confirmation. "Why X fails" finds disconfirmation. Always include a disconfirming query. Frame at least one search as "problems with X" or "X alternatives."

## Source quality blindness
WebSearch returns SEO farms ranked by optimization, not truth. Run `scripts/source-quality.sh tiers` to internalize the hierarchy. context7 and codebase grep are T1. Random blog posts are T3-T5. A single T1 source outweighs five T4 sources. See `references/evidence-hierarchy.md`.

## Topic repetition without action
Same topic researched 3+ times = something is wrong. Run `scripts/research-log.sh repeats` to check. Either the question is too vague (narrow it), the findings aren't actionable (convert to assertions or kill the todos), or the problem keeps shifting (update the model with why).

## context7 coverage gaps
context7 is excellent for popular frameworks, incomplete for niche libraries. If context7 returns thin results, fall back to WebSearch + official docs site via WebFetch. Don't assume silence from context7 means the feature doesn't exist.

## Findings without action
Research that produces "interesting" but no "build X" or "kill Y" is theater. Every session must end with one of: a task proposal, an assertion, a model update, or a specific next experiment. If you can't produce any of these, the research question was wrong.

## Unknown territory neglect
Known patterns are comfortable to re-validate. Unknown territory has the highest learning value. If `scripts/knowledge-gaps.sh` shows unknowns and you're researching known areas, you're confirming, not learning. Explore the unknown first.

## Market research hallucination
Market size numbers from WebSearch are unreliable. Use specific competitor evidence: "Series B with 50 employees" tells you more than "$4.2B TAM." Use `scripts/market-scan.sh` for structured competitor data. See `templates/market-context.json` for the schema.

## Dump without synthesis
If findings exceed 10 items without a "what this changes" section, you're collecting, not researching. After every 5 findings, pause and write the pattern. If no pattern after 10 items, the question is too broad. Narrow and restart.

## Source overload
More than 5 sources consulted without a finding = vague question, not insufficient data. Stop, reformulate, resume. The problem is the question, not the sources.
